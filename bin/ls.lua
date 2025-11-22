-- Photon 1.0.0
-- photon@ls
-- Advanced file listing tool

local args = {...}

local cwd = shell.dir()

local switch_long_list = false -- "-l"
local switch_all = false -- "-a"
-- args like "-la" will also work :3

local paths = {}

for _, arg in pairs(args) do
    if string.sub(arg,1,1) == "-" then
        for switchI=2, #arg do
            local switch = string.sub(arg, switchI, switchI)
            if switch == "l" then
                switch_long_list = true
            elseif switch == "a" then
                switch_all = true
            end
        end
    else
        table.insert(paths, arg)
    end
end

local function sizeStr(size)
    local s = tostring(size)

    return string.rep(" ", 5-#s) .. s
end

local function getAllOfPath(path)
    local showHidden = settings.get("list.show_hidden")
    if path == "~" then path ="/home" end
    if not fs.exists(path) then
        printError("photon@ls: '".. path .."' does not exist.")
        return
    elseif not fs.isDir(path) then
        printError("photon@ls: '".. path .."' is not a directory.")
        return
    end


    -- Storage
    if switch_all then _G.PHOTON_SWITCH_SHOW_ALL_FILES = true end
    local all = fs.list(path)
    local files = {}
    local dirs = {}

    if not all then
        printError("photon@ls: Error reading '".. path .."'.")
        return
    end

    -- Parse
    for _, value in pairs(all) do
        if showHidden or string.sub(value, 1, 1) ~= "." or switch_all then
            local path = fs.combine(path, value)
            if fs.isDir(path) then
                table.insert(dirs, value)
            else
                table.insert(files, value)
            end
        end
    end

    -- Print
    local dirColor = colors.green
    local dangerColor=colors.red
    if not term.isColor() then dirColor = colors.lightGray end
    if not term.isColor() then dangerColor = colors.gray end

    if switch_long_list then
        for _, dir in pairs(dirs) do

            --local size = fs.getSize(fs.combine(path, dir)) -- Maybe some other day >n<
            term.setTextColor(colors.white)
            term.write(sizeStr("[DIR]").. " ")
            term.setTextColor(dirColor)
            if dir == "rom" then term.setTextColor(dangerColor) end
            
            print(dir)
        end
        for _, file in pairs(files) do

            local size = fs.getSize(fs.combine(path, file))
            term.setTextColor(colors.white)
            term.write(sizeStr(size).. " ")

            term.setTextColor(colors.white)
            if file == "startup.lua" then term.setTextColor(dangerColor) end

            print(file)
        end
    else
        textutils.pagedTabulate(dirColor, dirs, colors.white, files)
    end
    term.setTextColor(colors.white)
end

if #paths == 0 then
    getAllOfPath(cwd)
elseif #paths == 1 then
    getAllOfPath(paths[1])
else
    for _, path in pairs(paths) do
        print(path..": ")
        getAllOfPath(path)
        print() -- Newline
    end
end