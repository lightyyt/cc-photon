local simple_arg =  {}

function simple_arg.showUsage(args)
    local arg = ""
    for _, argument in pairs(args) do
        arg = arg .. " "..argument
    end

    local programName = fs.getName(shell.getRunningProgram())
    print("Usage: " .. programName .. arg)
end

function simple_arg.parse(args, argv)
    local arguments = {}

    for i, key in pairs(args) do
        -- Set K/V pair
        arguments[key] = argv[i]
    end
    return arguments
end

return simple_arg