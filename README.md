# hammerspoon
This is a collection of my [Hammerspoon](http://hammerspoon.org) scripts.

## token.lua
This script retrieves a [Google authenticator](https://github.com/google/google-authenticator) token seed from OSX's [Keychain](https://en.wikipedia.org/wiki/Keychain_%28software%29), generates keystrokes for the current TOTP token. This way you can enter TOTP tokens without having to remove your hands from the keyboard. OSX' Keychain is used for safe storage of the token seed.

####Requirements: ####
- [`gauth.lua`](https://github.com/teunvink/hammerspoon/blob/master/gauth.lua) - a slightly modified version of `gauth.lua`  by [imzyxwvu](https://github.com/imzyxwvu/lua-gauth) to work with Lua 5.3 use `basexx`
- [`sha1.lua`](https://github.com/teunvink/hammerspoon/blob/master/sha1.lua) - original code by [kikito](https://github.com/kikito/sha1.lua)
- [`basexx.lua`](https://github.com/teunvink/hammerspoon/blob/master/basexx.lua) - original code by [aiq](https://github.com/aiq/basexx)

####Prerequisites:####
- Open Keychain and select the `login` chain
- Create a new password, store a Google Authenticator token seed

####Usage:####
You can use the `token_keystroke` function to generate keystrokes for a generated token generated with a specific seed. In the example below, `token_github` is the name of the password in the login keychain.

    -- Cmd-Alt-G - type Github token  
    hs.hotkey.bind({"cmd", "alt"}, "G", function()
        token_keystroke("token_github")
    end)
    
The first time you try this, OSX will ask permission for `security` to access your Keychain. After that, when you press <kbd>⌘</kbd> + <kbd>⌥</kbd> + <kbd>G</kbd>, the current token value will be typed.
