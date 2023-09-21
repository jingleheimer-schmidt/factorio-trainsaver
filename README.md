### Sit back, relax, and watch your trains drive around! 
This mod creates a dynamic screensaver which follows trains as they drive around from station to station. The screensaver can be started or stopped at any time with cmd/ctrl + t or the /trainsaver chat command. The screensaver can also start automatically when a player is AFK. Most game-control keys will exit the screensaver and return control to the player, except the right/left arrow keys which navigate a history of previously viewed targets.

Please report any issues or suggestions on the [Discussion](https://mods.factorio.com/mod/trainsaver/discussion) page.

Contribute to the project on [GitHub](https://github.com/jingleheimer-schmidt/factorio-trainsaver)

------------------------------------------
# Features
- *Easy Access:* start or stop trainsaver at any time with a configurable hotkey (default: cmd/ctrl + t) or use the /trainsaver command in chat console
- *AFK AutoStart:* trainsaver can start automatically when player is afk 
- *Quick Escape:* easily exit trainsaver by pressing any game-control key (inventory, logistic network, train overview, etc.)
- *Transition Control:* choose between instant or speed based camera transitions in mod settings
- *Fully Configurable:* each player has their own individual settings to control how trainsaver behaves (zoom, transitions, AFK AutoStart time, etc.)
- *Time Travel:* take control of trainsaver's focus target and navigate through the history of previously viewed targets (default: right/left arrow keys)
- *Custom Achievements:* 8 unique trainsaver achievements to unlock, plus 3 additional secret hidden ones!
- *Scope Creep:* enable the scope creep mod setting to expand trainsaver's focus beyond just trains

------------------------------------------
# trainsaver demo video
[![](https://github.com/jingleheimer-schmidt/imgs/raw/primary/factorio%20trainsaver%20mod%20demo%20overview%20video.png)](http://www.youtube.com/watch?v=AbDN4SM4cg8 "trainsaver demo video")

------------------------------------------
# trainsaver extended preview video
[![](https://github.com/jingleheimer-schmidt/imgs/raw/primary/factorio%20trainsaver%20mod%2030%20min%20preview%20video%20thumbnail.png)](http://www.youtube.com/watch?v=ru0OYqdHTfI "trainsaver 30 minute preview")

---------------------
##### Interface
trainsaver provides an interface for other mods to interact with. The interface is named `trainsaver` and includes the following functions:
- trainsaver_status(player_index) --> returns the status of trainsaver for a given player, either "active" or "inactive"
- trainsaver_target(player_index) --> returns the current target (LuaEntity | LuaUnitGroup) trainsaver is following for a given player or nil if none
- focus_next_target(player_index) --> tells trainsaver to go forward in history. finds a new target if current target is the newest in history
- focus_previous_target(player_index) --> tells trainsaver to go backward in history. won't do anything the current target is the oldest in history

Example interface usage:
- https://lua-api.factorio.com/latest/classes/LuaRemote.html#call
- remote.call("trainsaver", "trainsaver_status", player_index)
- remote.call("trainsaver", "trainsaver_target", player_index)
- remote.call("trainsaver", "focus_next_target", player_index)
- remote.call("trainsaver", "focus_previous_target", player_index)

---------------------
##### Translation
Help translate trainsaver to more languages: https://crowdin.com/project/factorio-mods-localization
Currently available locale:
- English (en)

------------------------------------------
##### Compatibility:
There are currently no known mod compatibility issues. To report a compatibility issue, please make a post on the discussion page.

------------------------------------------
##### Other mods by asher_sky:

- [Cooked fish](https://mods.factorio.com/mod/factorio-cooked-fish) Allows raw fish to be cooked in a furnace.
- [Auto Color Lamps](https://mods.factorio.com/mod/auto-color-lamps) Automatically colors lamps according to the color of item and fluid signals passed to them.
- [Chorus fruit](https://mods.factorio.com/mod/factorio-chorus-fruit) Adds chorus fruit you can eat to teleport randomly, just like minecraft.
- [Apples](https://mods.factorio.com/mod/factorio-apples) Adds apples you can eat to regenerate health, just like minecraft.
- [Ender Pearl](https://mods.factorio.com/mod/factorio-ender-pearl) Adds an ender pearl you can throw to teleport, just like minecraft.
- [Cutscene Creator](https://mods.factorio.com/mod/cutscene-creator) Adds a command to create custom cutscenes. 
