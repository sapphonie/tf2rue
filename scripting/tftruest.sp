#include <sourcemod>
#include <sdktools>
#include <tf_econ_data>
#include <sourcescramble>
#include <adt_array>

GameData tftruest_gamedata;


Handle SDKCall_GiveDefaultItems;
Handle SDKCall_ItemSystem;
Handle SDKCall_ReloadWhitelist;
// Address Addr_ItemSys;

ConVar mptw;

ConVar tft_whitelist_id;
ConVar tft_no_hats;
ConVar tft_no_misc;
ConVar tft_no_action;

public void OnPluginStart()
{
    DoGamedata();
    DoMemPatches();
    DoConVars();
}

void DoConVars()
{
    mptw = FindConVar("mp_tournament_whitelist");
    HookConVarChange(mptw, mptw_changed);

    tft_whitelist_id = CreateConVar
    (
        "tft_whitelist_id",
        "-1",
        "tftruest whitelist id",
        _,
        true, -1.0,
        false
    );
    tft_no_hats = CreateConVar
    (
        "tft_no_hats",
        "0",
        "",
        _,
        true, 0.0,
        true, 1.0
    );
    tft_no_misc = CreateConVar
    (
        "tft_no_misc",
        "0",
        "",
        _,
        true, 0.0,
        true, 1.0
    );
    tft_no_action = CreateConVar
    (
        "tft_no_action",
        "0",
        "",
        _,
        true, 0.0,
        true, 1.0
    );
}


void mptw_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (StrContains(newValue, "_no_") != -1)
    {
        ReloadWhitelist();
    }
    else if (!StrEqual(oldValue, newValue))
    {
        CheckTFTOverride();
    }
}

CheckTFTOverride()
{
    if (!tft_no_hats.BoolValue && !tft_no_misc.BoolValue && !tft_no_action.BoolValue)
    {
        ReloadWhitelist();
    }
    else
    {
        iterItems();
    }
}




void iterItems()
{
    KeyValues item_whitelist = new KeyValues("");

    char strWL[128];
    mptw.GetString(strWL, sizeof(strWL));

    LogMessage("strWL %s", strWL);

    item_whitelist.ImportFromFile(strWL);
    item_whitelist.Rewind();

    BrowseKeyValues(item_whitelist);

    item_whitelist.Rewind();

    // if (!KvJumpToKey(item_whitelist, "item_whitelist"))
    // {
    //     LogMessage("Item Whitelist not valid.");
    //     return;
    // }

    // if ( !KvJumpToKey(item_whitelist, "unlisted_items_default_to", false) )
    // {
    //     LogMessage("couldn't find unlisted_items_default_to");
    //     item_whitelist.Rewind();
    //     KvJumpToKey(item_whitelist, "unlisted_items_default_to", true);
    //     KvSetNum(item_whitelist, "unlisted_items_default_to", 1);
    // }

    ArrayList ItemArray = TF2Econ_GetItemList();

    int maxItems = ItemArray.Length;
    for (int i = 0; i < maxItems; i++)
    {
        int itemdef = ItemArray.Get(i);
        // LogMessage("%i", itemdef);

        char strItemSlot    [64];
        char strItemName    [64];
        char strCraftClass  [64];
        char strBaseItem    [64];
        TF2Econ_GetItemDefinitionString(itemdef, "item_slot",    strItemSlot,        sizeof(strItemSlot));
        TF2Econ_GetItemDefinitionString(itemdef, "name",         strItemName,        sizeof(strItemName));
        TF2Econ_GetItemDefinitionString(itemdef, "craft_class",  strCraftClass,      sizeof(strCraftClass));
        TF2Econ_GetItemDefinitionString(itemdef, "baseitem",     strBaseItem,        sizeof(strBaseItem));

        // LogMessage("slot %s", strItemSlot);

        // Make sure we have an item name and slot
        if (!strItemName[0] || !strItemSlot[0])
        {
            continue;
        }

        // Do not try to add the item called "default"
        if (StrEqual(strItemName, "default"))
        {
            continue;
        }

        // Do not add base items
        if (strBaseItem && StrEqual(strBaseItem, "1"))
        {
            continue;
        }

        // Do not add craft tokens
        if (strCraftClass && StrEqual(strCraftClass, "craft_token"))
        {
            continue;
        }

        if
        (
                ( tft_no_hats.BoolValue         && StrEqual(strItemSlot, "head")    )
            ||  ( tft_no_misc.BoolValue         && StrEqual(strItemSlot, "misc")    )
            ||  ( tft_no_action.BoolValue       && StrEqual(strItemSlot, "action")  )
        )
        {
            KvSetNum(item_whitelist, strItemName, 0);
        }
    }

    ReplaceString(strWL, sizeof(strWL), ".txt", "", false);

    // didn't find an existing 
    if (StrContains(strWL, "_no_") == -1)
    {
        if (tft_no_hats.BoolValue)
        {
            StrCat(strWL, sizeof(strWL), "_no_hats");
        }
        if (tft_no_misc.BoolValue)
        {
            StrCat(strWL, sizeof(strWL), "_no_misc");
        }
        if (tft_no_action.BoolValue)
        {
            StrCat(strWL, sizeof(strWL), "_no_action");
        }
    }

    StrCat(strWL, sizeof(strWL), ".txt");

    LogMessage("%s", strWL);
    item_whitelist.ExportToFile(strWL);
    SetConVarString(mptw, strWL);
    ReloadWhitelist();
}


void ReloadWhitelist()
{
    // Reload the whitelist
    Address Addr_ItemSys = SDKCall(SDKCall_ItemSystem);
    LogMessage("Addr_ItemSys %x", Addr_ItemSys);
    SDKCall(SDKCall_ReloadWhitelist, Addr_ItemSys);

    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientConnected(client) || IsFakeClient(client))
        {
            continue;
        }

        // Remove taunt
        TF2_RemoveCondition(client, TFCond_Taunting);

        // Remove all wearables, GiveDefaultItems doesn't remove them for some reason
        int child = GetEntPropEnt(client, Prop_Data, "m_hMoveChild");
        while (child > 0)
        {
            char classname[64];
            GetEntityClassname(child, classname, sizeof(classname));
            if (!strcmp(classname, "tf_wearable"))
            {
                TF2_RemoveWearable(client, child);

                // Go back to the first child
                child = GetEntPropEnt(client, Prop_Data, "m_hMoveChild")
            }
            else
            {
                child = GetEntPropEnt(child, Prop_Data, "m_hMovePeer")
            }
        }

        // Regenerate client
        SetEntProp(client, Prop_Send, "m_bRegenerating", 1);
        SDKCall(SDKCall_GiveDefaultItems, client);
        SetEntProp(client, Prop_Send, "m_bRegenerating", 0);
    }
}


void DoGamedata()
{
    tftruest_gamedata = LoadGameConfigFile("tf2.tftruest");
    if (tftruest_gamedata == null)
    {
        SetFailState("Couldn't load gamedata");
    }

    StartPrepSDKCall(SDKCall_Player);
    if (!PrepSDKCall_SetFromConf(tftruest_gamedata, SDKConf_Signature, "CTFPlayer::GiveDefaultItems"))
    {
        SetFailState("Couldn't prep CTFPlayer::GiveDefaultItems SDKCall");
    }
    // PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_ByValue);
    SDKCall_GiveDefaultItems = EndPrepSDKCall();
    if (SDKCall_GiveDefaultItems == null)
    {
        SetFailState("Couldn't endPrepSdkcall for CTFPlayer::GiveDefaultItems");
    }




    StartPrepSDKCall(SDKCall_Raw);
    if (!PrepSDKCall_SetFromConf(tftruest_gamedata, SDKConf_Signature, "CEconItemSystem::ReloadWhitelist"))
    {
        SetFailState("Couldn't prep CEconItemSystem::ReloadWhitelist SDKCall");
    }
    SDKCall_ReloadWhitelist = EndPrepSDKCall();
    if (SDKCall_ReloadWhitelist == null)
    {
        SetFailState("Couldn't endPrepSdkcall for CEconItemSystem::ReloadWhitelist");
    }



    StartPrepSDKCall(SDKCall_Static);
    if (!PrepSDKCall_SetFromConf(tftruest_gamedata, SDKConf_Signature, "ItemSystem"))
    {
        SetFailState("Couldn't prep ItemSystem SDKCall");
    }
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
    SDKCall_ItemSystem = EndPrepSDKCall();
    if (SDKCall_ItemSystem == null)
    {
        SetFailState("Couldn't end PrepSdkcall for ItemSystem");
    }




    LogMessage("%x", SDKCall_GiveDefaultItems);
    LogMessage("%x", SDKCall_ItemSystem);
    LogMessage("%x", SDKCall_ReloadWhitelist);
}

void DoMemPatches()
{
    // tftruest_gamedata

    // as mentioned, patches are cleaned up when the handle is deleted
    MemoryPatch memp_ReloadWhitelist = MemoryPatch.CreateFromConf(tftruest_gamedata, "CEconItemSystem::ReloadWhitelist::nopnop");
    MemoryPatch memp_GetLoadoutItem  = MemoryPatch.CreateFromConf(tftruest_gamedata, "CTFPlayer::GetLoadoutItem::nopnop");

    if (!memp_ReloadWhitelist.Validate())
    {
        ThrowError("Failed to verify CEconItemSystem::ReloadWhitelist::nopnop.");
    }
    else if (memp_ReloadWhitelist.Enable())
    {
        LogMessage("Patched CEconItemSystem::ReloadWhitelist::nopnop.");
    }

    if (!memp_GetLoadoutItem.Validate())
    {
        ThrowError("Failed to verify CTFPlayer::GetLoadoutItem::nopnop.");
    }
    else if (memp_GetLoadoutItem.Enable())
    {
        LogMessage("Patched CTFPlayer::GetLoadoutItem::nopnop");
    }
}




/*
    item_whitelist.ImportFromFile("cfg/custom_whitelist_12612.txt");

    if (!KvJumpToKey(item_whitelist, "unlisted_items_default_to", false))
    {
        KvSetNum(item_whitelist, "unlisted_items_default_to", 1);
    }

    int maxItems = ItemArray.Length;
    for (int i = 0; i < maxItems; i++)
    {
        int itemdef = ItemArray.Get(i);
        // LogMessage("%i", itemdef);

        char strItemSlot    [64];
        char strItemName    [64];
        char strCraftClass  [64];
        char strBaseItem    [64];
        TF2Econ_GetItemDefinitionString(itemdef, "item_slot",    strItemSlot,        sizeof(strItemSlot));
        TF2Econ_GetItemDefinitionString(itemdef, "name",         strItemName,        sizeof(strItemName));
        TF2Econ_GetItemDefinitionString(itemdef, "craft_class",  strCraftClass,      sizeof(strCraftClass));
        TF2Econ_GetItemDefinitionString(itemdef, "baseitem",     strBaseItem,        sizeof(strBaseItem));

        // LogMessage("name %s", strItemName);

        // Make sure we have an item name and slot
        if (!strItemName[0] || !strItemSlot[0])
        {
            // LogMessage("invalid?");
            continue;
        }

        // Do not try to add the item called "default"
        if (StrEqual(strItemName, "default"))
        {
            //LogMessage("not adding default");
            continue;
        }

        // Do not add base items
        if (strBaseItem && StrEqual(strBaseItem, "1"))
        {
            //LogMessage("not adding base");
            continue;
        }

        // Do not add craft tokens
        if (strCraftClass && StrEqual(strCraftClass, "craft_token"))
        {
            //LogMessage("not adding craft_token");
            continue;
        }

        if
        (
                ( !StrEqual(strItemSlot, "head") )
            ||  ( !StrEqual(strItemSlot, "misc") )
            ||  ( !StrEqual(strItemSlot, "action") )
        )
        {
            KvSetNum(item_whitelist, strItemName, 0);
        }


        item_whitelist.ExportToFile("cfg/custom_whitelist_12612.txt");
        // SetConVarString(FindConVar("mp_tournament_whitelist"), "cfg/custom_whitelist_12612.txt");
    }
*/


void BrowseKeyValues(KeyValues kv)
{
    char thisthis[64];
    do
    {
        // You can read the section/key name by using kv.GetSectionName here.

        kv.GetSectionName(thisthis, sizeof(thisthis));
        LogMessage("%s", thisthis);
 
        if (kv.GotoFirstSubKey(false))
        {
            // Current key is a section. Browse it recursively.
            BrowseKeyValues(kv);
            kv.GoBack();
        }
        else
        {
            // Current key is a regular key, or an empty section.
            if (kv.GetDataType(NULL_STRING) != KvData_None)
            {
                // Read value of key here (use NULL_STRING as key name). You can
                // also get the key name by using kv.GetSectionName here.
                LogMessage("---> %i", kv.GetNum(NULL_STRING), -1);
            }
            else
            {
                LogMessage("empty");

                // Found an empty sub section. It can be handled here if necessary.
            }
        }
    } while (kv.GotoNextKey(false));
}