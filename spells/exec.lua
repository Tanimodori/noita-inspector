loadfile("spells/reflection.lua",nil,_ENV)()

-- check for updates
local function check_update_for_varible(varible, source)
    if type(varible) == "table" then
        -- expression
        varible.source.modified = (varible.source.value ~= varible.source.init_value)
        return varible
    else
        -- value
        source.modified = true
        source.assign = varible
        return setmetatable({source = source}, reflection_metatable_for_varible)
    end
end

local function copy_only_modified(reflection_table, field_name, source_table)
    for k,v in pairs(source_table) do
        if (v.modified == true) then
            if reflection_table[field_name] == nil then
                reflection_table[field_name] = {}
            end
            reflection_table[field_name][k] = v
        end
    end
end

local function get_reflection(env, action)
    action.reflection = {}
    copy_only_modified(action.reflection,"c",env.c.source)
    copy_only_modified(action.reflection,"shot_effects",env.shot_effects.source)
    copy_only_modified(action.reflection,"current_reload_time",{current_reload_time = env.current_reload_time.source})
    if function_args ~= {} then
        action.reflection.function_args = env.function_args
    end
    action.action = nil
end


function exec_action(env, index)
    -- reset env init values
    reset_table_values(env.c)
    reset_table_values(env.shot_effects)
    reset_variable_values(env.current_reload_time)
    env.function_args={}
    -- copy env
    local env_local = {}
    setmetatable(env_local,{__index=env})
    env_local._G = env_local
    -- exec action
    local action = env.exec_action(index)
    -- restore metatable & check for varible updates
    env.current_reload_time = check_update_for_varible(env.current_reload_time,env._current_reload_time)
    -- get_reflection & save them
    get_reflection(env, action)
    return action
end