
---@type data.ModDoubleSettingPrototype
local transitionSpeedSetting = {
    type = "double-setting",
    name = "ts-transition-speed",
    setting_type = "runtime-per-user",
    minimum_value = 0,
    default_value = 0, -- km/h, will be converted to time (ticks)
    order = "ts-a-a"
}

---@type data.ModDoubleSettingPrototype
local transitionTimeSetting = {
    type = "double-setting",
    name = "ts-transition-time",
    setting_type = "runtime-per-user",
    minimum_value = 0,
    --   maximum_value = 1800,
    default_value = 0, -- km/h, will be converted to time (ticks)
    order = "ts-a-b",
    hidden = true,
}

---@type data.ModIntSettingPrototype
local waitAtSignalSetting = {
    type = "int-setting",
    name = "ts-wait-at-signal",
    setting_type = "runtime-per-user",
    default_value = 30, -- seconds, will be converted to ticks
    minimum_value = 0,
    order = "ts-b-1"
}

---@type data.ModIntSettingPrototype
local stationMinimumlSetting = {
    type = "int-setting",
    name = "ts-station-minimum",
    setting_type = "runtime-per-user",
    default_value = 5, -- seconds, will be converted to ticks
    minimum_value = 0,
    order = "ts-b-2"
}

---@type data.ModIntSettingPrototype
local drivingMinimumlSetting = {
    type = "int-setting",
    name = "ts-driving-minimum",
    setting_type = "runtime-per-user",
    default_value = 10, -- minutes, will be converted to ticks
    minimum_value = 0,
    order = "ts-b-3"
}

---@type data.ModDoubleSettingPrototype
local timeWaitSetting = {
    type = "double-setting",
    name = "ts-time-wait",
    setting_type = "runtime-per-user",
    minimum_value = 1, -- need to have at least 1 minute of "inactivity", because it's not actually inactivity, it's how long the cutscene lasts before returning to player.
    default_value = 60, -- minutes, will be converted to ticks
    order = "ts-c",
    hidden = true,
}

---@type data.ModDoubleSettingPrototype
local afkAutoStartSetting = {
    type = "double-setting",
    name = "ts-afk-auto-start",
    setting_type = "runtime-per-user",
    minimum_value = 0,
    default_value = 5, -- minutes, will be converted to ticks
    order = "ts-d"
}

---@type data.ModDoubleSettingPrototype
local zoomSetting = {
    type = "double-setting",
    name = "ts-zoom",
    setting_type = "runtime-per-user",
    minimum_value = .1,
    default_value = .375,
    maximum_value = 5,
    order = "ts-e"
}

---@type data.ModBoolSettingPrototype
local variableZoomSetting = {
    type = "bool-setting",
    name = "ts-variable-zoom",
    setting_type = "runtime-per-user",
    default_value = true,
    order = "ts-f",
    hidden = true,
    forced_value = false, -- temporary until zoom issue is fixed
}

---@type data.ModBoolSettingPrototype
local autoStartWhileGuiIsOpenSetting = {
    type = "bool-setting",
    name = "ts-autostart-while-gui-is-open",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "ts-g"
}

---@type data.ModBoolSettingPrototype
local autoStartWhileViewingMapSetting = {
    type = "bool-setting",
    name = "ts-autostart-while-viewing-map",
    setting_type = "runtime-per-user",
    default_value = true,
    order = "ts-h"
}

---@type data.ModBoolSettingPrototype
local menuEndsTrainsaverSetting = {
    type = "bool-setting",
    name = "ts-menu-hotkey",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "ts-i",
    hidden = true,
}

---@type data.ModBoolSettingPrototype
local linkedGameControlEndsTrainsaverSetting = {
    type = "bool-setting",
    name = "ts-linked-game-control-hotkey",
    setting_type = "runtime-per-user",
    default_value = true,
    order = "ts-j"
}

---@type data.ModBoolSettingPrototype
local notableEventAlerts = {
    type = "bool-setting",
    name = "ts-notable-events",
    setting_type = "runtime-per-user",
    default_value = true,
    order = "ts-k"
}

---@type data.ModBoolSettingPrototype
local hiddenSecretsSetting = {
    type = "bool-setting",
    name = "ts-secrets",
    setting_type = "runtime-per-user",
    default_value = true,
    order = "ts-z"
}

data:extend({
    transitionSpeedSetting,
    transitionTimeSetting,
    timeWaitSetting,
    zoomSetting,
    variableZoomSetting,
    waitAtSignalSetting,
    stationMinimumlSetting,
    drivingMinimumlSetting,
    afkAutoStartSetting,
    menuEndsTrainsaverSetting,
    autoStartWhileViewingMapSetting,
    autoStartWhileGuiIsOpenSetting,
    linkedGameControlEndsTrainsaverSetting,
    notableEventAlerts,
    hiddenSecretsSetting,
})
