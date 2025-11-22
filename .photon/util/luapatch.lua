-- Photon 1.0.0
-- .photon_util@luapatch
-- A Quick tool for patching functions in certain files to enhance user experience
local luapatch = {
}
function luapatch.is_shell()
    -- "shell" program gets identified by nil
    return shell.getRunningProgram() == nil or luapatch.is("shell") or luapatch.is("mshell")
end

function luapatch.is(program)
    local parts = require("cc.strings").split(shell.getRunningProgram(),"/")
    local prog = parts[#parts]
    return prog == program..".lua"
end

function luapatch.patch(identifier, value, patch)
    luapatch.enable()
    if _G.photon_luapatches == nil then _G.photon_luapatches = {} end
    
    -- Save original function (if not saved yet)
    if _G.photon_luapatches[identifier] == nil then
        _G.photon_luapatches[identifier] = value
    end
    
    -- Create patch function
    local patched = function(...)
        -- Disable Patches (blocked by default)
        --if not _G.luapatch_enabled then return _G.photon_luapatches[identifier](...) end
        
        -- Call Patch first
        local ret = patch(_G.photon_luapatches[identifier], ...)
        
        -- Return if Patch not nil
        if ret ~= nil then return ret end

        if ret == _G.luapatch_nil then
            return nil
        end
        local e = {...}
        local res = nil
        local status, error = pcall(function()
            res = _G.photon_luapatches[identifier](table.unpack(e))
        end)
        if not status then
            printError("LuaPatch, An Error ocurred!")
            printError(error)
        end
        -- Call original if patch didn't return
        return res
    end
    
    -- Return Patch
    
    return patched
end

function luapatch.disable()
    _G.luapatch_enabled = false
end

function luapatch.enable()
    _G.luapatch_enabled = true
end


_G.luapatch_nil = {}
return luapatch
