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

    function self:index_of_locale(locale)
        local fields = self.locale_row
        -- search for index of locale
        for i, v in ipairs(fields) do
            if v == locale then
                return i
            end
        end
        return -1
    end

    function self:translate(source, locale) 
        local current_locale = locale or self.locale
        local locale_index = self:index_of_locale(current_locale)
        local fields = self.locale_row
        -- locale not found
        if locale_index == -1 then
            print("[WARN] translator: unknown locale '"..current_locale.."'")
            return source
        end
        local result = self.indecies[source]
        if result then
            if result[locale_index] ~= '' then
                return result[locale_index]
            else
                local locale_index_en = self:index_of_locale('en')
                if locale_index_en == -1 or result[locale_index_en] == '' then
                    -- word not found
                    print("[WARN] translator: unknown source '"..source.."' at locale '"..current_locale.."'")
                    return source
                else
                    -- use locale:en fallback
                    print("[WARN] translator: unknown source '"..source.."' at locale '"..current_locale.."', using locale en translation '".. result[locale_index_en] .."'")
                    return result[locale_index_en]
                end
            end
        else
            -- word not found
            print("[WARN] translator: unknown source '"..source.."' at locale '"..current_locale.."'")
            return source
        end
    end
    return self
end

return translator