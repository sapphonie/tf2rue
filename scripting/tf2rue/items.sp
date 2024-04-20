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
        "tftrue_whitelist_id",
        "-1",
        "tf2rue whitelist id",
        FCVAR_NOTIFY,
        true, -1.0,
        false
    );
    HookConVarChange(tft_whitelist_id,  tft_wl_changed);
}

void DoItemsGamedata()
{
    // CTFPlayer::GiveDefaultItems
    StartPrepSDKCall(SDKCall_Player);
    if (PrepSDKCall_SetFromConf(tf2rue_gamedata, SDKConf_Signature, "CTFPlayer::GiveDefaultItems"))
    {
        // PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_ByValue);
        SDKCall_GiveDefaultItems = EndPrepSDKCall();
        LogMessage("-> Prepped SDKCall for CTFPlayer::GiveDefaultItems");
    }
    if (SDKCall_GiveDefaultItems == null)
    {
        // as of 8826692 or so, GiveDefaultItems is now inlined on Windows
        // we'll just disable the call for now
        LogMessage("Couldn't prep CTFPlayer::GiveDefaultItems SDKCall");
    }



    // CEconItemSystem::ReloadWhitelist
    StartPrepSDKCall(SDKCall_Raw);
    if (!PrepSDKCall_SetFromConf(tf2rue_gamedata, SDKConf_Signature, "CEconItemSystem::ReloadWhitelist"))
    {
        SetFailState("Couldn't prep CEconItemSystem::ReloadWhitelist SDKCall");
    }
    SDKCall_ReloadWhitelist = EndPrepSDKCall();
    if (SDKCall_ReloadWhitelist == null)
    {
        SetFailState("Couldn't endPrepSdkcall for CEconItemSystem::ReloadWhitelist");
    }
    LogMessage("-> Prepped SDKCall for CEconItemSystem::ReloadWhitelist");



    // ItemSystem (this ptr for CEconItemSystem::ReloadWhitelist)
    StartPrepSDKCall(SDKCall_Static);
    if (!PrepSDKCall_SetFromConf(tf2rue_gamedata, SDKConf_Signature, "ItemSystem"))
    {
        SetFailState("Couldn't prep ItemSystem SDKCall");
    }
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
    SDKCall_ItemSystem = EndPrepSDKCall();
    if (SDKCall_ItemSystem == null)
    {
        SetFailState("Couldn't end PrepSdkcall for ItemSystem");
    }
    LogMessage("-> Prepped SDKCall for ItemSystem*");

    // Debug
    //LogMessage("%x", SDKCall_GiveDefaultItems);
    //LogMessage("%x", SDKCall_ItemSystem);
    //LogMessage("%x", SDKCall_ReloadWhitelist);
}

void DoItemsMemPatches()
{
    // For allowing mp_tournament_whitelist in mp_tournament 0
    MemoryPatch memp_ReloadWhitelist_tournamentfix = MemoryPatch.CreateFromConf(tf2rue_gamedata, "CEconItemSystem::ReloadWhitelist::nopnop");

    if (!memp_ReloadWhitelist_tournamentfix.Validate())
    {
        ThrowError("Failed to verify CEconItemSystem::ReloadWhitelist::nopnop");
    }
    else if (memp_ReloadWhitelist_tournamentfix.Enable())
    {
        LogMessage("-> Patched CEconItemSystem::ReloadWhitelist::nopnop");
    }



    // For getting rid of spam Msgs when applying whitelist
    MemoryPatch memp_ReloadWhitelist_NoSpamMsgs = MemoryPatch.CreateFromConf(tf2rue_gamedata, "CEconItemSystem::ReloadWhitelist::nopMsg");

    if (!memp_ReloadWhitelist_NoSpamMsgs.Validate())
    {
        ThrowError("Failed to verify CEconItemSystem::ReloadWhitelist::nopMsg");
    }
    else if (memp_ReloadWhitelist_NoSpamMsgs.Enable())
    {
        LogMessage("-> Patched CEconItemSystem::ReloadWhitelist::nopMsg");
    }



    // For getting rid of spam Warnings when applying whitelist
    MemoryPatch memp_ReloadWhitelist_NoSpamWarnings = MemoryPatch.CreateFromConf(tf2rue_gamedata, "CEconItemSystem::ReloadWhitelist::nopWarning");

    if (!memp_ReloadWhitelist_NoSpamWarnings.Validate())
    {
        ThrowError("Failed to verify CEconItemSystem::ReloadWhitelist::nopWarning");
    }
    else if (memp_ReloadWhitelist_NoSpamWarnings.Enable())
    {
        LogMessage("-> Patched CEconItemSystem::ReloadWhitelist::nopWarning");
    }



    // For ?
    // Idk what this does yet...
    MemoryPatch memp_GetLoadoutItem  = MemoryPatch.CreateFromConf(tf2rue_gamedata, "CTFPlayer::GetLoadoutItem::nopnop");

    if (!memp_GetLoadoutItem.Validate())
    {
        ThrowError("Failed to verify CTFPlayer::GetLoadoutItem::nopnop");
    }
    else if (memp_GetLoadoutItem.Enable())
    {
        LogMessage("-> Patched CTFPlayer::GetLoadoutItem::nopnop");
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
    char lastUpdateTimeURL[256];

    /* string vs numeric ids */
    if (IsStringNumeric(wlvalue))
    {
        Format(wlurl, sizeof(wlurl), "https://whitelist.tf/custom_whitelist_%s.txt", wlvalue);
        Format(wlcfg, sizeof(wlcfg), "cfg/custom_whitelist_%s.txt",                  wlvalue);
        Format(lastUpdateTimeURL, sizeof(lastUpdateTimeURL), "https://whitelist.tf/last_update_time");
    }
    else
    {
        Format(wlurl, sizeof(wlurl), "https://whitelist.tf/%s.txt",  wlvalue);
        Format(wlcfg, sizeof(wlcfg), "cfg/%s.txt",                   wlvalue);
        Format(lastUpdateTimeURL, sizeof(lastUpdateTimeURL), "https://whitelist.tf/last_update_time?whitelist=%s", wlvalue);
    }
    localmtime = -1;
    localmtime = GetFileTime(wlcfg, FileTime_LastChange);
    LogMessage("CheckWltfMtime - localmtime %i", localmtime);
    LogMessage("CheckWltfMtime - GETing url %s", lastUpdateTimeURL);

    Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, lastUpdateTimeURL);

    SteamWorks_SetHTTPCallbacks(hRequest, SteamWorks_OnCheckWltfMtime);
    SteamWorks_SendHTTPRequest(hRequest);
}

public void SteamWorks_OnCheckWltfMtime(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode)
{
    wltfmtime = -1;
    if
    (
        !bFailure
        && bRequestSuccessful
        &&
        (
            eStatusCode == k_EHTTPStatusCode200OK
            //||
            //eStatusCode == k_EHTTPStatusCode304NotModified
            // caching currently doesn't work with steamworks...?
        )
    )
    {
        int bodysize;
        bool bodyexists = SteamWorks_GetHTTPResponseBodySize(hRequest, bodysize);
        if (bodyexists == false)
        {
            LogImportant("No bodysize for wltf mtime request??? Forcibly redownloading whitelist...");

            CloseHandle(hRequest);
            CheckMtimes();
            return;
        }
        // this is on the stack it gets auto delete'd
        char[] strResponse = new char[bodysize];

        SteamWorks_GetHTTPResponseBodyData(hRequest, strResponse, bodysize);
        wltfmtime = StringToInt(strResponse);
    }
    else
    {
        LogImportant("Failed to check whitelist modified time. Forcibly redownloading whitelist.\nStatusCode = %i, bFailure = %i, RequestSuccessful = %i.", eStatusCode, bFailure, bRequestSuccessful);
    }

    CloseHandle(hRequest);
    CheckMtimes();
    return;
}

void CheckMtimes()
{
    // TODO; need to make sure localmtime is in UTC...
    if (wltfmtime > localmtime || wltfmtime <= 0 || localmtime <= 0)
    {
        LogMessage("CheckMtimes - wltfmtime %i > %i localmtime || wltfmtime %i <= 0 || localtime %i <= 0", wltfmtime, localmtime, wltfmtime, localmtime);
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
    //SteamWorks_SetHTTPRequestHeaderValue(request, "cache-control", "max-age=1200");
    //SteamWorks_SetHTTPRequestHeaderValue(request, "If-Modified-Since", "Wed, 21 Oct 2024 07:28:00 GMT");

    SteamWorks_SetHTTPCallbacks(request, SteamWorks_OnDownloadWhitelist);
    SteamWorks_SendHTTPRequest(request);
}


public void SteamWorks_OnDownloadWhitelist(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode)
{
    if
    (
        !bFailure
        && bRequestSuccessful
        &&
        (
            eStatusCode == k_EHTTPStatusCode200OK
            // ||
            // eStatusCode == k_EHTTPStatusCode304NotModified
        )
    )
    {
        SteamWorks_WriteHTTPResponseBodyToFile(hRequest, wlcfg);
    }
    else
    {
        LogImportant("Failed to download whitelist. Attempting to use cached whitelist...\nStatusCode = %i, bFailure = %i, RequestSuccessful = %i.", eStatusCode, bFailure, bRequestSuccessful);
    }

    CloseHandle(hRequest);

    // check that the file exists
    if (FileExists(wlcfg))
    {
        LogMessage("Setting whitelist %s...", wlcfg);
        SetWhitelist();
    }
    else
    {
        LogImportant("Whitelist %s DOES NOT EXIST, CAN NOT SET WHITELIST!", wlcfg);
    }
}

void SetWhitelist()
{
    mptw.SetString(wlcfg);
    LogImportant("Setting whitelist %s...", wlcfg);
}

void mptw_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (!StrEqual(oldValue, newValue))
    {
        ReloadWhitelist();
    }
}

void ReloadWhitelist()
{
    static Profiler prof = null;
    if (!prof)
    {
        prof = CreateProfiler();
    }


    StartProfiling(prof);
    // Reload the whitelist - this is laggy (BECAUSE OF KeyValues::LoadFromFile in ReloadWhitelist, not because of my code), we need to optimize this at some point...
    Address Addr_ItemSys = SDKCall(SDKCall_ItemSystem);
    SDKCall(SDKCall_ReloadWhitelist, Addr_ItemSys);
    StopProfiling(prof);


    float profTime = GetProfilerTime(prof);
    LogMessage("CEconItemSystem::ReloadWhitelist took %fms", profTime * 1000.0);

    if (!SDKCall_GiveDefaultItems)
    {
        LogMessage("Skipped regenerating players because we can't grant default items");
        return;
    }

    StartProfiling(prof);
    // Remove all client items
    for (int client = 1; client <= MaxClients; client++)
    {
        // ignore bogons
        if (!IsClientInGame(client) || IsFakeClient(client))
        {
            continue;
        }
        TFTeam clientTeam = TF2_GetClientTeam(client);
        if (clientTeam != TFTeam_Blue && clientTeam != TFTeam_Red)
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
                child = GetEntPropEnt(client, Prop_Data, "m_hMoveChild");
            }
            else
            {
                child = GetEntPropEnt(child, Prop_Data, "m_hMovePeer");
            }
        }

        // Give client default weapons and then regenerate them
        SetEntProp(client, Prop_Send, "m_bRegenerating", 1);
        SDKCall(SDKCall_GiveDefaultItems, client);
        SetEntProp(client, Prop_Send, "m_bRegenerating", 0);
        // TF2_RegeneratePlayer(client);
    }
    StopProfiling(prof);

    profTime = GetProfilerTime(prof);
    LogMessage("Regenerating all players took %fms", profTime * 1000.0);
}
