local utils = require("spells/utils")

wikitextformatter = {}

function wikitextformatter:new(file, columns, context)
    self.file = file
    self.columns = columns
    self.context = context
    function self:pre_format()
        file:write("{| class=\"wikitable sortable\" style=\"text-align: center\" width=\"100%\"\n")
        for i,column in ipairs(columns) do
            if context ~= nil and context.translator ~= nil then
                --file:write("! " .. context.translator:translate("$" .. column.title) .. "\n")
                file:write("! " .. column.title .. "\n")
            else
                file:write("! " .. column.title .. "\n")
            end
        end
    end
    function self:format(action, index, total)
        file:write("|-\n")
        for i,column in ipairs(columns) do
            file:write("| " .. column.encode(action, context) .. "\n")
        end
        print(string.format("[%d/%d] action %s dumped.", index, total, action.id))
    end
    function self:post_format()
        file:write("|}\n")
    end
    return self
end



local function base_column_generator(title,key)
    return {
        title = title,
        encode = function(action)
            if action[key] ~= nil then
                return tostring(action[key])
            else
                return "-"
            end
        end
    }
end


local function print_property(property)
    print("{")
    for k,v in pairs(property) do
        print("   "..tostring(k).." = "..tostring(v))
    end
    print("}")
end

local pure_verifier_factory = function(func, func_key)
    return function(action, key, context)
        property, path = utils.get_property(action, key)
        if property == nil then
            return "-"
        else
            if  property.modified and 
                property[func_key] ~= nil and
                (property.value == property.assign or (func_key == "sub" and property.assign == 0 and context.non_negtive) ) and 
                property.value == func(property) then
                return property[func_key], func_key
            else
                return "ERROR"
            end
        end
    end
end

wikitextformatter.verifier = {
    pure_add = pure_verifier_factory(function(property) return property.init_value + property["add"] end, "add"),
    pure_sub = pure_verifier_factory(function(property) return property.init_value - property["sub"] end, "sub"),
    pure_mul = pure_verifier_factory(function(property) return property.init_value * property["mul"] end, "mul"),
    pure_div = pure_verifier_factory(function(property) return property.init_value / property["div"] end, "div"),
    pure_concat = pure_verifier_factory(function(property) return property.init_value .. property["concat"] end, "concat"),
    pure_assign = pure_verifier_factory(function(property) return property.assign end, "assign")
}

local scalar_indicator = function(verifiers, key, suffix, additional_context)
    return function(action,context)
        if additional_context == nil then
            current_context = context
        else
            current_context = setmetatable(additional_context, {__index = context})
        end
        has_error = false
        for i,verifier in ipairs(verifiers) do
            value, func_key = verifier(action, key, current_context)
            if(value == "ERROR") then
                has_error = true
            elseif (type(value) == "number") then
                break
            end
        end
        if(type(value) == "number") then
            sign = "+"
            if(func_key == "assign") then
                sign = "="
            elseif (func_key == "sub") then
                    sign = "-"
            end
            -- factor
            if (type(current_context.factor) == "number") then
                value = value * current_context.factor
            end
            -- format
            if (type(current_context.format) == "string") then
                value_string = string.format(current_context.format, value)
            else
                value_string = tostring(value)
            end
            return sign .. value_string .. suffix
        elseif has_error then
            print("[Error] Not pure scale operation detected in action id: "..action.id..path..", dumping key-values of the property")
            print_property(property)
            return "ERROR"
        else
            return value
        end
    end
end

-- page title hax
local function TitleCase(str)
	local function tchelper(first, rest)
	   return first:upper()..rest:lower()
	end
	return str:gsub("(%a)([%w_']*)", tchelper):gsub(" Of "," of ")
end

wikitextformatter.columns = {
    icon = {
        title = "Icon",
        encode = function(action, context)
            return "[[File:Spell " .. string.gsub(string.match(action.sprite,"/([^/]+.png)$"),"_"," ") .. "]]"
        end
    },
    name = {
        title = "Spell",
        encode = function(action, context)
            local basename = action.name
            if context ~= nil and context.translator ~= nil then
                if context.translator.locale == "en" then
                    return "[[" .. TitleCase(context.translator:translate(basename,"en")) .. "]]"
                else
                    return "[[" .. TitleCase(context.translator:translate(basename,"en")) .. "|" .. context.translator:translate(basename) .. "]]"
                end
            else
                return "[[" .. basename .. "]]"
            end
        end
    },
    description = {
        title = "Description",
        encode = function(action, context)
            local basename = action.description
            if context ~= nil and context.translator ~= nil then
                return context.translator:translate(basename)
            else
                return basename
            end
        end
    },
    uses = {
        title = "Uses",
        encode = function(action, context)
            if action.max_uses ~= nil then
                return tostring(action.max_uses)
            else
                return "&#8734;"
            end
        end
    },
    mana = base_column_generator("Mana Drain", "mana"),
    price = base_column_generator("Price", "price"),
    type = base_column_generator("Type", "type"),
    id = base_column_generator("ID", "id"),
    damage_critical_chance = {
        title = "Critical chance",
        encode = scalar_indicator({ wikitextformatter.verifier.pure_add,
                                    wikitextformatter.verifier.pure_sub,
                                    wikitextformatter.verifier.pure_assign
                                  },
                                  {"reflection","c","damage_critical_chance"},
                                  "%",
                                  {non_negative = true}) -- fire_rate_time > 0 hax 
    },
    fire_rate_wait = {
        title = "Cast Delay",
        encode = scalar_indicator({ wikitextformatter.verifier.pure_add,
                                    wikitextformatter.verifier.pure_sub,
                                    wikitextformatter.verifier.pure_assign
                                  },
                                  {"reflection","c","fire_rate_wait"},
                                  "s",
                                  {non_negative = true, factor = 1/60, format="%0.2f"})
    },
    spread_degrees = {
        title = "Spread modifier",
        encode = scalar_indicator({ wikitextformatter.verifier.pure_add,
                                    wikitextformatter.verifier.pure_sub,
                                    wikitextformatter.verifier.pure_assign
                                  },
                                  {"reflection","c","spread_degrees"},
                                  " DEG",
                                  {non_negative = true})
    },
    speed = base_column_generator("Speed", "speed"),
}

wikitextformatter.debug_columns = {
    wikitextformatter.columns.icon,
    wikitextformatter.columns.name,
    wikitextformatter.columns.type,
    wikitextformatter.columns.id,
    wikitextformatter.columns.uses,
    wikitextformatter.columns.mana,
    -- damage
    -- radius
    -- spread
    wikitextformatter.columns.speed,
    wikitextformatter.columns.fire_rate_wait,
    -- recharge_time
    wikitextformatter.columns.spread_degrees,
    wikitextformatter.columns.damage_critical_chance,
    wikitextformatter.columns.description,
    wikitextformatter.columns.price
}
wikitextformatter.default_columns = {
    wikitextformatter.columns.icon,
    wikitextformatter.columns.name,
    wikitextformatter.columns.uses,
    wikitextformatter.columns.mana,
    -- damage
    -- radius
    -- spread
    wikitextformatter.columns.speed,
    wikitextformatter.columns.fire_rate_wait,
    -- recharge_time
    wikitextformatter.columns.spread_degrees,
    wikitextformatter.columns.damage_critical_chance,
    wikitextformatter.columns.description
}

return wikitextformatter