
local constants = require("util.constants")
local idle_states = constants.idle_states

-- returns the current trainsaver target for a given player, if any
---@param player LuaPlayer
---@return LuaEntity|LuaCommandable|nil
local function current_trainsaver_target(player)
    storage.current_target = storage.current_target or {}
    local target = storage.current_target[player.index]
    if target and target.valid then
        return target
    end
end

-- returns true if the provided cutscene waypoint target is a valid entity
---@param target LuaEntity|LuaCommandable|nil
---@return boolean
local function target_is_entity(target)
    local entity = target and target.valid and (target.object_name == "LuaEntity")
    return entity and true or false
end

-- returns true if the given target is a valid locomotive
---@param target LuaEntity|LuaCommandable|nil
---@return boolean
local function target_is_locomotive(target)
    local locomotive = target and target_is_entity(target) and (target.type == "locomotive")
    return locomotive and true or false
end

-- returns true if the given target is a valid spidertron
---@param target LuaEntity|LuaCommandable|nil
---@return boolean
local function target_is_spider(target)
    local spider = target and target_is_entity(target) and (target.type == "spider-vehicle")
    return spider and true or false
end

-- returns true if the given target is a valid rocket silo
---@param target LuaEntity|LuaCommandable|nil
---@return boolean
local function target_is_rocket_silo(target)
    local silo = target and target_is_entity(target) and (target.type == "rocket-silo")
    return silo and true or false
end

-- returns true if the given target is a valid unit group
---@param target LuaEntity|LuaCommandable|nil
---@return boolean
local function target_is_unit_group(target)
    local group = target and target.valid and (target.object_name == "LuaUnitGroup")
    return group and true or false
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
