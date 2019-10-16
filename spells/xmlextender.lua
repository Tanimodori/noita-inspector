local utils = require("spells/utils")
--Uses a handler that converts the XML to a Lua table
xmlextender = {}

function xmlextender.extend(path_to_data, action)

    -- entity_filename
    local entity_filename = utils.get_property(action, {"reflection", "function_args", "add_projectile", "entity_filename"})
    if entity_filename ~= nil then
        entity_filename = path_to_data .. "\\" .. entity_filename:gsub("^data/",""):gsub("/","\\")
        local xml2lua = require("xml2lua")
        local tree = require("xmlhandler.tree")
        local entity_xml = xml2lua.loadFile(entity_filename)
        --Instantiates the XML parser
        local handler = tree:new()
        local parser = xml2lua.parser(handler)
        parser:parse(entity_xml)
        -- XML now in handler
        local proj_cp = utils.get_property(handler, {"root", "Entity", "ProjectileComponent"})
        if proj_cp~= nil and proj_cp._attr ~= nil then
            -- speed
            local speed_min = proj_cp._attr.speed_min
            local speed_max = proj_cp._attr.speed_max
            print(speed_min, speed_max)
            if speed_min ~= nil and speed_max ~= nil then
                if speed_min < speed_max then
                    action.speed = tostring(speed_min) .. "~" .. tostring(speed_max)
                else
                    action.speed = tostring(speed_min)
                end
            end
        end
        xml2lua = nil
        handler = nil
        parser = nil
        entity_xml = nil
    end
end

return xmlextender