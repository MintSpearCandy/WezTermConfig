-- 字体配置
-- 来自 Tabby: 主字体 Cascadia Code, 回退 JetBrainsMono NF

local wezterm = require("wezterm")

return function(config)
  config.font = wezterm.font_with_fallback({
    "Cascadia Code",
    "JetBrains Mono",    -- WezTerm 内置字体, 本机未装 Cascadia 时兑底
    "JetBrainsMono NF",
  })
end
