--[[
Noita inspector by Tanimodori
MIT License

Usage lua.exe noita_inspector.lua -h
--]]


-- utils
local json = require ("dkjson")
local argparse = require ("argparse")

local function parse_args()
    local parser = argparse()
        :name "noita-inspector"
        :description "A lua script to inspect noita data."
    parser:argument("path","path to the data folder of unpacked data.wak of Noita.")
    parser:option("-s --source")
          :description "The filename of action file storing spells data."
          :default "gun_actions.lua"
    parser:option("-o --output")
          :description "The filename of output file."
          :default ("output/output_" .. os.date("%Y-%m-%d_%H%M%S",os.time()) .. ".json")
    return parser:parse()
end

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
    local args = parse_args()
    if(string.find(args.source,".lua") == nil) then
        args.source = args.source .. ".lua"
    end
    
    -- open file
    local file = io.open(args.output, "w")
    file:write("[\n")
    -- set env & stimulate
    spells = require("spells/spells")
    print(string.format("Dump starting, loading %s.", args.source))
    local env = spells.get_simulation_env(args.path, args.source)
    spells.simulate_action(env, save_result_closure(file))
    -- close file
    file:write("\n]")
    file:close()
    print("Dump competed.")
end

main()