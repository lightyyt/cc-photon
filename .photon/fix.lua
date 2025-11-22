-- Photon 1.0.0
-- .photon@fix
-- Fixes critical Photon files if necessary

local photon_sum = require("/lib.photonsum")
local files = {
    ["/startup.lua"]="-- Part of Photon\n-- DO NOT CHANGE!!!\n_G.require = require\npackage.path = package.path .. \";./.photon/?.lua\"\nrequire(\"photon\")"
}

-- Helper for status texts
local function coloredWrite(col, text)
    local orig = term.getTextColor()
    term.setTextColor(col)
    term.write(text)
    term.setTextColor(orig)
end

for path, expected_content in pairs(files) do
    term.write("Checking: " .. path .. "...")
    -- Checksum
    local expected_sum = photon_sum.sumString(expected_content)
    local actual_sum = photon_sum.sumFile(path)
    
    -- Status
    local x, y = term.getCursorPos()
    term.setCursorPos(x-3, y)
    if expected_sum == actual_sum then
        coloredWrite(colors.green, "  [ OK ]")
    else
        coloredWrite(colors.red, "  [FAIL]")
        print() -- Newline
        coloredWrite(colors.orange, "Fixing...")

        -- Fix file
        -- Needed, otherwise we might not be able to write to startup.lua
        _G.PHOTON_ALLOW_UNSAFE_WRITES = true
        local f = fs.open(path, "w")
        f.write(expected_content)
        f.close()

        -- End status
        local x, y = term.getCursorPos()
        term.setCursorPos(x-9, y)
        coloredWrite(colors.green, "Fixed!   ")
    end
    print() -- Newline
end