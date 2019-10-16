loadfile("spells/reflection.lua",nil,_ENV)()

local function load_noita_symbols(path_to_data, gun_actions)
    -- get actions & 'ConfigGunActionInfo_Init' & ConfigGunShotEffects_Init
    gun_actions_base_path = path_to_data .. '\\scripts\\gun\\';

    -- enums from data/script/gun.lua
    ACTION_DRAW_RELOAD_TIME_INCREASE = 0
    ACTION_MANA_DRAIN_DEFAULT = 10
    ACTION_UNIDENTIFIED_SPRITE_DEFAULT = "data/ui_gfx/gun_actions/unidentified.png"

    loadfile(gun_actions_base_path .. "gun_enums.lua", nil, _ENV)()
    loadfile(gun_actions_base_path .. gun_actions, nil, _ENV)()
    loadfile(gun_actions_base_path .. "gunaction_generated.lua", nil, _ENV)()
    loadfile(gun_actions_base_path .. "gunshoteffects_generated.lua", nil, _ENV)()
end

local function load_reflection_symbols()
    -- Dump function args
    draw_actions = function (how_many, instant_reload_if_empty)
        function_args.draw_actions = {
            how_many = how_many,
            instant_reload_if_empty = instant_reload_if_empty
        }
    end

    add_projectile = function ( entity_filename )
        function_args.add_projectile = {
            entity_filename = entity_filename
        }
    end

    add_projectile_trigger_timer = function ( entity_filename, delay_frames, action_draw_count )
        function_args.add_projectile_trigger_timer = {
            entity_filename = entity_filename,
            delay_frames = delay_frames,
            action_draw_count = action_draw_count
        }
    end

    add_projectile_trigger_hit_world = function  ( entity_filename, action_draw_count )
        function_args.add_projectile_trigger_hit_world = {
            entity_filename = entity_filename,
            action_draw_count = action_draw_count
        }
    end

    add_projectile_trigger_death = function  ( entity_filename, action_draw_count )
        function_args.add_projectile_trigger_death = {
            entity_filename = entity_filename,
            action_draw_count = action_draw_count
        }
    end

    -- math.max hax
    local get_true_value = function(...)
        local args = {...}
        for i,v in ipairs(args) do
            if (type(v) == "table") then
                if (v.source ~= nil) then
                    args[i] = v.source.value
                else
                    args[i] = v.value
                end
            else
                args[i] = v
            end
        end
        return args
    end

    local old_math_amx = math.max
    math.max = function (...)
        return old_math_amx(table.unpack(get_true_value(...)))
    end

    -- tables
    _c = {}
    c = {source = _c}

    _shot_effects = {}
    shot_effects = {source = _shot_effects}

    -- varibles
    _current_reload_time = {name = "current_reload_time", modified = false, init_value = 0, value = 0}
    current_reload_time = {source = _current_reload_time}

    -- args
    function_args = {}
end


local function configure_reflection_env()
    ConfigGunActionInfo_Init(_c)
    ConfigGunShotEffects_Init(_shot_effects)
    -- store init value & key in field
    -- set metatable for keys
    set_reflection_metatable_for_table(c)
    set_reflection_metatable_for_table(shot_effects)
    set_reflection_metatable_for_varible(current_reload_time)
end

function load_symbols(path_to_data, gun_actions)
    load_reflection_symbols()
    load_noita_symbols(path_to_data, gun_actions)
    configure_reflection_env()
end


function exec_action(index)
    local current_action = actions[index]
    current_action.action()
    return current_action
end

