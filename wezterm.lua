-- WezTerm 模块化配置入口
-- 由 Tabby (config.yaml) 迁移而来
-- 旧配置备份: ~/.wezterm.lua.bak / ~/.wezterm.lua.disabled

local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- 模块加载（按依赖顺序）
require("colors")(config)
require("fonts")(config)
require("background")(config)
require("appearance")(config)
require("tabs")(config)
require("profiles")(config)
require("keys")(config)

return config
