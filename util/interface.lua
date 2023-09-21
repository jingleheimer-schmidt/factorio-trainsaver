
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
    local mock_event_data = { player_index = player_index }
    focus_next_target(mock_event_data)
end

interface_functions.focus_previous_target = function(player_index)
    local mock_event_data = { player_index = player_index }
    focus_previous_target(mock_event_data)
end

return {
    interface_functions = interface_functions,
}
