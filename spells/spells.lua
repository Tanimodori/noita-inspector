spells = {}

function spells.get_simulation_env(path_to_data, gun_actions)
    local env = {}
    setmetatable(env,{__index=_G})
    env._G = env
    loadfile("spells/env.lua", "t", env)()
    env.load_symbols(path_to_data, gun_actions)
    return env
end

function spells.simulate_action(env, save_result)
    dofile("spells/exec.lua")
    for i,v in ipairs(env.actions) do
        action = exec_action(env,i)
        save_result(i, #env.actions, action)
    end
end

return spells