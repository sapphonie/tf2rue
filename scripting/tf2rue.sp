#include <sourcemod>
#include <sdktools>
#include <dhooks>
#include <sourcescramble>
#include <tf2>
#include <SteamWorks>


GameData tf2rue_gamedata;

#include <tf2rue/items.sp>
// #include <tf2rue/stv.sp>
// #include <tf2rue/fov.sp>

public void OnPluginStart()
{
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
        SetFailState("Couldn't load gamedata");
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
