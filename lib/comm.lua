local comm = {}

function comm.receive(identifier)
    local data = nil
    while true do
        local f = fs.open("/etc/.comm_wait."..identifier, "r")
        if f == nil then goto continue end

        data = f.readAll()
        f.close()
        fs.delete("/etc/.comm_wait."..identifier)
        break

        ::continue::
        sleep(0.01)
    end
    return photon.lib.json.decode(data)["data"]
end

function comm.send(identifier, data)
    local f = fs.open("/etc/.comm_wait."..identifier, "w")
    f.write(photon.lib.json.encode({
        ["data"] = data
    }))
    f.close()
    sleep(0.3)
    fs.delete("/etc/.comm_wait."..identifier)
end
return comm