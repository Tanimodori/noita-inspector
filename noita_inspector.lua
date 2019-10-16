--[[
Noita inspector by Tanimodori
MIT License

Usage lua.exe noita_inspector.lua -h
--]]


-- utils
local argparse = require ("argparse")

local function parse_args()
    local parser = argparse()
        :name "noita-inspector"
        :description "A lua script to inspect noita data."
    parser:argument("path","path to the data folder of unpacked data.wak of Noita.")
    parser:option("-s --source")
          :description "The filename of action file storing spells data."
          :default "gun_actions.lua"
    parser:mutex(
        parser:option "-j --json"
              :args(0)
              :description "Output as json.",
        parser:option "-w --wikitext"
              :args(1)
              :description "Output as wikitext. Argument are the desired outcome of your columns"
    )
    parser:option("-o --output")
          :args(1)
          :description "The filename of output file."
    return parser:parse()
end


-- main
local function main()

    -- parse args
    local args = parse_args()
    if(string.find(args.source,".lua") == nil) then
        args.source = args.source .. ".lua"
    end
    
    -- determine output location
    if args.output == nil then
        suffix = "json"
        if args.wikitext then
            suffix = "txt"
        end
        args.output = "output/output_" .. os.date("%Y-%m-%d_%H%M%S",os.time()) .. "." .. suffix
    end
    -- open file
    local file = io.open(args.output, "w")

    -- set env
    spells = require("spells/spells")
    print(string.format("Dump starting, loading %s.", args.source))
    local env = spells.get_simulation_env(args.path, args.source)
    -- simulate & print
    if args.wikitext then
        local wikitextformatter = require ("spells/formatters/wikitextformatter")
        local columns = wikitextformatter.default_columns
        if type(args.wikitext == string) then
            if args.wikitext == "debug" then
                columns = wikitextformatter.debug_columns
            end
        end
        local context = {}
        spells.simulate_action(env, wikitextformatter:new(file, columns, context))
    else
        local jsonformatter = require ("spells/formatters/jsonformatter")
        spells.simulate_action(env, jsonformatter:new(file))
    end

    -- close file
    file:close()
    print("Dump competed.")
end

main()