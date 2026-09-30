[![Ko-fi Donate](https://img.shields.io/badge/Ko--fi-Donate%20-indianred?logo=kofi\&logoColor=white)](https://ko-fi.com/asher_sky) [![GitHub Contribute](https://img.shields.io/badge/GitHub-Contribute-blue?logo=github)](https://github.com/jingleheimer-schmidt/factorio-trainsaver) [![Crowdin Translate](https://img.shields.io/badge/Crowdin-Translate-green?logo=crowdin)](https://crowdin.com/project/factorio-mods-localization) [![Mod Portal Download](https://img.shields.io/badge/Mod_Portal-Download-orange?logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAsAAAALCAMAAACecocUAAABhGlDQ1BJQ0MgcHJvZmlsZQAAKJF9kT1Iw0AcxV9bS4tUHewg4hCwOlkQFXHUKhShQqgVWnUwufQLmjQkKS6OgmvBwY/FqoOLs64OroIg+AHi4uqk6CIl/i8ptIjx4Lgf7+497t4B/kaFqWbXOKBqlpFOJoRsblUIvSKMIHoxjJjETH1OFFPwHF/38PH1Ls6zvM/9OXqUvMkAn0A8y3TDIt4gnt60dM77xFFWkhTic+Ixgy5I/Mh12eU3zkWH/TwzamTS88RRYqHYwXIHs5KhEk8RxxRVo3x/1mWF8xZntVJjrXvyF0by2soy12kOIYlFLEGEABk1lFGBhTitGikm0rSf8PAPOn6RXDK5ymDkWEAVKiTHD/4Hv7s1C5MTblIkAQRfbPtjBAjtAs26bX8f23bzBAg8A1da219tADOfpNfbWuwI6NsGLq7bmrwHXO4AA0+6ZEiOFKDpLxSA9zP6phzQfwt0r7m9tfZx+gBkqKvUDXBwCIwWKXvd493hzt7+PdPq7wdcTnKeyn2biAAAAAlwSFlzAAAuIwAALiMBeKU/dgAAAAd0SU1FB+MIBQ4nOKPzX44AAAAZdEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBXgQ4XAAAAnFBMVEUAAAAAAAAAAAAAAABBPj5EQ0NBQUFCQkJYV1daWlpcXFxfXl19enl7enp6enp9fX2Rjo2Ojo6RkZGUk5OfnJufn5+goKCioqK5uLe3t7e5ubm6urrPz8/Pz8/R0NDT0tHT09PV1dXW1tXh4ODh4eHg4ODh4eHi4eHi4uLi4uLi4uLk4+Pk5OTl5eXm5ubm5ubn5ubn5+fp6en+/vsJa+h2AAAAMnRSTlMAAgMEEBIUFR0jJSY8PUBDU1daX2hucHOTlpicxcbIyc7R0unq6+vt7e7v8vT2+Pn6+p+as4UAAAABYktHRDM31XxeAAAAYUlEQVQIHQXBBQLCQBDAwJTF3b0Uh2IH+f/jmAGA5yYygG65OFpOOoMMmqrqJWCoaZt0FizPpnpUP+6Dh+YR5PqGwtSIWvK6gqn+dl8dBZxU1VZArz2+eZjf+xkA61dUgD8jzgwslUkzIwAAAABJRU5ErkJggg==)](https://mods.factorio.com/mod/trainsaver)

### Sit back, relax, and watch your trains drive around!
trainsaver drives a dynamic camera to follow trains as they travel around the factory. Start or stop it at any time with Cmd/Ctrl+T or the `/trainsaver` command. It can also start automatically while you are AFK. Common game controls return control to the player, while the right and left arrow keys navigate previously viewed targets.

Please report any issues or suggestions on the [Discussion](https://mods.factorio.com/mod/trainsaver/discussion) page.

------------------------------------------
# Features
- *Easy access:* start or stop trainsaver with a configurable hotkey (default: Cmd/Ctrl+T) or the `/trainsaver` command.
- *AFK auto-start:* trainsaver can start automatically when you are AFK.
- *Quick escape:* return control to the player with common game controls such as movement, inventory, logistic network, or train overview.
- *Per-player settings:* includes individual player settings to configure camera zoom, transitions, viewing times, AFK behavior, and more.
- *Target history:* navigate previously viewed targets with configurable controls (default: right and left arrow keys).
- *Custom achievements:* unlock achievements for viewing milestones and other special events.
- *Scope creep:* Spider? I hardly know her! Trainsaver can also target spidertrons and rocket launches.

------------------------------------------
# trainsaver demo video
(4 minutes, v0.0.3, December 2020)
[![](https://github.com/jingleheimer-schmidt/imgs/raw/primary/factorio%20trainsaver%20mod%20demo%20overview%20video.png)](http://www.youtube.com/watch?v=AbDN4SM4cg8 "trainsaver demo video")

------------------------------------------
# trainsaver extended preview video
(30 minutes, v0.0.3, December 2020)
[![](https://github.com/jingleheimer-schmidt/imgs/raw/primary/factorio%20trainsaver%20mod%2030%20min%20preview%20video%20thumbnail.png)](http://www.youtube.com/watch?v=ru0OYqdHTfI "trainsaver 30 minute preview")

------------------------------------------
# Commands
trainsaver provides the following console commands:

- `/trainsaver` — starts or ends trainsaver.
- `/ts-start` — starts trainsaver.
- `/ts-end` — ends trainsaver and returns camera control to the player.
- `/ts-verbose` — toggles verbose trainsaver messages.
- `/ts-reset_history` — clears the trainsaver target history.
- `/ts-next_target` — moves forward through target history and selects a new target when already at the newest entry.
- `/ts-previous_target` — moves backward through target history.
- `/ts-ignore_stations <train-stop...>` — ignores trains traveling to train stops with the specified names.
- `/ts-unignore_stations <train-stop...>` — stops ignoring train stops with the specified names.
- `/ts-list_ignored_stations` — lists all ignored train stop names.

The ignored train stop name list is shared across the save. Adding a name affects every train stop with that name.

---------------------
# Interface
trainsaver provides an interface for other mods to interact with. The interface is named `trainsaver` and includes the following functions:

- `trainsaver_status(player_index)` --> returns the status of trainsaver for a given player, either "active" or "inactive"
- `trainsaver_target(player_index)` --> returns the current target (LuaEntity | LuaUnitGroup) trainsaver is following for a given player, or nil if there is none
- `start_trainsaver(player_index)` --> starts trainsaver for a given player
- `end_trainsaver(player_index)` --> ends trainsaver for a given player
- `toggle_trainsaver(player_index)` --> toggles trainsaver for a given player
- `focus_next_target(player_index)` --> tells trainsaver to go forward in history. finds a new target if current target is the newest in history
- `focus_previous_target(player_index)` --> tells trainsaver to go backward in history. won't do anything if the current target is the oldest in history
- `reset_player_history(player_index)` --> clears the target history for a given player

Example interface usage:

- https://lua-api.factorio.com/latest/classes/LuaRemote.html#call
- `remote.call("trainsaver", "toggle_trainsaver", player_index)`
---------------------
# Translation
Help translate trainsaver to more languages: https://crowdin.com/project/factorio-mods-localization
Currently available locales:
🇺🇸 English (en), 🇷🇺 Russian (ru), 🇺🇦 Ukrainian (uk)

------------------------------------------
# Compatibility
Please report compatibility issues on the [mod discussion page](https://mods.factorio.com/mod/trainsaver/discussion).

If you have suggestions or bug fixes that you would like to contribute directly, feel free to open a pull request on [GitHub](https://github.com/jingleheimer-schmidt/factorio-trainsaver).
