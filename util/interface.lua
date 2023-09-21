
--[[
Remote Interface:
    remote.call("trainsaver", "trainsaver_status", player_index) --> returns the status of trainsaver for a given player, either "active" or "inactive"
    remote.call("trainsaver", "trainsaver_target", player_index) --> returns the current target (locomotive or other entity) trainsaver is following for a given player or nil if none
--]]

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

return {
    interface_functions = interface_functions,
}
