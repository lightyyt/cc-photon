local pathutils={}

-- Remove file extension
-- e.g. /a/.e/b.directory/file.txt -> /a/.e/b.directory/file
function pathutils.removeFileExtension(filePath)
    local filename = filePath:match("^.+/(.+)$") or filePath
    local base = filename:match("(.+)%..+$") or filename
    return base
end



-- Get Relative Path.
-- e.g. /dir/files/file -> file
function pathutils.relativePath(filePath)
    local list = photon.lib.cc_strings.split(filePath, "/")

    -- Return last element
    return list[#list]
end

return pathutils