-- Photon 1.0.0
-- .photon_util@set_globals
-- A Script to add all files inside the lib folder into "photon.lib.*"
-- So you can just do photon.lib.cc_strings.split().
-- No need for require now, usually.

_G.photon = {}
_G.photon.lib = {}

_ENV.photon = _G.photon

-- Get lib files
local path = "/lib/"
local path_alt="lib."


local function removeFileExtension(filePath)
    local filename = filePath:match("^.+/(.+)$") or filePath
    local base = filename:match("(.+)%..+$") or filename
    return base
end


-- Get all lib files
for i, v in pairs(fs.list(path)) do
    -- Remove file extensions
    local no_file_ext = removeFileExtension(v)

    -- Add file
    _G.photon.lib[no_file_ext] = require(path_alt..no_file_ext)
end