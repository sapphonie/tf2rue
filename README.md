# TFTruest
SourceMod plugin fork of AnAkkk's TFTrue. Infdev

# What works

- `mp_tournament_whitelist` in mp_tournament 0

# What doesn't

- Everything else

# Added / Tweaked / Planned features

- [indev] Significantly faster whitelist reloading when changing any whitelist cvars (fixes ["gg lag"](https://github.com/ldesgoui/tf2-comp-fixes/issues/20))
- [todo] Only download whitelist from whitelist.tf if local copy isn't present or if the item schema has updated
- [todo] everything else

# Removed features

- `tftrue_no_hats`
- `tftrue_no_misc`
- `tftrue_no_action`

These cvars were removed because they are infrequently used and have a therefore unjustifiable amount of code and cpu time attatched to them. TFTrue was iterating thru keyvalues every single time a whitelist cvar was changed, for essentially no reason.
