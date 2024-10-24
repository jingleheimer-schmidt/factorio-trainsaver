
local function toggle_chatty()
    if not storage.chatty then
        storage.chatty = true
        game.print("verbose trainsaver enabled")
    else
        storage.chatty = false
        game.print("verbose trainsaver disabled")
    end
end

-- print a message to the game console if storage.chatty is true
---@param message string
local function chatty_print(message)
    if storage.chatty then
        game.print(message)
    end
end

-- return a string with the current game tick and the name of a player colored with the player's color;
-- i.e. "[123456] [[color=1,1,1]player_name[/color]]"
---@param player LuaPlayer
---@return string
local function chatty_player_name(player)
    return "[" .. game.tick .. "] [[color=" .. player.color.r .. "," .. player.color.g .. "," .. player.color.b .. "]" .. player.name .. "[/color]]: "
end

-- return a string with the name of the train, colored if possible with color of a locomotive on the train
---@param train LuaTrain
---@return string
local function chatty_target_train_name(train)
    local target_name = "train " .. train.id
    local front_mover = train.locomotives["front_movers"][1]
    local back_mover = train.locomotives["back_movers"][1]
    if not ((front_mover and front_mover.color) or (back_mover and back_mover.color)) then return target_name end
    local color = front_mover.color or back_mover.color
    if color then
        target_name = "[color=" .. color.r .. "," .. color.g .. "," .. color.b .. "]" .. target_name .. "[/color]"
    end
    return target_name
end

-- return a string with the name of the entity, colored if possible with its color
---@param entity LuaEntity
---@return string
local function chatty_target_entity_name(entity)
    local id = entity.entity_label or entity.backer_name or entity.unit_number or script.register_on_object_destroyed(entity)
    local target_name = entity.name .. " " .. id
    if entity.train then target_name = "train " .. entity.train.id .. ": " .. id end
    local color = entity.color
    if color then
        target_name = "[color=" .. color.r .. "," .. color.g .. "," .. color.b .. "]" .. target_name .. "[/color]"
    end
    return target_name
end

-- return a string with the name of the target, colored if possible with its color
---@param target LuaEntity|LuaCommandable|LuaTrain|LuaPlayer|nil
---@return string
local function get_chatty_name(target)
    if not target then return "nil" end
    local object_name = target.object_name
    if object_name == "LuaTrain" then
        return chatty_target_train_name(target)
    elseif object_name == "LuaPlayer" then
        return chatty_player_name(target)
    elseif object_name == "LuaEntity" then
        return chatty_target_entity_name(target)
    else
        return "LuaUnitGroup"
    end
end

-- print a message to all players who have notable events enabled
---@param message string
local function print_notable_event(message)
    for _, player in pairs(game.connected_players) do
        if player.mod_settings["ts-notable-events"].value == true then
            player.print(message)
        end
    end
end

return {
    toggle_chatty = toggle_chatty,
    chatty_print = chatty_print,
    chatty_player_name = chatty_player_name,
    chatty_target_train_name = chatty_target_train_name,
    chatty_target_entity_name = chatty_target_entity_name,
    get_chatty_name = get_chatty_name,
    print_notable_event = print_notable_event,
}
