local wez = require "wezterm"

---@class bar.wezterm
local M = {}
local options = {}

-- local separator = package.config:sub(1, 1) == "\\" and "\\" or "/"
-- local plugin_dir = wez.plugin.list()[1].plugin_dir:gsub(separator .. "[^" .. separator .. "]*$", "")

-- ---checks if the plugin directory exists
-- ---@param path string
-- ---@return boolean
-- local function directory_exists(path)
--   local success, result = pcall(wez.read_dir, plugin_dir .. path)
--   return success and result
-- end

-- ---returns the name of the package, used when requiring modules
-- ---@return string
-- local function get_require_path()
--   local path = "httpssCssZssZsgithubsDscomsZsadriankarlensZsbarsDswezterm"
--   local path_trailing_slash = "httpssCssZssZsgithubsDscomsZsadriankarlensZsbarsDsweztermsZs"
--   return directory_exists(path_trailing_slash) and path_trailing_slash or path
-- end

-- package.path = package.path
-- .. ";"
-- .. plugin_dir
-- .. separator
-- .. get_require_path()
-- .. separator
-- .. "plugin"
-- .. separator
-- .. "?.lua"

local home = os.getenv "HOME"
if not home then
  error "HOME env var not found!!"
end
local plugin_dir = home .. "\\.config\\wezterm\\plugins"
local plugins = wez.read_dir(plugin_dir)
if not plugins then
  error("Failed to list plugin directory in " .. plugin_dir)
end

local function basename(path)
  return path:match "([^\\]+)$"
end

for _, plugin_path in ipairs(plugins) do
  local name = basename(plugin_path)
  -- print("Plugin name:", name)
  package.path = package.path .. ";" .. plugin_dir .. "\\" .. name .. "\\plugin\\?.lua"
end

local utilities = require "bar.utilities"
local config = require "bar.config"
local tabs = require "bar.tabs"
local user = require "bar.user"
-- local spotify = require "bar.spotify"
local paths = require "bar.paths"
local battery = require "bar.battery"

---conforming to https://github.com/wez/wezterm/commit/e4ae8a844d8feaa43e1de34c5cc8b4f07ce525dd
---@param c table: wezterm config object
---@param opts bar.options
M.apply_to_config = function(c, opts)
  -- make the opts arg optional
  if not opts then
    opts = {}
  end

  -- combine user config with defaults
  options = config.extend_options(config.options, opts)

  local scheme = wez.color.get_builtin_schemes()[c.color_scheme]
  if scheme == nil then
    scheme = wez.color.get_default_colors()
  end

  local default_colors = {
    tab_bar = {
      background = "transparent",
      active_tab = {
        bg_color = "transparent",
        fg_color = scheme.ansi[options.modules.tabs.active_tab_fg],
      },
      inactive_tab = {
        bg_color = "transparent",
        fg_color = scheme.ansi[options.modules.tabs.inactive_tab_fg],
      },
    },
  }

  c.colors = utilities._merge(default_colors, scheme)

  -- make the plugin own these settings
  c.tab_bar_at_bottom = options.position == "bottom"
  c.use_fancy_tab_bar = false
  c.tab_max_width = options.max_width
end

wez.on("format-tab-title", function(tab, _, _, conf, _, _)
  local palette = conf.resolved_palette

  local index = tab.tab_index + 1
  local offset = #tostring(index)
    + 1 -- for extra space
    + #options.separator.left_icon
    + (2 * options.separator.space)
    + 1

  local tab_title = tabs.get_title(tab)
  local ext = ".exe"
  if tab_title:sub(-#ext) == ext then
    tab_title = tab_title:sub(1, -#ext - 1)
  end
  local title = " " .. tostring(index) .. utilities._space(options.separator.left_icon, 0, 1) .. tab_title

  local width = conf.tab_max_width - offset
  if #title > conf.tab_max_width then
    title = wez.truncate_right(title, width) .. "…"
  end

  local fg = palette.tab_bar.inactive_tab.fg_color
  local bg = palette.tab_bar.inactive_tab.bg_color
  if tab.is_active then
    fg = palette.tab_bar.active_tab.fg_color
    bg = palette.tab_bar.active_tab.bg_color
  end

  return {
    { Background = { Color = bg } },
    { Foreground = { Color = fg } },
    { Attribute = { Intensity = "Bold" } },
    { Text = utilities._space(title, 0, 1) },
  }
end)

wez.on("update-status", function(window, pane)
  local present, conf = pcall(window.effective_config, window)
  if not present then
    return
  end

  local palette = conf.resolved_palette

  -- left status
  local left_cells = {
    { Background = { Color = palette.tab_bar.background } },
  }

  table.insert(left_cells, { Text = string.rep(" ", options.padding.left) })

  if options.modules.workspace.enabled then
    local stat = options.modules.workspace.icon .. utilities._space(window:active_workspace(), options.separator.space)
    -- local stat_fg = palette.ansi[options.modules.workspace.color]
    local stat_fg = palette.ansi[options.modules.pane.color]

    if options.modules.leader.enabled and window:leader_is_active() then
      stat_fg = palette.ansi[options.modules.leader.color]
      stat = utilities._constant_width(stat, options.modules.leader.icon)
    end

    table.insert(left_cells, { Foreground = { Color = stat_fg } })
    table.insert(left_cells, { Text = stat })
  end

  if options.modules.pane.enabled then
    local process = pane:get_foreground_process_name()
    if not process then
      goto set_left_status
    end
    table.insert(left_cells, { Foreground = { Color = palette.ansi[options.modules.pane.color] } })
    table.insert(
      left_cells,
      { Text = options.modules.pane.icon .. utilities._space(utilities._basename(process), options.separator.space) }
    )
  end

  ::set_left_status::
  window:set_left_status(wez.format(left_cells))

  -- right status
  local right_cells = {
    { Background = { Color = palette.tab_bar.background } },
  }

  local callbacks = {
    --     {
    --       name = "spotify",
    --       func = function()
    --         return spotify.get_currently_playing(options.modules.spotify.max_width, options.modules.spotify.throttle)
    --       end,
    --     },
    {
      name = "username",
      func = function()
        return user.username
      end,
    },
    {
      name = "hostname",
      func = function()
        return wez.hostname()
      end,
    },
    {
      name = "clock",
      func = function()
        return wez.time.now():format "%H:%M"
      end,
    },
    {
      name = "battery",
      func = function()
        return battery.get_battery_stats()
      end,
    },
    {
      name = "cwd",
      func = function()
        return paths.get_cwd(pane, true)
      end,
    },
  }

  for _, callback in ipairs(callbacks) do
    local name = callback.name
    local func = callback.func
    if not options.modules[name].enabled then
      goto continue
    end
    local text = func()
    if #text > 0 then
      table.insert(right_cells, { Foreground = { Color = palette.ansi[options.modules[name].color] } })
      table.insert(right_cells, { Text = text })
      table.insert(right_cells, { Foreground = { Color = palette.brights[1] } })
      --       table.insert(right_cells, {
      --         Text = utilities._space(options.separator.right_icon, options.separator.space, nil)
      --           .. options.modules[name].icon,
      --       })
      -- table.insert(right_cells, { Text = utilities._space(options.separator.field_icon, options.separator.space, nil) })
      table.insert(right_cells, { Text = utilities._space(options.separator.field_icon, 0, 1) })
    end
    ::continue::
  end
  -- remove trailing separator
  table.remove(right_cells, #right_cells)
  table.insert(right_cells, { Text = string.rep(" ", options.padding.right) })

  window:set_right_status(wez.format(right_cells))
end)

return M
