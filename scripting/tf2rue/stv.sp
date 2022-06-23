
ConVar tftrue_tv_autorecord("tftrue_tv_autorecord", "1", FCVAR_NOTIFY,
    "Turn on/off auto STV recording when both teams are ready in tournament mode. It will stop when the win conditions are reached.",
    true, 0, true, 1,
    &CSourceTV::AutoRecord_Callback);

ConVar tftrue_tv_recordpath("tftrue_tv_demos_path", "");

ConVar tftrue_tv_prefix("tftrue_tv_prefix", "", FCVAR_NONE,
    "Prefix to add to the demo names with auto STV recording.",
    &CSourceTV::Prefix_Callback);


ConVar tv_enable;

public void OnMapStart()
{
            tv_enable       = FindConVar("tv_enable");
    ConVar  tv_snapshotrate = FindConVar("tv_snapshotrate");
    ConVar  tv_maxrate      = FindConVar("tv_maxrate");

    // tv_snapshotrate.SetValue("66");
    // tv_maxrate.SetValue("0");
}

void CSourceTV::OnTournamentStarted(const char *szBlueTeamName, const char* szRedTeamName)
{
    if (tv_enable.GetBool() && tftrue_tv_autorecord.GetBool())
    {
        char strTime[128];
        FormatTime(strTime, sizeof(strTime), "Y-%m-%d-%H-%M", GetTime());


        char strTvRecordPath[32];
        GetConVarString(tft_tv_recordpath, strTvRecordPath, sizeof(strTvRecordPath));

        char strFolder[32];
        Format(strFolder, sizeof(strFolder), "%s", strTvRecordPath)

        if (!StrEqual(strTvRecordPath, ""))
        {
            CreateDirectory(strFolder);
        }

        char strTvPrefix[32];
        GetConVarString(tft_tv_recordpath, strTvPrefix, sizeof(strTvPrefix));

        char strMap[64];
        GetCurrentMap(strMap, sizeof(strMap));
        // GetMapDisplayName

        char tvRecordCmd[256];
        if (!StrEqual(strTvPrefix, ""))
        {
            Format(tvRecordCmd, sizeof(tvRecordCmd),
                "tv_record \"\
                    %s\
                    %s-\
                    %s-\
                    %s_vs_%s\
                    -%s\
                \"",
                strFolder,
                strTvPrefix,
                strTime,
                strBlueTeamName, strRedTeamName,
                strMap
            );
        }
        else
        {
            Format(tvRecordCmd, sizeof(tvRecordCmd),
                "tv_record \
                    \"\
                    %s\
                    %s-\
                    %s_vs_%s\
                    -%s\
                \"",
                strFolder,
                strTime,
                strBlueTeamName, strRedTeamName,
                strMap
            );
        }

        ServerCommand(tvRecordCmd);
    }
}

void CSourceTV::OnGameOver()
{
    StopTVRecord();
}

void CSourceTV::StopTVRecord()
{
    static ConVarRef tv_enable("tv_enable");
    static ConVarRef mp_tournament("mp_tournament");
    static ConVarRef tf_gamemode_mvm("tf_gamemode_mvm");

    if
    (
            tv_enable.GetBool()
        &&  tftrue_tv_autorecord.GetBool()
        &&  mp_tournament.GetBool()
        &&  !tf_gamemode_mvm.GetBool()
    )
    {
        engine->InsertServerCommand("tv_stoprecord\n");
        engine->ServerExecute();
    }
}

void CSourceTV::AutoRecord_Callback( IConVar *var, const char *pOldValue, float flOldValue )
{
    if(!flOldValue && g_Tournament.TournamentStarted() && tv_enable.GetBool())
    {
        engine->InsertServerCommand(g_SourceTV.m_szTVRecord);
        engine->ServerExecute();
    }
}

void CSourceTV::Enable_Callback( IConVar *var, const char *pOldValue, float flOldValue )
{
    g_SourceTV.m_Enable_OldCallback(var, pOldValue, flOldValue);

    ConVar* v = (ConVar*)var;
    if(v->GetBool() && !flOldValue)
    {
        AllMessage("\003[TFTruer] Source TV enabled! Changing map...\n");
        g_Plugin.ForceReloadMap(gpGlobals->curtime+3.0f);
    }
    else if(!v->GetBool() && flOldValue)
    {
        AllMessage("\003[TFTruer] Source TV disabled!\n");
        engine->InsertServerCommand("tv_stop\n");
        engine->ServerExecute();
    }
}

void CSourceTV::Prefix_Callback( IConVar *var, const char *pOldValue, float flOldValue )
{
    ConVar* v = (ConVar*)var;

    std::string strPrefix = v->GetString();

    ReplaceAlphaWithUnderscore(strPrefix);

    char szPrefix[64];
    strncpy(szPrefix, strPrefix.c_str(), sizeof(szPrefix));

    if (strcmp(v->GetString(), szPrefix) != 0)
    {
        v->SetValue(szPrefix);
    }
}
