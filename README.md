# TF2rue
SourceMod plugin replacement for AnAkkk's TFTrue.

Also replaces F2's logstf/supstats/medicstats plugin.

***This plugin is not yet finished and should not be used in a production environment unless you are crazy.***

# Why
TFTrue is ancient, uses a ton of boilerplate code, has sporadic crashes, contains closed source code (in violation of its supposed GPL-2 liscensing) and is poorly maintained. 

Logstf/supstats/medicstats is similarly old, depends on the unmaintained and partially broken cURL extension, and similarly has a lot of boilerplate for things that SourceMod didn't provide at the time, but that now exists and is maintained.

The aim of this project is to optimize as much as possible, while relying on dependencies maintained either directly by the SourceMod team themselves, or by well known, still active developers.

# Dependencies

- [SourceScramble](https://github.com/nosoop/SMExt-SourceScramble) by nosoop - for memory patching
- [SteamWorks](https://github.com/KyleSanderson/SteamWorks) by KyleS - for SteamWorks functions (web requests etc)
- DHooks2 by PeaceMaker and the SourceMod team - for detouring and hooking functions
- [SM Json](https://github.com/clugg/sm-json) by clugg - for log parsing

Don't worry, all of this is included in the release zip file. Just drag and drop to your server. Plus, this plugin keeps itself up to date with GoDTony's popular Updater plugin, if you have it installed.

# Features

- [done] NEW! Significantly faster whitelist reloading when changing any whitelist cvars (fixes ["gg lag"](https://github.com/ldesgoui/tf2-comp-fixes/issues/20))
- [done] NEW! Only download whitelist from whitelist.tf if local copy isn't present or if the item schema has updated
- [todo] bhop
- [indev] fov
- [todo] stv stuff
- [todo] logs
- [todo] demostf support
- [todo] rgl configs
- [todo] redirect output with `log on` to not spam console
- [indev] everything else

# Removed features

- `tftrue_no_hats`
- `tftrue_no_misc`
- `tftrue_no_action`

These cvars were removed because they are infrequently used and have a therefore unjustifiable amount of code and cpu time attatched to them. TFTrue was iterating thru keyvalues every single time a whitelist cvar was changed, for essentially no reason.
