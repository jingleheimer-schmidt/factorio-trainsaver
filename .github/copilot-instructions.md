# Copilot Instructions for trainsaver

## Project Overview

trainsaver is a Factorio mod that creates a dynamic screensaver which follows trains as they drive around from station to station. The mod is written in Lua using the Factorio modding API and targets Factorio 2.0.

## Project Structure

- `control.lua` - Main control script with event handlers and game logic
- `data.lua` - Defines custom inputs, hotkeys, and achievements
- `settings.lua` - Defines mod settings and configuration options
- `util/` - Modular utility files organized by functionality:
  - `constants.lua` - Constant definitions for train states
  - `controls.lua` - Functions for starting/ending trainsaver and focus control
  - `cutscene.lua` - Cutscene creation and management
  - `globals.lua` - Global state management
  - `gui.lua` - GUI manipulation utilities
  - `interface.lua` - Remote interface for mod interoperability
  - `math.lua` - Mathematical utilities
  - `message.lua` - Chatty/debug message utilities
  - `status.lua` - Status checking functions
  - `target.lua` - Target entity identification and validation
  - `waypoint.lua` - Waypoint creation for cutscenes
- `locale/` - Localization files (en, ru, uk)

## Coding Standards

### Lua Style

- Use **snake_case** for variable and function names
- Use **camelCase** for Factorio data prototype table keys (e.g., `toggleTrainsaverKey`)
- Organize code into small, focused utility modules in `util/` directory
- Use descriptive variable names; avoid abbreviations except for well-known cases

### Type Annotations

- Use **LuaLS/EmmyLua** type annotations (`---@param`, `---@return`, `---@type`, `---@class`)
- Annotate function parameters with their types (e.g., `LuaPlayer`, `LuaTrain`, `uint`)
- Document event handlers with appropriate event data types (e.g., `EventData.on_train_changed_state`)
- Use nullable types with `?` suffix when applicable (e.g., `boolean?`)

### Comments

- Add single-line comments for complex logic blocks
- Use multi-line block comments `--[[ ]]--` for sections or major functionality
- Include header comments for files: `--[[ factorio mod trainsaver <file purpose> created by asher_sky --]]`
- Document achievements and special features clearly

### Code Organization

- Import utility modules at the top of files
- Extract individual functions from utility modules (e.g., `local chatty_print = message_util.chatty_print`)
- Keep `control.lua` focused on event registration; extract logic to `util/` modules
- Use `require()` for module imports, not `dofile()`

## Factorio Modding Conventions

### Data Stage (data.lua)

- Define prototypes using tables assigned to local variables first
- Use `data:extend({})` to register prototypes
- Follow Factorio's prototype type naming (e.g., `custom-input`, `achievement`, `int-setting`)
- Use `order` fields for consistent UI positioning

### Control Stage (control.lua)

- Use `storage` for persistent data across saves (replaces `global` in Factorio 2.0+)
- Always validate entities/players exist before using them (`if not player then return end`)
- Use `script.on_event()` for event registration
- Use `script.on_nth_tick()` for periodic checks
- Use event filters when possible to reduce overhead (e.g., `locomotive_filter`)

### Remote Interface

- Export functions via `remote.add_interface()` for mod interoperability
- Document interface functions with usage examples
- Follow naming convention: `<mod_name>.<function_name>`

### Settings

- Use runtime-per-user settings for player-specific preferences
- Provide reasonable default values
- Use descriptive `order` fields for settings UI organization
- Include minimum/maximum value constraints where appropriate

## Key Technical Details

### Event Handling Patterns

- Use labeled blocks with `goto` statements (`::next_player::`) to skip to next iteration in complex loops (pattern used throughout this codebase)
- Check controller type before operating on player: `player.controller_type`
- Validate entity validity: `if not entity.valid then return end`
- Use `script.register_on_object_destroyed()` for tracking entity lifecycle

### Cutscene Management

- Create waypoints using `create_waypoint()` utility
- Use `player.set_controller()` to switch to cutscene mode
- Store player state before cutscene, restore on exit
- Handle cutscene end via `on_cutscene_cancelled`, `on_cutscene_finished`, `on_cutscene_waypoint_reached` events

### Achievement System

- Unlock achievements via `player.unlock_achievement()`
- Track continuous and total duration in storage
- Use hidden achievements for secrets
- Print notable events to inform other players

### Debug/Verbose Mode

- Use `storage.chatty` flag to control debug output
- Provide `chatty_print()` function that only prints when verbose mode is enabled
- Include tick numbers and colored player names in debug messages
- Toggle via `/verbose-trainsaver` command

## Testing and Validation

- Test in-game with Factorio 2.0
- Verify compatibility with Space Age DLC features (planets, space platforms)
- Test multiplayer scenarios (multiple players, different surfaces)
- Validate entity lifecycle handling (trains destroyed, mined, etc.)
- Test achievement unlocking conditions
- Check remote interface functionality with example calls

## Dependencies

- Factorio 2.0.0 or higher
- No external mod dependencies (base game only)

## License

CC BY-NC-SA 4.0 (Attribution-NonCommercial-ShareAlike 4.0 International) - Non-commercial use only with attribution to asher_sky.

## Special Features to Consider

- **Cross-surface support**: Mod can target entities on any planet/surface
- **Spidertron tracking**: Includes logic for following spidertron autopilot paths
- **Rocket launch tracking**: Special handling for rocket silo events
- **Bi-directional trains**: Handles trains with front/back movers, tracks leading locomotive based on speed
- **AFK auto-start**: Automatically starts screensaver when player is AFK
- **Target history**: Navigate through previously viewed targets with arrow keys
- **Scope creep mode**: Optional setting to expand beyond trains (spidertrons, rockets, unit groups)

## Common Patterns

### Checking if trainsaver is active for a player
```lua
if not trainsaver_is_active(player) then return end
```

### Getting current target
```lua
local current_target = current_trainsaver_target(player)
if not current_target then return end
```

### Creating and playing a cutscene
```lua
local waypoints = create_waypoint(entity, player_index)
play_cutscene(waypoints, player_index, record_history)
```

### Iterating connected players safely
```lua
for _, player in pairs(game.connected_players) do
    if not trainsaver_is_active(player) then goto next_player end
    -- logic here
    ::next_player::
end
```

## Localization

- Support multiple languages (en, ru, uk currently available)
- Use Crowdin for community translations
- Localize mod name, description, settings, and achievements
- Follow Factorio locale file format in `locale/<lang>/` directories
