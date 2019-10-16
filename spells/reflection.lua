-- construct reflections metatable
reflection_metatable_for_table = {
    __index = function(table, key)
        return table.source[key]
    end,
    __newindex = function(table, key, value)
        if( type(value) == "table") then
            -- expression
            table[key].assign = value.value
        else
            -- raw value
            table[key].assign = value
        end
        table[key].modified = true
    end
}
reflection_metatable_for_keys = {
    __tostring = function(this)
        return this.value
    end,
    __add = function(this, that)
        if type(that) == "table" then
            this, that = that, this
        end
        if(this.add == nil) then
            this.add = 0
        end
        this.add = this.add + that
        this.value = this.value + that
        return this
    end,
    __sub = function(this, that)
        if type(that) == "table" then
            this, that = that, this
        end
        if(this.sub == nil) then
            this.sub = 0
        end
        this.sub = this.sub + that
        this.value = this.value - that
        return this
    end,
    __mul = function(this, that)
        if type(that) == "table" then
            this, that = that, this
        end
        if(this.mul == nil) then
            this.mul = 1
        end
        this.mul = this.mul * that
        this.value = this.value * that
        return this
    end,
    __div = function(this, that)
        if type(that) == "table" then
            this, that = that, this
        end
        if(this.div == nil) then
            this.div = 1
        end
        this.div = this.div * that
        this.value = this.value / that
        return this
    end,
    __concat = function(this, that)
        if type(that) == "table" then
            this, that = that, this
        end
        if(this.concat == nil) then
            this.concat = ""
        end
        this.concat = this.concat .. that
        this.value = this.value .. that
        return this
    end
}
reflection_metatable_for_varible = {
    __tostring = function(this)
        return this.source.value
    end,
    __add = function(this, that)
        if type(that) == "table" then
            this, that = that, this
        end
        if(this.source.add == nil) then
            this.source.add = 0
        end
        this.source.add = this.source.add + that
        this.source.value = this.source.value + that
        return this
    end,
    __sub = function(this, that)
        if type(that) == "table" then
            this, that = that, this
        end
        if(this.source.sub == nil) then
            this.source.sub = 0
        end
        this.source.sub = this.source.sub + that
        this.source.value = this.source.value - that
        return this
    end,
    __mul = function(this, that)
        if type(that) == "table" then
            this, that = that, this
        end
        if(this.source.mul == nil) then
            this.source.mul = 1
        end
        this.source.mul = this.source.mul * that
        this.source.value = this.source.value * that
        return this
    end,
    __div = function(this, that)
        if type(that) == "table" then
            this, that = that, this
        end
        if(this.source.div == nil) then
            this.source.div = 1
        end
        this.source.div = this.source.div * that
        this.source.value = this.source.value / that
        return this
    end,
    __concat = function(this, that)
        if type(that) == "table" then
            this, that = that, this
        end
        if(this.source.concat == nil) then
            this.source.concat = ""
        end
        this.source.concat = this.source.concat .. that
        this.source.value = this.source.value .. that
        return this
    end
}

-- reflection setter
function reset_table_values(table)
    for k,v in pairs(table.source) do
        table.source[k].value = table.source[k].init_value
        table.source[k].add = nil
        table.source[k].sub = nil
        table.source[k].mul = nil
        table.source[k].div = nil
        table.source[k].assign = nil
        table.source[k].concat = nil
        table.source[k].modified = false
    end
end

function reset_variable_values(variable)
    variable.source.value = variable.source.init_value
    variable.source.add = nil
    variable.source.sub = nil
    variable.source.mul = nil
    variable.source.div = nil
    variable.source.assign = nil
    variable.source.concat = nil
    variable.source.modified = false
end

function set_reflection_metatable_for_table(table)
    for k,v in pairs(table.source) do
        table.source[k] = setmetatable({ name = k, modified = false, init_value = v, value = v}, reflection_metatable_for_keys)
    end
    setmetatable(table, reflection_metatable_for_table)
end

function set_reflection_metatable_for_varible(varible)
    setmetatable(varible.source,reflection_metatable_for_keys)
    setmetatable(varible, reflection_metatable_for_varible)
end