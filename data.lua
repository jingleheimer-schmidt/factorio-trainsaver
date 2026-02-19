
local toggle_trainsaver_key = {
    type = "custom-input",
    name = "toggle-trainsaver",
    key_sequence = "COMMAND + T",
    alternative_key_sequence = "CONTROL + T",
    enabled_while_in_cutscene = true,
    action = "lua",
    order = "[1][A]",
}

local start_trainsaver_key = {
    type = "custom-input",
    name = "start-trainsaver",
    key_sequence = "",
    alternative_key_sequence = "",
    enabled_while_in_cutscene = true,
    action = "lua",
    order = "[2][A]",
}

local end_trainsaver_key = {
    type = "custom-input",
    name = "end-trainsaver",
    key_sequence = "",
    alternative_key_sequence = "",
    enabled_while_in_cutscene = true,
    action = "lua",
    order = "[1][B]",
}

local open_inventory_trainsaver_key = {
    type = "custom-input",
    name = "open-inventory-trainsaver",
    key_sequence = "",
    linked_game_control = "open-character-gui",
    enabled_while_in_cutscene = true,
    action = "lua",
}

local open_technology_gui_trainsaver_key = {
    type = "custom-input",
    name = "open-research-trainsaver",
    key_sequence = "",
    linked_game_control = "open-technology-gui",
    enabled_while_in_cutscene = true,
    action = "lua",
}

local open_production_stats_gui_trainsaver_key = {
    type = "custom-input",
    name = "open-production-stats-trainsaver",
    key_sequence = "",
    linked_game_control = "production-statistics",
    enabled_while_in_cutscene = true,
    action = "lua",
}

local open_logistic_network_gui_trainsaver_key = {
    type = "custom-input",
    name = "open-logistic-netowrk-trainsaver",
    key_sequence = "",
    linked_game_control = "logistic-networks",
    enabled_while_in_cutscene = true,
    action = "lua",
}

local toggle_menu_trainsaver_key = {
    type = "custom-input",
    name = "toggle-menu-trainsaver",
    key_sequence = "",
    linked_game_control = "toggle-menu",
    enabled_while_in_cutscene = true,
    action = "lua",
}

local open_train_gui_trainsaver_key = {
    type = "custom-input",
    name = "open-train-gui-trainsaver",
    key_sequence = "",
    linked_game_control = "open-trains-gui",
    enabled_while_in_cutscene = true,
    action = "lua",
}

local toggle_driving_trainsaver_key = {
    type = "custom-input",
    name = "toggle-driving-trainsaver",
    key_sequence = "",
    linked_game_control = "toggle-driving",
    enabled_while_in_cutscene = true,
    action = "lua",
}

local move_up_trainsaver_key = {
    type = "custom-input",
    name = "move-up-trainsaver",
    key_sequence = "",
    linked_game_control = "move-up",
    enabled_while_in_cutscene = true,
    action = "lua",
}

local move_down_trainsaver_key = {
    type = "custom-input",
    name = "move-down-trainsaver",
    key_sequence = "",
    linked_game_control = "move-down",
    enabled_while_in_cutscene = true,
    action = "lua",
}

local move_right_trainsaver_key = {
    type = "custom-input",
    name = "move-right-trainsaver",
    key_sequence = "",
    linked_game_control = "move-right",
    enabled_while_in_cutscene = true,
    action = "lua",
}

local move_left_trainsaver_key = {
    type = "custom-input",
    name = "move-left-trainsaver",
    key_sequence = "",
    linked_game_control = "move-left",
    enabled_while_in_cutscene = true,
    action = "lua",
}

local toggle_map_trainsaver_key = {
    type = "custom-input",
    name = "toggle-map-trainsaver",
    key_sequence = "",
    linked_game_control = "toggle-map",
    enabled_while_in_cutscene = true,
    action = "lua",
}

local shoot_enemy_trainsaver_key = {
    type = "custom-input",
    name = "shoot-enemy-trainsaver",
    key_sequence = "",
    linked_game_control = "shoot-enemy",
    enabled_while_in_cutscene = true,
    action = "lua",
}

local next_target_trainsaver_key = {
    type = "custom-input",
    name = "next-target-trainsaver",
    key_sequence = "RIGHT",
    linked_game_control = "",
    enabled_while_in_cutscene = true,
    action = "lua",
    order = "[3][A]",
}

local previous_target_trainsaver_key = {
    type = "custom-input",
    name = "previous-target-trainsaver",
    key_sequence = "LEFT",
    linked_game_control = "",
    enabled_while_in_cutscene = true,
    action = "lua",
    order = "[3][B]",
}

local self_reflection_achievement = {
    type = "achievement",
    name = "trainsaver-self-reflection",
    order = "t[secret]-a[1][self-reflection]",
    icon = "__base__/graphics/achievement/lazy-bastard.png",
    icon_size = 128,
    hidden = false,
}

local find_a_friend_achievement = {
    type = "achievement",
    name = "trainsaver-find-a-friend",
    order = "t[secret]-a[2][find-a-friend]",
    icon = "__trainsaver__/graphics/achievement/find-a-friend.png",
    icon_size = 128,
    hidden = false,
}

local continuous_ten_minutes_achievement = {
    type = "achievement",
    name = "trainsaver-continuous-10-minutes",
    order = "t[secret]-b[1][continuous-10-minutes]",
    icon = "__base__/graphics/achievement/getting-on-track.png",
    icon_size = 128,
    hidden = false,
}

local continuous_thirty_minutes_achievement = {
    type = "achievement",
    name = "trainsaver-continuous-30-minutes",
    order = "t[secret]-b[2][continuous-30-minutes]",
    icon = "__base__/graphics/achievement/getting-on-track.png",
    icon_size = 128,
    hidden = false,
}

local continuous_one_hour_achievement = {
    type = "achievement",
    name = "trainsaver-continuous-60-minutes",
    order = "t[secret]-b[3][continuous-60-minutes]",
    icon = "__base__/graphics/achievement/getting-on-track-like-a-pro.png",
    icon_size = 128,
    hidden = false,
}

local total_one_hours_achievement = {
    type = "achievement",
    name = "trainsaver-1-hours-total",
    order = "t[secret]-c[1][1-hours-total]",
    icon = "__base__/graphics/achievement/getting-on-track.png",
    icon_size = 128,
    hidden = false,
}

local total_two_hours_achievement = {
    type = "achievement",
    name = "trainsaver-2-hours-total",
    order = "t[secret]-c[2][2-hours-total]",
    icon = "__base__/graphics/achievement/getting-on-track.png",
    icon_size = 128,
    hidden = false,
}

local total_five_hours_achievement = {
    type = "achievement",
    name = "trainsaver-5-hours-total",
    order = "t[secret]-c[3][5-hours-total]",
    icon = "__base__/graphics/achievement/getting-on-track-like-a-pro.png",
    icon_size = 128,
    hidden = false,
}

local rocket_launched_achievement = {
    type = "achievement",
    name = "trainsaver-a-spectacular-view",
    order = "t[secret]-d[1][a-spectacular-view]",
    icon = "__base__/graphics/achievement/smoke-me-a-kipper-i-will-be-back-for-breakfast.png",
    icon_size = 128,
    hidden = true,
}

local character_damaged_achievement = {
    type = "achievement",
    name = "trainsaver-character-damaged",
    order = "t[secret]-d[2][character-damaged]",
    icon = "__base__/graphics/achievement/watch-your-step.png",
    icon_size = 128,
    hidden = true,
}

local damaged_by_followed_train_achievement = {
    type = "achievement",
    name = "trainsaver-damaged-by-followed-train",
    order = "t[secret]-d[3][damaged-by-followed-train]",
    icon = "__base__/graphics/achievement/watch-your-step.png",
    icon_size = 128,
    hidden = true,
}

local the_long_haul_achievement = {
    type = "achievement",
    name = "trainsaver-long-haul",
    order = "t[secret]-a[3][long-haul]",
    icon = "__base__/graphics/achievement/trans-factorio-express.png",
    icon_size = 128,
    hidden = false,
}

local toggled_command_achievement = {
    type = "achievement",
    name = "trainsaver-toggled-command",
    order = "t[secret]-a[4][toggled-command]",
    icon = "__base__/graphics/achievement/trans-factorio-express.png",
    icon_size = 128,
    hidden = false,
}

local toggled_hotkey_achievement = {
    type = "achievement",
    name = "trainsaver-toggled-hotkey",
    order = "t[secret]-a[5][toggled-hotkey]",
    icon = "__base__/graphics/achievement/trans-factorio-express.png",
    icon_size = 128,
    hidden = false,
}

local afk_auto_start_achievement = {
    type = "achievement",
    name = "trainsaver-afk-auto-start",
    order = "t[secret]-a[6][afk-auto-start]",
    icon = "__base__/graphics/achievement/trans-factorio-express.png",
    icon_size = 128,
    hidden = false,
}

data:extend({
    toggle_trainsaver_key,
    start_trainsaver_key,
    end_trainsaver_key,
    open_inventory_trainsaver_key,
    open_technology_gui_trainsaver_key,
    open_production_stats_gui_trainsaver_key,
    open_logistic_network_gui_trainsaver_key,
    toggle_menu_trainsaver_key,
    open_train_gui_trainsaver_key,
    toggle_driving_trainsaver_key,
    move_up_trainsaver_key,
    move_down_trainsaver_key,
    move_right_trainsaver_key,
    move_left_trainsaver_key,
    toggle_map_trainsaver_key,
    shoot_enemy_trainsaver_key,
    next_target_trainsaver_key,
    previous_target_trainsaver_key,
    -- self_reflection_achievement,
    find_a_friend_achievement,
    continuous_ten_minutes_achievement,
    continuous_thirty_minutes_achievement,
    continuous_one_hour_achievement,
    total_one_hours_achievement,
    total_two_hours_achievement,
    total_five_hours_achievement,
    rocket_launched_achievement,
    character_damaged_achievement,
    damaged_by_followed_train_achievement,
    the_long_haul_achievement,
    toggled_command_achievement,
    toggled_hotkey_achievement,
    afk_auto_start_achievement,
})
