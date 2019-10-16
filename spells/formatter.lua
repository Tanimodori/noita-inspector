formatter = {}
formatter.jsonformatter = {}

function formatter.jsonformatter:new(file)
    self.file = file
    function self:pre_format( )
        file:write("[\n")
    end
    function self:format(action, index, total)
        local json = require ("dkjson")
        if (index>1) then
            file:write(",\n")
        end
        file:write(json.encode(action))
        print(string.format("[%d/%d] action %s dumped.", index, total, action.id))
    end
    function self:post_format( )
        file:write("\n]")
    end
    return self
end

return formatter