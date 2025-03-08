# batbar.wezterm

A tab bar configuration for wezterm, this configuration is based on [bar.wezterm](https://github.com/adriankarlen/bar.wezterm) and [battery.wez](https://github.com/rootiest/battery.wez). Basically incorporating the battery module into the original bar.wezterm, and modify it so I can load this module locally.

## Screenshot

> I am using Tokyo Night theme from wezterm!

![image](./screenshot.png)

## Installation

This is a wezterm plugin, and I have modified the configuration so you can use it by downloading it locally without git. Use this plugin by putting it under `$HOME/.config/wezterm/plugins/batbar.wezterm`

```lua
local bar = dofile(wezterm.config_dir .. "\\plugins\\bar.wezterm\\plugin\\init.lua")
bar.apply_to_config(config, {
	separator = {
		space = 1,
		left_icon = "",
		right_icon = "",
		field_icon = wezterm.nerdfonts.indent_line,
	},
	modules = {
		pane = { enabled = false },
		cwd = { enabled = false },
	},
})
```

> [!NOTE]
> I have specifically modified this plugin to be able to load locally without git. You can just add your own code to this and it would probably still load without issues.

## Configuration

For configuring stuff in the bar, you can take a look at the original repo that I am modifying this from: [bar.wezterm](https://github.com/adriankarlen/bar.wezterm)

And for the battery module, you can take a look at this module: [battery.wez](https://github.com/rootiest/battery.wez)
