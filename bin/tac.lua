-- Photon 1.0.0
-- photon@tac
-- A File listing program for ComputerCraft (but reversed)

local argv = {...}
local simple_arg = photon.lib.simple_arg
local cc_strings = photon.lib.cc_strings

local args = simple_arg.parse({"file"}, argv)

if not args["file"] then
    simple_arg.showUsage({"<file>"})
    return
end


local possible = fs.find(args["file"])
if #possible == 0 then
    -- Maybe they're checking a program
    possible = fs.find(args["file"]..".lua")

    if #possible == 0 then
        return printError("File not found!")
    end
end

local f = fs.open(possible[1], "r")
if f == nil then
    return printError("File not found!")
end
local data = f.readAll()
f.close()

local lines = cc_strings.split(data, "\n")
for i = #lines, 1, -1 do
    print(lines[i])
end
