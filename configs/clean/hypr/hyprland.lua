---@module 'hl'
-- What runs what

local mod = "SUPER"

local scripts = os.getenv("HOME") .. "/.config/scripts/"

local terminal     = "kitty"
local webBrowser   = "helium"
local fileManager  = "nautilus"
local notesApp     = "obsidian"
local discord      = "vesktop"
local musicPlayer  = "spotify"
local gameLauncher = "heroic"
local steamLauncher = "steam"
local passwords    = "keepassxc"

local appLauncher      = "qs ipc call launcher toggle"
local powerMenu        = "qs ipc call powerMenu toggle"
local wallpaperManager = "qs ipc call wallpaperPicker toggle"
local statusBar        = "systemctl --user restart quickshell.service"


local primaryOutput

local cursorTheme = "Adwaita"
local cursorSize  = 24
local cursorTime  = 2

-- Look

hl.config({
  general = {
    layout           = "dwindle",
    border_size      = 0,
    gaps_in          = 6,
    gaps_out         = 12,
    resize_on_border = true,
    allow_tearing    = false,
  },

  decoration = {
    rounding         = 10,
    rounding_power   = 2.0,
    active_opacity   = 1.0,
    inactive_opacity = 1.0,

    blur = {
      enabled        = true,
      size           = 6,
      passes         = 2,
      noise          = 0.008,
      contrast       = 1.0,
      brightness     = 1.0,
      vibrancy       = 0.2,
      ignore_opacity = true,
    },

    shadow = { enabled = false },
  },

  dwindle = { preserve_split = true },
  master  = { new_status = "master" },

  cursor = {
    inactive_timeout    = cursorTime,
    no_hardware_cursors = true,
  },

  input = {
    accel_profile = "flat",
    sensitivity   = -0.3,
  },

  misc     = { disable_hyprland_logo = true },
  xwayland = { force_zero_scaling = true },

  animations = { enabled = true },
})

-- Animations

hl.curve("easeOutQuint",   { type = "bezier", points = { { 0.23, 1    }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear",         { type = "bezier", points = { { 0,    0    }, { 1,    1 } } })
hl.curve("almostLinear",   { type = "bezier", points = { { 0.5,  0.5  }, { 0.75, 1 } } })
hl.curve("quick",          { type = "bezier", points = { { 0.15, 0    }, { 0.1,  1 } } })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default"      })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick"        })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 7,    bezier = "quick"        })

-- Monitors

local function readToml(path)
  local f = io.open(path, "r"); if not f then return nil end
  local root, tbl = {}, nil
  for raw in f:lines() do
    local line = raw:gsub("#.*", ""):match("^%s*(.-)%s*$")
    local section = line:match("^%[(.+)%]$")
    if section then
      tbl = root
      for part in section:gmatch("[^%.]+") do
        tbl[part] = tbl[part] or {}
        tbl = tbl[part]
      end
    elseif tbl then
      local k, v = line:match("^([%w_-]+)%s*=%s*(.+)$")
      if k then
        if v:sub(1, 1) == '"' then v = v:sub(2, -2)
        elseif v == "true" then v = true
        elseif v == "false" then v = false
        else v = tonumber(v) or v end
        tbl[k] = v
      end
    end
  end
  f:close()
  return root
end

local function connected(port)
  for _, card in ipairs({ "card0", "card1", "card2" }) do
    local f = io.open("/sys/class/drm/" .. card .. "-" .. port .. "/status", "r")
    if f then
      local st = f:read("l"); f:close()
      if st == "connected" then return true end
    end
  end
  return false
end

local tomlPath = os.getenv("HOME") .. "/.config/monitor.toml"

os.execute(os.getenv("HOME") .. "/.config/scripts/monitor.sh sync 2>/dev/null")  -- position is derived

local monitors = readToml(tomlPath)

if monitors then
  -- The built-in panel is whatever the undocked profile names.
  local builtIn
  for _, m in pairs(monitors.undocked or {}) do builtIn = m.port end

  -- Docked when any output the docked profile names is actually plugged in.
  local profile = monitors.undocked
  for _, m in pairs(monitors.docked or {}) do
    if m.port ~= builtIn and connected(m.port) then
      profile = monitors.docked
      break
    end
  end

  local ordered = {}
  for _, m in pairs(profile or {}) do ordered[#ordered + 1] = m end
  table.sort(ordered, function(a, b) return a.index < b.index end)

  for _, m in ipairs(ordered) do
    hl.monitor({
      output    = m.port,
      mode      = m.resolution .. "@" .. m["refresh-rate"],
      position  = m.position,                    -- derived by monitor.sh sync
      scale     = 1,
      transform = m.orientation,
    })
    if m.primary then primaryOutput = m.port end
  end

  -- Five per output, by index: 0 gets 1-5, 1 gets 6-10, and so on.
  for _, m in ipairs(ordered) do
    for n = 1, 5 do
      hl.workspace_rule({ workspace = m.index * 5 + n, monitor = m.port })
    end
  end
end

-- Environment

hl.env("XCURSOR_THEME",    cursorTheme)
hl.env("XCURSOR_SIZE",     cursorSize)
hl.env("HYPRCURSOR_THEME", cursorTheme)
hl.env("HYPRCURSOR_SIZE",  cursorSize)

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE",    "wayland")

hl.env("GDK_SCALE",       1)
hl.env("GDK_BACKEND",     "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("ADW_DEBUG_COLOR_SCHEME", "prefer-dark")

hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("__GL_GSYNC_ALLOWED", 1)
hl.env("__GL_VRR_ALLOWED",   0)
hl.env("NVD_BACKEND",        "direct")

-- Binds: launching things

hl.bind(mod .. " + Return",         hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + Space",          hl.dsp.exec_cmd(appLauncher))
hl.bind(mod .. " + Escape",         hl.dsp.exec_cmd(powerMenu))
hl.bind(mod .. " + F",              hl.dsp.exec_cmd(fileManager))
hl.bind(mod .. " + B",              hl.dsp.exec_cmd(webBrowser))
hl.bind(mod .. " + N",              hl.dsp.exec_cmd(notesApp))
hl.bind(mod .. " + D",              hl.dsp.exec_cmd(discord))
hl.bind(mod .. " + M",              hl.dsp.exec_cmd(musicPlayer))
hl.bind(mod .. " + G",              hl.dsp.exec_cmd(gameLauncher))
hl.bind(mod .. " + SHIFT + G",      hl.dsp.exec_cmd(steamLauncher))
hl.bind(mod .. " + P",              hl.dsp.exec_cmd(passwords))
hl.bind(mod .. " + W",              hl.dsp.exec_cmd(wallpaperManager))

-- Binds: windows

for key, dir in pairs({ H = "l", L = "r", K = "u", J = "d" }) do
  hl.bind(mod .. " + " .. key,           hl.dsp.focus({ direction = dir }))
  hl.bind(mod .. " + SHIFT + " .. key,   hl.dsp.window.move({ direction = dir }))
end

hl.bind(mod .. " + CTRL + H", hl.dsp.window.resize({ x = -40, y =   0, relative = true }), { repeating = true })
hl.bind(mod .. " + CTRL + L", hl.dsp.window.resize({ x =  40, y =   0, relative = true }), { repeating = true })
hl.bind(mod .. " + CTRL + K", hl.dsp.window.resize({ x =   0, y = -40, relative = true }), { repeating = true })
hl.bind(mod .. " + CTRL + J", hl.dsp.window.resize({ x =   0, y =  40, relative = true }), { repeating = true })

hl.bind(mod .. " + Backspace", hl.dsp.window.close())
hl.bind(mod .. " + T",         hl.dsp.window.float({ action = "toggle" }))

hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Binds: workspaces

for ws = 1, 10 do
  local key = tostring(ws % 10)   -- workspace 10 is on the 0 key
  hl.bind(mod .. " + " .. key,         hl.dsp.focus({ workspace = ws }))
  hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = ws }))
end

-- Binds: hardware keys

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true, locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume      @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true, locked = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { repeating = true, locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { repeating = true, locked = true })

hl.bind(mod .. " + equal", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"))
hl.bind(mod .. " + minus", hl.dsp.exec_cmd("wpctl set-volume      @DEFAULT_AUDIO_SINK@ 5%-"))

hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -q s 10%+"), { repeating = true, locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -q s 10%-"), { repeating = true, locked = true })

-- Binds: screenshots

hl.bind(mod .. " + S",         hl.dsp.exec_cmd(scripts .. "screenshot.sh select"))
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd(scripts .. "screenshot.sh screen"))
hl.bind(mod .. " + CTRL + S",  hl.dsp.exec_cmd(scripts .. "screenshot.sh all"))

-- Binds: display plumbing

hl.bind(mod .. " + backslash", hl.dsp.exec_cmd(scripts .. "monitor.sh flip"))

-- Window rules

hl.window_rule({
  name  = "pip",
  match = { title = "^(Picture-in-Picture)$" },
  float = true,
  pin   = true,
  move  = { "73%", "72%" },
  size  = { 426, 240 },
})

-- LibreOffice asks for fullscreen via xdg-activation; ignore it.
hl.window_rule({
  name           = "libreoffice-suppress-fs",
  match          = { class = "^(libreoffice-.*)$" },
  suppress_event = "fullscreen maximize",
})

-- Layer rules

-- ignore_alpha: blur only the painted inset, not the full-width surface.
hl.layer_rule({
  match        = { namespace = "^quickshell:(bar|popup|launcher|notifications|osd)$" },
  blur         = true,
  ignore_alpha = 0.08,
  xray         = 0,
})

hl.layer_rule({
  match = { namespace = "^quickshell:wallpaper$" },
  blur  = false,
})

-- Autostart

hl.on("hyprland.start", function()
  hl.exec_cmd(statusBar)
  hl.exec_cmd("awww-daemon")
  hl.exec_cmd("sleep 2; " .. scripts .. "wallpaper.sh restore")
  if primaryOutput then
    hl.exec_cmd("xrandr --output " .. primaryOutput .. " --primary")
  end
end)
