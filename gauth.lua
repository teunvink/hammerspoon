-- modified version of https://github.com/kikito/sha.lua
-- uses internal binary and operator and basexx module for Base32

local sha1 = require "sha1"
local basexx = require "basexx"

local band = function(a, b)
    return a & b
end

local GAuth = {}

function GAuth.GenCode(skey, value)
    skey = basexx.from_base32(skey)
    value = string.char(
        0, 0, 0, 0,
        band(value, 0xFF000000) / 0x1000000,
        band(value, 0xFF0000) / 0x10000,
        band(value, 0xFF00) / 0x100,
        band(value, 0xFF))
    local hash = sha1.hmac_binary(skey, value)
    local offset = band(hash:sub(-1):byte(1, 1), 0xF)
    local function bytesToInt(a,b,c,d)
        return a*0x1000000 + b*0x10000 + c*0x100 + d
    end
    hash = bytesToInt(hash:byte(offset + 1, offset + 4))
    hash = band(hash, 0x7FFFFFFF) % 1000000
    return ("%06d"):format(hash)
end

return GAuth

