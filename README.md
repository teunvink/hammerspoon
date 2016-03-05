# hammerspoon
This is a collection of my [Hammerspoon](http://hammerspoon.org) scripts. Currently containing:
* `token.lua` - calculate a Google authenticator token value and generate keystrokes for it. Use OSX Keychain to store the token seed.
* `tvmenu.lua` - a menubar showing a TV guide for (mostly) Dutch channels

More details can be found below.

## token.lua
This script retrieves a [Google authenticator](https://github.com/google/google-authenticator) token seed from OSX's [Keychain](https://en.wikipedia.org/wiki/Keychain_%28software%29), generates keystrokes for the current TOTP token. This way you can enter TOTP tokens without having to remove your hands from the keyboard. OSX' Keychain is used for safe storage of the token seed.

####Requirements: ####
The `token.lua` module requires the following modules, which are also included in this repository:
- [`gauth.lua`](https://github.com/teunvink/hammerspoon/blob/master/gauth.lua) - a slightly modified version of `gauth.lua`  by [imzyxwvu](https://github.com/imzyxwvu/lua-gauth) to work with Lua 5.3 and use `basexx` and `hs.hash`
- [`basexx.lua`](https://github.com/teunvink/hammerspoon/blob/master/basexx.lua) - original code by [aiq](https://github.com/aiq/basexx)

####Prerequisites:####
- Open Keychain and select the `login` chain
- Create a new password, store a Google Authenticator token seed (a 16-byte string)

####Usage:####
`token.lua` provides the `token_keystroke` function to generate keystrokes for a generated token generated with a specific seed. In the example below, argument `token_github` is the name of the password stored in the login keychain.

    -- Cmd-Alt-G - type Github token  
    hs.hotkey.bind({"cmd", "alt"}, "G", function()
        token_keystroke("token_github")
    end)
    
The first time you try this, OSX will ask permission for `security` to access your Keychain. After that, when you press <kbd>⌘</kbd> + <kbd>⌥</kbd> + <kbd>G</kbd>, the current token value will be typed.

##tvmenu.lua##
Add a program guide for Dutch tv channels to the menubar. This script uses the [tvgids.nl API](https://tvgids.nl). Since it's aimed at Dutch users, all user interaction is in Dutch.

###Features:###
- show favorite channels in the menu
- save a list of favorite channels
- alert (popup and sound) of the start of a program
- show currently playing and upcoming programs
- use emoji's to indicate the program type

###Usage:###
Just include the script in your `init.lua`:

    require "tvmenu"

The first time you launch the script the list of favorite channels is empty, so click on "Kanaal toevoegen" and pick a channel from the list. It will then be added at the top of the menu, and all scheduled tvshows starting with the one currently playing are shown in that menu.

By clicking on a tvshow you can set a popup alert for the start of the show. If "Alarmgeluid" is on, a sound will be played as well. A list of all alerts set is available in the menu as well. Clicking on the name of a show for which an alert was set disables the alert.

The menu includes two items "Nu op TV" and "Straks op TV" showing the shows currently playing and up next for all your favorite channels.

### Screenshot:###
![tvmenu.lua screenshot](https://raw.githubusercontent.com/teunvink/hammerspoon/master/images/tvmenu.png "Screenshot")

### TODO's:###
- proper error handling
- more emoji's?

## utils.lua ##
A small collection of useful functions written by me and found on the internet.
