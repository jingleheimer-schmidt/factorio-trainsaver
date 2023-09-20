
-- returns the distance between two map positions
---@param position_1 MapPosition
---@param position_2 MapPosition
---@return integer
local function calculate_distance(position_1, position_2)
    local distance = math.floor(((position_1.x - position_2.x) ^ 2 + (position_1.y - position_2.y) ^ 2) ^ 0.5)
    return distance
end

-- converts speed in kmph into time in ticks
---@param speed_kmph number
---@param distance_in_meters number
---@return number
local function convert_speed_into_time(speed_kmph, distance_in_meters)
    local speed = speed_kmph / 60 / 60 / 60    -- speed in km/tick
    local distance = distance_in_meters / 1000 -- distance in kilometers
    local time = 0
    if speed ~= 0 then
        time = distance / speed
    end
    return time
end

return {
    calculate_distance = calculate_distance,
    convert_speed_into_time = convert_speed_into_time
}
