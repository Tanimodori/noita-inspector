spells = {}

function spells.get_simulation_env(path_to_data, gun_actions)
    local env = {}
    setmetatable(env,{__index=_G})
    env._G = env
    loadfile("spells/env.lua", "t", env)()
    env.load_symbols(path_to_data, gun_actions)
    return env
end

function spells.simulate_action(path_to_data, env, formatter)
    dofile("spells/exec.lua")
    if formatter.pre_format then
        formatter:pre_format()
    end
    for i,v in ipairs(env.actions) do
        action = exec_action(path_to_data, env,i)
        formatter:format(action, i, #env.actions)
    end
    if formatter.post_format then
        formatter:post_format()
    end
end

return spells