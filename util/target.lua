
local constants = require("util.constants")
local idle_states = constants.idle_states

-- returns the current trainsaver target for a given player, if any
---@param player LuaPlayer
---@return LuaEntity|LuaUnitGroup|nil
local function current_trainsaver_target(player)
    global.current_target = global.current_target or {}
    local target = global.current_target[player.index]
    if target.valid then
        return target
    end
end

-- returns true if the provided cutscene waypoint target is a valid entity
---@param target LuaEntity|LuaUnitGroup|nil
---@return boolean
local function target_is_entity(target)
    if target and target.valid and (target.object_name == "LuaEntity") then
        return true
    else
        return false
    end
end

-- returns true if the given target is a valid locomotive
---@param target LuaEntity|LuaUnitGroup|nil
---@return boolean
local function target_is_locomotive(target)
    if target and target_is_entity(target) and (target.type == "locomotive") then
        return true
    else
        return false
    end
end

-- returns true if the given target is a valid spidertron
---@param target LuaEntity|LuaUnitGroup|nil
---@return boolean
local function target_is_spider(target)
    if target and target_is_entity(target) and (target.type == "spider-vehicle") then
        return true
    else
        return false
    end
end

-- returns true if the given target is a valid rocket silo
---@param target LuaEntity|LuaUnitGroup|nil
---@return boolean
local function target_is_rocket_silo(target)
    if target and target_is_entity(target) and (target.type == "rocket-silo") then
        return true
    else
        return false
    end
end

-- returns true if the given target is a valid unit group
---@param target LuaEntity|LuaUnitGroup|nil
---@return boolean
local function target_is_unit_group(target)
    if target and target.valid and (target.object_name == "LuaUnitGroup") then
        return true
    else
        return false
    end
end

-- return true if the current trainsaver target is a locomotive and the train has an idle state, or the current target is a spidertron and it is not moving
---@param player LuaPlayer
---@return boolean
local function waypoint_target_has_idle_state(player)
    local bool = false
    local current_target = current_trainsaver_target(player)
    if current_target and target_is_locomotive(current_target) then
        local locomotive = current_target --[[@as LuaEntity]]
        local state = locomotive.train.state
        if idle_states[state] then
            bool = true
        end
    elseif current_target and target_is_spider(current_target) then
        local spider = current_target --[[@as LuaEntity]]
        local speed = spider.speed
        if speed == 0 then
            bool = true
        end
    elseif current_target and target_is_rocket_silo(current_target) then
        bool = false
    end
    return bool
end

return {
    current_trainsaver_target = current_trainsaver_target,
    target_is_entity = target_is_entity,
    target_is_locomotive = target_is_locomotive,
    target_is_spider = target_is_spider,
    target_is_rocket_silo = target_is_rocket_silo,
    target_is_unit_group = target_is_unit_group,
    waypoint_target_has_idle_state = waypoint_target_has_idle_state
}
