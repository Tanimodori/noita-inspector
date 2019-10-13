--[[
Noita inspector by Tanimodori
MIT License

Usage lua.exe noita_inspector.lua <path-to-data> [<action_file_basename>]
--]]

-- utils
local json = require ("dkjson")

-- shallow copy
local function table_clone(org)
    return {table.unpack(org)}
end

local function copy_only_modified(reflection_table, field_name, source_table)
    for k,v in pairs(source_table) do
        if (v.modified == true) then
            if reflection_table[field_name] == nil then
                reflection_table[field_name] = {}
            end
            reflection_table[field_name][k] = v
        end
    end
end

-- parse args
local path_to_data = arg[1]
local gun_actions = "gun_actions.lua"

assert(arg[1] ~= nil, "Cannot find data")

if (arg[2] ~= nil) then
    if(string.find(arg[2],".lua") == nil) then
        arg[2] = arg[2] .. ".lua"
    end
    gun_actions = arg[2]
end



-- get actions & 'ConfigGunActionInfo_Init' & ConfigGunShotEffects_Init
gun_actions_base_path = path_to_data .. '\\scripts\\gun\\';
print(string.format("Dump starting, loading %s.",gun_actions_base_path .. gun_actions))

-- enums
dofile(gun_actions_base_path .. "gun_enums.lua")
ACTION_DRAW_RELOAD_TIME_INCREASE = 0
ACTION_MANA_DRAIN_DEFAULT = 10
ACTION_UNIDENTIFIED_SPRITE_DEFAULT = "data/ui_gfx/gun_actions/unidentified.png"

dofile(gun_actions_base_path .. gun_actions)
dofile(gun_actions_base_path .. "gunaction_generated.lua")
dofile(gun_actions_base_path .. "gunshoteffects_generated.lua")


-- Dump function args
function draw_actions(how_many, instant_reload_if_empty)
    function_args.draw_actions = {
        how_many = how_many,
        instant_reload_if_empty = instant_reload_if_empty
    }
end


function add_projectile( entity_filename )
	function_args.add_projectile = {
        entity_filename = entity_filename
    }
end

function add_projectile_trigger_timer( entity_filename, delay_frames, action_draw_count )
	function_args.add_projectile_trigger_timer = {
        entity_filename = entity_filename,
        delay_frames = delay_frames,
        action_draw_count = action_draw_count
    }
end

function add_projectile_trigger_hit_world( entity_filename, action_draw_count )
	function_args.add_projectile_trigger_hit_world = {
        entity_filename = entity_filename,
        action_draw_count = action_draw_count
    }
end

function add_projectile_trigger_death( entity_filename, action_draw_count )
	function_args.add_projectile_trigger_death = {
        entity_filename = entity_filename,
        action_draw_count = action_draw_count
    }
end


-- construct metatable
reflection_metatable_for_table = {
    __index = function(table, key)
        return table.source[key]
    end,
    __newindex = function(table, key, value)
        table[key].assign = value
        table[key].modified = true
    end
}
reflection_metatable_for_keys = {
    __add = function(this, that)
        if type(that) == "table" then
            this, that = that, this
        end
        this.add = that
        return this.init_value + that
    end,
    __sub = function(this, that)
        if type(that) == "table" then
            this, that = that, this
        end
        this.sub = that
        return this.init_value - that
    end,
    __mul = function(this, that)
        if type(that) == "table" then
            this, that = that, this
        end
        this.mul = that
        return this.init_value * that
    end,
    __div = function(this, that)
        if type(that) == "table" then
            this, that = that, this
        end
        this.div = that
        return this.init_value / that
    end,
    __concat = function(this, that)
        if type(that) == "table" then
            this, that = that, this
        end
        this.concat = that
        return this.init_value .. that
    end
}
reflection_metatable_for_varible = {
    __add = function(this, that)
        if type(that) == "table" then
            this, that = that, this
        end
        this.source.add = that
        return this.source.init_value + that
    end,
    __sub = function(this, that)
        if type(that) == "table" then
            this, that = that, this
        end
        this.source.sub = that
        return this.source.init_value - that
    end,
    __mul = function(this, that)
        if type(that) == "table" then
            this, that = that, this
        end
        this.source.mul = that
        return this.source.init_value * that
    end,
    __div = function(this, that)
        if type(that) == "table" then
            this, that = that, this
        end
        this.source.div = that
        return this.source.init_value / that
    end,
    __concat = function(this, that)
        if type(that) == "table" then
            this, that = that, this
        end
        this.source.concat = that
        return this.source.init_value .. that
    end
}

local function set_reflection_metatable_for_table(table)
    for k,v in pairs(table.source) do
        table.source[k] = setmetatable({ name = k, modified = false, init_value = v}, reflection_metatable_for_keys)
    end
    setmetatable(table, reflection_metatable_for_table)
end

local function set_reflection_metatable_for_varible(varible)
    setmetatable(varible.source,reflection_metatable_for_keys)
    setmetatable(varible, reflection_metatable_for_varible)
end

-- check for updates
local function check_update_for_varible(varible, source)
    if type(varible) ~= "table" then
        source.modified = true
        source.assign = varible
        return setmetatable({source = source}, reflection_metatable_for_varible)
    end
    return varible
end

-- init a simulation environments
local function init_simulation()
    -- init states

    -- tables
    _c = {}
    ConfigGunActionInfo_Init(_c)
    c = {source = _c}

    _shot_effects = {}
    ConfigGunShotEffects_Init(_shot_effects)
    shot_effects = {source = _shot_effects}

    -- varibles
    _current_reload_time = {name = "current_reload_time", modified = false, init_value = 0}
    current_reload_time = {source = _current_reload_time}

    -- args
    function_args = {}
    
    -- store init value & key in field
    -- set metatable for keys
    set_reflection_metatable_for_table(c)
    set_reflection_metatable_for_table(shot_effects)
    set_reflection_metatable_for_varible(current_reload_time)
end

local function simulate(action)
    action.action()
    -- restore metatable & check for varible updates
    current_reload_time = check_update_for_varible(current_reload_time,_current_reload_time)
end

local function get_reflection(action)
    action.reflection = {}
    copy_only_modified(action.reflection,"c",c.source)
    copy_only_modified(action.reflection,"shot_effects",shot_effects.source)
    copy_only_modified(action.reflection,"current_reload_time",{current_reload_time = current_reload_time.source})
    if function_args ~= {} then
        action.reflection.function_args = function_args
    end
    action.action = nil
end

-- io
local file, err = io.open("output_" .. gun_actions .. "_" .. os.date("%Y-%m-%d_%H%M%S",os.time()) .. ".json", "w")
file:write("[\n")
-- stimulate
for i,v in ipairs(actions) do
    init_simulation()
    simulate(v)
    get_reflection(v)

    -- get json from reflection result
    if (i>1) then
        file:write(",\n")
    end
    local json_string = json.encode(v)
    file:write(json_string)

    print(string.format("[%d/%d] action %s dumped.", i, #actions, v.id))
end
file:write("]")
file:close()

print("Dump competed.")