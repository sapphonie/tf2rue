#include <sourcemod>
#include <sdktools>
// #include <tf_econ_data>
#include <sourcescramble>

GameData tftruest_gamedata;

Handle SDKCall_GiveDefaultItems;
Handle SDKCall_ItemSystem;
Handle SDKCall_ReloadWhitelist;

ConVar mptw;
ConVar tft_whitelist_id;

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
    HookConVarChange(tft_whitelist_id,  tft_wl_changed);
}

void mptw_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (!StrEqual(oldValue, newValue))
    {
        ReloadWhitelist();
    }
}

void tft_wl_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (!StrEqual(oldValue, newValue))
    {
        ReloadWhitelist();
    }
}

void ReloadWhitelist()
{
    // Reload the whitelist
    Address Addr_ItemSys = SDKCall(SDKCall_ItemSystem);
    LogMessage("Addr_ItemSys %x", Addr_ItemSys);
    SDKCall(SDKCall_ReloadWhitelist, Addr_ItemSys);

    // Remove all client items
    for (int client = 1; client <= MaxClients; client++)
    {
        // ignore bogons
        if (!IsClientConnected(client) || IsFakeClient(client))
        {
            continue;
        }

        // Stop client from taunting
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
        // Give em the default stuff
        SDKCall(SDKCall_GiveDefaultItems, client);
        // 
        SetEntProp(client, Prop_Send, "m_bRegenerating", 0);
    }
}


void DoGamedata()
{
    // main gamedata cfg
    tftruest_gamedata = LoadGameConfigFile("tf2.tftruest");
    if (tftruest_gamedata == null)
    {
        SetFailState("Couldn't load gamedata");
    }



    // CTFPlayer::GiveDefaultItems
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



    // CEconItemSystem::ReloadWhitelist
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



    // ItemSystem (this ptr for CEconItemSystem::ReloadWhitelist)
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



    // Debug
    LogMessage("%x", SDKCall_GiveDefaultItems);
    LogMessage("%x", SDKCall_ItemSystem);
    LogMessage("%x", SDKCall_ReloadWhitelist);
}

void DoMemPatches()
{
    // patches are cleaned up when the handle is deleted
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
