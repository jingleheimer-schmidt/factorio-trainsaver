
---@type data.ModDoubleSettingPrototype
local zoom = {
    type = "double-setting",
    name = "ts-zoom",
    setting_type = "runtime-per-user",
    minimum_value = .1,
    default_value = .375,
    maximum_value = 5,
    order = "ts-a-1"
}

---@type data.ModDoubleSettingPrototype
local transition_speed = {
    type = "double-setting",
    name = "ts-transition-speed",
    setting_type = "runtime-per-user",
    minimum_value = 0,
    default_value = 0, -- km/h, will be converted to time (ticks)
    order = "ts-a-2"
}

---@type data.ModDoubleSettingPrototype
local transition_time = {
    type = "double-setting",
    name = "ts-transition-time",
    setting_type = "runtime-per-user",
    minimum_value = 0,
    -- maximum_value = 1800,
    default_value = 0, -- km/h, will be converted to time (ticks)
    order = "ts-a-3",
    hidden = true,
}

---@type data.ModIntSettingPrototype
local wait_at_signal = {
    type = "int-setting",
    name = "ts-wait-at-signal",
    setting_type = "runtime-per-user",
    default_value = 30, -- seconds, will be converted to ticks
    minimum_value = 0,
    order = "ts-b-1"
}

---@type data.ModIntSettingPrototype
local station_minimum = {
    type = "int-setting",
    name = "ts-station-minimum",
    setting_type = "runtime-per-user",
    default_value = 5, -- seconds, will be converted to ticks
    minimum_value = 0,
    order = "ts-b-2"
}

---@type data.ModIntSettingPrototype
local driving_minimum = {
    type = "int-setting",
    name = "ts-driving-minimum",
    setting_type = "runtime-per-user",
    default_value = 10, -- minutes, will be converted to ticks
    minimum_value = 0,
    order = "ts-b-3"
}

---@type data.ModDoubleSettingPrototype
local time_wait = {
    type = "double-setting",
    name = "ts-time-wait",
    setting_type = "runtime-per-user",
    minimum_value = 1, -- minimum cutscene duration
    default_value = 60, -- minutes, will be converted to ticks
    order = "ts-c",
    hidden = true,
}

---@type data.ModBoolSettingPrototype
local variable_zoom = {
    type = "bool-setting",
    name = "ts-variable-zoom",
    setting_type = "runtime-per-user",
    default_value = true,
    order = "ts-e",
    hidden = true,
    forced_value = false, -- temporary until zoom issue is fixed
}

---@type data.ModDoubleSettingPrototype
local afk_auto_start = {
    type = "double-setting",
    name = "ts-afk-auto-start",
    setting_type = "runtime-per-user",
    minimum_value = 0,
    default_value = 5, -- minutes, will be converted to ticks
    order = "ts-f"
}

---@type data.ModBoolSettingPrototype
local auto_start_while_gui_is_open = {
    type = "bool-setting",
    name = "ts-autostart-while-gui-is-open",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "ts-g"
}

---@type data.ModBoolSettingPrototype
local auto_start_while_viewing_map = {
    type = "bool-setting",
    name = "ts-autostart-while-viewing-map",
    setting_type = "runtime-per-user",
    default_value = true,
    order = "ts-h"
}

---@type data.ModBoolSettingPrototype
local menu_ends_trainsaver = {
    type = "bool-setting",
    name = "ts-menu-hotkey",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "ts-i",
    hidden = true,
}

---@type data.ModBoolSettingPrototype
local linked_game_control_ends_trainsaver = {
    type = "bool-setting",
    name = "ts-linked-game-control-hotkey",
    setting_type = "runtime-per-user",
    default_value = true,
    order = "ts-j"
}

---@type data.ModBoolSettingPrototype
local notable_event_alerts = {
    type = "bool-setting",
    name = "ts-notable-events",
    setting_type = "runtime-per-user",
    default_value = true,
    order = "ts-k"
}

---@type data.ModBoolSettingPrototype
local hidden_secrets = {
    type = "bool-setting",
    name = "ts-secrets",
    setting_type = "runtime-per-user",
    default_value = true,
    order = "ts-z"
}

data:extend({
    transition_speed,
    transition_time,
    time_wait,
    zoom,
    variable_zoom,
    wait_at_signal,
    station_minimum,
    driving_minimum,
    afk_auto_start,
    menu_ends_trainsaver,
    auto_start_while_viewing_map,
    auto_start_while_gui_is_open,
    linked_game_control_ends_trainsaver,
    notable_event_alerts,
    hidden_secrets,
})
