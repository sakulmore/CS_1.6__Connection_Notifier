# CS 1.6 - Connection Notifier
A plugin that sends notifications to the chat when players connect to the server.

One advantage of this plugin is that you can set up custom messages and connection sounds for specific players (using SteamID).

I got the inspiration for the plugin from [**this forum thread (AlliedMods)**](https://forums.alliedmods.net/showthread.php?t=352432).

# Installation
- Just download the plugin and upload the .amxx file to your plugins folder on your server (or you can of course compile the .sma file and then upload the compilated .amxx file to your server).
- Then write the plugin name (with .amxx) to `/cstrike/addons/amxmodx/configs/plugins.ini`.

# Requirements
- AMX Mod X 1.10

# Default Config File
connections.cfg:
```
; Here you can edit messages or add custom sounds
;
; You can use these placeholders:
; {PLAYER_NAME}     =   Displays the player's name
; {DATE}            =   Displays the connection date
; {TIME}            =   Displays the connection time
; {STEAMID}         =   Displays the player's SteamID
;
; You can use these colors:
; *d    =   Default (Yellow) Color
; *g    =   Green Color
; *t    =   Team Color

; You can use "none" value in: "default_connect_sound", "default_disconnect_sound", "<sound>"
; Settings
default_connect_message="The player *g{PLAYER_NAME} *dhas joined the server."
default_disconnect_message="The player *g{PLAYER_NAME} *dhas disconnected from the server."
default_connect_sound=""
default_disconnect_sound=""

; Custom Messages by SteamID:
;
; "<connection_type>"   =   Enter either "connect" or "disconnect" here
;
; Syntax: "<SteamID>" "<message>" "<sound>" "<connection_type>"
```

# Support
If you having any issues please feel free to write your issue to the issue section :) .