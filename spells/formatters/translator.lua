translator = {}

function translator:new(locale)
    
    self.locale = locale or "en"
    self.locale = string.lower(self.locale)

    local csv = require("csv")
    self.indecies = {}
    -- self.locale_row = nil

    function self:load(path)
        local f = csv.open(path)
        for fields in f:lines() do
            self.locale_row = self.locale_row or fields
            self.indecies[ "$" .. fields[1] ] = fields
        end
    end

    function self:translate(source, locale) 
        local current_locale = locale or self.locale
        local locale_index = -1
        local fields = self.locale_row
        -- search for index of locale
        for i, v in ipairs(fields) do
            if v == current_locale then
                locale_index = i
                break
            end
        end
        -- locale not found
        if locale_index == -1 then
            print("[WARN] translator: unknown locale '"..current_locale.."'")
            return source
        end
        result = self.indecies[source]
        if result and result[locale_index] ~= '' then
            return result[locale_index]
        else
            -- word not found
            print("[WARN] translator: unknown source '"..source.."' at locale '"..current_locale.."'")
            return source
        end
    end
    return self
end

return translator