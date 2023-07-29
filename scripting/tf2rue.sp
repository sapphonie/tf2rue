#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>
#include <sourcescramble>
#include <tf2>
#include <tf2_stocks>
#include <SteamWorks>
#include <concolors>
// #include <morecolors>
#include <color_literals>
#include <profiler>

#undef REQUIRE_PLUGIN
#include <updater>

public Plugin myinfo =
{
    name        = "tf2rue",
    author      = "https://sappho.io",
    description = "Replacement for AnAkkk's TFTrue. Currently only handles whitelists.",
    version     = "0.0.9",
    url         = "https://sappho.io"
}

#define chatTag \
COLOR_SLATEGREY ... "[" ... COLOR_FULLRED ... "tf" ... COLOR_LIGHTGREEN ... "2" ... COLOR_FULLRED ... "rue" ... COLOR_SLATEGREY ... "]" ... COLOR_WHITE ... " "

GameData tf2rue_gamedata;

#include <tf2rue/updater.sp>
#include <tf2rue/items.sp>

// #include <tf2rue/stv.sp>
// #include <tf2rue/fov.sp>

public void OnPluginStart()
{
    InitUpdater();
    DoGamedata();
    DoMemPatches();
    DoConVars();
}

void DoGamedata()
{
    // main gamedata cfg
    tf2rue_gamedata = LoadGameConfigFile("tf2.rue");
    if (tf2rue_gamedata == null)
    {
        LogImportant("Couldn't load gamedata!");
        SetFailState("[tf2rue] Couldn't load gamedata");
    }

    DoItemsGamedata();
}

void DoMemPatches()
{
    DoItemsMemPatches();
}

void DoConVars()
{
    DoItemsConVars();
}

bool IsStringNumeric(const char[] str, int nBase=10)
{
    int result;
    return StringToIntEx(str, result, nBase) == strlen(str);
}

// log to server and print to chat
void LogImportant(const char[] format, any ...)
{
    char buffer[254];
    VFormat(buffer, sizeof(buffer), format, 2);

    // clear color tags from LogMsg
    char stripped_buffer[254];
    StripColorChars(buffer, stripped_buffer, sizeof(stripped_buffer), true);
    LogMessage("%s", stripped_buffer);

    // allow colors in normal ptc
    Format(buffer, sizeof(buffer), "%s %s", chatTag, buffer);
    PrintColoredChatAll("%s", buffer);
}
