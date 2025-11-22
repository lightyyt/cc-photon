-- Photon 1.0.0
-- .photon@photon
-- Main photon "kernel"
_G.photon_version = "Photon 1.0.0"


dofile(".photon/util/settings_setup.lua")
dofile(".photon/util/set_globals.lua")


-- Patch shell.resolve to make cd ~ resolve to /home
-- and to show /home/* as ~/*
-- Only if the setting is set
if settings.get("photon.patch_cwd") then
    require("patches.cwd_patch")
end

-- Always run fs patch
require("patches.fs_patch")


-- Add Default Aliases
shell.setAlias("vim", "edit")
shell.setAlias("nvim", "edit")
shell.setAlias("vi", "edit")
shell.setAlias("nano", "edit")

function removeFileExtension(filePath)
    local filename = filePath:match("^.+/(.+)$") or filePath
    local base = filename:match("(.+)%..+$") or filename
    return base
end


-- Add Aliases for all programs in /bin/
local list = fs.list("/bin/")

if list ~= nil then
    for i, v in pairs(list) do
        local f = removeFileExtension(v)
        shell.setAlias(f, "/bin/"..v)
    end
end

fs.delete(".blocked_write.lua")
shell.setDir("/home/")

term.setTextColor(colors.purple)
print(_G.photon_version)
term.setTextColor(colors.white)


-- Inject autocompletes
local completion = require("cc.shell.completion")
local json = require("lib.json")
local bins =fs.list("/bin/")
if bins == nil then return end
for _,script in pairs(bins) do
    -- Get pure file name
    local fname = removeFileExtension(script)

    -- Get autocomplete info
    local complete = "/etc/complete/"..fname..".json"

    -- Read autocomplete file
    local f = fs.open(complete, "r")

    -- If it exists, continue
    if f ~= nil then
        -- Read the file
        local data = f.readAll()
        f.close()

        -- Convert to JSON
        local complete = json.decode(data)

        -- Store results
        local choice = {}
        local out = {}
        for _, arg in pairs(complete) do
            -- Template strings
            if arg=="&DIRS&" then
                table.insert(out, completion.dir)
            elseif arg == "&FILES&" then
                table.insert(out, { completion.file, many = true})
            else
                -- Regular strings
                table.insert(choice, arg)
            end
        end

        -- PREPEND (not append) choice if found
        if #choice ~= 0 then
            table.insert(out, 1, {completion.choice, choice})
        end

        local compl = completion.build(
            table.unpack(out)
        )
        shell.setCompletionFunction("bin/"..fname..".lua", compl)
    end
end