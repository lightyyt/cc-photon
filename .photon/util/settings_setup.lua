-- Photon 1.0.0
-- .photon_util@settings_setup
-- A Script to set up user settings if not existing

local function create(set_key, value, desc)
    local key = "photon." .. set_key
    if settings.get(key) == nil then
        settings.define(key, {
            description = desc,
            default = value,
            type = type(value)
        })
    end
end

create("patch_cwd", true)

settings.save()