-- 配色方案
-- 深色: IR_Black (自定义 16 色 + 光标 + 选区)
-- 浅色: Rose Pine Dawn
-- 自动跟随系统深浅色切换 (对应 Tabby colorSchemeMode: auto)

local wezterm = require("wezterm")
local utils = require("utils")

return function(config)
  config.color_schemes = {
    ["IR_Black"] = {
      foreground = "#f1f1f1",
      background = "#000000",
      cursor_bg = "#808080",
      cursor_fg = "#000000",
      -- 选区: 暗色半透明底 + 灰色文字 (不反色)
      selection_bg = "rgba(255, 255, 255, 0.15)",
      selection_fg = "#9e9e9e",
      ansi = {
        "#4f4f4f", "#fa6c60", "#a8ff60", "#fffeb7",
        "#96cafe", "#fa73fd", "#c6c5fe", "#efedef",
      },
      brights = {
        "#7b7b7b", "#fcb6b0", "#cfffab", "#ffffcc",
        "#b5dcff", "#fb9cfe", "#e0e0fe", "#ffffff",
      },
    },
    ["Rose Pine Dawn"] = {
      foreground = "#575279",
      background = "#faf4ed",
      cursor_bg = "#9893a5",
      cursor_fg = "#faf4ed",
      -- 选区: 半透明底 + 灰色文字
      selection_bg = "rgba(87, 82, 121, 0.20)",
      selection_fg = "#6e6a86",
      ansi = {
        "#f2e9de", "#b4637a", "#286983", "#ea9d34",
        "#56949f", "#907aa9", "#d7827e", "#575279",
      },
      brights = {
        "#6e6a86", "#b4637a", "#286983", "#ea9d34",
        "#56949f", "#907aa9", "#d7827e", "#575279",
      },
    },
  }

  local appearance = utils.get_appearance()
  config.color_scheme = appearance:find("Dark") and "IR_Black" or "Rose Pine Dawn"
end
