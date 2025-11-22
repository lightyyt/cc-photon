-- Photon 1.0.0
-- .photon_util@fs_patch
-- Make protected files and directories hidden
-- And startup.lua unwriteable

local luapatch = require("util.luapatch")

-- Patch fs.list to hide rom folder and startup file
fs.list = luapatch.patch("fs_patch:fs.list", fs.list, function(original, ...)
    -- Get arguments
    local argv = {...}

    -- Block shell from being patched
    if luapatch.is_shell() then return end
    
    -- Only allow list program to be patched
    
    if not luapatch.is("list") and not luapatch.is("ls") then return end

    -- Don't patch if bypassing
    if _G.PHOTON_SWITCH_SHOW_ALL_FILES then
        _G.PHOTON_SWITCH_SHOW_ALL_FILES = false
        return
    end

    -- If argument 1 is not empty (not in root dir), run original function
    if argv[1] ~= "" and argv[1] ~= "/" then return end

    -- Intercept original function to remove rom and startup.lua from it
    local out = {}
    for i,v in pairs(original(...)) do
        if v ~= "rom" and v ~="startup.lua" then
            table.insert(out, v)
        end
    end
    return out
end)

-- Patch fs.open to block writes to startup.lua (from ALL programs unless specified)
fs.open = luapatch.patch("fs_patch:fs.open", fs.open, function(original, ...)
    -- Run this to allow writing to startup.lua (only once)
    if _G.PHOTON_ALLOW_UNSAFE_WRITES then
        _G.PHOTON_ALLOW_UNSAFE_WRITES = false
        return
    end

    local argv = {...}

    local path = argv[1]
    local mode = argv[2]
    
    if mode == "r" then
        return original(...)
    else
        if path == "/startup.lua" or path == "startup.lua" then
            return original("/.blocked_write.lua", mode)
        end
    end
end)