local utils = require("utils")
--Uses a handler that converts the XML to a Lua table
xmlextender = {}

local function load_projectile_handler(path_to_data, action)
    -- entity_filename
    local entity_filename = utils.get_property(action, {"reflection", "function_args", "add_projectile", "entity_filename"})
    if entity_filename then
        entity_filename = path_to_data .. "\\" .. entity_filename:gsub("^data/",""):gsub("/","\\")
        local xml2lua = require("xml2lua")
        local tree = require("xmlhandler.tree")
        local entity_xml = xml2lua.loadFile(entity_filename)
        --Instantiates the XML parser
        local handler = tree:new()
        local parser = xml2lua.parser(handler)
        parser:parse(entity_xml)
        -- XML now in handler
        return handler
    end
    return nil
end

-- return a list of components from document recursively
local function load_components(document, targets)
    local current_targets = nil
    if type(targets) == "string" then
        current_targets = {targets}
    else
        current_targets = targets
    end

    local ret = {}
    for key,value in pairs(document) do
        if utils.index_of(key,current_targets) ~= -1 then
            table.insert(ret, value)
        else
            -- get ProjectileComponent recursively
            if type(value) == "table" then
                local sub_ret = load_components(value, targets)
                if #sub_ret > 0 then
                    -- insert into return values
                    for i,comp in ipairs(sub_ret) do table.insert(ret, comp) end
                end
            end
        end
    end
    return ret
end

function xmlextender.extend(path_to_data, action)
    local handler = load_projectile_handler(path_to_data, action)
    if handler then
        local entity = utils.get_property(handler, {"root", "Entity"})
        if entity then
            for i,proj_cp in ipairs(load_components(entity, {"ProjectileComponent", "LightningComponent"})) do 
                if proj_cp and proj_cp._attr then
                    -- speed_min, speed_max -> speed
                    local speed_min = proj_cp._attr.speed_min
                    local speed_max = proj_cp._attr.speed_max
                    if speed_min and speed_max then
                        if speed_min < speed_max then
                            action.speed = {tonumber(speed_min),tonumber(speed_max)}
                        else
                            action.speed = tonumber(speed_min)
                        end
                    end
                    -- direction_random_rad -> spread
                    local spread = proj_cp._attr.direction_random_rad
                    if spread then
                        action.spread = tonumber(spread)
                    end
                    -- damage
                    _damage = {modified = false}
                    local damage_impact = proj_cp._attr.damage
                    if damage_impact and tonumber(damage_impact) > 0 then
                        _damage.impact = damage_impact * 25
                        _damage.modified = true
                    end
                    -- config_explosion
                    local config_explosion_attr = utils.get_property(proj_cp, {"config_explosion","_attr"})
                    if config_explosion_attr then
                        -- radius
                        local explosion_radius = config_explosion_attr.explosion_radius 
                        if explosion_radius and tonumber(explosion_radius) > 0 then
                            action.radius = {explosion = explosion_radius}
                        end
                        -- damage
                        local damage_explosion = config_explosion_attr.damage
                        if damage_explosion and tonumber(damage_explosion) > 0 then
                            _damage.explosion = damage_explosion * 100
                            _damage.modified = true
                        end
                    end
                    -- damage_by_type
                    local damage_by_type_attr = utils.get_property(proj_cp, {"damage_by_type","_attr"})
                    if damage_by_type_attr then
                        -- slice
                        local damage_slice = damage_by_type_attr.slice
                        if damage_slice and tonumber(damage_slice) > 0 then
                            _damage.slice = damage_slice * 25
                            _damage.modified = true
                        end
                        -- fire
                        local damage_fire = damage_by_type_attr.fire
                        if damage_fire and tonumber(damage_fire) > 0 then
                            _damage.fire = damage_fire * 25
                            _damage.modified = true
                        end
                        -- electricity
                        local damage_electricity = damage_by_type_attr.electricity
                        if damage_electricity and tonumber(damage_electricity) > 0 then
                            _damage.electricity = damage_electricity * 500
                            _damage.modified = true
                        end
                    end
                    if _damage.modified then
                        action.damage = _damage
                    end
                end
            end
        end
    end
end

return xmlextender