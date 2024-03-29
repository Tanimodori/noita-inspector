
local function title_wrapper(source, fallback)
    return function(context)
        return context.translate(source, nil, fallback)
    end
end

local function base_column_generator(title,key,group)
    return {
        title = title_wrapper('$__inspector_'..key, title),
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
                property[func_key] and
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
            if (type(suffix) ~= 'string') then
                suffix = suffix(context)
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
        title = title_wrapper("$__inspector_icon", "Icon"),
        encode = function(action, context)
            return "[[File:Spell " .. string.gsub(string.match(action.sprite,"/([^/]+.png)$"),"_"," ") .. "]]"
        end
    },
    name = {
        title = title_wrapper("$__inspector_name", "Spell"),
        encode = function(action, context)
            local basename = action.name
            if context and context.translator then
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
        title = title_wrapper("$__inspector_description", "Description"),
        encode = function(action, context)
            local basename = action.description
            if context and context.translator then
                local translation = context.translate(basename)
                local delay_frames = utils.get_property(action, {"reflection", "function_args","add_projectile_trigger_timer","delay_frames"})
                if delay_frames then
                    -- delay_times hax
                    local timer_localized = context.translate("$__inspector_timer",nil,"timer")
                    local second_localized = context.translate("$__inspector_second",nil,"s")
                    return translation:gsub(timer_localized, string.format(timer_localized .." (%0.2f%s)",tonumber(delay_frames/60), second_localized))
                else
                    return translation
                end
            else
                return basename
            end
        end
    },
    uses = {
        title = title_wrapper("$__inspector_uses", "Uses"),
        encode = function(action, context)
            if action.max_uses then
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
        title = title_wrapper("$__inspector_damage_critical_chance", "Critical chance"),
        encode = scalar_indicator({ verifier.pure_add,
                                    verifier.pure_sub,
                                    verifier.pure_assign
                                  },
                                  {"reflection","c","damage_critical_chance"},
                                  "%",
                                  {non_negative = true}) -- fire_rate_time > 0 hax 
    },
    fire_rate_wait = {
        title = title_wrapper("$__inspector_fire_rate_wait", "Cast delay"),
        encode = scalar_indicator({ verifier.pure_add,
                                    verifier.pure_sub,
                                    verifier.pure_assign
                                  },
                                  {"reflection","c","fire_rate_wait"},
                                  title_wrapper("$__inspector_second","s"),
                                  {non_negative = true, factor = 1/60, format="%0.2f"})
    },
    spread_degrees = {
        title = title_wrapper("$__inspector_spread_degrees", "Spread modifier"),
        encode = scalar_indicator({ verifier.pure_add,
                                    verifier.pure_sub,
                                    verifier.pure_assign
                                  },
                                  {"reflection","c","spread_degrees"},
                                  title_wrapper("$__inspector_deg"," DEG"),
                                  {non_negative = true})
    },
    speed = {
        title = title_wrapper("$__inspector_speed", "Speed"),
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
        title = title_wrapper("$__inspector_spread", "Spread"),
        encode = function(action,context)
            if(type(action.spread) == "number") then
                return string.format("%0.1f" .. context.translate("$__inspector_deg",nil," DEG"), math.deg(action.spread))
            else
                return "-"
            end
        end
    },
    current_reload_time =
    {
        title = title_wrapper("$__inspector_current_reload_time", "Recharge time"),
        encode = scalar_indicator({ verifier.pure_add,
                                    verifier.pure_sub,
                                    verifier.pure_assign
                                  },
                                  {"reflection","current_reload_time","current_reload_time"},
                                  title_wrapper("$__inspector_second","s"),
                                  {non_negative = true, factor = 1/60, format="%0.2f"})
    },
    radius = {
        title = title_wrapper("$__inspector_radius", "Radius"),
        encode = function(action, context)
            local radius = action.radius
            if radius then
                ret = ""
                if radius.explosion then
                    ret = ret .. context.translate("$__inspector_explosion",nil,"s") .. ": " .. radius.explosion
                end
                return ret
            else
                return "-"
            end
        end
    },
    damage = {
        title = title_wrapper("$__inspector_damage", "Damage"),
        encode = function(action, context)
            local damage = action.damage
            if damage then
                ret = ""
                if damage.slice then
                    ret = ret .. context.translate("$__inspector_slice",nil,"s") .. ": " .. tostring(damage.slice)
                end
                if damage.fire then
                    if ret ~= "" then
                        ret = ret .. " <br/>"
                    end
                    ret = ret .. context.translate("$__inspector_fire",nil,"s") .. ": " .. tostring(damage.fire)
                end
                if damage.explosion then
                    if ret ~= "" then
                        ret = ret .. " <br/>"
                    end
                    ret = ret .. context.translate("$__inspector_explosion",nil,"s") .. ": " .. tostring(damage.explosion)
                end
                if damage.electricity then
                    if ret ~= "" then
                        ret = ret .. " <br/>"
                    end
                    ret = ret .. context.translate("$__inspector_electricity",nil,"s") .. ": " .. tostring(damage.electricity)
                end
                if damage.impact then
                    if ret ~= "" then
                        ret = ret .. " <br/>"
                        ret = ret .. context.translate("$__inspector_impact",nil,"s") .. ": " .. tostring(damage.impact)
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
        title = title_wrapper("$__inspector_note", "Notes"),
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

columns.title_wrapper = title_wrapper

return columns