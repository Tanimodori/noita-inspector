--[[
Noita inspector by Tanimodori
MIT License

Usage lua.exe noita_inspector.lua -h
--]]


-- utils
local json = require ("dkjson")
local argparse = require ("argparse")
local jsonformatter = require ("spells/formatter").jsonformatter

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


-- main
local function main()

    -- parse args
    local args = parse_args()
    if(string.find(args.source,".lua") == nil) then
        args.source = args.source .. ".lua"
    end
    
    -- open file
    local file = io.open(args.output, "w")
    -- set env & stimulate
    spells = require("spells/spells")
    print(string.format("Dump starting, loading %s.", args.source))
    local env = spells.get_simulation_env(args.path, args.source)
    spells.simulate_action(env, jsonformatter:new(file))
    -- close file
    file:close()
    print("Dump competed.")
end

main()