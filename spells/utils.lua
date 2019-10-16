utils = {}

function utils.get_property(action, key)
    if type(key) == "table" then
        path = ""
        property = action
        for i,v in ipairs(key) do
            if property == nil then
                return nil
            end
            property = property[v]
            path = path .. "." .. v
        end
    else
        if action == nil then
            return nil
        end
        path = key
        property = action[key]
    end
    return property, path
end

return utils