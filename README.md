# TFTruest
SourceMod plugin replacement for nAkkk's TFTrue. Infdev

# Why
TFTrue is ancient, uses a ton of boilerplate code, has sporadic crashes, contains closed source code (in violation of its supposed GPL-2 liscensing)and is poorly maintained. The aim of this project is to optimize as much as possible, while relying on dependencies maintained either directly by the SourceMod team themselves, or by well known, still active developers.

# Dependencies

- [SourceScramble](https://github.com/nosoop/SMExt-SourceScramble) by nosoop - for memory patching
- [SteamWorks](https://github.com/KyleSanderson/SteamWorks) by KyleS - for SteamWorks functions (web requests etc)
- DHooks2 by PeaceMaker and the SourceMod team - for detouring and hooking functions
- [SM Json](https://github.com/clugg/sm-json) by clugg - for log parsing

Don't worry, all of this is included in the release zip file. Just drag and drop to your server. Plus, this plugin keeps itself up to date with GoDTony's popular Updater plugin, if you have it installed.

# Added / Tweaked / Planned features

- [done] Significantly faster whitelist reloading when changing any whitelist cvars (fixes ["gg lag"](https://github.com/ldesgoui/tf2-comp-fixes/issues/20))
- [done] Only download whitelist from whitelist.tf if local copy isn't present or if the item schema has updated
- [todo] bhop
- [indev] fov
- [todo] stv stuff
- [todo] logs
- [indev] everything else

# Removed features

- `tftrue_no_hats`
- `tftrue_no_misc`
- `tftrue_no_action`

These cvars were removed because they are infrequently used and have a therefore unjustifiable amount of code and cpu time attatched to them. TFTrue was iterating thru keyvalues every single time a whitelist cvar was changed, for essentially no reason.
