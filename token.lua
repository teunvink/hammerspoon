local gauth = require "gauth"

-- written by Teun Vink <github@teun.tv>
-- code is based on:
--   https://github.com/imzyxwvu/lua-gauth/blob/master/gauth.lua (with small modifications)
--   https://github.com/kikito/sha.lua

-- read a password from a keychain
function password_from_keychain(name)
    -- 'name' should be saved in the login keychain
    local cmd="/usr/bin/security 2>&1 >/dev/null find-generic-password -ga " .. name .. " | sed -En '/^password: / s,^password: \"(.*)\"$,\\1,p'"
    local handle = io.popen(cmd)
    local result = handle:read("*a")
    handle:close()
    return (result:gsub("^%s*(.-)%s*$", "%1"))
end

-- read a token seed from keychain, generate a code and make keystrokes for it
function token_keystroke(token_name)
    token = password_from_keychain(token_name)
    hash = gauth.GenCode(token, math.floor(os.time() / 30))

    -- generate keystrokes for the result
    for c in ("%06d"):format(hash):gmatch"." do
        hs.eventtap.keyStroke({},c)
    end
end

