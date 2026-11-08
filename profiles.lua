-- Shell Profile / 环境变量 / 启动菜单
-- 来自 Tabby: PowerShell -NoLogo, cwd D:\Data\Desktop, WT_SESSION=0

return function(config)
  config.default_prog = { "powershell.exe", "-NoLogo" }
  config.default_cwd = "D:/Home"

  config.set_environment_variables = {
    WT_SESSION = "0",
  }

  config.exit_behavior = "Close"
  config.scrollback_lines = 8000
  config.adjust_window_size_when_changing_font_size = false

  config.launch_menu = {
    { label = "Windows PowerShell", args = { "powershell.exe", "-NoLogo" } },
    { label = "Git Bash", args = { "D:/Envs/Git/bin/bash.exe", "-i", "-l" } },
    { label = "Command Prompt", args = { "cmd.exe" } },
  }
end
