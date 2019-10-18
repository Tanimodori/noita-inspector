local utils = require("utils")

wikitextformatter = {}

function wikitextformatter:new(file, context)
    -- fallback translating function
    context = context or {}
    function context.translate(source, locale, fallback)
        local translation = nil
        if context.translator then
            translation = context.translator:translate(source, locale)
        else
            translation = source
        end

        if translation == source and string.find(translation,"$") then
            -- try fallback
            if fallback then
                return fallback
            end
        end
        return translation
    end

    function self:pre_format()
        if context.groups then
            -- grouped
            for i,group in ipairs(context.groups) do
                group.actions = {}
                group.action_ids = {}
            end
        else
            -- column
            file:write("{| class=\"wikitable sortable\" style=\"text-align: center\" width=\"100%\"\n")
            for i,column in ipairs(context.columns) do
                -- if context ~= nil and context.translator ~= nil then
                --file:write("! " .. context.translator:translate("$" .. column.title) .. "\n")
                file:write("! " .. column.title(context) .. "\n")
            end
        end
    end
    function self:format(action, index, total)
        if context.groups then
            -- grouped
            for i,group in ipairs(context.groups) do
                if group.contains_action(action, context) then
                    table.insert(group.action_ids, action.id)
                    group.actions[action.id] = "|-\n"
                    for j,column in ipairs(group.columns) do
                        group.actions[action.id] = group.actions[action.id] .. "| " .. column.encode(action, context) .. "\n"
                    end
                end
            end
            print(string.format("[%d/%d] action %s dumped.", index, total, action.id))
        else
            -- column
            file:write("|-\n")
            for i,column in ipairs(context.columns) do
                file:write("| " .. column.encode(action, context) .. "\n")
            end
            print(string.format("[%d/%d] action %s dumped.", index, total, action.id))
        end
    end
    function self:post_format()
        if context.groups then
            -- grouped
            file:write("== " .. context.translate("$__inspector_list_of_spells", nil, "List Of Spells") .. " ==\n")
            for i,group in ipairs(context.groups) do
                -- headers
                file:write("=== " .. group.title(context) .. " ===\n")
                file:write("{| class=\"wikitable sortable\" style=\"text-align: center\" width=\"100%\"\n")
                for i,column in ipairs(group.columns) do
                    file:write("! " .. column.title(context) .. "\n")
                end

                -- contents
                table.sort(group.action_ids)
                for j,id in ipairs(group.action_ids) do
                    file:write(group.actions[id])
                end

                -- footers
                file:write("|}\n\n")
            end
        else
            -- column
            file:write("|}\n")
        end
    end
    return self
end

wikitextformatter.columns = require ("spells/formatters/wikitextformatter/columns")
wikitextformatter.groups = require ("spells/formatters/wikitextformatter/groups")

return wikitextformatter