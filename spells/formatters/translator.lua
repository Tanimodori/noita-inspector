translator = {}

function translator:new(path, locale)
    
    if locale == nil then
        self.locale = "en"
    else
        self.locale = string.lower(locale)
    end

    local csv = require("csv")
    local path_to_translation = path .. '\\translations\\common.csv'

    self.f = csv.open(path_to_translation)
    self.indecies = {}

    -- index
    function self:index()
        for fields in self.f:lines() do
            self.indecies[ "$" .. fields[1] ] = fields
        end
    end

    function self:translate(source, locale) 
        local current_locale = self.locale
        local locale_index = -1
        if locale ~= nil then
            current_locale = locale
        end
        for fields in self.f:lines() do
            if locale_index == -1 then
                -- first line, search for index of locale
                for i, v in ipairs(fields) do
                    if v == current_locale then
                        locale_index = i
                        break
                    end
                end
                -- locale not found
                if locale_index == -1 then
                    return source
                end
            end
            result = self.indecies[source]
            if result then
                return result[locale_index]
            else
                -- word not found
                return source
            end
            -- break
        end
    end
    self:index()
    return self
end

return translator