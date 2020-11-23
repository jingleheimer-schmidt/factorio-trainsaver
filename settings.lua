
local transitionTimeSetting = {
  type = "double-setting",
  name = "ts-transition-time",
  setting_type = "runtime-per-user",
  minimum_value = 0,
--   maximum_value = 1800,
  default_value = 1, -- seconds, will be converted to ticks
  order = "ts-1"
}

local timeWaitSetting = {
  type = "double-setting",
  name = "ts-time-wait",
  setting_type = "runtime-per-user",
  minimum_value = 1/60,
  default_value = 10, -- minutes, will be converted to ticks
  order = "ts-2"
}

local zoomSetting = {
  type = "double-setting",
  name = "ts-zoom",
  setting_type = "runtime-per-user",
  minimum_value = .1,
  default_value = .26,
  maximum_value = 5,
  order = "ts-3"
}

local variableZoomSetting = {
  type = "bool-setting",
  name = "ts-variable-zoom",
  setting_type = "runtime-per-user",
  default_value = true,
  order = "ts-4"
}

data:extend({
  transitionTimeSetting,
  timeWaitSetting,
  zoomSetting,
  variableZoomSetting,
})
