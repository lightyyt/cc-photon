local argv = {...}
local simple_arg = photon.lib.simple_arg
local pathutils = photon.lib.pathutils
local mf = photon.lib.morefonts

local args = simple_arg.parse({"program"}, argv)

if not args["program"] then
    simple_arg.showUsage({"<program>"})
    return
end


local manpage = "/etc/man/"..pathutils.removeFileExtension(args["program"])..".md"
if not fs.exists(manpage) then
    printError("photon@man error, page '"..manpage.."' does not exist!")
    return
end

local f = fs.open(manpage, "r")
if f == nil then
    printError("photon@man error reading page '"..manpage.."'!")
    return
end

local md_data = f.readAll()
local lines = photon.lib.cc_strings.split(md_data, "\n")
f.close()

local font = "fonts/Scientifica"
local tinyFont="fonts/Silkscreen"

local sw, sh = term.getSize()

local multilineCodeStarted = false

local yOff = 1
local yOffChanged = false
local function parseLine(line)
    local x, y = term.getCursorPos()

    if y >= sh then
        local _, key = os.pullEvent("key")
        if key == keys.up or key == keys.w then
            yOff=yOff+1
            if yOff > 1 then yOff = 1 end
            yOffChanged = true
        elseif key == keys.down or key == keys.s then
            yOff=yOff-1
            yOffChanged = true
        elseif key == keys.enter then
            return -1
        end
    end
    local inf = photon.lib.cc_strings.split(line, " ")
    if multilineCodeStarted then
        term.setBackgroundColor(colors.gray)
        if line == "```" then
            term.setBackgroundColor(colors.black)
            multilineCodeStarted = false
            return
        end
        term.write(line)
        term.write(string.rep(" ",sw-#line))
        print()
        return
    end

    if inf[1] == "#" then
        mf.print(string.sub(line,3), {font=font, scale=1.5, dx=sw, textAlign="center", condense=true})
    elseif inf[1] == "##" then
        mf.print(string.sub(line,4), {font=font, scale=1, dx=sw, textAlign="center", condense=true})
    elseif inf[1] == "###" then
        mf.print(string.sub(line,4), {font=tinyFont, scale=1, dx=sw, textAlign="center", condense=true})
    elseif line == "```" then
        multilineCodeStarted = true
    else
        -- Handle lists
        if string.sub(line,1,1) == "-" then
            line = " \07"..string.sub(line,2)
        end

        -- Handle oneline code
        local start, send = string.find(line, "`.*`")
        if start ~= nil and send ~= nil then
            term.write(string.sub(line, 1, start-1))
            term.setBackgroundColor(colors.gray)
            term.write(string.sub(line, start+1, send-1))
            term.setBackgroundColor(colors.black)
            term.write(string.sub(line, send+1))
            print()
        else
            print(line)
        end
        
    end
end



local function doParse()
    local prevOff = yOff
    for _, line in pairs(lines) do
        if parseLine(line) == -1 then return -1 end
        if yOff ~= prevOff or yOffChanged then
            yOffChanged = false
            return
        end
    end
    return 1
end
while true do
    term.setCursorPos(1,yOff)
    term.clear()
    local res = doParse()
    if res == -1 then return
    elseif res == 1 then
        if yOff == 1 then return end -- Exit short manuals
        sleep(0.01)
    end

end