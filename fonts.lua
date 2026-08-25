-- 字体配置
-- 来自 Tabby: 主字体 Cascadia Code, 回退 JetBrainsMono NF

local wezterm = require("wezterm")

return function(config)
  config.font = wezterm.font_with_fallback({
    "Cascadia Code",
    "JetBrainsMono NF",
  })
end
