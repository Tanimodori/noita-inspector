--[[
Noita inspector by Tanimodori
MIT License

Usage lua.exe noita_inspector.lua <path-to-data> [<action_file_basename>]
--]]


-- utils
local json = require ("dkjson")

local function save_result_closure(file)
    local function _save_result(file, index, total, action)
        -- get json from reflection result
        if (index>1) then
            file:write(",\n")
        end
        local json_string = json.encode(action)
        file:write(json_string)
        print(string.format("[%d/%d] action %s dumped.", index, total, action.id))
    end
    local function save_result(index, total, action)
        return _save_result(file, index, total, action)
    end
    return save_result
end

-- main
local function main()

    -- parse args
    local path_to_data = arg[1]
    local gun_actions = "gun_actions.lua"
    assert(arg[1] ~= nil, "Cannot find data")
    if (arg[2] ~= nil) then
        if(string.find(arg[2],".lua") == nil) then
            arg[2] = arg[2] .. ".lua"
        end
        gun_actions = arg[2]
    end
    
    -- open file
    local file = io.open("output/output_" .. gun_actions .. "_" .. os.date("%Y-%m-%d_%H%M%S",os.time()) .. ".json", "w")
    file:write("[\n")
    -- set env & stimulate
    spells = require("spells/spells")
    print(string.format("Dump starting, loading %s.", gun_actions))
    local env = spells.get_simulation_env(path_to_data, gun_actions)
    spells.simulate_action(env, save_result_closure(file))
    -- close file
    file:write("\n]")
    file:close()
    print("Dump competed.")
end

main()