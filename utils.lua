-- 公共工具函数
local wezterm = require("wezterm")
local M = {}

--- 获取系统当前深浅色外观
--- @return string "Dark" | "Light"
M.get_appearance = function()
  if wezterm.gui then
    return wezterm.gui.get_appearance()
  end
  return "Dark"
end

return M
