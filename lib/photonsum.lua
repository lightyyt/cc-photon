-- Photon 1.0.0
-- Photonsum 1.0.0
-- A Simple Checksum algorithm

-- By Lighty

local photonsum = {}

function photonsum.sumFile(path)
    -- Read File
    local file = fs.open(path, "r")
    if not file then return nil end
    local data = file.readAll()
    file.close()

    return photonsum.sumString(data)
end

function photonsum.sumString(value)
    -- Prepare Checksum
    local sum = 0
    for i = 1, #value do
        -- Checksum byte with mod 2^32
        sum = (sum + string.byte(value, i)) % 2^32
    end

    -- Return Checksum as a string of 8 values
    return string.format("%08x", sum)
end



return photonsum