#include <amxmodx>
#include <amxmisc>

#define PLUGIN_NAME     "Connection Notifier"
#define PLUGIN_VERSION  "1.1"
#define PLUGIN_AUTHOR   "sakulmore"

new g_szCfgFile[128]

new g_szDefConnectMsg[192]
new g_szDefDisconnectMsg[192]
new g_szDefConnectSound[64]
new g_szDefDisconnectSound[64]

new Trie:g_tCustomMsgs
new Trie:g_tCustomSounds

new g_msgSayText

new bool:g_bHasAnnounced[33]

public plugin_precache() {
    g_tCustomMsgs = TrieCreate()
    g_tCustomSounds = TrieCreate()
    
    LoadConfig()
}

public plugin_init() {
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
    
    g_msgSayText = get_user_msgid("SayText")
    
    register_event("TeamInfo", "Event_TeamInfo", "a")
}

public plugin_end() {
    TrieDestroy(g_tCustomMsgs)
    TrieDestroy(g_tCustomSounds)
}

LoadConfig() {
    new szDataDir[128]
    get_localinfo("amxx_datadir", szDataDir, charsmax(szDataDir))
    
    formatex(g_szCfgFile, charsmax(g_szCfgFile), "%s/connections.cfg", szDataDir)
    
    if (!file_exists(g_szCfgFile)) {
        new file = fopen(g_szCfgFile, "wt")
        if (file) {
            fprintf(file, "; Here you can edit messages or add custom sounds%c", 10)
            fprintf(file, ";%c", 10)
            fprintf(file, "; You can use these placeholders:%c", 10)
            fprintf(file, "; {PLAYER_NAME}      =   Displays the player's name%c", 10)
            fprintf(file, "; {DATE}             =   Displays the connection date%c", 10)
            fprintf(file, "; {TIME}             =   Displays the connection time%c", 10)
            fprintf(file, "; {STEAMID}          =   Displays the player's SteamID%c", 10)
            fprintf(file, ";%c", 10)
            fprintf(file, "; You can use these colors:%c", 10)
            fprintf(file, "; *d    =   Default (Yellow) Color%c", 10)
            fprintf(file, "; *g    =   Green Color%c", 10)
            fprintf(file, "; *t    =   Team Color%c", 10)
            fprintf(file, "; %c*    =   Displays a literal asterisk (*)%c", 92, 10)
            fprintf(file, ";%c", 10)
            fprintf(file, "; You can use %cnone%c value in: %cdefault_connect_sound%c, %cdefault_disconnect_sound%c, %c<sound>%c%c", 34, 34, 34, 34, 34, 34, 34, 34, 10, 10)
            
            fprintf(file, "; Settings%c", 10)
            fprintf(file, "default_connect_message=%cThe player *g%c*{PLAYER_NAME}%c* *dhas joined the server.%c%c", 34, 92, 92, 34, 10)
            fprintf(file, "default_disconnect_message=%cThe player *g%c*{PLAYER_NAME}%c* *dhas disconnected from the server.%c%c", 34, 92, 92, 34, 10)
            fprintf(file, "default_connect_sound=%c%c%c", 34, 34, 10)
            fprintf(file, "default_disconnect_sound=%c%c%c%c", 34, 34, 10, 10)
            
            fprintf(file, "; Custom Messages by SteamID:%c", 10)
            fprintf(file, ";%c", 10)
            fprintf(file, "; %c<connection_type>%c   =   Enter either %cconnect%c or %cdisconnect%c here%c", 34, 34, 34, 34, 34, 34, 10)
            fprintf(file, ";%c", 10)
            fprintf(file, "; Syntax: %c<SteamID>%c %c<message>%c %c<sound>%c %c<connection_type>%c%c", 34, 34, 34, 34, 34, 34, 34, 34, 10)
            
            fclose(file)
        }
    }
    
    new file = fopen(g_szCfgFile, "rt")
    if (!file) return
    
    new szLine[256], szKey[64], szVal[192]
    
    while (!feof(file)) {
        fgets(file, szLine, charsmax(szLine))
        trim(szLine)
        
        if (!szLine[0] || szLine[0] == ';') continue
        
        if (containi(szLine, "default_") == 0) {
            strtok(szLine, szKey, charsmax(szKey), szVal, charsmax(szVal), '=')
            trim(szKey)
            trim(szVal)
            remove_quotes(szVal)
            
            if (equal(szKey, "default_connect_message")) {
                copy(g_szDefConnectMsg, charsmax(g_szDefConnectMsg), szVal)
            }
            else if (equal(szKey, "default_disconnect_message")) {
                copy(g_szDefDisconnectMsg, charsmax(g_szDefDisconnectMsg), szVal)
            }
            else if (equal(szKey, "default_connect_sound")) {
                copy(g_szDefConnectSound, charsmax(g_szDefConnectSound), szVal)
                if (equali(g_szDefConnectSound, "none") || !PrecacheCustomSound(g_szDefConnectSound)) {
                    g_szDefConnectSound[0] = 0
                }
            }
            else if (equal(szKey, "default_disconnect_sound")) {
                copy(g_szDefDisconnectSound, charsmax(g_szDefDisconnectSound), szVal)
                if (equali(g_szDefDisconnectSound, "none") || !PrecacheCustomSound(g_szDefDisconnectSound)) {
                    g_szDefDisconnectSound[0] = 0
                }
            }
            continue
        }
        
        new szSteam[32], szMsg[192], szSound[64], szType[32]
        parse(szLine, szSteam, charsmax(szSteam), szMsg, charsmax(szMsg), szSound, charsmax(szSound), szType, charsmax(szType))
        
        if (containi(szSteam, "STEAM_") == 0) {
            new szTrieKey[64]
            formatex(szTrieKey, charsmax(szTrieKey), "%s_%s", szSteam, szType[0] ? szType : "connect")
            
            if (szMsg[0]) {
                TrieSetString(g_tCustomMsgs, szTrieKey, szMsg)
            }
            if (szSound[0] && !equali(szSound, "none")) {
                if (PrecacheCustomSound(szSound)) {
                    TrieSetString(g_tCustomSounds, szTrieKey, szSound)
                }
            }
        }
    }
    fclose(file)
}

bool:PrecacheCustomSound(const szSound[]) {
    if (!szSound[0]) return false
    
    new szPath[128]
    formatex(szPath, charsmax(szPath), "sound/%s", szSound)
    
    if (file_exists(szPath)) {
        precache_sound(szSound)
        return true
    }
    
    return false
}

FormatAndPrintMessage(id, const szInputMsg[]) {
    if (!szInputMsg[0]) return

    new szFormatted[256]
    copy(szFormatted, charsmax(szFormatted), szInputMsg)

    new szName[32], szSteamID[32], szDate[16], szTime[16]
    get_user_name(id, szName, charsmax(szName))
    get_user_authid(id, szSteamID, charsmax(szSteamID))
    get_time("%d.%m.%Y", szDate, charsmax(szDate))
    get_time("%H:%M:%S", szTime, charsmax(szTime))

    new szPlaceholder[32]

    formatex(szPlaceholder, charsmax(szPlaceholder), "{PLAYER_NAME}")
    replace_all(szFormatted, charsmax(szFormatted), szPlaceholder, szName)

    formatex(szPlaceholder, charsmax(szPlaceholder), "{STEAMID}")
    replace_all(szFormatted, charsmax(szFormatted), szPlaceholder, szSteamID)

    formatex(szPlaceholder, charsmax(szPlaceholder), "{DATE}")
    replace_all(szFormatted, charsmax(szFormatted), szPlaceholder, szDate)

    formatex(szPlaceholder, charsmax(szPlaceholder), "{TIME}")
    replace_all(szFormatted, charsmax(szFormatted), szPlaceholder, szTime)

    new szEscapedAsterisk[4]
    formatex(szEscapedAsterisk, charsmax(szEscapedAsterisk), "%c*", 92)
    replace_all(szFormatted, charsmax(szFormatted), szEscapedAsterisk, "#ESC_AST#")

    new szColor[4]
    
    szColor[0] = 1; szColor[1] = 0;
    replace_all(szFormatted, charsmax(szFormatted), "*d", szColor)
    
    szColor[0] = 3; szColor[1] = 0;
    replace_all(szFormatted, charsmax(szFormatted), "*t", szColor)
    
    szColor[0] = 4; szColor[1] = 0;
    replace_all(szFormatted, charsmax(szFormatted), "*g", szColor)

    replace_all(szFormatted, charsmax(szFormatted), "#ESC_AST#", "*")

    if (szFormatted[0] != 1 && szFormatted[0] != 3 && szFormatted[0] != 4) {
        new szTemp[256]
        formatex(szTemp, charsmax(szTemp), "%c%s", 1, szFormatted)
        copy(szFormatted, charsmax(szFormatted), szTemp)
    }

    new players[32], num, target
    get_players(players, num, "ch")
    
    for (new i = 0; i < num; i++) {
        target = players[i]
        message_begin(MSG_ONE, g_msgSayText, _, target)
        write_byte(id)
        write_string(szFormatted)
        message_end()
    }
}

public client_putinserver(id) {
    g_bHasAnnounced[id] = false
}

public Event_TeamInfo() {
    new id = read_data(1)
    
    if (!is_user_connected(id) || is_user_bot(id) || is_user_hltv(id) || g_bHasAnnounced[id]) {
        return
    }
    
    new szTeam[16]
    read_data(2, szTeam, charsmax(szTeam))
    
    if (szTeam[0] == 'T' || szTeam[0] == 'C' || szTeam[0] == 'S') {
        g_bHasAnnounced[id] = true
        AnnounceConnect(id)
    }
}

AnnounceConnect(id) {
    new szSteamID[32]
    get_user_authid(id, szSteamID, charsmax(szSteamID))
    
    new szTrieKey[64]
    formatex(szTrieKey, charsmax(szTrieKey), "%s_connect", szSteamID)
    
    new szMsg[192], szSound[64]
    
    if (!TrieGetString(g_tCustomMsgs, szTrieKey, szMsg, charsmax(szMsg))) {
        copy(szMsg, charsmax(szMsg), g_szDefConnectMsg)
    }
    
    if (!TrieGetString(g_tCustomSounds, szTrieKey, szSound, charsmax(szSound))) {
        copy(szSound, charsmax(szSound), g_szDefConnectSound)
    }
    
    FormatAndPrintMessage(id, szMsg)
    
    if (szSound[0]) {
        client_cmd(0, "spk %c%s%c", 34, szSound, 34)
    }
}

public client_disconnected(id) {
    if (is_user_bot(id) || is_user_hltv(id)) {
        g_bHasAnnounced[id] = false
        return
    }
    
    if (g_bHasAnnounced[id]) {
        new szSteamID[32]
        get_user_authid(id, szSteamID, charsmax(szSteamID))
        
        new szTrieKey[64]
        formatex(szTrieKey, charsmax(szTrieKey), "%s_disconnect", szSteamID)
        
        new szMsg[192], szSound[64]
        
        if (!TrieGetString(g_tCustomMsgs, szTrieKey, szMsg, charsmax(szMsg))) {
            copy(szMsg, charsmax(szMsg), g_szDefDisconnectMsg)
        }
        
        if (!TrieGetString(g_tCustomSounds, szTrieKey, szSound, charsmax(szSound))) {
            copy(szSound, charsmax(szSound), g_szDefDisconnectSound)
        }
        
        FormatAndPrintMessage(id, szMsg)
        
        if (szSound[0]) {
            client_cmd(0, "spk %c%s%c", 34, szSound, 34)
        }
    }
    
    g_bHasAnnounced[id] = false
}