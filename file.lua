File = {
    fileExists = function (path)
        local f = io.open(path, "rb")
        if f then f:close() end
        return f ~= nil
    end,
    readFile = function (path)
        if File.fileExists(path) then            
            local f = assert(io.open(path, "rb"))
            local content = f:read("*all")
            f:close()
            return content
        end
        return ""
    end,
    readFileLines = function (path)
        if not File.fileExists(path) then return {} end
        local lines = {}
        for line in io.lines(path) do
            lines[#lines + 1] = line
        end
        return lines
    end,
    getFilename = function (path)
        return path:match("^.+/(.+)$")
    end,
    getFileExtension = function (path)
        return path:match("^.+(%..+)$")
    end
}

return File
