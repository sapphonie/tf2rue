Handle SDKCall_GiveDefaultItems;
Handle SDKCall_ItemSystem;
Handle SDKCall_ReloadWhitelist;

ConVar mptw;
ConVar tft_whitelist_id;

char wlurl[256];
char wlcfg[256];

int wltfmtime;
int localmtime;


void DoItemsConVars()
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

void DoItemsGamedata()
{
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
    PrintToServer("-> Prepped SDKCall for CEconItemSystem::ReloadWhitelist");



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
    PrintToServer("-> Prepped SDKCall for ItemSystem*");


    Handle Sys_SpewFunc = DHookCreateFromConf(tftruest_gamedata, "Sys_SpewFunc");
    if (!Sys_SpewFunc)
    {
        SetFailState("Failed to setup detour for Sys_SpewFunc");
    }

    if (!DHookEnableDetour(Sys_SpewFunc, false, Detour_Sys_SpewFunc))
    {
        SetFailState("Failed to detour Sys_SpewFunc.");
    }

    PrintToServer("-> Detoured Sys_SpewFunc");

    // Debug
    // LogMessage("%x", SDKCall_GiveDefaultItems);
    // LogMessage("%x", SDKCall_ItemSystem);
    // LogMessage("%x", SDKCall_ReloadWhitelist);
}

public MRESReturn Detour_Sys_SpewFunc(Handle hParams)
{
    // Don't really care if it truncates here lol
    char spew[64];

    DHookGetParamString(hParams, 2, spew, sizeof(spew));

    // Get rid of garbage spam
    if
    (
            ( StrContains(spew, "-> Removing") != -1 )
        ||  ( StrContains(spew, "-> Allowing") != -1 )
        ||  ( StrContains(spew, "-> Could not find an item definition named") != -1 )
    )
    {
        return MRES_Supercede;
    }

    return MRES_Ignored;
}

void DoItemsMemPatches()
{
    // For allowing mp_tournament_whitelist in mp_tournament 0
    MemoryPatch memp_ReloadWhitelist = MemoryPatch.CreateFromConf(tftruest_gamedata, "CEconItemSystem::ReloadWhitelist::nopnop");

    if (!memp_ReloadWhitelist.Validate())
    {
        ThrowError("Failed to verify CEconItemSystem::ReloadWhitelist::nopnop");
    }
    else if (memp_ReloadWhitelist.Enable())
    {
        PrintToServer("-> Patched CEconItemSystem::ReloadWhitelist::nopnop");
    }



    // For ?
    MemoryPatch memp_GetLoadoutItem  = MemoryPatch.CreateFromConf(tftruest_gamedata, "CTFPlayer::GetLoadoutItem::nopnop");

    if (!memp_GetLoadoutItem.Validate())
    {
        ThrowError("Failed to verify CTFPlayer::GetLoadoutItem::nopnop");
    }
    else if (memp_GetLoadoutItem.Enable())
    {
        PrintToServer("-> Patched CTFPlayer::GetLoadoutItem::nopnop");
    }
}


void mptw_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (!StrEqual(oldValue, newValue))
    {
        ReloadWhitelist();
    }
}
char wlvalue[32];

void tft_wl_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
    strcopy(wlvalue, sizeof(wlvalue), newValue);

    if (!StrEqual(oldValue, newValue))
    {
        // Check whitelist.tf's last modified time first before downloading a potentially large whitelist file
        // We only download a new whitelist if the whitelist.tf timestamp is newer than our local version
        CheckWltfMtime();
    }
}
void CheckWltfMtime()
{
    /* string vs numeric ids */
    if (IsStringNumeric(wlvalue))
    {
        Format(wlurl, sizeof(wlurl), "https://whitelist.tf/custom_whitelist_%s.txt", wlvalue);
        Format(wlcfg, sizeof(wlcfg), "cfg/custom_whitelist_%s.txt",                  wlvalue);
    }
    else
    {
        Format(wlurl, sizeof(wlurl), "https://whitelist.tf/%s.txt",  wlvalue);
        Format(wlcfg, sizeof(wlcfg), "cfg/%s.txt",                   wlvalue);
    }

    localmtime = GetFileTime(wlcfg, FileTime_LastChange);
    // LogMessage("%i", localmtime);

    // LogMessage("GETing url %s", "https://whitelist.tf/last_update_time");

    Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, "https://whitelist.tf/last_update_time");

    SteamWorks_SetHTTPCallbacks(hRequest, SteamWorks_OnCheckWltfMtime);
    SteamWorks_SendHTTPRequest(hRequest);
}

public void SteamWorks_OnCheckWltfMtime(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode)
{
    if (!bFailure && bRequestSuccessful && eStatusCode == k_EHTTPStatusCode200OK)
    {
        int bodysize;
        bool bodyexists = SteamWorks_GetHTTPResponseBodySize(hRequest, bodysize);
        if (bodyexists == false)
        {
            LogMessage("No bodysize for wltf mtime request???");
            CloseHandle(hRequest);
            return;
        }
        char[] strResponse = new char[bodysize];


        SteamWorks_GetHTTPResponseBodyData(hRequest, strResponse, bodysize);
        //Print successful response to server.
        wltfmtime = StringToInt(strResponse);

        CheckMtimes();
    }
    else
    {
        LogMessage("[TFT] Failed to download whitelist. StatusCode = %i, bFailure = %i, RequestSuccessful = %i.", eStatusCode, bFailure, bRequestSuccessful);
    }

    CloseHandle(hRequest);
}

void CheckMtimes()
{
    if (wltfmtime > localmtime)
    {
        LogMessage("wltfmtime %i > %i localmtime", wltfmtime, localmtime);
        DownloadWhitelist();
    }
    else
    {
        LogMessage("Not redownloading unchanged whitelist for no reason.");
        LogMessage("wltfmtime %i < %i localmtime", wltfmtime, localmtime);

        SetWhitelist();
    }
}

void DownloadWhitelist()
{
    LogMessage("GETing url %s", wlurl);

    Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, wlurl);

    SteamWorks_SetHTTPCallbacks(request, SteamWorks_OnDownloadWhitelist);
    SteamWorks_SendHTTPRequest(request);
}


public void SteamWorks_OnDownloadWhitelist(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode)
{
    if (!bFailure && bRequestSuccessful && eStatusCode == k_EHTTPStatusCode200OK)
    {
        SteamWorks_WriteHTTPResponseBodyToFile(hRequest, wlcfg);
        SetWhitelist();
    }
    else
    {
        LogMessage("[TFT] Failed to download whitelist. StatusCode = %i, bFailure = %i, RequestSuccessful = %i.", eStatusCode, bFailure, bRequestSuccessful);
    }

    CloseHandle(hRequest);
}

void SetWhitelist()
{
    mptw.SetString(wlcfg);
}

void ReloadWhitelist()
{
    // Reload the whitelist
    Address Addr_ItemSys = SDKCall(SDKCall_ItemSystem);
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

        // Give client default weapons and then regenerate them
        SetEntProp(client, Prop_Send, "m_bRegenerating", 1);
        SDKCall(SDKCall_GiveDefaultItems, client);
        SetEntProp(client, Prop_Send, "m_bRegenerating", 0);
        // TF2_RegeneratePlayer(client);
    }
}


