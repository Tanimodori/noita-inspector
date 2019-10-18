local function base_column_generator(title,key,group)
    return {
        title = title,
        encode = function(action)
            if action[key] == nil then
                return "-"
            else
                return tostring(action[key])
            end
        end,
        group = group
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
        local property, path = utils.get_property(action, key)
        if property == nil then
            return "-"
        else
            if property.modified and 
                property[func_key] ~= nil and
                ( 
                  (property.value == property.assign and property.value == func(property) ) or 
                  (func_key == "sub" and property.assign == 0 and context.non_negative     )
                ) then 
                return property[func_key], func_key
            else
                return "ERROR"
            end
        end
    end
end

local verifier = {
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

columns = {
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
    mana = base_column_generator("Mana drain", "mana"),
    price = base_column_generator("Price", "price"),
    type = base_column_generator("Type", "type"),
    id = base_column_generator("ID", "id"),
    damage_critical_chance = {
        title = "Critical chance",
        encode = scalar_indicator({ verifier.pure_add,
                                    verifier.pure_sub,
                                    verifier.pure_assign
                                  },
                                  {"reflection","c","damage_critical_chance"},
                                  "%",
                                  {non_negative = true}) -- fire_rate_time > 0 hax 
    },
    fire_rate_wait = {
        title = "Cast delay",
        encode = scalar_indicator({ verifier.pure_add,
                                    verifier.pure_sub,
                                    verifier.pure_assign
                                  },
                                  {"reflection","c","fire_rate_wait"},
                                  "s",
                                  {non_negative = true, factor = 1/60, format="%0.2f"})
    },
    spread_degrees = {
        title = "Spread modifier",
        encode = scalar_indicator({ verifier.pure_add,
                                    verifier.pure_sub,
                                    verifier.pure_assign
                                  },
                                  {"reflection","c","spread_degrees"},
                                  " DEG",
                                  {non_negative = true})
    },
    speed = {
        title = "Speed",
        encode = function(action,context)
            if(type(action.speed) == "table") then
                return tostring(action.speed[1]) .. "~" ..  tostring(action.speed[2])
            elseif(type(action.speed) == "number") then
                return tostring(action.speed)
            else
                return "-"
            end
        end
    },
    spread =  {
        title = "Spread",
        encode = function(action,context)
            if(type(action.spread) == "number") then
                return string.format("%0.1f DEG", math.deg(action.spread))
            else
                return "-"
            end
        end
    },
    current_reload_time =
    {
        title = "Recharge time",
        encode = scalar_indicator({ verifier.pure_add,
                                    verifier.pure_sub,
                                    verifier.pure_assign
                                  },
                                  {"reflection","current_reload_time","current_reload_time"},
                                  "s",
                                  {non_negative = true, factor = 1/60, format="%0.2f"})
    },
    radius = {
        title = "Radius",
        encode = function(action, context)
            local radius = action.radius
            if radius ~= nil then
                ret = ""
                if radius.explosion ~= nil then
                    ret = ret .. "Explosion: " .. radius.explosion
                end
                return ret
            else
                return "-"
            end
        end
    },
    damage = {
        title = "Damage",
        encode = function(action, context)
            local damage = action.damage
            if damage ~= nil then
                ret = ""
                if damage.slice ~= nil then
                    ret = ret .. "Slice: " .. tostring(damage.slice)
                end
                if damage.fire ~= nil then
                    if ret ~= "" then
                        ret = ret .. " <br/>"
                    end
                    ret = ret .. "Fire: " .. tostring(damage.fire)
                end
                if damage.explosion ~= nil then
                    if ret ~= "" then
                        ret = ret .. " <br/>"
                    end
                    ret = ret .. "Explosion: " .. tostring(damage.explosion)
                end
                if damage.impact ~= nil then
                    if ret ~= "" then
                        ret = ret .. " <br/>"
                        ret = ret .. "Impact: " .. tostring(damage.impact)
                    else
                        ret = ret  .. tostring(damage.impact)
                    end
                end
                return ret
            else
                return "-"
            end
        end
    },
    note = {
        title = "Notes",
        encode = function(action, context)
            return "-"
        end
    },
}

columns.debug_columns = {
    columns.icon,
    columns.name,
    columns.type,
    columns.id,
    columns.uses,
    columns.mana,
    columns.damage,
    columns.radius,
    columns.spread,
    columns.speed,
    columns.fire_rate_wait,
    columns.current_reload_time,
    columns.spread_degrees,
    columns.damage_critical_chance,
    columns.description,
    columns.price
}
columns.default_columns = {
    columns.icon,
    columns.name,
    columns.uses,
    columns.mana,
    columns.damage,
    columns.radius,
    columns.spread,
    columns.speed,
    columns.fire_rate_wait,
    columns.current_reload_time,
    columns.spread_degrees,
    columns.damage_critical_chance,
    columns.description
}

return columns