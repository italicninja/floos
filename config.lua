--[[
* Floos - Settings + config editor
* UI layout adapted from XIUI (GPLv3).
]]--

require('common');
local chat = require('chat');
local imgui = require('imgui');
local settings = require('settings');
local theme = require('libs.theme');
local portrait = require('libs.portrait');
local ui = require('libs.ui');
local fonts = require('libs.fonts');
local attribution = require('libs.attribution');

local M = {};

M.editor_open = T{ false };
M.pricing = T{};

M.default_settings = T{
    font_size = T{ 13 },
    reset_on_load = T{ false },
    panels_hidden = T{ false },
    layout_version = T{ 170 },
    lifetime = T{
        gil_gained = T{ 0 }, -- overall history; never cleared by session reset
        skill_w = T{ 0 },
        skill_m = T{ 0 },
        skill_b = T{ 0 },
        wins = T{ 0 },
        misses = T{ 0 },
        break_only = T{ 0 },
    },
    item_index = T{
        'chunk of iron ore:650',
        'chunk of copper ore:123',
        'chunk of zinc ore:166',
        'chunk of tin ore:123',
        'chunk of silver ore:0',
        'chunk of darksteel ore:6000',
        'chunk of gold ore:3000',
        'chunk of mythril ore:800',
        'chunk of platinum ore:5000',
        'pebble:123',
        'flint stone:123',
        'red rock:123',
        'white rock:123',
        'black rock:123',
        'blue rock:123',
        'green rock:123',
        'yellow rock:123',
        'purple rock:123',
        'translucent rock:123',
        'bundle of lumber:200',
        'arrowwood log:50',
        'maple log:80',
        'ash log:100',
        'walnut log:150',
        'elm log:200',
        'oak log:300',
        'rosewood log:500',
        'mahogany log:800',
        'fresh leaves:50',
        'saruta cotton:100',
        'flax flower:150',
        'moko grass:80',
        -- Clamming (Bibiki Bay). Rough Horizon values; edit to taste.
        'piece of oxblood:13250',
        'tropical clam:5100',
        'lacquer tree log:3578',
        'high-quality crab shell:3312',
        'petrified log:2193',
        'coral fragment:1735',
        'uragnite shell:1455',
        'turtle shell:1190',
        'bibiki urchin:750',
        'crab shell:392',
        'titanictus shell:357',
        'shall shell:307',
        'handful of high-quality pugil scales:253',
        'sack of white sand:250',
        'vongola clam:192',
        'hobgoblin pie:153',
        'loaf of hobgoblin bread:91',
        'nebimonite:53',
        'jacknife:38',
        'seashell:29',
        'handful of pugil scales:23',
        'handful of fish scales:23',
        'bibiki slug:7',
        'clump of pamtam kelp:7',
        'broken willow fishing rod:0',
        'suit of goblin armor:0',
        'suit of goblin mail:0',
        'goblin mask:0',
    },
    mining = T{
        pickaxe_cost = T{ 120 },
        pickaxe_subtract = T{ false },
        skillup_display = T{ true },
        mine_skill = T{ 0 },
        fatigue_cap = T{ 200 },
        session_active = T{ 0 },
        last_mine = T{ 0 },
    },
    logging = T{
        hatchet_cost = T{ 300 },
        hatchet_subtract = T{ false },
        skillup_display = T{ true },
        log_skill = T{ 0 },
        fatigue_cap = T{ 200 },
    },
    harvest = T{
        sickle_cost = T{ 400 },
        sickle_subtract = T{ false },
        skillup_display = T{ true },
        harvest_skill = T{ 0 },
        fatigue_cap = T{ 200 },
    },
    excavate = T{
        skillup_display = T{ true },
        exca_skill = T{ 0 },
        fatigue_cap = T{ 200 },
    },
    fishing = T{
        idle_grace = T{ 60 },      -- clock freezes this long after each action
        bait_cost = T{ 0 },        -- gil per bait; Horizon spends one per BITE
        bait_subtract = T{ false },
        skillup_display = T{ true },
        fish_skill = T{ 0 },
    },
    digging = T{
        idle_grace = T{ 10 },      -- clock freezes this long after each dig
        green_cost = T{ 0 },       -- gil per bunch of Gysahl Greens
        green_subtract = T{ false },
        skillup_display = T{ true },
        dig_skill = T{ 0 },        -- rank IS skill/10, so there is no rank setting
        ore_watch = T{ true },     -- show the elemental ore condition row
    },
    clamming = T{
        idle_grace = T{ 15 },      -- clamming points come back about every 10s
        kit_cost = T{ 500 },       -- a kit from Toh Zonikki; the first is free
        kit_subtract = T{ true },
        hq_body = T{ false },      -- HQ swimwear halves the 200pz incident rate
        dig_delay = T{ 10 },       -- per-point cooldown, measured from the find
        -- List what is actually in the bucket, not just its weight. Off by
        -- default because it grows the panel by a line per item type; on if
        -- you price your own haul and want to see it before turning in.
        show_bucket = T{ false },
        -- Unit price beside each bucket line. Only useful with the above.
        bucket_prices = T{ true },
    },
    --- Which activity tabs appear on the panel. Eight will not fit a 340px
    --- window; switching one off only hides the tab, it keeps tracking.
    tabs = T{
        mining = T{ true },
        logging = T{ true },
        harvest = T{ true },
        excavate = T{ true },
        hunting = T{ true },
        fishing = T{ true },
        digging = T{ true },
        clamming = T{ true },
    },
    fatigue = T{
        observations = T{},        -- epochs of resets we actually witnessed
        period_hours = T{ 24 },
        last_seen = T{ 0 },
        -- Count fatigue per zone (mining, logging, harvesting, excavation)
        -- instead of per session. On: the per-zone number is the one that
        -- matches what the server is actually doing.
        per_zone = T{ true },
        -- The per-zone counters themselves. Written by the tracker.
        zones = T{},
        -- The global counter: climbs in its home zone, and every hit in
        -- any other zone takes one off. On by default - it is the thing
        -- Tyflow asked Floos for, so it should be on the panel without a
        -- trip through the commands. /floos global off puts it away.
        global_on = T{ true },
        -- Whether /floos clear is allowed to wipe it. On by default: a
        -- counter that exists to be watched across zones is worthless if
        -- clearing a session takes it with it.
        global_protect = T{ true },
        global = T{},
    },
    journal = T{
        enabled = T{ true },
    },
    hunt = T{
        respawn_sec = T{ 345 }, -- 5 min 45 sec from death
        track_list = T{},       -- only these mob names get respawn timers
    },
    helm = T{},
    session = T{
        swings = T{ 0 },
        breaks = T{ 0 },
        items = T{ 0 },
        skill_gain = T{ 0 },
        rewards = T{},
    },
    tracker = T{
        visible = T{ true },
        -- Follow the activity you are doing: mine then dig and the panel
        -- moves to the Dig tab by itself.
        auto_switch_tab = T{ true },
        -- Un-hide the panel when an activity starts. Asked for by Babs, who
        -- keeps it hidden on purpose and does not want it appearing over the
        -- game every time they swing. On by default - that is how Floos has
        -- always behaved - but it is a choice now.
        auto_show = T{ true },
        x = T{ 120 },
        y = T{ 120 },
        width = T{ 340 },
        height = T{ 0 },
        display_timeout = T{ 600 },
        never_hide = T{ false },
        show_duration = T{ true },
        show_controls = T{ false },
        show_moon = T{ true },
        show_fatigue = T{ true },
        show_accuracy = T{ false },   -- Accuracy row under Zone fatigue
        show_zone_verdict = T{ true },
        verdict_metric = T{ 'Gil' },   -- Gil | Skill
        show_best_for = T{ true },
    },
    -- Sound alerts. Empty filenames mean that event stays silent, which is
    -- the default for all of them: the addon ships no audio, so anything set
    -- here would point at a file that is not there.
    sounds = T{
        enabled = T{ true },
        rank_up = T{ '' },
        skill_up = T{ '' },
        big_drop = T{ '' },
        big_drop_gil = T{ 3000 },
        fatigue_cap = T{ '' },
        clam_ready = T{ '' },
    },
    ui = T{
        background_theme = T{ 'DarkGold' },
        -- A faded picture behind the panel. Empty by default; drop a PNG in
        -- assets/portraits/ and pick it in Appearance. Nothing ships here -
        -- see that folder's README for why.
        bg_image = T{ '' },
        bg_image_alpha = T{ 0.12 },
        -- Image width as a multiple of panel height. The texture manager
        -- does not report image dimensions, so this cannot be worked out -
        -- it has to be told. 0.671 is the reference portrait's true ratio.
        bg_image_width = T{ 0.671 },
        -- Which theme put the current picture there, or '' if the player
        -- chose it themselves. See apply_theme_portrait.
        bg_image_owner = T{ '' },
        font_family = T{ 'Tahoma Bold (Default)' },
        accent_by_activity = T{ true },
        text_style = T{ 'Shadow' },
        show_bars = T{ true },
        -- The config window used to draw at ImGui's default size no matter
        -- what Font Size said, because it is rendered before the font push.
        -- It now follows Font Size like everything else, and this multiplies
        -- on top for people who want it bigger or smaller than the panels.
        config_scale = T{ 1.0 },
        show_strip = T{ true },
        show_sparkline = T{ true },
        -- Skill-up rate split by moon phase. Off by default: it needs
        -- hundreds of swings per bucket before it says anything.
        show_moon_rates = T{ false },
        -- The centred RANK UP! banner. Six times in a career to 60.
        rank_toast = T{ true },
        -- Step aside while the map or the main menu is open, come back after.
        hide_on_menu = T{ true },
        animations = T{ true },
        expert = T{ true },     -- labeled rules, 10m trend, meter graduations
        detail = T{ 'Full' },   -- Full | Compact | Mini
        compact = T{ false },   -- legacy mirror of detail == 'Compact'
        tracker = T{
            scale = T{ 1.0 },
            padding = T{ 8 },
            bg_scale = T{ 1.0 },
            border_scale = T{ 1.0 },
            background_opacity = T{ 0.72 },
            border_opacity = T{ 0.9 },
            border_thickness = T{ 0 },
            panel_rounding = T{ 8 },
            show_duration = T{ true },
            show_controls = T{ false },
        },
        background_gradient_start = T{ '#01122b' },
        background_gradient_end = T{ '#061c39' },
    },
};

M.settings = settings.load(M.default_settings);

--- Set by floos.lua. The settings library swaps the whole settings table when
--- you log out or in - every module holding a reference to the old table must
--- be rebound to the new one, or their writes land in a dead table and are
--- never saved. That was the "it has no memory" bug: play after a relog wrote
--- all session progress into the orphaned pre-login table.
M.on_settings_change = nil;

settings.register('settings', 'settings_update', function (s)
    if s ~= nil then
        M.settings = s;
    end
    M.ensure_ui_settings();
    if M.on_settings_change ~= nil then
        M.on_settings_change();
    end
    settings.save();
    M.update_pricing();
end);

local function split(inputstr, sep)
    sep = sep or '%s';
    local t = {};
    for str in string.gmatch(inputstr, '([^' .. sep .. ']+)') do
        table.insert(t, str);
    end
    return t;
end

local function fill_height(min_h)
    local avail = imgui.GetContentRegionAvail();
    local h = 0;
    if type(avail) == 'table' then
        h = tonumber(avail.y or avail[2]) or 0;
    else
        local _, ay = imgui.GetContentRegionAvail();
        h = tonumber(ay) or 0;
    end
    if h < min_h then
        return min_h;
    end
    return h;
end

--- Move the background picture along with the theme.
---
--- A tribute theme is a package - the colours AND the picture - so picking it
--- should be one click, not a theme followed by a hunt through the Background
--- Picture combo. The whole difficulty is doing that without ever throwing
--- away a picture the player chose for themselves.
---
--- So ownership is tracked. bg_image_owner holds the id of the theme that put
--- the current picture there, or '' when the player picked it. This function
--- only ever touches a picture it owns:
---
---   no picture at all      -> the new theme may set one
---   picture owned by the   -> replaced by the new theme's, or cleared
---     theme being left        if the new theme has none
---   picture owned by the   -> left completely alone, forever
---     player
---
--- Which means: pick Beasty and his portrait appears. Switch to Itmejammy and
--- it goes, because it came with the theme. But drop your own screenshot in
--- and choose it, and no theme switch will ever disturb it again.
---
--- CHOOSING "NONE" IS ALSO A CHOICE
--- --------------------------------
--- The subtle case, and the one worth getting right: somebody on Beasty who
--- sets the picture to None. That leaves no picture to own, so a naive
--- version reads it as "nothing set yet" and puts the portrait straight back
--- on the next load - which is the addon overruling the player, every single
--- session. So a refusal is recorded as 'none:<theme>' and honoured for that
--- theme. Deliberately switching to a different theme offers its package
--- again, because that is a fresh decision; reloading does not.
---
--- The file is only set if it actually exists in assets/portraits. Character
--- art is not redistributable so it is not shipped, and a theme naming a file
--- nobody has must be a no-op rather than a broken-looking setting.
---@param prev_id string|nil  theme being left, nil on first load
---@param new_id  string|nil  theme being taken up
function M.apply_theme_portrait(prev_id, new_id)
    local uiset = M.settings ~= nil and M.settings.ui or nil;
    if uiset == nil or uiset.bg_image == nil then return; end
    if uiset.bg_image_owner == nil then uiset.bg_image_owner = T{ '' }; end

    local cur   = tostring(uiset.bg_image[1] or '');
    local owner = tostring(uiset.bg_image_owner[1] or '');

    -- The player's own picture outranks every theme. Bail before anything
    -- else so there is no path through here that can lose it.
    if cur ~= '' and owner == '' then return; end
    -- Owned by some other theme than the one being left: also not ours.
    if cur ~= '' and prev_id ~= nil and owner ~= tostring(prev_id) then return; end
    -- A recorded refusal, still on the theme it was made for: honour it.
    local refused = owner:match('^none:(.*)$');
    if cur == '' and refused ~= nil then
        if refused == tostring(new_id or '') then return; end
        -- Refused under a different theme. Picking a new one is a fresh
        -- decision, so the old refusal is spent and its package may be
        -- offered again. Without this the refusal is permanent and "choose
        -- Beasty, get the package" quietly stops working forever for anyone
        -- who ever pressed None.
        owner = '';
        uiset.bg_image_owner[1] = '';
    end

    local name, alpha, width = theme.portrait_for(new_id);
    if name ~= nil then
        local present = false;
        for _, f in ipairs(portrait.list()) do
            if tostring(f):lower() == tostring(name):lower() then
                name = f;          -- take the file's real casing
                present = true;
                break;
            end
        end
        if present then
            uiset.bg_image[1] = name;
            uiset.bg_image_owner[1] = tostring(new_id);
            if uiset.bg_image_alpha ~= nil and alpha ~= nil then
                uiset.bg_image_alpha[1] = alpha;
            end
            if uiset.bg_image_width ~= nil and width ~= nil then
                uiset.bg_image_width[1] = width;
            end
            return;
        end
    end

    -- New theme carries no picture, or its file is not installed. Clear the
    -- outgoing theme's picture so it does not linger under the wrong colours.
    if cur ~= '' and owner ~= '' then
        uiset.bg_image[1] = '';
        uiset.bg_image_owner[1] = '';
    end
end

function M.ensure_ui_settings()
    -- Ashita's settings.load does not merge, so a file written by an older
    -- Floos simply lacks these keys. The guards in tracker.lua already treat
    -- a missing key as "on", so behaviour is unchanged either way - this is
    -- what makes them appear in the config window.
    if M.settings.ui ~= nil then
        if M.settings.ui.bg_image == nil then M.settings.ui.bg_image = T{ '' }; end
        if M.settings.ui.bg_image_alpha == nil then
            M.settings.ui.bg_image_alpha = T{ 0.12 };
        end
        if M.settings.ui.bg_image_width == nil then
            M.settings.ui.bg_image_width = T{ 0.671 };
        end
        if M.settings.ui.bg_image_owner == nil then
            M.settings.ui.bg_image_owner = T{ '' };
        end
    end
    if M.settings.tracker ~= nil then
        if M.settings.tracker.auto_switch_tab == nil then
            M.settings.tracker.auto_switch_tab = T{ true };
        end
        if M.settings.tracker.auto_show == nil then
            M.settings.tracker.auto_show = T{ true };
        end
    end
    if M.settings.font_size == nil then
        M.settings.font_size = T{ 13 };
    end
    local size = tonumber(M.settings.font_size[1]) or 13;
    if size < 6 then size = 6; end
    if size > 30 then size = 30; end
    M.settings.font_size[1] = math.floor(size + 0.5);

    if M.settings.panels_hidden == nil then
        M.settings.panels_hidden = T{ false };
    end
    if M.settings.ui == nil then
        M.settings.ui = M.default_settings.ui:copy();
    end
    if M.settings.ui.font_family == nil then
        M.settings.ui.font_family = T{ 'Tahoma Bold (Default)' };
    end
    if M.settings.ui.background_theme == nil
        or M.settings.ui.background_theme[1] == 'Transparent'
        or M.settings.ui.background_theme[1] == 'Window1'
        or M.settings.ui.background_theme[1] == '' then
        M.settings.ui.background_theme = T{ 'DarkGold' };
    end
    -- A palette that has been renamed would otherwise silently revert to
    -- DarkGold, because the settings file stores the id and not the label.
    -- Runs after the normalisation above so it is looking at a real id.
    do
        local was = tostring(M.settings.ui.background_theme[1] or '');
        local now = theme.canonical_theme(was);
        if now ~= nil and now ~= was then
            M.settings.ui.background_theme[1] = now;
            if M.settings.ui.bg_image_owner ~= nil
                and tostring(M.settings.ui.bg_image_owner[1] or '') == was then
                M.settings.ui.bg_image_owner[1] = now;
            end
        end
    end
    -- Somebody already sitting on a theme that carries a picture, from before
    -- themes carried pictures, should get it on the next load rather than
    -- having to switch away and back to trigger it.
    M.apply_theme_portrait(nil, M.settings.ui.background_theme[1]);
    -- Presentation flags added in 1.7.0.
    local function ensure_flag(tbl, key, value)
        if tbl[key] == nil then
            tbl[key] = T{ value };
        end
    end

    ensure_flag(M.settings.ui, 'accent_by_activity', true);
    ensure_flag(M.settings.ui, 'text_style', 'Shadow');
    ensure_flag(M.settings.ui, 'show_bars', true);
    if M.settings.ui.config_scale == nil then
        M.settings.ui.config_scale = T{ 1.0 };
    end
    ensure_flag(M.settings.ui, 'show_strip', true);
    ensure_flag(M.settings.ui, 'show_sparkline', true);
    ensure_flag(M.settings.ui, 'show_moon_rates', false);
    ensure_flag(M.settings.ui, 'rank_toast', true);
    ensure_flag(M.settings.ui, 'hide_on_menu', true);
    -- Sound alerts, added later than the rest, so an existing settings file
    -- will not have the group at all.
    if M.settings.sounds == nil then
        M.settings.sounds = T{};
    end
    ensure_flag(M.settings.sounds, 'enabled', true);
    ensure_flag(M.settings.sounds, 'rank_up', '');
    ensure_flag(M.settings.sounds, 'skill_up', '');
    ensure_flag(M.settings.sounds, 'big_drop', '');
    ensure_flag(M.settings.sounds, 'big_drop_gil', 3000);
    ensure_flag(M.settings.sounds, 'fatigue_cap', '');
    ensure_flag(M.settings.sounds, 'clam_ready', '');
    ensure_flag(M.settings.ui, 'animations', true);

    -- Names the player taught it with /floos menu add, for any menu the
    -- built-in list does not know about. Plain lists, not T{ value } flags.
    if M.settings.ui.menu_extra == nil then
        M.settings.ui.menu_extra = T{};
    end
    -- Built-ins the player took back out, e.g. one that turns out to fire on
    -- something ordinary. Wins over the built-in list.
    if M.settings.ui.menu_never == nil then
        M.settings.ui.menu_never = T{};
    end
    pcall(function ()
        local menu = require('libs.menu');
        menu.set_extra(M.settings.ui.menu_extra);
        menu.set_never(M.settings.ui.menu_never);
    end);
    ensure_flag(M.settings.ui, 'expert', true);
    ensure_flag(M.settings.ui, 'compact', false);

    -- 1.7.3: the compact boolean became a three-level detail setting.
    ensure_flag(M.settings.ui, 'detail', nil);
    local lvl = M.settings.ui.detail[1];
    if lvl ~= 'Full' and lvl ~= 'Compact' and lvl ~= 'Mini' then
        lvl = M.settings.ui.compact[1] and 'Compact' or 'Full';
        M.settings.ui.detail[1] = lvl;
    end
    M.settings.ui.compact[1] = (lvl == 'Compact');

    if M.settings.ui.text_style[1] ~= 'Shadow'
        and M.settings.ui.text_style[1] ~= 'Outline'
        and M.settings.ui.text_style[1] ~= 'None' then
        M.settings.ui.text_style[1] = 'Shadow';
    end

    if M.settings.ui.tracker == nil then
        M.settings.ui.tracker = M.default_settings.ui.tracker:copy();
    end
    local tui = M.settings.ui.tracker;
    if tui.scale == nil then tui.scale = T{ 1.0 }; end
    if tui.padding == nil then tui.padding = T{ 8 }; end
    if tui.background_opacity == nil then tui.background_opacity = T{ 0.72 }; end
    if tui.border_opacity == nil then tui.border_opacity = T{ 0.9 }; end
    if tui.border_thickness == nil then tui.border_thickness = T{ 0 }; end
    if tui.panel_rounding == nil then tui.panel_rounding = T{ 8 }; end
    if tui.show_duration == nil then tui.show_duration = T{ true }; end
    if tui.show_controls == nil then tui.show_controls = T{ false }; end

    if M.settings.tracker == nil then
        M.settings.tracker = M.default_settings.tracker:copy();
    end
    if M.settings.tracker.never_hide == nil then
        M.settings.tracker.never_hide = T{ false };
    end
    if M.settings.tracker.width == nil then
        M.settings.tracker.width = T{ 340 };
    end
    -- Renderer clamps to 320; keep the stored value in the same range.
    if M.settings.tracker.width[1] < 320 then
        M.settings.tracker.width[1] = 320;
    end
    if M.settings.tracker.width[1] > 600 then
        M.settings.tracker.width[1] = 600;
    end
    if M.settings.tracker.height == nil then
        M.settings.tracker.height = T{ 0 };
    end
    if M.settings.tracker.height[1] < 0 then
        M.settings.tracker.height[1] = 0;
    end
    if M.settings.tracker.height[1] > 900 then
        M.settings.tracker.height[1] = 900;
    end
    if M.settings.tracker.show_duration == nil then
        M.settings.tracker.show_duration = T{ tui.show_duration[1] };
    end
    if M.settings.tracker.show_controls == nil then
        M.settings.tracker.show_controls = T{ tui.show_controls[1] };
    end
    if M.settings.tracker.show_fatigue == nil then
        M.settings.tracker.show_fatigue = T{ true };
    end
    if M.settings.tracker.show_accuracy == nil then
        M.settings.tracker.show_accuracy = T{ false };
    end
    if M.settings.tracker.show_zone_verdict == nil then
        M.settings.tracker.show_zone_verdict = T{ true };
    end
    if M.settings.tracker.show_best_for == nil then
        M.settings.tracker.show_best_for = T{ true };
    end
    if M.settings.fatigue == nil then
        M.settings.fatigue = M.default_settings.fatigue:copy();
    end
    if M.settings.fatigue.observations == nil then
        M.settings.fatigue.observations = T{};
    end
    if M.settings.fatigue.period_hours == nil then
        M.settings.fatigue.period_hours = T{ 24 };
    end
    if (tonumber(M.settings.fatigue.period_hours[1]) or 0) <= 0 then
        M.settings.fatigue.period_hours[1] = 24;
    end
    if M.settings.fatigue.per_zone == nil then
        M.settings.fatigue.per_zone = T{ true };
    end
    if M.settings.fatigue.zones == nil then
        M.settings.fatigue.zones = T{};
    end
    if M.settings.fatigue.global_on == nil then M.settings.fatigue.global_on = T{ true }; end
    -- A file written by an early 3.8.0 build carries global_on = false from
    -- the days it was off by default. Switch it on once, and remember that
    -- it was done so a deliberate /floos global off is respected after.
    if M.settings.fatigue.global_seeded == nil then
        M.settings.fatigue.global_seeded = T{ true };
        M.settings.fatigue.global_on[1] = true;
    end
    if M.settings.fatigue.global_protect == nil then M.settings.fatigue.global_protect = T{ true }; end
    if M.settings.fatigue.global == nil then M.settings.fatigue.global = T{}; end
    if M.settings.fatigue.last_seen == nil then
        M.settings.fatigue.last_seen = T{ 0 };
    end
    if M.settings.journal == nil then
        M.settings.journal = T{ enabled = T{ true } };
    end
    if M.settings.journal.enabled == nil then
        M.settings.journal.enabled = T{ true };
    end
    if M.settings.tracker.verdict_metric == nil then
        M.settings.tracker.verdict_metric = T{ 'Gil' };
    end
    if M.settings.tracker.verdict_metric[1] ~= 'Gil'
        and M.settings.tracker.verdict_metric[1] ~= 'Skill' then
        M.settings.tracker.verdict_metric[1] = 'Gil';
    end

    -- One-time 1.7.0 layout migration: the panel auto-fits now, so drop any
    -- height locked in by the old resize grip and widen narrow panels.
    if M.settings.layout_version == nil then
        M.settings.layout_version = T{ 0 };
    end
    if (tonumber(M.settings.layout_version[1]) or 0) < 170 then
        M.settings.layout_version[1] = 170;
        M.settings.tracker.height[1] = 0;
        if M.settings.tracker.width[1] < 340 then
            M.settings.tracker.width[1] = 340;
        end
    end
    if M.settings.tracker.show_moon == nil then
        M.settings.tracker.show_moon = T{ true };
    end

    if M.settings.mining == nil then
        M.settings.mining = M.default_settings.mining:copy();
    end
    if M.settings.mining.session_active == nil then
        M.settings.mining.session_active = T{ 0 };
    end
    if M.settings.mining.last_mine == nil then
        M.settings.mining.last_mine = T{ 0 };
    end
    if M.settings.logging == nil then
        M.settings.logging = M.default_settings.logging:copy();
    end
    if M.settings.logging.log_skill == nil then
        M.settings.logging.log_skill = T{ 0 };
    end
    if M.settings.logging.fatigue_cap == nil then
        M.settings.logging.fatigue_cap = T{ 200 };
    end
    if M.settings.harvest == nil then
        M.settings.harvest = M.default_settings.harvest:copy();
    end
    if M.settings.harvest.fatigue_cap == nil then
        M.settings.harvest.fatigue_cap = T{ 200 };
    end
    if M.settings.harvest.harvest_skill == nil then
        M.settings.harvest.harvest_skill = T{ 0 };
    end
    if M.settings.harvest.skillup_display == nil then
        M.settings.harvest.skillup_display = T{ true };
    end
    if M.settings.excavate == nil then
        M.settings.excavate = T{ fatigue_cap = T{ 200 } };
    end
    if M.settings.fishing == nil then
        M.settings.fishing = M.default_settings.fishing:copy();
    end
    if M.settings.digging == nil then
        M.settings.digging = M.default_settings.digging:copy();
    end
    if M.settings.clamming == nil then
        M.settings.clamming = M.default_settings.clamming:copy();
    end
    if M.settings.tabs == nil then
        M.settings.tabs = M.default_settings.tabs:copy();
    end
    for _, pair in ipairs({
        { 'fishing', 'idle_grace', 60 }, { 'digging', 'idle_grace', 10 },
        { 'fishing', 'bait_cost', 0 },   { 'fishing', 'bait_subtract', false },
        { 'fishing', 'skillup_display', true }, { 'fishing', 'fish_skill', 0 },
        { 'digging', 'green_cost', 0 },  { 'digging', 'green_subtract', false },
        { 'digging', 'skillup_display', true }, { 'digging', 'dig_skill', 0 },
        { 'digging', 'ore_watch', true },
        { 'clamming', 'idle_grace', 15 }, { 'clamming', 'kit_cost', 500 },
        { 'clamming', 'kit_subtract', true }, { 'clamming', 'hq_body', false },
        { 'clamming', 'show_bucket', false }, { 'clamming', 'bucket_prices', true },
        { 'clamming', 'dig_delay', 10 },
        { 'tabs', 'mining', true },   { 'tabs', 'logging', true },
        { 'tabs', 'harvest', true },  { 'tabs', 'excavate', true },
        { 'tabs', 'hunting', true },  { 'tabs', 'fishing', true },
        { 'tabs', 'digging', true },  { 'tabs', 'clamming', true },
    }) do
        local grp = M.settings[pair[1]];
        if grp ~= nil and grp[pair[2]] == nil then
            grp[pair[2]] = T{ pair[3] };
        end
    end
    if M.settings.excavate.fatigue_cap == nil then
        M.settings.excavate.fatigue_cap = T{ 200 };
    end
    if M.settings.excavate.exca_skill == nil then
        M.settings.excavate.exca_skill = T{ 0 };
    end
    if M.settings.excavate.skillup_display == nil then
        M.settings.excavate.skillup_display = T{ true };
    end
    if M.settings.hunt == nil then
        M.settings.hunt = T{ respawn_sec = T{ 345 } };
    end
    if M.settings.hunt.respawn_sec == nil then
        M.settings.hunt.respawn_sec = T{ 345 };
    end
    if M.settings.hunt.track_list == nil then
        M.settings.hunt.track_list = T{};
    end
    if M.settings.helm == nil then
        M.settings.helm = T{};
    end
    if M.settings.session == nil then
        M.settings.session = M.default_settings.session:copy();
    end
    if M.settings.lifetime == nil then
        M.settings.lifetime = T{ gil_gained = T{ 0 } };
    end
    if M.settings.lifetime.gil_gained == nil then
        M.settings.lifetime.gil_gained = T{ 0 };
    end
    if M.settings.item_index == nil then
        M.settings.item_index = M.default_settings.item_index:copy();
    end
end

function M.panels_are_shown()
    if M.settings.panels_hidden ~= nil and M.settings.panels_hidden[1] then
        return false;
    end
    return true;
end

function M.update_pricing()
    M.pricing = T{};
    for _, line in pairs(M.settings.item_index) do
        local parts = split(line, ':');
        if parts[1] ~= nil then
            local name = string.lower((parts[1]:match('^%s*(.-)%s*$')) or '');
            local price = tonumber(parts[2]) or 0;
            if name ~= '' then
                M.pricing[name] = price;
            end
        end
    end
end

--- Merge `name:price` lines into the price list: existing names are updated in
--- place, new names appended, anything unparseable is skipped and counted.
--- This is how a price file generated outside the game (for example by the
--- psxi market tool) gets in without retyping thirty prices by hand.
function M.merge_prices(lines)
    local updated, added, skipped = 0, 0, 0;

    -- Index the current list by normalized name.
    local index = {};
    for i, line in ipairs(M.settings.item_index) do
        local name = split(line, ':')[1];
        if name ~= nil then
            index[string.lower(name:match('^%s*(.-)%s*$') or '')] = i;
        end
    end

    for _, raw in ipairs(lines) do
        local line = tostring(raw or ''):gsub('[\r\n]', '');
        local name, price = line:match('^%s*(.-)%s*:%s*(-?%d+)%s*$');
        if name ~= nil and name ~= '' and tonumber(price) ~= nil
            and tonumber(price) >= 0 then
            local key = string.lower(name);
            local entry = name .. ':' .. price;
            if index[key] ~= nil then
                M.settings.item_index[index[key]] = entry;
                updated = updated + 1;
            else
                M.settings.item_index[#M.settings.item_index + 1] = entry;
                index[key] = #M.settings.item_index;
                added = added + 1;
            end
        elseif line:match('%S') then
            skipped = skipped + 1;
        end
    end

    M.update_pricing();
    return updated, added, skipped;
end

--- Where the import looks when given a bare filename.
function M.prices_dir()
    local ok, p = pcall(function ()
        return AshitaCore:GetInstallPath();
    end);
    if ok and p ~= nil and p ~= '' then
        return (tostring(p):gsub('[/\\]+$', '')) .. '/config/addons/floos';
    end
    return '.';
end


local function render_general()
    imgui.Text('Modules');
    ui.begin_child('floos_modules', { 0, 90 }, true);
    imgui.Checkbox('Session Tracker', M.settings.tracker.visible);
    imgui.Checkbox('Reset Session On Load', M.settings.reset_on_load);
    ui.end_child();

    imgui.Text('Fonts');
    ui.begin_child('floos_fonts', { 0, 150 }, true);
    if imgui.InputInt('Font Size', M.settings.font_size) then
        if M.settings.font_size[1] < 6 then M.settings.font_size[1] = 6; end
        if M.settings.font_size[1] > 30 then M.settings.font_size[1] = 30; end
    end
    if M.settings.ui.font_family == nil then
        M.settings.ui.font_family = T{ 'Tahoma Bold (Default)' };
    end
    fonts.render_combo(M.settings.ui.font_family);

    if M.settings.ui.config_scale == nil then
        M.settings.ui.config_scale = T{ 1.0 };
    end
    imgui.SliderFloat('Config Window', M.settings.ui.config_scale, 0.60, 2.00, '%.2f');
    imgui.TextDisabled('This window only. Font Size above drives everything.');
    ui.end_child();
end

local function render_appearance()
    ui.begin_child('floos_appearance', { 0, fill_height(280) }, true);

    imgui.Text('Tabs On The Panel');
    imgui.TextDisabled('Eight tabs do not fit a narrow window. Untick the ones you');
    imgui.TextDisabled('do not use - they keep tracking, they just stop taking space.');
    do
        local TAB_ROWS = {
            { { 'mining', 'Mine' }, { 'logging', 'Logg' }, { 'harvest', 'Harv' }, { 'excavate', 'Exca' } },
            { { 'hunting', 'Hunt' }, { 'fishing', 'Fish' }, { 'digging', 'Dig' }, { 'clamming', 'Clam' } },
        };
        local shown = 0;
        for _, row in ipairs(TAB_ROWS) do
            for i, entry in ipairs(row) do
                local key, label = entry[1], entry[2];
                if M.settings.tabs[key] == nil then
                    M.settings.tabs[key] = T{ true };
                end
                imgui.Checkbox(label .. '##tab_' .. key, M.settings.tabs[key]);
                if M.settings.tabs[key][1] then shown = shown + 1; end
                if i < #row then imgui.SameLine(); end
            end
            imgui.NewLine();
        end
        -- Zero tabs is a broken panel, not a preference. Put one back.
        if shown == 0 then
            M.settings.tabs.mining[1] = true;
            imgui.TextDisabled('At least one tab has to stay on - Mine was put back.');
        end
    end

    imgui.Separator();
    imgui.Text('Window Theme');
    local themes = theme.THEME_OPTIONS;
    local current_theme = M.settings.ui.background_theme[1];
    for _, entry in ipairs(themes) do
        if imgui.RadioButton(entry.label, current_theme == entry.id) then
            M.settings.ui.background_theme[1] = entry.id;
            -- A theme can bring a picture with it, so switching theme has
            -- to move the picture too.
            M.apply_theme_portrait(current_theme, entry.id);
        end
        imgui.SameLine();
    end
    imgui.NewLine();

    imgui.Text('Text Edge');
    local styles = { 'Shadow', 'Outline', 'None' };
    for _, name in ipairs(styles) do
        if imgui.RadioButton(name .. '##textstyle', M.settings.ui.text_style[1] == name) then
            M.settings.ui.text_style[1] = name;
        end
        imgui.SameLine();
    end
    imgui.NewLine();

    imgui.Separator();
    imgui.Text('Display');
    imgui.Checkbox('Accent Color Per Activity', M.settings.ui.accent_by_activity);
    -- A palette can claim the whole panel, in which case this control has
    -- nothing left to do and should say so rather than looking broken.
    -- Named the active palette rather than hardcoding one: this hint said
    -- "Itmejammy" regardless of which whole-panel theme was on, which is
    -- wrong the moment there is more than one of them.
    if theme.active ~= nil and theme.active.force_accent then
        imgui.TextDisabled(string.format(
            '%s uses one colour everywhere, so this has no effect.',
            tostring(theme.active_label or theme.active_name or 'This theme')));
    end
    -- The faded picture behind the panel. Sits with the other appearance
    -- controls rather than in its own tab: it is a background, same as the
    -- panel style above it.
    do
        local files = portrait.list();
        local cur = tostring(M.settings.ui.bg_image[1] or '');
        local label = (cur == '') and 'None' or cur;
        imgui.SetNextItemWidth(200);
        if imgui.BeginCombo('Background Picture', label) then
            -- Anything chosen here is the player's own choice, so it is
            -- marked as theirs and a later theme switch will leave it alone.
            -- That includes picking None: somebody who turned the theme's
            -- picture off meant it, and it must not come back.
            if imgui.Selectable('None', cur == '') then
                M.settings.ui.bg_image[1] = '';
                M.settings.ui.bg_image_owner[1] = 'none:'
                    .. tostring(M.settings.ui.background_theme[1] or '');
            end
            for _, f in ipairs(files) do
                if imgui.Selectable(f, cur == f) then
                    M.settings.ui.bg_image[1] = f;
                    M.settings.ui.bg_image_owner[1] = '';
                end
            end
            imgui.EndCombo();
        end
        imgui.SameLine();
        if imgui.SmallButton('Rescan##portraits') then portrait.rescan(); end
        if cur ~= '' then
            imgui.SetNextItemWidth(200);
            imgui.SliderFloat('Picture Fade', M.settings.ui.bg_image_alpha,
                0.02, portrait.MAX_ALPHA, '%.2f');
            imgui.TextDisabled('Capped on purpose - past this the numbers stop being readable.');
            imgui.SetNextItemWidth(200);
            imgui.SliderFloat('Picture Width', M.settings.ui.bg_image_width,
                portrait.MIN_RATIO, portrait.MAX_RATIO, '%.2f');
            imgui.TextDisabled('Ashita cannot tell an addon how big an image is, so this\nhas to be set by hand. Use the picture\'s width divided by\nits height - a 687x1024 portrait is 0.67 - and it will\nkeep its proportions at any panel size.');
        elseif #files == 0 then
            imgui.TextDisabled('Drop a PNG in assets/portraits/ and press Rescan.');
        end
    end

    imgui.Checkbox('Progress Bars', M.settings.ui.show_bars);
    imgui.Checkbox('Swing History Strip', M.settings.ui.show_strip);
    imgui.Checkbox('Rate Sparkline', M.settings.ui.show_sparkline);
    imgui.Checkbox('Skillup Rate By Moon Phase', M.settings.ui.show_moon_rates);
    imgui.TextDisabled('Off by default. Splits your lifetime skill-up rate into\nNew / Full / Normal moon. Needs hundreds of swings per\nbucket before the numbers mean anything.');
    imgui.Checkbox('Rank-up Banner', M.settings.ui.rank_toast);
    imgui.TextDisabled('Centred RANK UP! banner for five seconds.');
    imgui.Checkbox('Hide Behind Map / Main Menu', M.settings.ui.hide_on_menu);
    imgui.TextDisabled('Panel steps aside while a full-screen game menu is open\nand comes back when you close it.');
    imgui.Checkbox('Animations (flash / count-up)', M.settings.ui.animations);
    imgui.Checkbox('Expert visuals', M.settings.ui.expert);
    imgui.TextDisabled('Labeled section rules, last-10m rate trend, meter graduations.');
    imgui.Text('Detail Level');
    for _, level in ipairs({ 'Full', 'Compact', 'Mini' }) do
        if imgui.RadioButton(level .. '##detail', M.settings.ui.detail[1] == level) then
            M.settings.ui.detail[1] = level;
            M.settings.ui.compact[1] = (level == 'Compact');
            M.settings.tracker.height[1] = 0;
        end
        imgui.SameLine();
    end
    imgui.NewLine();
    imgui.TextDisabled('Full: everything. Compact: no drop list or footer.');
    imgui.TextDisabled('Mini: rate, fatigue, tools, gil. Five lines.');
    imgui.Checkbox('Zone Stay/Move Verdict', M.settings.tracker.show_zone_verdict);
    imgui.Text('Judge zones by');
    for _, metric in ipairs({ 'Gil', 'Skill' }) do
        if imgui.RadioButton(metric .. '/hr##verdict', M.settings.tracker.verdict_metric[1] == metric) then
            M.settings.tracker.verdict_metric[1] = metric;
        end
        imgui.SameLine();
    end
    imgui.NewLine();

    imgui.Separator();
    imgui.Text('Session Panel');
    local ms = M.settings.ui.tracker;
    imgui.SliderFloat('Scale', ms.scale, 0.50, 2.50, '%.2f');
    imgui.SliderFloat('Background Opacity', ms.background_opacity, 0.0, 1.0, '%.2f');
    imgui.SliderInt('Border Thickness', ms.border_thickness, 0, 6);
    imgui.SliderInt('Padding', ms.padding, 2, 20);
    imgui.SliderInt('Panel Rounding', ms.panel_rounding, 0, 16);

    imgui.Separator();
    imgui.Checkbox('Show Duration', ms.show_duration);
    M.settings.tracker.show_duration[1] = ms.show_duration[1];
    M.settings.tracker.show_controls[1] = false;
    ms.show_controls[1] = false;

    imgui.Checkbox('Show Fatigue', M.settings.tracker.show_fatigue);
    imgui.Checkbox('Show Accuracy (under Zone fatigue)', M.settings.tracker.show_accuracy);
    imgui.Checkbox('Show Moon Phase', M.settings.tracker.show_moon);
    imgui.Checkbox('Show Skill Line', M.settings.mining.skillup_display);
    ui.end_child();
end

local function render_mining()
    ui.begin_child('floos_mining', { 0, 320 }, true);
    imgui.Text('Mining');
    imgui.InputFloat('Mining Skill', M.settings.mining.mine_skill, 0.1, 0.1, '%.1f');
    imgui.InputInt('Mine Fatigue Cap', M.settings.mining.fatigue_cap);
    imgui.InputInt('Pickaxe Cost', M.settings.mining.pickaxe_cost);
    imgui.Checkbox('Subtract Pickaxe Breaks', M.settings.mining.pickaxe_subtract);
    imgui.TextDisabled('HELM fatigue is not a flat 200 and is not tied to your');
    imgui.TextDisabled('character level. Horizon scales it with your GATHERING rank');
    imgui.TextDisabled('and sets it per zone. The base numbers are unpublished, so');
    imgui.TextDisabled('these caps raise themselves whenever you gather past one.');

    imgui.Separator();
    imgui.Text('Logging');
    imgui.InputFloat('Logging Skill', M.settings.logging.log_skill, 0.1, 0.1, '%.1f');
    imgui.InputInt('Log Fatigue Cap', M.settings.logging.fatigue_cap);
    imgui.InputInt('Hatchet Cost', M.settings.logging.hatchet_cost);
    imgui.Checkbox('Subtract Hatchet Breaks', M.settings.logging.hatchet_subtract);
    imgui.Checkbox('Show Logging Skillups', M.settings.logging.skillup_display);

    imgui.Separator();
    imgui.Text('Harvesting');
    imgui.InputFloat('Harvesting Skill', M.settings.harvest.harvest_skill, 0.1, 0.1, '%.1f');
    imgui.InputInt('Harv Fatigue Cap', M.settings.harvest.fatigue_cap);
    imgui.InputInt('Sickle Cost', M.settings.harvest.sickle_cost);
    imgui.Checkbox('Subtract Sickle Breaks', M.settings.harvest.sickle_subtract);
    imgui.Checkbox('Show Harvesting Skillups', M.settings.harvest.skillup_display);

    imgui.Separator();
    imgui.Text('Excavation');
    imgui.InputFloat('Excavation Skill', M.settings.excavate.exca_skill, 0.1, 0.1, '%.1f');
    imgui.InputInt('Exca Fatigue Cap', M.settings.excavate.fatigue_cap);
    imgui.Checkbox('Show Excavation Skillups', M.settings.excavate.skillup_display);
    imgui.TextDisabled('Excavation uses the Pickaxe Cost set under Mining.');

    imgui.Separator();
    imgui.Text('Fishing');
    imgui.InputInt('Bait Cost', M.settings.fishing.bait_cost);
    if M.settings.fishing.bait_cost[1] < 0 then M.settings.fishing.bait_cost[1] = 0; end
    imgui.Checkbox('Subtract Bait Cost', M.settings.fishing.bait_subtract);
    imgui.TextDisabled('Bait is spent per BITE on Horizon, not per cast, so the');
    imgui.TextDisabled('bill follows bites. Casts that get no bite are free.');
    imgui.InputInt('Fishing Idle Grace (s)', M.settings.fishing.idle_grace);
    if M.settings.fishing.idle_grace[1] < 1 then M.settings.fishing.idle_grace[1] = 1; end
    imgui.TextDisabled('gil/hr clock freezes this long after each action.');
    imgui.Checkbox('Show Fishing Skillups', M.settings.fishing.skillup_display);
    imgui.TextDisabled('No fishing fatigue on Horizon - each water has a shared fish');
    imgui.TextDisabled('stock that refills at Vana hours 0, 4, 6, 7, 17, 18 and 20.');

    imgui.Separator();
    imgui.Text('Chocobo Digging');
    imgui.InputInt('Gysahl Greens Cost', M.settings.digging.green_cost);
    if M.settings.digging.green_cost[1] < 0 then M.settings.digging.green_cost[1] = 0; end
    imgui.Checkbox('Subtract Greens Cost', M.settings.digging.green_subtract);
    imgui.TextDisabled('A green is spent on every accepted dig, including the ones');
    imgui.TextDisabled('that find nothing. Only "wait longer" refusals are free.');
    imgui.InputFloat('Digging Skill', M.settings.digging.dig_skill, 0.1, 0.1, '%.1f');
    if M.settings.digging.dig_skill[1] < 0 then M.settings.digging.dig_skill[1] = 0; end
    if M.settings.digging.dig_skill[1] > 100 then M.settings.digging.dig_skill[1] = 100; end
    do
        local tracker = require('modules.tracker');
        local rank = tracker.dig_rank_from_skill(M.settings.digging.dig_skill[1]);
        local names = require('constants').DIG_RANKS or {};
        imgui.TextDisabled(string.format('Rank: %s (%d)   Daily item cap: %d',
            names[rank] or '?', rank, 100 + (rank * 10)));
    end
    imgui.TextDisabled('Rank is just skill divided by ten, same as a craft, so');
    imgui.TextDisabled('the addon works it out. Skill-ups keep this current.');
    imgui.InputInt('Digging Idle Grace (s)', M.settings.digging.idle_grace);
    if M.settings.digging.idle_grace[1] < 1 then M.settings.digging.idle_grace[1] = 1; end
    imgui.TextDisabled('gil/hr clock runs this long after each dig, then freezes');
    imgui.TextDisabled('until the next one. Stops AFK time diluting your rate.');
    imgui.Checkbox('Show Digging Skillups', M.settings.digging.skillup_display);
    imgui.Checkbox('Elemental Ore Watch', M.settings.digging.ore_watch);
    imgui.TextDisabled('Ore needs Craftsman+ rank, a 7-24 waxing crescent, an active');
    imgui.TextDisabled('weather (fog counts) and a non-Zilart zone. Ore element');
    imgui.TextDisabled('follows the Vana\'diel day. Weather is read straight out of');
    imgui.TextDisabled('the client, the same way the Vana\'diel clock already is.');


    imgui.Separator();
    imgui.Text('Clamming');
    imgui.InputInt('Clamming Kit Cost', M.settings.clamming.kit_cost);
    if M.settings.clamming.kit_cost[1] < 0 then M.settings.clamming.kit_cost[1] = 0; end
    imgui.Checkbox('Subtract Kit Cost', M.settings.clamming.kit_subtract);
    imgui.TextDisabled('500g per kit from Toh Zonikki - your first one is free.');
    imgui.Checkbox('HQ Swimwear Body', M.settings.clamming.hq_body);

    imgui.Checkbox('Show Bucket Contents', M.settings.clamming.show_bucket);
    imgui.TextDisabled('Lists what is in the bucket while you dig, not just the weight.');
    if M.settings.clamming.show_bucket[1] then
        imgui.Indent(16);
        imgui.Checkbox('With Unit Prices', M.settings.clamming.bucket_prices);
        imgui.Unindent(16);
    end
    imgui.TextDisabled('The HQ body piece halves the chance of something jumping');
    imgui.TextDisabled('into a 200pz bucket, 10 percent down to 5. It changes the');
    imgui.TextDisabled('risk figure on the Clam tab, nothing else.');
    imgui.InputInt('Dig Cooldown (s)', M.settings.clamming.dig_delay);
    if M.settings.clamming.dig_delay[1] < 1 then M.settings.clamming.dig_delay[1] = 1; end
    imgui.TextDisabled('A clamming point is reusable 10s after your last dig on');
    imgui.TextDisabled('Horizon. The cooldown is per point, so hopping between two');
    imgui.TextDisabled('nearby points beats the timer. Clicking early is rejected');
    imgui.TextDisabled('and shows as "early" next to the dig count.');
    imgui.InputInt('Clamming Idle Grace (s)', M.settings.clamming.idle_grace);
    if M.settings.clamming.idle_grace[1] < 1 then M.settings.clamming.idle_grace[1] = 1; end
    imgui.TextDisabled('No skill, no rank, no daily cap on clamming - the bucket is');
    imgui.TextDisabled('the only limit, and it is all-or-nothing if you go over.');

    imgui.Separator();
    imgui.Text('Display');
    imgui.InputInt('Display Timeout (sec)', M.settings.tracker.display_timeout);
    imgui.Checkbox('Never Hide', M.settings.tracker.never_hide);

    imgui.Checkbox('Follow the activity (switch tabs automatically)',
        M.settings.tracker.auto_switch_tab);
    if imgui.IsItemHovered() then
        imgui.SetTooltip('Mine, then dig, and the panel moves to the Dig tab by itself.');
    end
    imgui.Checkbox('Show the panel when an activity starts',
        M.settings.tracker.auto_show);
    if imgui.IsItemHovered() then
        imgui.SetTooltip('Off keeps a hidden panel hidden. It still tracks - use /floos show to look.');
    end
    ui.end_child();

    imgui.Text('Item Prices (name:price, one per line)');
    local temp = T{ table.concat(M.settings.item_index, '\n') };
    if imgui.InputTextMultiline('##floos_prices', temp, 8192, { 0, fill_height(120) }) then
        M.settings.item_index = split(temp[1], '\n');
        M.update_pricing();
    end
end

local function render_data()
    local tracker = require('modules.tracker');
    local journal = require('libs.journal');

    ui.begin_child('floos_data_cfg', { 0, fill_height(320) }, true);

    imgui.Text('Digging reset schedule');
    imgui.TextDisabled('Chocobo digging is the only activity with a real daily');
    imgui.TextDisabled('allowance on a real-life clock, so the countdown shows on');
    imgui.TextDisabled('the Digging tab and nowhere else. The rest run on a rolling');
    imgui.TextDisabled('window with no fixed reset to count down to.');
    imgui.Spacing();
    imgui.TextDisabled('Learned by watching for the one thing that proves a reset:');
    imgui.TextDisabled('being at the cap, then digging successfully anyway.');
    imgui.TextDisabled('This only predicts the next reset - it never clears your');
    imgui.TextDisabled('counters. Use /floos clear for that.');
    imgui.Spacing();

    local conf = tracker.fatigue_confidence();
    local left = tracker.fatigue_time_left();
    if left ~= nil then
        imgui.Text(string.format('Next reset in %s   (confidence: %s)',
            require('libs.format').format_duration(left), conf));
    else
        imgui.Text('No reset seen yet. Keep gathering past the cap and it will learn.');
    end

    local measured = require('libs.fatigue').measured_period_hours({
        observations = M.settings.fatigue.observations,
        period_hours = tonumber(M.settings.fatigue.period_hours[1]) or 24,
    });
    if measured ~= nil then
        imgui.TextDisabled(string.format('Observed gap between resets: %.1f hours', measured));
        if math.abs(measured - (tonumber(M.settings.fatigue.period_hours[1]) or 24)) > 0.5 then
            imgui.TextColored({ 1.0, 0.74, 0.30, 1.0 },
                'That does not match the period below. Consider changing it.');
        end
    end

    imgui.InputInt('Period (hours)', M.settings.fatigue.period_hours);
    if M.settings.fatigue.period_hours[1] < 1 then
        M.settings.fatigue.period_hours[1] = 1;
    end
    imgui.TextDisabled(string.format('%d reset(s) recorded.',
        #M.settings.fatigue.observations));

    if imgui.Button('It just reset') then
        tracker.fatigue_reset(true);
        print(chat.header(addon.name):append(chat.message('Fatigue reset recorded.')));
    end
    imgui.SameLine();
    if imgui.Button('Forget schedule') then
        M.settings.fatigue.observations = T{};
    end

    imgui.Spacing();
    imgui.Separator();
    imgui.Text('Zone-specific fatigue');
    imgui.TextDisabled('Horizon\'s HELM allowance is per zone: 50 of 200 in Palborough');
    imgui.TextDisabled('stays 50 of 200 there however long you spend elsewhere.');
    imgui.TextDisabled('On, the Fatigue meter shows the count for the zone you are in,');
    imgui.TextDisabled('and remembers every zone across relogs. Mining, logging,');
    imgui.TextDisabled('harvesting and excavation only - digging is not touched.');
    imgui.Spacing();
    if imgui.Checkbox('Count fatigue per zone', M.settings.fatigue.per_zone) then
        settings.save();
    end
    imgui.SameLine();
    if M.settings.fatigue.per_zone[1] then
        imgui.TextColored({ 0.53, 0.82, 0.47, 1.0 }, 'ON - meter reads "Zone fatigue"');
    else
        imgui.TextColored({ 0.60, 0.58, 0.54, 1.0 }, 'off - meter reads "Fatigue" (session)');
    end

    if M.settings.fatigue.per_zone[1] then
        imgui.TextDisabled(string.format(
            'A zone clears itself %d hours after its first item, or the moment',
            tonumber(M.settings.fatigue.period_hours[1]) or 24));
        imgui.TextDisabled('you gather there past the cap. The period is the one above.');
        imgui.TextDisabled('/floos clear and Reset Session clear them all as well.');
        imgui.Spacing();

        local rows = tracker.zone_fatigue_rows();
        if #rows == 0 then
            imgui.TextDisabled('No zone has anything counted yet.');
        else
            local fmt = require('libs.format');
            local act_label = { mining = 'Mine', logging = 'Log', harvest = 'Harvest', excavate = 'Excav' };
            for i, r in ipairs(rows) do
                local cap = tracker.fatigue_cap_for and tracker.fatigue_cap_for(r.act) or nil;
                local count = cap and string.format('%d / %d', r.items or 0, cap)
                    or tostring(r.items or 0);
                local left = tracker.zone_fatigue_left(r);
                local when = left and (' - clears in ' .. fmt.format_duration(left)) or '';
                imgui.Text(string.format('%-8s %-26s %s%s',
                    act_label[r.act] or r.act, tostring(r.name), count, when));
                imgui.SameLine();
                if imgui.SmallButton('Clear##zf' .. i) then
                    tracker.zone_fatigue_clear(r.act, r.id);
                    settings.save();
                end
            end
            imgui.Spacing();
            if imgui.Button('Clear every zone') then
                tracker.zone_fatigue_clear_all();
                settings.save();
                print(chat.header(addon.name):append(chat.message('Zone fatigue counters cleared.')));
            end
        end
    end

    imgui.Separator();
    imgui.Text('Global fatigue');
    imgui.TextDisabled('One counter per activity that follows you between zones. It climbs');
    imgui.TextDisabled('in the zone you are working - its home - and every hit in any other');
    imgui.TextDisabled('zone takes one off. Drawn above Zone fatigue. Also: /floos global');
    imgui.Spacing();
    if imgui.Checkbox('Global fatigue counter', M.settings.fatigue.global_on) then
        settings.save();
    end
    imgui.SameLine();
    if M.settings.fatigue.global_on[1] then
        imgui.TextColored({ 0.53, 0.82, 0.47, 1.0 }, 'ON - a "Global" bar sits above Zone fatigue');
    else
        imgui.TextColored({ 0.60, 0.58, 0.54, 1.0 }, 'off');
    end
    if M.settings.fatigue.global_on[1] then
        if imgui.Checkbox('Protect it from /floos clear and Reset Session', M.settings.fatigue.global_protect) then
            settings.save();
        end
        local any = false;
        local gf_label = { mining = 'Mine', logging = 'Log', harvest = 'Harvest', excavate = 'Excav' };
        for _, a in ipairs({ 'mining', 'logging', 'harvest', 'excavate' }) do
            local r = tracker.global_fatigue_record and tracker.global_fatigue_record(a) or nil;
            if r ~= nil and (r.count or 0) > 0 then
                any = true;
                local cap = tracker.fatigue_cap_for and tracker.fatigue_cap_for(a) or 200;
                imgui.Text(string.format('%-8s %-26s %d / %d',
                    gf_label[a] or a, tostring(r.zone_name or '?'), r.count or 0, cap));
                imgui.SameLine();
                if imgui.SmallButton('Clear##gf' .. a) then
                    tracker.global_fatigue_clear(a);
                    settings.save();
                end
            end
        end
        if not any then
            imgui.TextDisabled('Nothing counted yet - the first hit sets the home zone.');
        end
    end

    imgui.Separator();
    imgui.Text('Zone advice');
    imgui.Checkbox('Show "Best for" line', M.settings.tracker.show_best_for);
    imgui.TextDisabled('Best zone for gil, and best for skill at your current level.');

    imgui.Separator();
    imgui.Text('Session journal');
    imgui.Checkbox('Write one line per swing', M.settings.journal.enabled);
    local st = journal.stats();
    imgui.TextDisabled(string.format('%d written, %d pending', st.written or 0, st.pending or 0));
    if st.path ~= nil then
        imgui.TextDisabled(tostring(st.path));
    end
    if st.error ~= nil then
        imgui.TextColored({ 0.96, 0.44, 0.44, 1.0 }, tostring(st.error));
    end
    if imgui.Button('Flush now') then
        journal.flush();
    end

    ui.end_child();

    imgui.Separator();
    imgui.Text('Zone advice');
    imgui.Checkbox('Show "Best for" line', M.settings.tracker.show_best_for);
    imgui.TextDisabled('Best zone for gil, and best for skill at your current level.');

    imgui.Separator();
    imgui.Text('Session journal');
    imgui.Checkbox('Write one line per swing', M.settings.journal.enabled);
    local st = journal.stats();
    imgui.TextDisabled(string.format('%d written, %d pending', st.written or 0, st.pending or 0));
    if st.path ~= nil then
        imgui.TextDisabled(tostring(st.path));
    end
    if st.error ~= nil then
        imgui.TextColored({ 0.96, 0.44, 0.44, 1.0 }, tostring(st.error));
    end
    if imgui.Button('Flush now') then
        journal.flush();
    end

    ui.end_child();
end

local function do_reset_defaults()
    settings.reset();
    M.ensure_ui_settings();
    ui.bind(M.settings, M.editor_open);
    M.update_pricing();
    print(chat.header(addon.name):append(chat.message('Settings reset for this character.')));
end

local function render_layout()
    ui.begin_child('floos_layout', { 0, 220 }, true);
    local tracker_pos = T{ M.settings.tracker.x[1], M.settings.tracker.y[1] };
    if imgui.InputInt2('Tracker Position', tracker_pos) then
        M.settings.tracker.x[1] = tracker_pos[1];
        M.settings.tracker.y[1] = tracker_pos[2];
    end
    imgui.SliderInt('Panel Width', M.settings.tracker.width, 320, 600);
    imgui.SliderInt('Panel Height (0 = auto)', M.settings.tracker.height, 0, 900);
    imgui.SameLine();
    if imgui.Button('Auto') then
        M.settings.tracker.height[1] = 0;
    end
    imgui.TextDisabled('Drag the bottom-right grip to resize. Double-click it for auto height.');
    imgui.Separator();
    imgui.Spacing();
    if imgui.Button('Reset Defaults') then
        imgui.OpenPopup('FloosResetDefaults##Confirm');
    end
    imgui.TextDisabled('Restores all Floos settings to factory defaults.');
    if imgui.BeginPopupModal('FloosResetDefaults##Confirm', nil, ImGuiWindowFlags_AlwaysAutoResize) then
        imgui.Text('Reset all Floos settings to defaults?');
        imgui.TextWrapped('This cannot be undone. Saved positions, prices, fonts, and appearance will be lost.');
        imgui.Spacing();
        if imgui.Button('Confirm Reset', { 140, 0 }) then
            do_reset_defaults();
            imgui.CloseCurrentPopup();
        end
        imgui.SameLine();
        if imgui.Button('Cancel', { 140, 0 }) then
            imgui.CloseCurrentPopup();
        end
        imgui.EndPopup();
    end
    ui.end_child();
end

--- The events a sound can be attached to, in the order they appear.
local SOUND_ROWS = {
    { key = 'rank_up',     label = 'Rank Up',
      help = 'Every 10.0 skill. Six times in a career to 60.' },
    { key = 'skill_up',    label = 'Skill Up',
      help = 'Every 0.1. Stays silent on a rank-up so that one has it alone.' },
    { key = 'big_drop',    label = 'Valuable Drop',
      help = 'A drop worth at least the gil figure set below.' },
    { key = 'fatigue_cap', label = 'Fatigue Cap Hit',
      help = 'The item that lands you on the cap - time to move or stop.' },
    { key = 'clam_ready',  label = 'Clam Point Ready',
      help = 'The clamming cooldown finishing. Fires whatever tab you are on.' },
};

--- One dropdown, built the same way the font picker is, so it uses only
--- imgui calls already proven to work in this addon.
---
--- "None" is a real entry rather than a blank line: an empty combo reads as
--- broken, and silence for one event needs to be as pickable as any file.
---@param row table   an entry from SOUND_ROWS
---@param snd table   libs.sound
local function render_sound_row(row, snd)
    local slot = M.settings.sounds[row.key];
    if slot == nil then
        return;
    end

    local cur = slot[1] or '';
    local preview = (cur ~= '') and cur or 'None';
    if cur ~= '' and not snd.exists(cur) then
        preview = cur .. '  (missing)';
    end

    -- Label first, on its own, then a combo with a hidden label. ImGui puts
    -- a widget's label to its RIGHT, which read as "[dropdown] Valuable Drop"
    -- - the name arriving after the thing it names, and colliding with the
    -- Play button besides.
    imgui.Text(row.label);
    imgui.SameLine(140);
    imgui.SetNextItemWidth(240);
    if imgui.BeginCombo('##snd_' .. row.key, preview) then
        if imgui.Selectable('None', cur == '') then
            slot[1] = '';
        end
        if cur == '' then
            imgui.SetItemDefaultFocus();
        end
        for _, file in ipairs(snd.files) do
            local selected = (file == cur);
            if imgui.Selectable(file .. '##snd_' .. row.key, selected) then
                slot[1] = file;
                -- Play it on pick. Choosing a sound you cannot hear is
                -- guesswork, and Yield makes you press a separate button.
                snd.play(file, true);
            end
            if selected then
                imgui.SetItemDefaultFocus();
            end
        end
        imgui.EndCombo();
    end

    if cur ~= '' then
        imgui.SameLine();
        if imgui.Button('Play##snd_' .. row.key) then
            local ok, why = snd.play(cur, true);
            if not ok then
                print(chat.header(addon.name):append(chat.error(
                    'Sound: ' .. tostring(why))));
            end
        end
    end

    imgui.TextDisabled('    ' .. row.help);
end

--- The Sound tab.
local function render_sound()
    local snd = require('libs.sound');
    if not snd.scanned then
        snd.scan();
    end

    ui.begin_child('floos_sound', { 0, fill_height(200) }, true);

    imgui.Checkbox('Enable Sound Alerts', M.settings.sounds.enabled);
    imgui.TextDisabled('Master switch. Individual events can also be set to None.');

    imgui.Separator();

    if #snd.files == 0 then
        imgui.Text('No .wav files found.');
        imgui.TextDisabled('Drop .wav files into the folder below, then press Rescan.');
        if snd.scan_error ~= nil then
            imgui.TextDisabled('Folder read failed: ' .. tostring(snd.scan_error));
        end
    else
        for _, row in ipairs(SOUND_ROWS) do
            render_sound_row(row, snd);
        end

        imgui.Separator();
        imgui.Text('Valuable Drop Threshold');
        imgui.SameLine(140);
        imgui.SetNextItemWidth(120);
        imgui.InputInt('gil##bigdropgil', M.settings.sounds.big_drop_gil);
        imgui.TextDisabled('    A drop counts as valuable when ONE of it is worth this');
        imgui.TextDisabled('    much in your price list. Items showing -- are priced at 0');
        imgui.TextDisabled('    and never trigger it, however rare they actually are.');

        imgui.Separator();

        -- Set-all, borrowed from Yield: handy when you just want to hear
        -- something on everything and narrow it down afterwards.
        imgui.Text('Set Every Event To');
        imgui.SameLine();
        imgui.SetNextItemWidth(200);
        if imgui.BeginCombo('##snd_setall', 'Pick one...') then
            if imgui.Selectable('None##setall', false) then
                for _, row in ipairs(SOUND_ROWS) do
                    M.settings.sounds[row.key][1] = '';
                end
            end
            for _, file in ipairs(snd.files) do
                if imgui.Selectable(file .. '##setall', false) then
                    for _, row in ipairs(SOUND_ROWS) do
                        M.settings.sounds[row.key][1] = file;
                    end
                    snd.play(file, true);
                end
            end
            imgui.EndCombo();
        end
    end

    imgui.Separator();
    if imgui.Button('Rescan Folder##sounds') then
        snd.scan();
        print(chat.header(addon.name):append(chat.message(string.format(
            '%d sound file%s found.', #snd.files, (#snd.files == 1) and '' or 's'))));
    end
    imgui.SameLine();
    imgui.TextDisabled(string.format('%d file%s in %s',
        #snd.files, (#snd.files == 1) and '' or 's', snd.dir()));
    imgui.TextDisabled('The folder is read at load and on Rescan, not every frame.');
    imgui.TextDisabled('Ashita plays .wav only - convert mp3 first. Keep them short.');

    ui.end_child();
end

local function render_about()
    ui.begin_child('floos_about', { 0, fill_height(200) }, true);
    imgui.Text('Floos - HELM companion for Ashita 4.3');
    imgui.TextDisabled(string.format('Version %s', addon.version));
    imgui.Spacing();
    if attribution ~= nil and attribution.render ~= nil then
        attribution.render();
    else
        imgui.TextDisabled('See THIRD_PARTY_NOTICES.md for license details.');
    end
    ui.end_child();
end

function M.render_editor()
    if not M.editor_open[1] then
        return;
    end
    M.ensure_ui_settings();
    imgui.SetNextWindowSize({ 540, 600 }, ImGuiCond_FirstUseEver);
    local style_counts = theme.apply_style();

    -- The chosen typeface, pushed before Begin so the title bar gets it too.
    -- floos.lua renders this window before its own fonts.push, which is why
    -- the config used to ignore both the family and the size.
    fonts.push(M.settings);

    if imgui.Begin('Floos##Config', M.editor_open) then
        -- Size has to be pushed INSIDE Begin: it applies to the current
        -- window, and there is no current window before this line.
        local cfg_mult = 1.0;
        if M.settings.ui and M.settings.ui.config_scale then
            cfg_mult = tonumber(M.settings.ui.config_scale[1]) or 1.0;
        end
        local font_tag = fonts.begin_scale(fonts.get_scale(M.settings) * cfg_mult);
        if imgui.Button('Save') then
            M.update_pricing();
            settings.save();
            print(chat.header(addon.name):append(chat.message('Settings saved.')));
        end
        imgui.SameLine();
        if imgui.Button('Reload') then
            settings.reload();
            M.ensure_ui_settings();
            ui.bind(M.settings, M.editor_open);
            M.update_pricing();
            print(chat.header(addon.name):append(chat.message('Settings reloaded.')));
        end
        imgui.SameLine();
        if imgui.Button('Reset Session') then
            local tracker = require('modules.tracker');
            -- Same reach as the slash command: an explicit clear takes the
            -- per-zone fatigue counters with it.
            tracker.reset_session('all', true);
            settings.save();
            print(chat.header(addon.name):append(chat.message(
                'Session cleared, zone fatigue cleared.')));
        end

        imgui.Separator();
        if imgui.BeginTabBar('##floos_tabs') then
            if imgui.BeginTabItem('General') then
                render_general();
                imgui.EndTabItem();
            end
            if imgui.BeginTabItem('Interface') then
                render_appearance();
                imgui.EndTabItem();
            end
            if imgui.BeginTabItem('HELM') then
                render_mining();
                imgui.EndTabItem();
            end
            if imgui.BeginTabItem('Data') then
                render_data();
                imgui.EndTabItem();
            end
            if imgui.BeginTabItem('Layout') then
                render_layout();
                imgui.EndTabItem();
            end
            if imgui.BeginTabItem('Sound') then
                render_sound();
                imgui.EndTabItem();
            end
            if imgui.BeginTabItem('About') then
                render_about();
                imgui.EndTabItem();
            end
            imgui.EndTabBar();
        end
        fonts.end_scale(font_tag);
    end
    imgui.End();
    fonts.pop();
    theme.pop_style(style_counts);
end

return M;
