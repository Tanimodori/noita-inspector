
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

local columns = require("spells/formatters/wikitextformatter/columns")

groups = {
    projectiles = {
        title = columns.title_wrapper("$__inspector_projectiles", "Projectiles"),
        contains_action = function(action, context)
            return action.type == action_type.ACTION_TYPE_PROJECTILE
        end,
        columns = columns.default_columns
    },
    static_projectiles = {
        title = columns.title_wrapper("$__inspector_static_projectiles", "Static Projectiles"),
        contains_action = function(action, context)
            return action.type == action_type.ACTION_TYPE_STATIC_PROJECTILE
        end,
        columns = {
            columns.icon,
            columns.name,
            columns.uses,
            columns.mana,
            columns.description,
            columns.fire_rate_wait,
            columns.current_reload_time,
            columns.note
        }
    },
    utility_passive = {
        title = columns.title_wrapper("$__inspector_utility_passive", "Utility/Passive"),
        contains_action = function(action, context)
            return action.type == action_type.ACTION_TYPE_UTILITY or action.type == action_type.ACTION_TYPE_PASSIVE
        end,
        columns = {
            columns.icon,
            columns.name,
            columns.uses,
            columns.mana,
            columns.description,
            columns.note
        }
    },
    modifier = {
        title = columns.title_wrapper("$__inspector_modifier", "Projectile Modifiers"),
        contains_action = function(action, context)
            return action.type == action_type.ACTION_TYPE_MODIFIER
        end,
        columns = {
            columns.icon,
            columns.name,
            columns.mana,
            columns.description,
            columns.fire_rate_wait,
            columns.note
        }
    },
    materials = {
        title = columns.title_wrapper("$__inspector_materials", "Materials"),
        contains_action = function(action, context)
            return action.type == action_type.ACTION_TYPE_MATERIAL
        end,
        columns = {
            columns.icon,
            columns.name,
            columns.uses,
            columns.description,
            columns.mana,
            columns.speed,
            columns.fire_rate_wait,
            columns.current_reload_time
        }
    },
    multicast = {
        title = columns.title_wrapper("$__inspector_multicast", "Multicast"),
        contains_action = function(action, context)
            return action.type == action_type.ACTION_TYPE_DRAW_MANY
        end,
        columns = {
            columns.icon,
            columns.name,
            columns.mana,
            columns.spread_degrees,
            columns.description
        }
    },

}

groups.default_groups = {
    groups.projectiles, 
    groups.static_projectiles, 
    groups.utility_passive, 
    groups.modifier, 
    groups.materials, 
    groups.multicast
}

return groups