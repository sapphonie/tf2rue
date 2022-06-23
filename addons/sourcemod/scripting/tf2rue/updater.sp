#define UpdateURL "https://raw.githubusercontent.com/sapphonie/tf2rue/main/updatefile.txt"

void InitUpdater()
{
    if (LibraryExists("updater"))
    {
        Updater_AddPlugin(UpdateURL);
    }
}


public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "updater"))
    {
        Updater_AddPlugin(UpdateURL);
    }
}
