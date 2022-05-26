#include <sourcemod>
#include <sdktools>
#include <dhooks>
#include <sourcescramble>
#include <tf2>
#include <SteamWorks>


GameData tftruest_gamedata;

#include <tftruest/items.sp>


public void OnPluginStart()
{
    DoGamedata();
    DoMemPatches();
    DoConVars();
}

void DoGamedata()
{
    // main gamedata cfg
    tftruest_gamedata = LoadGameConfigFile("tf2.tftruest");
    if (tftruest_gamedata == null)
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
