--[[
* Floos - Theme palettes and config menu styling
* Colors adapted from XIUI config.lua (https://github.com/tirem/XIUI), GPLv3.
]]--

require('common');
local imgui = require('imgui');

local M = {};

-- OceanBlue gold shared by OceanBlue and GreenGold.
local OCEAN_GOLD = { 1.0, 0.886, 0.278, 1.0 };         -- #FFE247
local OCEAN_GOLD_DARK = { 1.0, 0.843, 0.0, 1.0 };      -- #FFD700
local OCEAN_GOLD_DARKER = { 0.85, 0.65, 0.05, 1.0 };
local OCEAN_BORDER_GOLD = { 1.0, 0.886, 0.278, 0.95 };

--- Itmejammy's light blue, in place of the gold. Named for Itmejammy, who
--- has done more for this community's addons than anyone, and who asked for
--- exactly this: "like a light blue trim, instead of gold".
---
--- The base is a shade cooler than DarkGold's neutral black so the blue sits
--- on it rather than floating above it, and every trim value is a tint of
--- one hue - #8FD8FF - so highlights, borders and dim text read as one
--- family rather than three blues that happen to be nearby.
local JAM_BLUE        = { 0.561, 0.847, 1.000, 1.0 };   -- #8FD8FF
local JAM_BLUE_DARK   = { 0.373, 0.714, 0.902, 1.0 };   -- #5FB6E6
local JAM_BLUE_DARKER = { 0.227, 0.510, 0.678, 1.0 };   -- #3A82AD

--- Azurite, for Beasty - head developer of HorizonXI.
---
--- He was asked for his colour and gave it precisely: "probably Azurite
--- Blue. Think like the blue you see in Greece, or a perfectly blue ocean
--- that isnt too deep." So that is what this is, and the description is
--- doing real work - azurite the mineral is a darker, more inky blue than
--- what he described. The Aegean reading is brighter and cleaner, so the
--- trim follows the sentence rather than the rock.
---
--- THE HARD PART WAS NOT THE BLUE, IT WAS THE OTHER BLUE
--- ----------------------------------------------------
--- Itmejammy's tribute is already a blue theme, and two blue tributes that
--- look like each other is a worse gift than one. Every azure that reads as
--- "perfect ocean" lands within a few degrees of Itmejammy's hue, so hue
--- alone cannot separate them. Two things do:
---
---   SATURATION.  Itmejammy's is pale and washed out - S100 but up at L78,
---                which reads as ice or glass. This sits at L59, where the
---                colour is at its richest. Light blue against deep blue.
---   THE BASE.    Itmejammy's base is near-neutral black and only the trim
---                is blue. Here the base is water too - a deep sea navy at
---                50% saturation - so the whole panel is blue and the trim
---                is the shallow part of it. Side by side one reads as
---                frost on black, the other as looking down into water.
---
--- The base sits a little deeper in hue than the trim (215 against 205),
--- which is the same direction real water moves as it gets deeper, and is
--- why the panel reads as one body of colour instead of a blue box with a
--- blue edge stuck on it.
---
--- Every text-bearing colour clears WCAG AA against all four panel
--- backgrounds; the worst is 4.74:1 against a 4.5 requirement.
local AZURITE        = { 0.227, 0.647, 0.949, 1.0 };  -- #3AA5F2
local AZURITE_DARK   = { 0.180, 0.565, 0.878, 1.0 };  -- #2E90E0
local AZURITE_DARKER = { 0.090, 0.376, 0.561, 1.0 };  -- #17608F

M.palettes = {
    -- In honour of Beasty.
    Beasty = {
        gold = AZURITE,
        gold_dark = AZURITE_DARK,
        gold_darker = AZURITE_DARKER,
        bg_dark = { 0.020, 0.051, 0.094, 0.95 },   -- #050D18 deep water
        bg_medium = { 0.039, 0.082, 0.149, 1.0 },  -- #0A1526
        bg_light = { 0.055, 0.110, 0.188, 1.0 },   -- #0E1C30
        bg_lighter = { 0.071, 0.129, 0.227, 1.0 }, -- #12213A
        text_light = { 0.894, 0.929, 0.969, 1.0 }, -- #E4EDF7 cool off-white
        text_muted = { 0.561, 0.651, 0.761, 1.0 }, -- #8FA6C2
        border_dark = { 0.118, 0.208, 0.353, 1.0 },-- #1E355A
        border_gold = { 0.227, 0.647, 0.949, 0.90 },
        panel_bg_hex = '#050D18',
        panel_border_hex = '#3AA5F2',
        default_bg_opacity = 0.92,
        -- Takes the whole panel, same as Itmejammy. A tribute theme that
        -- only recolours half the window is not a tribute.
        force_accent = true,
        -- On an all-blue panel the semantic colours have to work harder,
        -- because anything blue-adjacent is now indistinguishable from the
        -- trim. So they go the other way round the wheel: warn and bad are
        -- warm, which is the strongest possible contrast against azure, and
        -- good is pulled to a true green (hue 144) rather than the sea-green
        -- Itmejammy can afford - a mint that close to cyan would read as
        -- "the trim again" here.
        state = {
            good    = { 0.373, 0.851, 0.561, 1.0 },  -- #5FD98F
            warn    = { 1.000, 0.761, 0.302, 1.0 },  -- #FFC24D
            bad     = { 1.000, 0.420, 0.369, 1.0 },  -- #FF6B5E
            info    = { 0.227, 0.647, 0.949, 1.0 },  -- the trim itself
            neutral = { 0.894, 0.929, 0.969, 1.0 },
        },
        -- A shade under the trim so a filled bar keeps an edge against its
        -- own border, exactly as Itmejammy's does.
        bar_fill = { 0.118, 0.478, 0.769, 1.0 },   -- #1E7AC4
        -- The picture this theme brings with it. Picking the theme loads it
        -- too, so a tribute is one click rather than a theme plus a trip
        -- through the Background Picture combo. Nothing happens if the file
        -- is not in assets/portraits - see the note by THEME_PORTRAIT.
        portrait = 'Beasty.jpg',
        portrait_alpha = 0.14,
        portrait_width = 0.671,   -- the file is 687 x 1024
    },
    -- In honour of Itmejammy.
    Itmejammy = {
        gold = JAM_BLUE,
        gold_dark = JAM_BLUE_DARK,
        gold_darker = JAM_BLUE_DARKER,
        bg_dark = { 0.039, 0.051, 0.067, 0.95 },   -- #0A0D11
        bg_medium = { 0.067, 0.090, 0.125, 1.0 },  -- #111720
        bg_light = { 0.094, 0.125, 0.169, 1.0 },   -- #18202B
        bg_lighter = { 0.129, 0.173, 0.227, 1.0 }, -- #212C3A
        text_light = { 0.871, 0.906, 0.949, 1.0 }, -- #DEE7F2
        text_muted = { 0.533, 0.584, 0.651, 1.0 }, -- #8895A6
        border_dark = { 0.169, 0.227, 0.290, 1.0 },-- #2B3A4A
        border_gold = { 0.561, 0.847, 1.000, 0.90 },
        panel_bg_hex = '#0A0D11',
        panel_border_hex = '#8FD8FF',
        default_bg_opacity = 0.92,
        -- One colour, everywhere. The per-activity accents (amber mining,
        -- crimson hunting and the rest) are what kept the panel gold no
        -- matter which palette was picked, so this palette overrides them
        -- and the Accent Color Per Activity toggle along with them.
        force_accent = true,
        -- Semantic colours still have to MEAN something, so they are not
        -- flattened to the trim - they are re-tuned cool so they sit in the
        -- same world as it. Warn keeps a hint of warmth because a caution
        -- that looks like every other blue is not a caution.
        state = {
            good    = { 0.42, 0.86, 0.71, 1.0 },   -- #6BDBB5 aqua-green
            warn    = { 0.98, 0.78, 0.44, 1.0 },   -- #FAC770 soft amber
            bad     = { 0.98, 0.51, 0.55, 1.0 },   -- #FA828C soft rose
            info    = { 0.561, 0.847, 1.000, 1.0 },-- the trim itself
            neutral = { 0.871, 0.906, 0.949, 1.0 },
        },
        -- Deeper than the trim on purpose: a bar filled in the same blue as
        -- its own border has no edge.
        bar_fill = { 0.310, 0.659, 0.863, 1.0 },   -- #4FA8DC
    },
    OceanBlue = {
        gold = OCEAN_GOLD,
        gold_dark = OCEAN_GOLD_DARK,
        gold_darker = OCEAN_GOLD_DARKER,
        bg_dark = { 0.035, 0.12, 0.38, 0.95 },     -- royal blue config bg
        bg_medium = { 0.06, 0.18, 0.48, 1.0 },
        bg_light = { 0.10, 0.26, 0.58, 1.0 },
        bg_lighter = { 0.15, 0.34, 0.70, 1.0 },
        text_light = { 0.92, 0.95, 1.0, 1.0 },
        text_muted = { 0.70, 0.78, 0.92, 1.0 },
        border_dark = { 0.20, 0.35, 0.70, 1.0 },
        border_gold = OCEAN_BORDER_GOLD,
        panel_bg_hex = '#163A9C',
        panel_border_hex = '#FFE247',
        default_bg_opacity = 0.30,
        bar_fill = { 0.25, 0.55, 0.95, 1.0 },
    },
    Plain = {
        -- Black panels / config; white text and separators.
        gold = { 1.0, 1.0, 1.0, 1.0 },
        gold_dark = { 0.85, 0.85, 0.85, 1.0 },
        gold_darker = { 0.65, 0.65, 0.65, 1.0 },
        bg_dark = { 0.0, 0.0, 0.0, 0.95 },
        bg_medium = { 0.08, 0.08, 0.08, 1.0 },
        bg_light = { 0.14, 0.14, 0.14, 1.0 },
        bg_lighter = { 0.22, 0.22, 0.22, 1.0 },
        text_light = { 1.0, 1.0, 1.0, 1.0 },
        text_muted = { 0.70, 0.70, 0.70, 1.0 },
        border_dark = { 1.0, 1.0, 1.0, 0.85 },
        border_gold = { 1.0, 1.0, 1.0, 0.90 },
        panel_bg_hex = '#000000',
        panel_border_hex = '#FFFFFF',
        default_bg_opacity = 0.50,
        bar_fill = { 0.85, 0.85, 0.85, 1.0 },
    },
    DarkGold = {
        gold = { 0.957, 0.855, 0.592, 1.0 },       -- #F4DA97
        gold_dark = { 0.765, 0.684, 0.474, 1.0 },  -- #C3AE79
        gold_darker = { 0.573, 0.512, 0.355, 1.0 }, -- #92835B
        bg_dark = { 0.051, 0.051, 0.051, 0.95 },   -- #0D0D0D
        bg_medium = { 0.098, 0.090, 0.075, 1.0 },  -- #191713
        bg_light = { 0.137, 0.125, 0.106, 1.0 },   -- #23201B
        bg_lighter = { 0.176, 0.161, 0.137, 1.0 }, -- #2D2923
        text_light = { 0.878, 0.855, 0.812, 1.0 }, -- #E0DACF
        text_muted = { 0.6, 0.58, 0.54, 1.0 },
        border_dark = { 0.3, 0.275, 0.235, 1.0 },  -- #4D463C
        border_gold = { 0.957, 0.855, 0.592, 0.85 },
        panel_bg_hex = '#0D0D0D',
        panel_border_hex = '#F4DA97',
        default_bg_opacity = 0.92,
        bar_fill = { 0.22, 0.60, 0.81, 1.0 },
    },
    GreenGold = {
        gold = OCEAN_GOLD,
        gold_dark = OCEAN_GOLD_DARK,
        gold_darker = OCEAN_GOLD_DARKER,
        bg_dark = { 0.02, 0.10, 0.05, 0.95 },      -- deep forest
        bg_medium = { 0.04, 0.16, 0.08, 1.0 },
        bg_light = { 0.07, 0.24, 0.12, 1.0 },
        bg_lighter = { 0.10, 0.32, 0.16, 1.0 },
        text_light = { 0.90, 0.96, 0.90, 1.0 },
        text_muted = { 0.60, 0.75, 0.62, 1.0 },
        border_dark = { 0.15, 0.40, 0.22, 1.0 },
        border_gold = OCEAN_BORDER_GOLD,
        panel_bg_hex = '#0A2E14',
        panel_border_hex = '#FFE247',
        default_bg_opacity = 0.55,
        bar_fill = { 0.25, 0.70, 0.40, 1.0 },
    },
    --[[
        Masuru. Green, but the airy kind: deep forest-black grounds under a
        cool mint trim, the way glass looks with light coming through it
        rather than paint. GreenGold is green with gold on it; this one is
        green all the way through.

        The trim is the palest mint that still reads as green rather than
        white on the darkest band, and it clears WCAG AA everywhere with room
        to spare (8.7:1 on the lightest panel band). The grounds are four
        steps of the same hue so the panel separates in a dark room without
        any band drifting toward teal or olive.
    --]]
    Masuru = {
        gold = { 0.345, 0.878, 0.659, 1.0 },        -- #58E0A8 aero mint
        gold_dark = { 0.243, 0.749, 0.541, 1.0 },   -- #3EBF8A
        gold_darker = { 0.165, 0.541, 0.384, 1.0 }, -- #2A8A62
        bg_dark = { 0.016, 0.067, 0.047, 0.95 },    -- #04110C
        bg_medium = { 0.031, 0.102, 0.075, 1.0 },   -- #081A13
        bg_light = { 0.047, 0.141, 0.098, 1.0 },    -- #0C2419
        bg_lighter = { 0.067, 0.184, 0.129, 1.0 },  -- #112F21
        text_light = { 0.867, 0.949, 0.910, 1.0 },  -- #DDF2E8 mint-tinted white
        text_muted = { 0.561, 0.710, 0.643, 1.0 },  -- #8FB5A4
        border_dark = { 0.118, 0.290, 0.212, 1.0 }, -- #1E4A36
        border_gold = { 0.345, 0.878, 0.659, 0.90 },
        panel_bg_hex = '#04110C',
        panel_border_hex = '#58E0A8',
        default_bg_opacity = 0.92,
        -- The whole panel, same rule as Itmejammy, Beasty and Amethyst: one
        -- trim colour, not eight activity colours over the top of it.
        force_accent = true,
        -- On an all-green panel "good" cannot be green - it would be the
        -- trim again. So good goes to a clear sky blue, which is the aero
        -- half of the name, and warn and bad stay warm, which is the
        -- strongest contrast there is against mint. Info is the trim.
        state = {
            good    = { 0.384, 0.800, 1.000, 1.0 },  -- #62CCFF sky
            warn    = { 1.000, 0.761, 0.302, 1.0 },  -- #FFC24D
            bad     = { 1.000, 0.420, 0.369, 1.0 },  -- #FF6B5E
            info    = { 0.345, 0.878, 0.659, 1.0 },  -- the trim itself
            neutral = { 0.867, 0.949, 0.910, 1.0 },
        },
        -- Deeper than the trim so a filled bar keeps an edge against its
        -- own border.
        bar_fill = { 0.184, 0.659, 0.467, 1.0 },    -- #2FA877
    },
};

-- Per-activity accent. The whole panel (tab underline, hero number, bars,
-- separators) recolors from this so each HELM tab has its own identity.
M.ACTIVITY_ACCENT = {
    mining   = { 1.00, 0.78, 0.30, 1.0 }, -- amber
    logging  = { 0.55, 0.86, 0.46, 1.0 }, -- green
    harvest  = { 0.38, 0.85, 0.78, 1.0 }, -- teal
    excavate = { 1.00, 0.58, 0.34, 1.0 }, -- orange
    hunting  = { 0.96, 0.46, 0.46, 1.0 }, -- crimson
    fishing  = { 0.42, 0.68, 0.96, 1.0 }, -- deep water blue
    digging  = { 0.88, 0.72, 0.44, 1.0 }, -- sand
    clamming = { 0.52, 0.86, 0.90, 1.0 }, -- shallow sea
};

-- Semantic colors for state, shared by every activity.
M.STATE = {
    good    = { 0.46, 0.86, 0.52, 1.0 },
    warn    = { 1.00, 0.74, 0.30, 1.0 },
    bad     = { 0.96, 0.44, 0.44, 1.0 },
    info    = { 0.56, 0.76, 0.98, 1.0 },
    neutral = { 0.86, 0.88, 0.92, 1.0 },
};

--- Accent for an activity tab. Plain stays monochrome by design, and the
--- Appearance toggle can force the palette gold everywhere.
function M.accent_for(act, enabled)
    if M.active_name == 'Plain' then
        return M.colors.text_gold;
    end
    -- A palette can claim the whole panel. Itmejammy does, which is the
    -- point of it: one trim colour, not eight activity colours over the top.
    if M.active ~= nil and M.active.force_accent then
        return M.colors.text_gold;
    end
    if enabled == false then
        return M.colors.text_gold;
    end
    return M.ACTIVITY_ACCENT[act] or M.colors.text_gold;
end

--- Semantic color, dimmed to the palette text color on Plain.
function M.state_color(name)
    if M.active_name == 'Plain' then
        if name == 'bad' then
            return { 0.75, 0.75, 0.75, 1.0 };
        end
        return M.colors.text_light;
    end
    if M.active ~= nil and M.active.state ~= nil and M.active.state[name] ~= nil then
        return M.active.state[name];
    end
    return M.STATE[name] or M.colors.text_light;
end

-- Display order / labels for the Appearance radio list.
M.THEME_OPTIONS = T{
    { id = 'DarkGold',  label = 'DarkGold (Default)' },
    { id = 'Itmejammy', label = 'Itmejammy' },
    { id = 'Beasty',    label = 'Beasty' },
    { id = 'OceanBlue', label = 'OceanBlue' },
    { id = 'Plain',     label = 'Plain' },
    { id = 'GreenGold', label = 'GreenGold' },
    { id = 'Masuru',    label = 'Masuru' },
};

--- Palettes that have been renamed, old id -> new id.
---
--- A settings file holds the id, not the label, so renaming a palette
--- orphans anyone already using it: set_active falls through to DarkGold and
--- their theme silently reverts. This is walked when settings load.
---
--- 'FirstLight' was the amber first cut of Beasty's theme, built before he
--- had been asked what colour he actually wanted. He answered Azurite Blue,
--- so the palette was rebuilt around that and renamed to him.
M.THEME_RENAMES = {
    FirstLight = 'Beasty',
    -- Misspelt in the first 3.8.0 build; the theme is named for Masuru.
    Masaru = 'Masuru',
};

---@param id string|nil
---@return string|nil  the current id for a possibly-renamed theme
function M.canonical_theme(id)
    if id == nil then return nil; end
    return M.THEME_RENAMES[id] or id;
end

--- What a theme wants sitting behind the panel, if anything.
---
--- Returns the file name plus the fade and width it should be shown at, so
--- picking the theme sets up the whole picture rather than dropping the
--- caller into the Appearance sliders. Returns nil for every theme that does
--- not carry one, which is all of them but this one.
---
--- The file itself is NOT shipped. Character art is derived from Square
--- Enix's designs and is not ours to redistribute, same rule as the fonts
--- and the sounds - so on a fresh public install this names a file that is
--- not there, the picture layer finds no texture, and the theme is simply a
--- theme. That is the intended fallback, not a failure.
---@param theme_name string|nil
---@return string|nil name, number|nil alpha, number|nil width
function M.portrait_for(theme_name)
    local p = M.palettes[M.canonical_theme(theme_name) or ''];
    if p == nil or p.portrait == nil or p.portrait == '' then return nil; end
    return p.portrait, p.portrait_alpha or 0.14, p.portrait_width or 0.671;
end

local function apply_palette(p)
    M.active = p;
    M.gold = p.gold;
    M.gold_dark = p.gold_dark;
    M.gold_darker = p.gold_darker;
    M.bg_dark = p.bg_dark;
    M.bg_medium = p.bg_medium;
    M.bg_light = p.bg_light;
    M.bg_lighter = p.bg_lighter;
    M.text_light = p.text_light;
    M.text_muted = p.text_muted;
    M.border_dark = p.border_dark;
    M.border_gold = p.border_gold;
    M.panel_bg_hex = p.panel_bg_hex;
    M.panel_border_hex = p.panel_border_hex;
    M.default_bg_opacity = p.default_bg_opacity;

    M.colors = {
        bg_dark       = p.bg_dark,
        bg_mid        = p.bg_medium,
        bg_light      = p.bg_light,
        border        = p.border_gold,
        border_gold   = p.border_gold,
        text          = p.text_light,
        text_light    = p.text_light,
        text_dim      = p.text_muted,
        text_gold     = p.gold,
        accent        = p.gold,
        bar_fill      = p.bar_fill,
    };
end

apply_palette(M.palettes.DarkGold);
M.active_name = 'DarkGold';
M.active_label = 'DarkGold';

--- Switch active palette used by overlays and the config window.
function M.set_active(theme_name)
    theme_name = M.canonical_theme(theme_name);
    local palette = M.palettes[theme_name];
    if palette == nil then
        palette = M.palettes.DarkGold;
        theme_name = 'DarkGold';
    end
    if M.active_name == theme_name then
        return;
    end
    apply_palette(palette);
    M.active_name = theme_name;
    -- The friendly label, for anything that has to name the theme in a
    -- sentence. The parenthetical is stripped: "DarkGold" reads better than
    -- "DarkGold (Default)" in the middle of a line of prose.
    M.active_label = theme_name;
    for _, o in ipairs(M.THEME_OPTIONS) do
        if o.id == theme_name then
            M.active_label = (tostring(o.label):gsub('%s*%b()%s*$', ''));
            break;
        end
    end
end

function M.get_palette(theme_name)
    return M.palettes[M.canonical_theme(theme_name) or ''] or M.palettes.DarkGold;
end

function M.hex_to_imgui(hex)
    local clean = hex:gsub('#', '');
    return {
        tonumber(clean:sub(1, 2), 16) / 255,
        tonumber(clean:sub(3, 4), 16) / 255,
        tonumber(clean:sub(5, 6), 16) / 255,
        1.0,
    };
end

-- Prefer first non-nil enum (Ashita 4.3 / ImGui 1.90.9+ renamed several colors).
local function style_col(...)
    for i = 1, select('#', ...) do
        local v = select(i, ...);
        if v ~= nil then
            return v;
        end
    end
    return nil;
end

local function push_style_color(idx, color)
    if idx == nil or color == nil then
        return 0;
    end
    local ok = pcall(function()
        imgui.PushStyleColor(idx, color);
    end);
    if ok then
        return 1;
    end
    -- Some bindings want ImVec4(r,g,b,a) instead of a table.
    if ImVec4 ~= nil and type(color) == 'table' then
        ok = pcall(function()
            imgui.PushStyleColor(idx, ImVec4(color[1] or 0, color[2] or 0, color[3] or 0, color[4] or 1));
        end);
        if ok then
            return 1;
        end
    end
    return 0;
end

local function push_style_var(idx, value)
    if idx == nil then
        return 0;
    end
    local ok = pcall(function()
        imgui.PushStyleVar(idx, value);
    end);
    if ok then
        return 1;
    end
    if type(value) == 'table' and ImVec2 ~= nil then
        ok = pcall(function()
            imgui.PushStyleVar(idx, ImVec2(value[1] or 0, value[2] or 0));
        end);
        if ok then
            return 1;
        end
    end
    return 0;
end

--- Push ImGui colors/vars for the config editor; pair with pop_style.
function M.apply_style()
    local style = imgui.GetStyle();
    if style ~= nil then
        pcall(function()
            style.WindowBorderSize = 1;
            style.ChildBorderSize = 1;
            style.FrameBorderSize = 1;
            style.TabBorderSize = 1;
        end);
    end

    local g = M.gold;
    local tab_active = { g[1], g[2], g[3], 0.3 };
    local plain = M.active_name == 'Plain';
    local text_disabled = plain and M.text_muted or M.gold_dark;

    local colors = 0;
    colors = colors + push_style_color(ImGuiCol_WindowBg, M.bg_dark);
    colors = colors + push_style_color(ImGuiCol_ChildBg, { 0, 0, 0, 0 });
    colors = colors + push_style_color(ImGuiCol_TitleBg, M.bg_medium);
    colors = colors + push_style_color(ImGuiCol_TitleBgActive, M.bg_light);
    colors = colors + push_style_color(ImGuiCol_TitleBgCollapsed, M.bg_dark);
    colors = colors + push_style_color(ImGuiCol_FrameBg, M.bg_medium);
    colors = colors + push_style_color(ImGuiCol_FrameBgHovered, M.bg_light);
    colors = colors + push_style_color(ImGuiCol_FrameBgActive, M.bg_lighter);
    colors = colors + push_style_color(ImGuiCol_Header, M.bg_light);
    colors = colors + push_style_color(ImGuiCol_HeaderHovered, M.bg_lighter);
    colors = colors + push_style_color(ImGuiCol_HeaderActive, tab_active);
    colors = colors + push_style_color(ImGuiCol_Border, M.border_gold);
    colors = colors + push_style_color(ImGuiCol_Text, M.text_light);
    colors = colors + push_style_color(ImGuiCol_TextDisabled, text_disabled);
    colors = colors + push_style_color(ImGuiCol_Button, M.bg_medium);
    colors = colors + push_style_color(ImGuiCol_ButtonHovered, M.bg_light);
    colors = colors + push_style_color(ImGuiCol_ButtonActive, M.bg_lighter);
    colors = colors + push_style_color(ImGuiCol_CheckMark, M.gold);
    colors = colors + push_style_color(ImGuiCol_SliderGrab, M.gold_dark);
    colors = colors + push_style_color(ImGuiCol_SliderGrabActive, M.gold);
    colors = colors + push_style_color(ImGuiCol_ScrollbarBg, M.bg_medium);
    colors = colors + push_style_color(ImGuiCol_ScrollbarGrab, M.bg_lighter);
    colors = colors + push_style_color(ImGuiCol_ScrollbarGrabHovered, M.border_dark);
    colors = colors + push_style_color(ImGuiCol_ScrollbarGrabActive, M.gold_dark);
    colors = colors + push_style_color(ImGuiCol_Separator, M.border_dark);
    colors = colors + push_style_color(ImGuiCol_PopupBg, M.bg_medium);
    colors = colors + push_style_color(ImGuiCol_Tab, M.bg_medium);
    colors = colors + push_style_color(ImGuiCol_TabHovered, M.bg_light);
    -- Renamed in ImGui 1.90.9 (Ashita 4.3): TabActive / TabUnfocused*.
    colors = colors + push_style_color(style_col(ImGuiCol_TabSelected, ImGuiCol_TabActive), tab_active);
    colors = colors + push_style_color(style_col(ImGuiCol_TabDimmed, ImGuiCol_TabUnfocused), M.bg_dark);
    colors = colors + push_style_color(style_col(ImGuiCol_TabDimmedSelected, ImGuiCol_TabUnfocusedActive), M.bg_medium);
    colors = colors + push_style_color(ImGuiCol_ResizeGrip, M.gold_darker);
    colors = colors + push_style_color(ImGuiCol_ResizeGripHovered, M.gold_dark);
    colors = colors + push_style_color(ImGuiCol_ResizeGripActive, M.gold);

    local vars = 0;
    vars = vars + push_style_var(ImGuiStyleVar_WindowPadding, { 12, 12 });
    vars = vars + push_style_var(ImGuiStyleVar_FramePadding, { 6, 4 });
    vars = vars + push_style_var(ImGuiStyleVar_ItemSpacing, { 8, 6 });
    vars = vars + push_style_var(ImGuiStyleVar_FrameRounding, 4.0);
    vars = vars + push_style_var(ImGuiStyleVar_WindowRounding, 6.0);
    vars = vars + push_style_var(ImGuiStyleVar_ChildRounding, 4.0);
    vars = vars + push_style_var(ImGuiStyleVar_PopupRounding, 4.0);
    vars = vars + push_style_var(ImGuiStyleVar_ScrollbarRounding, 4.0);
    vars = vars + push_style_var(ImGuiStyleVar_GrabRounding, 4.0);

    return { colors = colors, vars = vars };
end

function M.pop_style(counts)
    counts = counts or { colors = 0, vars = 0 };
    if (counts.vars or 0) > 0 then
        imgui.PopStyleVar(counts.vars);
    end
    if (counts.colors or 0) > 0 then
        imgui.PopStyleColor(counts.colors);
    end
end

return M;
