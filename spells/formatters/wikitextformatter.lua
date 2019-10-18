local utils = require("spells/utils")

wikitextformatter = {}

function wikitextformatter:new(file, columns, context)
    self.file = file
    self.columns = columns
    self.context = context
    function self:pre_format()
        file:write("{| class=\"wikitable sortable\" style=\"text-align: center\" width=\"100%\"\n")
        for i,column in ipairs(columns) do
            if context ~= nil and context.translator ~= nil then
                --file:write("! " .. context.translator:translate("$" .. column.title) .. "\n")
                file:write("! " .. column.title .. "\n")
            else
                file:write("! " .. column.title .. "\n")
            end
        end
    end
    function self:format(action, index, total)
        file:write("|-\n")
        for i,column in ipairs(columns) do
            file:write("| " .. column.encode(action, context) .. "\n")
        end
        print(string.format("[%d/%d] action %s dumped.", index, total, action.id))
    end
    function self:post_format()
        file:write("|}\n")
    end
    return self
end


-- types of actions
local action_type = {
    ACTION_TYPE_PROJECTILE	= 0,
    ACTION_TYPE_STATIC_PROJECTILE = 1,
    ACTION_TYPE_MODIFIER	= 2,
    ACTION_TYPE_DRAW_MANY	= 3,
    ACTION_TYPE_MATERIAL	= 4,
    ACTION_TYPE_OTHER		= 5,
    ACTION_TYPE_UTILITY		= 6,
    ACTION_TYPE_PASSIVE		= 7
}

wikitextformatter.columns = require ("spells/formatters/wikitextformatter/columns")

return wikitextformatter