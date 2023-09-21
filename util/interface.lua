
--[[
Example usage:
    remote.call("trainsaver", "trainsaver_status", player_index) --> returns the status of trainsaver for a given player, either "active" or "inactive"
    remote.call("trainsaver", "trainsaver_target", player_index) --> returns the current target (locomotive or other entity) trainsaver is following for a given player or nil if none
    remote.call("trainsaver", "focus_next_target", player_index) --> mimics the "focus next target" keybind for a given player
    remote.call("trainsaver", "focus_previous_target", player_index) --> mimics the "focus previous target" keybind for a given player
--]]

local controls_util = require("util.controls")
local focus_next_target = controls_util.focus_next_target
local focus_previous_target = controls_util.focus_previous_target
local start_trainsaver = controls_util.start_trainsaver
local end_trainsaver = controls_util.end_trainsaver
local toggle_trainsaver = controls_util.start_or_end_trainsaver
local reset_player_history = controls_util.reset_player_history

local interface_functions = {}

interface_functions.trainsaver_status = function(player_index)
    if global.trainsaver_status and global.trainsaver_status[player_index] then
        return global.trainsaver_status[player_index]
    else
        return "inactive"
    end
end

interface_functions.trainsaver_target = function(player_index)
    if global.current_target and global.current_target[player_index] then
        return global.current_target[player_index]
    else
        return nil
    end
end

interface_functions.focus_next_target = function(player_index)
    local mock_event_data = { name = "trainsaver", player_index = player_index }
    focus_next_target(mock_event_data)
end

interface_functions.focus_previous_target = function(player_index)
    local mock_event_data = { name = "trainsaver", player_index = player_index }
    focus_previous_target(mock_event_data)
end

interface_functions.start_trainsaver = function(player_index)
    local mock_event_data = { name = "trainsaver", player_index = player_index }
    start_trainsaver(mock_event_data)
end

interface_functions.end_trainsaver = function(player_index)
    local mock_event_data = { name = "trainsaver", player_index = player_index }
    end_trainsaver(mock_event_data)
end

interface_functions.toggle_trainsaver = function(player_index)
    local mock_event_data = { name = "trainsaver", player_index = player_index }
    toggle_trainsaver(mock_event_data)
end

interface_functions.reset_player_history = function(player_index)
    reset_player_history(player_index)
end

return {
    interface_functions = interface_functions,
}
