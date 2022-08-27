Data = {
    Set = function (list)
        local set = {}
        setmetatable(set, {
            __sub = function (s1, s2)
                local newSet = Data.Set()
                for elem, _ in pairs(s1) do
                    if not s2[elem] then
                        newSet[elem] = true
                    end
                end
                return newSet
            end,
            __add = function (s1, s2)
                local newSet = Data.Set()
                for elem, _ in pairs(s1) do newSet[elem] = true end
                for elem, _ in pairs(s2) do newSet[elem] = true end
                return newSet
            end,
            __tostring = function (s1)
                local s, i = "{", 1
                for elem, _ in pairs(s1) do
                    s = s .. tostring(elem)
                    if i ~= #s1 then
                        s = s .. ", "
                    end
                    i = i + 1
                end
                return s .. "}"
            end
        })
        if list then
            for _, l in ipairs(list) do set[l] = true end
        end
        return set
    end
}

return Data
