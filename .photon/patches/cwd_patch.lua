-- Photon 1.0.0
-- .photon_util@cwd_patch
-- Make home directory show properly

local luapatch = require("util.luapatch")

-- Patch Shell
shell.dir = luapatch.patch("cwd_patch:shell.dir", shell.dir, function(original, ...)
    -- If not shell, run original function
    if not luapatch.is_shell() then return end

    -- Replace "home" with "~" if found as prefix
    local original_value = original()
    if string.sub(original_value, 1, 4) == "home" then
        -- Return  ~/* or ~ if home/* and home respectively
        return "~" .. string.sub(original_value,5)
    end
    -- Return original value otherwise
    return original_value
end)

-- Patches for cd ~, ls ~ and list ~ to go to /home/
shell.resolve = luapatch.patch("cwd_patch:shell.resolve", shell.resolve, function(original, ...)
    -- Shell shouldn't be patched
    if luapatch.is_shell() then return end                        

    -- Only allow cd and list (and custom ls) to be patched
    if not luapatch.is("cd") and not luapatch.is("list") and not luapatch.is("ls") then return end

    -- Store all arguments argv[1] is the requested dir
    local argv = {...}

    -- Replace "~" with "home" if found as prefix (so subdirectories work)
    local request = argv[1]
    
    if string.sub(request, 1, 1) == "~" then
        -- Return  /home/* or /home if ~/* and ~ respectively
        return "/home" .. string.sub(request,2)
    end
    
    -- Return original value
    return original(...)
end)
