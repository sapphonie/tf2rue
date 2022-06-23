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

#undef REQUIRE_PLUGIN
#include <updater>

public Plugin myinfo =
{
    name        = "tf2rue",
    author      = "https://sappho.io",
    description = "Replacement for AnAkkk's TFTrue. Currently only handles whitelists.",
    version     = "0.0.3",
    url         = "https://sappho.io"
}

#define tagtag ansi_reset ... "[" ... ansi_bright_red ... "tf" ... ansi_bright_green ... "2" ... ansi_bright_red ... "rue" ... ansi_reset ... "] "

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
        PrintToServer(tagtag ... "Couldn't load gamedata!");
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
