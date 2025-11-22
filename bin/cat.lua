-- Photon 1.0.0
-- photon@cat
-- A File listing program for ComputerCraft

local argv = {...}
local simple_arg = photon.lib.simple_arg

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
print(f.readAll())
f.close()