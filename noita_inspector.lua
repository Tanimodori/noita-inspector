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
              :args("?")
              :description "Output as wikitext. Argument are the desired outcome of your columns"
    )
    --[[
    parser:option "-n --no-trigger-and-timer"
          :args(0)
          :description "Do not print trigger and timers.",
    ]]--
    parser:option("-l --locale")
          :args(1)
          :description "The locale of wikitext output file."
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
        local context = {}
        -- columns
        local columns = wikitextformatter.columns.default_columns
        if #args.wikitext > 0 then
            if args.wikitext[1] == "debug" then
                context.columns = wikitextformatter.columns.debug_columns
            elseif args.wikitext[1] == "group" then
                context.groups = wikitextformatter.groups.default_groups
            else
                context.columns = wikitextformatter.columns.default_columns
            end
        end
        -- locale
        if args.locale ~= nil then
            -- init translator
            translator = require("i18n/translator")
            translator_instance = translator:new(args.locale)
            -- load symbols
            local path_to_translation = args.path .. '\\translations\\common.csv'
            local path_to_translation_dev = args.path .. '\\translations\\common_dev.csv'
            local inspector_translations = '.\\i18n\\inspector_translations.csv'
            translator:load(path_to_translation_dev)
            translator:load(path_to_translation)
            translator:load(inspector_translations)
            context.translator = translator_instance
        end
        spells.simulate_action(args.path, env, wikitextformatter:new(file, context))
    else
        local jsonformatter = require ("spells/formatters/jsonformatter")
        spells.simulate_action(args.path, env, jsonformatter:new(file))
    end

    -- close file
    file:close()
    print("Dump competed.")
end

main()