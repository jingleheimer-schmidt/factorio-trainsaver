
---@param player LuaPlayer
---@param visible boolean
local function toggle_gui(player, visible)
    local gui = player.gui
    if not (gui and gui.valid) then return end
    gui.center.visible = visible
    gui.left.visible = visible
    gui.top.visible = visible
    gui.goal.visible = visible
    gui.relative.visible = visible
    gui.screen.visible = visible
end

return {
    toggle_gui = toggle_gui
}
