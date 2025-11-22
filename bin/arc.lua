-- Photon 1.0.0
-- photon@arc
-- A Package manager for Photon on ComputerCraft / CC: Tweaked

----[[      Libraries      ]]----
local json = photon.lib.json

----[[      Variables      ]]----
local error = printError
local argv = {...}


-- Check HTTP API Availability
if not http then
    error("Fatal Error!")
    error("Arc requires HTTP access to function!")
    error("Please enable HTTP API access inside your cc:tweaked server config to continue!")
    return
end

----[[      Utility      ]]----
local function invalidUsage()
    error("Invalid Usage!")
    print("Type \"arc help\" for usage information")
end

local function getJson(url)
    -- HTTP request
    local response = http.get(url)
    if not response then return nil end

    -- Read and Decode
    local data = json.decode(response.readAll())

    response.close()
    return data
end


local function getInstalledList()
    -- Get Installed File
    local file = fs.open("/etc/arc/installed.json", "r")
    local list = json.decode(file.readAll())
    -- Close and Return
    file.close()
    return list
end

local function isInstalled(pkg, version)
    local list = getInstalledList()
    
    if list[pkg] == nil then
        return nil -- Package not installed
    end

    if list[pkg] == version then
        return true -- Exists and version matches
    end

    return false -- Exists but version mismatch
end

local function tableContains(tbl, element)
    for _, v in pairs(tbl) do
        if v == element then
            return true
        end
    end
    return false
end

local function carriageReturn(wasWrite)
    local _, y = term.getCursorPos()
    if wasWrite then
        term.setCursorPos(1, y) -- Write doesn't do \n
    else
        term.setCursorPos(1, y - 1) -- Print does
    end
end

----[[    Repo Management    ]]----
local repo = {}

function repo.add(url)
    local out = getJson(url)
    
    if out == nil then
        error("Repository arc.repo.json not found!")
        error("Is it an arc-repo and does it exist?")
        return 2
    end
    
    local repoData = repo.getAll()
    repoData[out["name"]] = out
    

    local repos = fs.open("/etc/arc/repos.json", "w")
    repos.write(json.encode(repoData))
    repos.close()
end

function repo.getAll()
    -- Get Repo file
    local repos = fs.open("/etc/arc/repos.json", "r")
    local repoData = json.decode(repos.readAll())
    -- Close and Return
    repos.close()
    return repoData
end


----[[      Installer functions      ]]----
local install = {}

function install.files(pkg_location, install_path, file_list)
    -- Loop through list
    for _, file in pairs(file_list) do
        if string.sub(file, #file, #file) == "/" then
            -- It's a directory, so create it.
            local dirname = string.sub(file, 1, #file - 1)
            fs.makeDir(install_path .. dirname)
        else
            -- It's a file
            local file_url = pkg_location .. "/" .. file
            local req = http.get(file_url)
            
            if req == nil then
                error("Error!")
                error(file_url .. " HTTP errored!")
            else
                local data = req.readAll()
                req.close()
                
                local file_handle = fs.open(install_path .. file, "w")
                file_handle.write(data)
                file_handle.close()
            end
        end
    end
end

function install.package(package, version)
    local repos = repo.getAll()

    -- Loop through all repositories
    for repo_name, repo_info in pairs(repos) do
        local repo_url = repo_info["url"]
        local list_url = repo_url .. "arc.list.json"
        
        -- Check repository
        print(package .. "@" .. repo_url)
        sleep(0.1)
        
        local repo_list = getJson(list_url)
        
        if repo_list == nil then
            -- Repository not found
            term.setTextColor(colors.red)
            carriageReturn()
            print(package .. "@" .. repo_url .. " ! Not Found")
            term.setTextColor(colors.white)
        else
            -- Repository found
            term.setTextColor(colors.lightBlue)
            carriageReturn()
            print(package .. "@" .. repo_url)
            term.setTextColor(colors.white)
            
            -- Check if package exists in this repo
            if repo_list[package] then
                local repo_version = repo_list[package]["latest"]
                
                -- Use specific version if requested
                if version ~= "" then
                    if tableContains(repo_list[package]["versions"], version) then
                        repo_version = version
                    end
                end
                
                term.setTextColor(colors.green)
                carriageReturn()
                print(package .. "@" .. repo_url)
                term.setTextColor(colors.white)
                
                -- Check if already installed
                local install_status = isInstalled(package, repo_version)
                
                if install_status == true then
                    print("Package is already installed.")
                    return -1
                else
                    -- Begin installation
                    local pkg_location = repo_info["url"] .. "bin/" .. package .. "/" .. repo_version
                    local package_json_url = pkg_location .. "/arc.json"
                    local pkgjson = getJson(package_json_url)
                    if pkgjson == nil then
                        print("Package install encountered an unexpected error.")
                        return -1
                    end
                    -- Fallback for JSON fetch issues (dev protection)
                    if pkgjson["alias"] == nil then
                        pkgjson = getJson(package_json_url .. "#")
                    end
                    
                    local deps = pkgjson["dependencies"]
                    local bin = pkgjson["bin"]
                    local lib = pkgjson["lib"]
                    local etc = pkgjson["etc"]
                    local aliases = pkgjson["alias"]
                    
                    -- Install dependencies first
                    for _, dep in pairs(deps) do
                        install.package(dep["name"], dep["version"])
                    end
                    
                    -- Install package files
                    install.files(pkg_location .. "/bin/", "/bin/", bin)
                    install.files(pkg_location .. "/lib/", "/lib/", lib)
                    install.files(pkg_location .. "/etc/", "/etc/", etc)
                    
                    -- Save installation info
                    local installed_file = fs.open("/etc/arc/installed.json", "r")
                    local installed_data = json.decode(installed_file.readAll())
                    installed_file.close()
                    
                    installed_data[package] = pkgjson
                    installed_data[package]["version"] = repo_version
                    
                    installed_file = fs.open("/etc/arc/installed.json", "w")
                    installed_file.write(json.encode(installed_data))
                    installed_file.close()
                    
                    -- Set up shell aliases
                    for alias_name, program_path in pairs(aliases) do
                        shell.setAlias(alias_name, program_path)
                    end
                end
            end
        end
    end
    print("Updating System Libraries...")
    dofile(".photon/util/set_globals.lua")
end

----[[      Command Handler      ]]----

if #argv < 1 then
    invalidUsage()
    return
end

local command = argv[1]

if command == "help" then
    print("photon@arc - The Photon Package Manager")
    print(" arc install [package] - Install a Package")
    print(" arc remove [package] - Uninstall a Package [W.I.P.]")
    print(" arc system-update - Update Photon [W.I.P.]")
    print(" arc add-repo [repo-url] - Add Arc Repository")
    print(" arc add-gh-repo [owner] [repo] - Add Github Arc Repository")
    print(" arc update - Update Installed Packages [W.I.P.]")
    return 0

elseif command == "add-repo" then
    if #argv ~= 2 then
        invalidUsage()
        return 1
    end
    
    local url = argv[2]
    print("Adding Repository...")
    return repo.add(url)

elseif command == "add-gh-repo" then
    if #argv ~= 3 then
        invalidUsage()
        return 1
    end
    
    local owner = argv[2]
    local ghrepo = argv[3]
    print("Adding Repository " .. owner .. "@" .. ghrepo)
    
    local url = "https://raw.githubusercontent.com/" .. owner .. "/" .. ghrepo .. "/refs/heads/main/arc.repo.json"
    return repo.add(url)

elseif command == "install" then
    if #argv < 2 then
        invalidUsage()
        return 1
    end
    
    local package = argv[2]
    local version = ""
    
    if #argv == 3 then
        version = argv[3]
    end
    
    install.package(package, version)

else
    invalidUsage()
    return 1
end