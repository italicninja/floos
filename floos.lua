--[[
* Floos - HELM companion for Ashita 4.3
*
* Mining session tracker with skill, fatigue, and gil stats.
* UI rendering adapted from XIUI (GPLv3). See THIRD_PARTY_NOTICES.md.
* Mining logic adapted from HGather (Hastega).
]]--

addon.name = 'floos';
addon.author = 'Makee';
addon.version = '3.3.0';
addon.desc = 'HorizonXI hobby tracker: Mine, Logg, Harv, Exca, Hunt, Fish, Dig, Clam.';
addon.link = 'https://horizonffxi.wiki';
-- One command. /resetmine used to exist as well, doing exactly what
-- /floos clear does, and squatting on a global slash name that another
-- addon could reasonably want.
addon.commands = { '/floos' };

require('common');
local chat = require('chat');
local settings = require('settings');

-- Before ANYTHING parses a settings file. config.lua calls settings.load at
-- require time, and Ashita's library overwrites a file it cannot parse with
-- the defaults - so a truncated file from a crash last session would be
-- gone the moment config loaded. Pre-flight mends it first. See backup.lua.
local backup = require('libs.backup');
local preflight_report = backup.preflight();

local config = require('config');
local ui = require('libs.ui');
local fonts = require('libs.fonts');
local journal = require('libs.journal');
local menu = require('libs.menu');
local tracker = require('modules.tracker');

--- The command list, grouped and short.
---
--- This used to print 28 lines for 23 handlers, which is not a help screen,
--- it is a wall. Duplicates were deleted rather than hidden: an invisible
--- alias is how a list grows back. Sub-commands ride on their parent's line.
local COMMANDS = {
    { 'Panel', {
        { '/floos',            'Open the settings window.' },
        { '/floos show|hide',  'Show or hide the tracker.' },
        { '/floos sound',      'Sound alerts.  (+ on | off | test <file>)' },
        { '/floos menu',       'Hide behind map / main menu.  (+ recent | add | remove)' },
        { '/floos detail',     'full | compact | mini.' },
        { '/floos compact',    'Toggle compact mode (no drop list).' },
        { '/floos mini',       'Toggle the five-line mini panel.' },
        { '/floos auto',       'Release the locked panel height.' },
    }},
    { 'Session', {
        { '/floos pause',      'Pause or resume the active tab.' },
        { '/floos rankup',     'Preview the rank-up banner.' },
        { '/floos report',     'Print session stats to chat.' },
        { '/floos clear',      'Clear every session.' },
        { '/floos zones',      'Rank zones by gil/hr.  (+ clear)' },
        { '/floos insights',   'What your journal shows.  (+ tab name)' },
    }},
    { 'Activity', {
        { '/floos ore',        'Can you dig elemental ore right now?' },
        { '/floos dig',        'Daily count and JST reset.  (+ a number)' },
        { '/floos clam',       'Bucket weight, value, break odds.' },
        { '/floos fatigue',    'Reset countdown.  (+ reset)' },
        { '/floos global',     'Cross-zone counter: on|off, protect on|off, set <n>, reset.' },
    }},
    { 'Setup', {
        { '/floos prices fetch',  'Pull live prices from psxi.gg.' },
        { '/floos prices token <t>', 'Save a psxi.gg API token.' },
        { '/floos prices import <file>', 'Merge a name:price file.' },
        { '/floos debug',      'What the addon is actually seeing.  (+ on | off)' },
    }},
};

local function print_help(is_error)
    if is_error then
        print(chat.header(addon.name):append(chat.error(
            'Unknown command. /floos help lists them all.'
        )));
        return;
    end

    for _, group in ipairs(COMMANDS) do
        print(chat.header(addon.name):append(chat.color1(2, group[1])));
        for _, row in ipairs(group[2]) do
            print(chat.header(addon.name)
                :append(chat.message(row[1]))
                :append('  -  ')
                :append(chat.color1(6, row[2])));
        end
    end
end

--- Point every module at the current settings table and reload state from it.
--- Order matters: bind first, restore second, and never persist in between -
--- persisting before the restore would overwrite the character's saved
--- progress with whatever zeros are in memory.
local function bind_all()
    ui.bind(config.settings, config.editor_open);
    tracker.bind_settings(config.settings);
    tracker.restore_session();

    -- Journal path is per character, so it is only right once we are in game.
    local charname = '';
    pcall(function ()
        charname = AshitaCore:GetMemoryManager():GetParty():GetMemberName(0) or '';
    end);
    journal.flush();
    journal.configure({
        enabled = config.settings.journal.enabled[1],
        path = journal.default_path(charname),
    });
end

-- The settings library swaps to a per-character table at login and back to the
-- global one at logout. Rebinding here is what makes progress survive a relog.
config.on_settings_change = bind_all;

ashita.events.register('load', 'load_cb', function ()
    -- Anything the pre-flight had to mend is said here, once, in red, so a
    -- repair is never something you find out about weeks later.
    for _, line in ipairs(preflight_report or {}) do
        print(chat.header(addon.name):append(chat.error(line)));
    end

    config.ensure_ui_settings();
    config.update_pricing();
    bind_all();

    -- One good copy of the settings file, taken only when the live one looks
    -- healthy. Ashita silently reverts settings to defaults and overwrites
    -- the file if it ever fails to parse, and without this that is the end of
    -- your lifetime totals. /floos restore puts it back.
    do
        local state = backup.check();
        if state == 'wiped' then
            -- Say it loudly and say it once. Ashita's own revert notice goes
            -- past in the load spam, and a wipe found weeks later is a wipe
            -- that cannot be undone.
            print(chat.header(addon.name):append(chat.error(
                'Your settings look like they were reset to defaults.')));
            print(chat.header(addon.name):append(chat.error(
                'A healthy backup exists. To get your data back:')));
            print(chat.header(addon.name):append(chat.message(
                '    /floos restore     then    /addon reload floos')));
            print(chat.header(addon.name):append(chat.color1(6,
                'Nothing has been overwritten - the backup is untouched.')));
        elseif state == 'wiped_no_backup' then
            print(chat.header(addon.name):append(chat.color1(6,
                'Settings look empty. If this is not a new install, check ' ..
                'Windows Previous Versions on the config folder.')));
        else
            backup.backup();
        end
    end

    fonts.prewarm();

    if config.settings.reset_on_load[1] then
        tracker.reset_session();
    end
end);

ashita.events.register('unload', 'unload_cb', function ()
    journal.flush();
    tracker.persist_session();
    ui.cleanup();
    settings.save();
end);

ashita.events.register('command', 'command_cb', function (e)
    local args = e.command:args();
    if #args == 0 then
        return;
    end

    if not args[1]:any('/floos') then
        return;
    end

    e.blocked = true;

    if #args == 1 then
        config.editor_open[1] = not config.editor_open[1];
        return;
    end

    if args[2]:any('help', '?') then
        print_help(false);
        return;
    end

    if args[2]:any('report') then
        print(tracker.build_report(config.settings, config.pricing));
        return;
    end

    -- Flush everything to disk on demand. Worth having before replacing the
    -- addon's files: sessions and zone fatigue counters are written on a ten
    -- second autosave and on unload, so this is the way to be certain the
    -- file on disk is current without unloading first.
    -- The settings file, its backup, and putting the backup back.
    if args[2]:any('backup') then
        local st = backup.status();
        if #args >= 3 and args[3]:any('now') then
            local ok, why = backup.backup();
            print(chat.header(addon.name):append(ok
                and chat.message('Backup written (' .. why .. ').')
                or chat.error('Backup not written: ' .. tostring(why))));
            return;
        end
        print(chat.header(addon.name):append(chat.message(string.format(
            'Settings %d bytes, backup %d bytes.', st.live_bytes, st.backup_bytes))));
        print(chat.header(addon.name):append(chat.color1(6, tostring(st.live_path))));
        print(chat.header(addon.name):append(chat.color1(6,
            '/floos backup now  -  write one   |   /floos restore  -  put it back')));
        return;
    end

    if args[2]:any('restore') then
        local ok, why = backup.restore();
        if ok then
            print(chat.header(addon.name):append(chat.message(
                'Settings restored from backup (' .. why .. ').')));
            print(chat.header(addon.name):append(chat.message(
                'Run:  /addon reload floos')));
        else
            print(chat.header(addon.name):append(chat.error(
                'Restore failed: ' .. tostring(why))));
        end
        return;
    end

    if args[2]:any('save') then
        config.update_pricing();
        tracker.persist_session();
        settings.save();
        print(chat.header(addon.name):append(chat.message(
            'Settings, sessions and zone fatigue saved to disk.')));
        return;
    end

    if args[2]:any('clear') then
        -- Clears the sessions AND the per-zone fatigue counters. Anything
        -- persistent that this command leaves behind is a surprise, and the
        -- zone counters are the only persistent thing it could leave.
        tracker.reset_session('all', true);
        settings.save();
        print(chat.header(addon.name):append(chat.message(
            'All sessions cleared, zone fatigue cleared.')));
        return;
    end

    if args[2]:any('pause', 'resume') then
        -- One command that toggles, so it can go on a macro. An explicit
        -- `pause` or `resume` still forces that direction, for the case
        -- where you cannot see the panel to know which state it is in.
        local act = tracker.active_tab;
        local paused = tracker.is_session_hand_paused(act);
        local want_pause;
        if args[2]:any('resume') then
            want_pause = false;
        elseif #args >= 3 and args[3]:any('on') then
            want_pause = true;
        elseif #args >= 3 and args[3]:any('off') then
            want_pause = false;
        else
            want_pause = not paused;
        end

        if want_pause then
            tracker.pause_session(act);
        else
            tracker.resume_session(act);
        end
        settings.save();
        print(chat.header(addon.name):append(chat.message(
            (want_pause and 'Session paused: ' or 'Session resumed: ')
            .. tostring(tracker.TAB_LABELS[act] or act))));
        return;
    end

    if args[2]:any('rankup') then
        -- Fires the banner so you can see where it lands and how long it
        -- stays without waiting ten hours for a real rank.
        tracker.preview_rank_toast();
        return;
    end

    if args[2]:any('sound', 'sounds') then
        config.ensure_ui_settings();
        local snd = require('libs.sound');
        local cfg = config.settings.sounds;

        if #args >= 3 and args[3]:any('off', 'on') then
            cfg.enabled[1] = args[3]:any('on');
            settings.save();
            print(chat.header(addon.name):append(chat.message(
                'Sound alerts ' .. (cfg.enabled[1] and 'on.' or 'off.'))));
            return;
        end

        if #args >= 3 and args[3]:any('test', 'play') then
            snd.scan();
            local file = (#args >= 4) and args[4] or nil;
            if file == nil then
                -- No name given: play whatever the rank-up slot is set to,
                -- since that is the one you are most likely tuning.
                file = cfg.rank_up[1];
            end
            local ok, why = snd.play(file, true);
            if ok then
                print(chat.header(addon.name):append(chat.message('Played ' .. tostring(file))));
            else
                print(chat.header(addon.name):append(chat.error(
                    'Nothing played: ' .. tostring(why or 'no file set'))));
            end
            return;
        end

        snd.scan();
        print(chat.header(addon.name):append(chat.message(string.format(
            'Sound alerts %s - %d .wav file%s in %s',
            cfg.enabled[1] and 'on' or 'off',
            #snd.files, (#snd.files == 1) and '' or 's', snd.dir()))));
        if snd.scan_error ~= nil then
            print(chat.header(addon.name):append(chat.error(
                'Folder read failed: ' .. tostring(snd.scan_error))));
        end

        for _, row in ipairs({
            { 'rank_up', 'Rank up' }, { 'skill_up', 'Skill up' },
            { 'big_drop', 'Valuable drop' }, { 'fatigue_cap', 'Fatigue cap' },
            { 'clam_ready', 'Clam ready' },
        }) do
            local set = cfg[row[1]] and cfg[row[1]][1] or '';
            local note;
            if set == '' then
                note = 'silent';
            elseif snd.exists(set) then
                note = set;
            else
                note = set .. '  (MISSING)';
            end
            print(chat.header(addon.name):append(chat.color1(6,
                string.format('  %-14s %s', row[2], note))));
        end

        if #snd.files > 0 then
            print(chat.header(addon.name):append(chat.message(
                'Available: ' .. table.concat(snd.files, ', '))));
        else
            print(chat.header(addon.name):append(chat.color1(6,
                'Drop .wav files into that folder, then run this again.')));
        end
        return;
    end

    if args[2]:any('menu') then
        config.ensure_ui_settings();
        local ui_cfg = config.settings.ui;

        if #args >= 3 and args[3]:any('name', 'what', 'which') then
            -- Run this with the menu already open. Ashita commands go through
            -- the chat box, so bind it to a macro if the menu eats input.
            local name = menu.name();
            if not menu.signature_ok() then
                print(chat.header(addon.name):append(chat.error(
                    'Menu signature did not resolve in FFXiMain.dll - this feature is off.'
                )));
                return;
            end
            print(chat.header(addon.name):append(chat.color1(6,
                'Raw bytes: ' .. menu.printable(menu.raw()) .. '   (. = null, _ = space)'
            )));
            if name == '' then
                print(chat.header(addon.name):append(chat.message('No menu open right now.')));
            else
                print(chat.header(addon.name):append(chat.message(string.format(
                    'Menu open: "%s"  (%s)', name,
                    menu.blocking() and 'panel hides for this one' or 'panel stays up for this one'
                ))));
            end
            return;
        end

        if #args >= 3 and args[3]:any('recent', 'seen', 'list') then
            -- The one that actually works: you cannot type while a game menu
            -- is open, so open it, close it, then run this.
            if #menu.recent == 0 then
                print(chat.header(addon.name):append(chat.message(
                    'No menus seen yet. Open one, close it, then run this again.'
                )));
                if not menu.signature_ok() then
                    print(chat.header(addon.name):append(chat.error(
                        'Menu signature did not resolve in FFXiMain.dll.'
                    )));
                end
                return;
            end
            print(chat.header(addon.name):append(chat.message(
                'Menus seen, newest last.  Add one with /floos menu add <name>'
            )));
            local now = os.time();
            for _, e in ipairs(menu.recent) do
                local covered = menu.covers(e.name);
                local note = covered and 'hides panel' or 'stays up';
                if menu.always_ignored(e.name) then
                    note = 'stays up (always - normal play)';
                end
                local line = string.format('%-10s %4ds ago  %-16s %s',
                    (e.name ~= '' and e.name or '(blank)'),
                    now - (e.t or now),
                    tostring(e.shown or '?'),
                    note);
                print(chat.header(addon.name):append(
                    covered and chat.color1(2, line) or chat.color1(6, line)));
            end
            return;
        end

        if #args >= 3 and args[3]:any('add') then
            -- Deliberately does NOT ask for the live menu name. You are typing
            -- when you run this, so the live name is always the chat input
            -- bar - adding that would hide the panel every time you talk.
            local name = (#args >= 4) and args[4]:lower() or nil;
            if name == nil or name == '' then
                -- Take the newest menu we saw that is not already covered,
                -- which is the one you just closed and are complaining about.
                for i = #menu.recent, 1, -1 do
                    local n = menu.recent[i].name;
                    if n ~= '' and not menu.always_ignored(n) and not menu.covers(n) then
                        name = n;
                        break;
                    end
                end
            end
            if name == nil or name == '' then
                print(chat.header(addon.name):append(chat.error(
                    'Nothing to add. Open the menu, close it, then run this.'
                )));
                return;
            end
            if menu.always_ignored(name) then
                print(chat.header(addon.name):append(chat.error(
                    '"' .. name .. '" is open during normal play - hiding for it'
                )));
                print(chat.header(addon.name):append(chat.error(
                    'would make the panel vanish while you type. Refused.'
                )));
                return;
            end
            local already = false;
            for _, v in ipairs(ui_cfg.menu_extra) do
                if v == name then already = true; end
            end
            if not already then
                ui_cfg.menu_extra[#ui_cfg.menu_extra + 1] = name;
            end
            menu.set_extra(ui_cfg.menu_extra);
            settings.save();
            print(chat.header(addon.name):append(chat.message(
                'Panel will now hide for "' .. name .. '".'
            )));
            return;
        end

        if #args >= 3 and args[3]:any('remove', 'drop', 'keep') then
            -- Stops the panel hiding for a menu, built-in ones included.
            -- Same reason as add: never the live name, or this always picks
            -- the chat input bar you are typing into right now.
            local name = (#args >= 4) and args[4]:lower() or nil;
            if name == nil or name == '' then
                for i = #menu.recent, 1, -1 do
                    if menu.covers(menu.recent[i].name) then
                        name = menu.recent[i].name;
                        break;
                    end
                end
            end
            if name == nil or name == '' then
                print(chat.header(addon.name):append(chat.error(
                    'Nothing to remove. Open the menu, close it, then run this.'
                )));
                return;
            end
            if menu.always_ignored(name) then
                print(chat.header(addon.name):append(chat.message(
                    '"' .. name .. '" never hides the panel anyway. Nothing to do.'
                )));
                return;
            end

            -- Drop it from the added list as well, or it would just come back.
            for i = #ui_cfg.menu_extra, 1, -1 do
                if ui_cfg.menu_extra[i] == name then
                    table.remove(ui_cfg.menu_extra, i);
                end
            end
            local already = false;
            for _, v in ipairs(ui_cfg.menu_never) do
                if v == name then already = true; end
            end
            if not already then
                ui_cfg.menu_never[#ui_cfg.menu_never + 1] = name;
            end

            menu.set_extra(ui_cfg.menu_extra);
            menu.set_never(ui_cfg.menu_never);
            settings.save();
            print(chat.header(addon.name):append(chat.message(
                'Panel will stay up for "' .. name .. '".'
            )));
            return;
        end

        if #args >= 3 and args[3]:any('log') then
            local on = not (#args >= 4 and args[4]:any('off'));
            menu.log_enabled = on;
            menu.log_lines = 0;
            print(chat.header(addon.name):append(chat.message(
                'Menu name log ' .. (on and 'on.' or 'off.')
            )));
            if on then
                print(chat.header(addon.name):append(chat.color1(6, menu.log_path())));
            end
            return;
        end

        if #args >= 3 and args[3]:any('clear', 'forget') then
            ui_cfg.menu_extra = T{};
            ui_cfg.menu_never = T{};
            menu.set_extra(ui_cfg.menu_extra);
            menu.set_never(ui_cfg.menu_never);
            settings.save();
            print(chat.header(addon.name):append(chat.message(
                'Menu list back to defaults - additions and removals both.'
            )));
            return;
        end

        local on;
        if #args >= 3 and args[3]:any('on') then on = true;
        elseif #args >= 3 and args[3]:any('off') then on = false;
        else on = not ui_cfg.hide_on_menu[1]; end

        ui_cfg.hide_on_menu[1] = on;
        settings.save();
        print(chat.header(addon.name):append(chat.message(
            'Hide behind map / main menu: ' .. (on and 'on.' or 'off.')
        )));
        return;
    end

    if args[2]:any('show') then
        if config.settings.panels_hidden == nil then
            config.settings.panels_hidden = T{ false };
        end
        config.settings.panels_hidden[1] = false;
        config.settings.tracker.visible[1] = true;
        tracker.touch_activity();
        return;
    end

    if args[2]:any('hide') then
        if config.settings.panels_hidden == nil then
            config.settings.panels_hidden = T{ false };
        end
        config.settings.panels_hidden[1] = true;
        return;
    end

    -- `/floos detail <level>` sets a level outright; `/floos compact`, `mini`
    -- and `full` are the shorthands, and compact/mini toggle back to Full when
    -- you are already on them, so one word switches the panel both ways.
    if args[2]:any('mini', 'compact', 'detail', 'full') then
        config.ensure_ui_settings();
        local ui_cfg = config.settings.ui;
        local current = ui_cfg.detail[1];
        local target = nil;

        if args[2]:any('detail') then
            local want = (#args >= 3) and args[3]:lower() or '';
            if want == 'full' then target = 'Full';
            elseif want == 'compact' then target = 'Compact';
            elseif want == 'mini' then target = 'Mini';
            else
                print(chat.header(addon.name):append(chat.error(
                    'Usage: /floos detail full | compact | mini'
                )));
                return;
            end
        elseif args[2]:any('full') then
            target = 'Full';
        elseif args[2]:any('mini') then
            target = (current == 'Mini') and 'Full' or 'Mini';
        else
            target = (current == 'Compact') and 'Full' or 'Compact';
        end

        ui_cfg.detail[1] = target;
        ui_cfg.compact[1] = (target == 'Compact');
        -- A locked height would leave a big empty box under a smaller panel.
        config.settings.tracker.height[1] = 0;
        settings.save();
        print(chat.header(addon.name):append(chat.message('Panel detail: ' .. target .. '.')));
        return;
    end

    if args[2]:any('auto', 'autoheight') then
        config.settings.tracker.height[1] = 0;
        settings.save();
        print(chat.header(addon.name):append(chat.message('Panel height set to auto.')));
        return;
    end

    if args[2]:any('clam', 'bucket') then
        local s = tracker.sessions and tracker.sessions.clamming or nil;
        if s == nil then
            print(chat.header(addon.name):append(chat.error('No clamming session.')));
            return;
        end
        local cap = s.bucket_capacity or 0;
        if cap <= 0 then cap = 50; end
        local wt = s.bucket_weight or 0;
        local gil = tracker.get_bucket_value(config.pricing);
        local hq = config.settings.clamming and config.settings.clamming.hq_body
            and config.settings.clamming.hq_body[1];
        local risk = tracker.clam_risk(wt, cap, hq);

        print(chat.header(addon.name):append(chat.message(string.format(
            'Bucket: %d / %d pz, worth %s gil. %d pz of room left.',
            wt, cap, tostring(gil), risk.headroom
        ))));

        if risk.break_pct <= 0.001 then
            print(chat.header(addon.name):append(chat.color1(2,
                'Nothing in the pool can break this bucket. Dig away.')));
        else
            local lose = math.floor((gil * risk.break_pct / 100) + 0.5);
            print(chat.header(addon.name):append(chat.color1(6, string.format(
                'Next dig: %.1f%% chance the bucket bursts (%.1f%% too heavy, %.1f%% jumped in).',
                risk.break_pct, risk.overflow_pct, risk.incident_pct
            ))));
            print(chat.header(addon.name):append(chat.color1(6, string.format(
                'That is %s gil at risk on average. Bucket holds %s gil now.',
                tostring(lose), tostring(gil)
            ))));
        end

        if tracker.clam_upgrade_ready(wt, cap) then
            print(chat.header(addon.name):append(chat.color1(2,
                'Heavy enough for an upgrade - hand in for the next bucket size.')));
        end
        if s.bucket_broken then
            print(chat.header(addon.name):append(chat.error(
                'Your bucket is broken. Buy a new kit from Toh Zonikki.')));
        end
        return;
    end

    if args[2]:any('dig', 'daily') then
        local s = tracker.sessions and tracker.sessions.digging or nil;
        if s == nil then
            print(chat.header(addon.name):append(chat.error('No digging session.')));
            return;
        end
        tracker.roll_dig_day(s);

        if #args >= 3 then
            if args[3]:any('reset', 'clear', 'zero') then
                s.daily_items = 0;
            else
                local n = tonumber(args[3]);
                if n == nil or n < 0 then
                    print(chat.header(addon.name):append(chat.error(
                        'Usage: /floos dig <number of items dug today> | reset'
                    )));
                    return;
                end
                s.daily_items = math.floor(n);
            end
            tracker.persist_session();
            settings.save();
        end

        local vana = require('libs.vana');
        local cap = tracker.dig_daily_cap(config.settings);
        local left = math.max(0, cap - (s.daily_items or 0));
        local secs = vana.seconds_until_jst_midnight();
        print(chat.header(addon.name):append(chat.message(string.format(
            'Dug today: %d / %d  (%d left).', s.daily_items or 0, cap, left
        ))));
        print(chat.header(addon.name):append(chat.color1(6, string.format(
            'Resets in %dh %02dm, at midnight Japan time - 6PM in Kuwait.',
            math.floor(secs / 3600), math.floor((secs % 3600) / 60)
        ))));
        return;
    end

    if args[2]:any('ore', 'orewatch') then
        local ore = tracker.ore_conditions(config.settings);

        local head;
        if ore.verdict == 'yes' then
            head = 'Ore window is OPEN'
                .. (ore.element and (' - digging can turn up ' .. ore.element .. ' Ore today.') or '.');
        elseif ore.verdict == 'maybe' then
            head = 'Cannot say yet - ' .. table.concat(ore.unknowns, ', ')
                .. ' still unknown. Nothing else is blocking.';
        else
            head = 'No ore right now. Blocked by: ' .. table.concat(ore.blockers, ', ') .. '.';
        end
        print(chat.header(addon.name):append(chat.message(head)));

        for _, c in ipairs(ore.conds) do
            local mark = (c.ok == true) and 'OK  ' or ((c.ok == false) and 'NO  ' or '??  ');
            local line = string.format('%s%-8s %s', mark, c.label, c.detail or '');
            if c.ok ~= true then
                line = line .. '   (need: ' .. (c.want or '?') .. ')';
            end
            if c.key == 'moon' and ore.moon_days ~= nil and ore.moon_days > 0 then
                line = line .. string.format('   opens in %d Vana days', ore.moon_days);
            end
            if c.ok == true then
                print(chat.header(addon.name):append(chat.color1(2, line)));
            else
                print(chat.header(addon.name):append(chat.color1(6, line)));
            end
        end

        if ore.day ~= nil then
            print(chat.header(addon.name):append(chat.color1(6, string.format(
                'Today is %s, so any ore found would be %s Ore. Rate is about 5 in 1120 digs.',
                ore.day, ore.element or '?'))));
        end
        return;
    end

    --[[
        /floos global - the counter that follows you between zones.

        on | off        the feature
        protect on|off  whether /floos clear may wipe it
        set <n>         put it at n, for a test
        reset           empty it (explicit, so protection does not apply)
        (nothing)       what it holds
    --]]
    if args[2]:any('global', 'glob') then
        local f = config.settings.fatigue;
        if #args >= 3 and args[3]:any('on', 'off') then
            f.global_on[1] = args[3]:any('on');
            settings.save();
            print(chat.header(addon.name):append(chat.message(
                f.global_on[1]
                    and 'Global fatigue on. It climbs in the zone you are working and every hit anywhere else takes one off.'
                    or 'Global fatigue off. The counter is kept, just not shown or moved.')));
            return;
        end
        if #args >= 4 and args[3]:any('protect', 'protected', 'lock') then
            f.global_protect[1] = args[4]:any('on', 'yes', 'true');
            settings.save();
            print(chat.header(addon.name):append(chat.message(
                f.global_protect[1]
                    and 'Protected: /floos clear leaves the global counter alone.'
                    or 'Unprotected: /floos clear will wipe the global counter too.')));
            return;
        end
        if #args >= 4 and args[3]:any('set') then
            local n = tonumber(args[4]);
            if n == nil then
                print(chat.header(addon.name):append(chat.error('Usage: /floos global set <number>')));
                return;
            end
            local act = tracker.active_tab or 'mining';
            if tracker.global_fatigue_set(act, n) then
                print(chat.header(addon.name):append(chat.message(string.format(
                    'Global fatigue for %s set to %d%s.', act, n,
                    (n > 0) and ', home is the zone you are standing in' or ' and the home zone forgotten'))));
            end
            return;
        end
        if #args >= 3 and args[3]:any('reset', 'clear') then
            tracker.global_fatigue_clear((#args >= 4) and args[4] or 'all');
            print(chat.header(addon.name):append(chat.message('Global fatigue emptied.')));
            return;
        end
        for _, line in ipairs(tracker.global_fatigue_report()) do
            print(chat.header(addon.name):append(chat.message(line)));
        end
        return;
    end

    if args[2]:any('fatigue', 'fat') then
        if #args >= 3 and args[3]:any('reset', 'now') then
            tracker.fatigue_reset(true);
            settings.save();
            print(chat.header(addon.name):append(chat.message(
                'Fatigue reset recorded. Confidence: ' .. tracker.fatigue_confidence() .. '.'
            )));
            return;
        end
        if #args >= 3 and args[3]:any('forget', 'clear') then
            config.settings.fatigue.observations = T{};
            settings.save();
            print(chat.header(addon.name):append(chat.message('Fatigue schedule forgotten.')));
            return;
        end

        local left = tracker.fatigue_time_left();
        if left == nil then
            print(chat.header(addon.name):append(chat.message(
                'No reset seen yet. Gather past the cap once and it learns, or use /floos fatigue reset.'
            )));
        else
            local fmt = require('libs.format');
            print(chat.header(addon.name):append(chat.message(string.format(
                'Next fatigue reset in %s (confidence: %s).',
                fmt.format_duration(left), tracker.fatigue_confidence()
            ))));
        end
        return;
    end

    if args[2]:any('prices', 'price') then
        if #args >= 3 and args[3]:any('fetch', 'psxi', 'update') then
            print(chat.header(addon.name):append(chat.message(
                'Asking psxi.gg for prices - the game will hitch for a moment.'
            )));
            -- Second return is the snapshot timestamp on success, the reason
            -- on failure.
            local token = config.settings.psxi_token;
            local updated, info = config.fetch_prices(token and token[1] or '');
            if updated == nil then
                print(chat.header(addon.name):append(chat.error(info)));
                return;
            end
            settings.save();
            print(chat.header(addon.name):append(chat.message(string.format(
                '%d prices updated from psxi.gg%s.', updated,
                info ~= nil and (' (snapshot ' .. tostring(info) .. ')') or ''
            ))));
            return;
        end
        if #args >= 3 and args[3]:any('token', 'key') then
            if config.settings.psxi_token == nil then
                config.settings.psxi_token = T{ '' };
            end
            config.settings.psxi_token[1] = (#args >= 4) and args[4] or '';
            settings.save();
            print(chat.header(addon.name):append(chat.message(
                config.settings.psxi_token[1] == ''
                    and 'psxi.gg token cleared.'
                    or 'psxi.gg token saved.'
            )));
            return;
        end
        if #args >= 3 and args[3]:any('import', 'load') then
            local fname = (#args >= 4) and args[4] or 'prices.txt';
            local path = fname;
            if not fname:match('^%a:[/\\]') and not fname:match('^[/\\]') then
                path = config.prices_dir() .. '/' .. fname;
            end
            local f = io.open(path, 'r');
            if f == nil then
                print(chat.header(addon.name):append(chat.error('Cannot open ' .. path)));
                print(chat.header(addon.name):append(chat.message(
                    'Expected one "name:price" per line, e.g. chunk of iron ore:650'
                )));
                return;
            end
            local lines = {};
            for line in f:lines() do
                lines[#lines + 1] = line;
            end
            f:close();
            local updated, added, skipped = config.merge_prices(lines);
            settings.save();
            print(chat.header(addon.name):append(chat.message(string.format(
                'Prices imported: %d updated, %d added, %d skipped.', updated, added, skipped
            ))));
            return;
        end
        local count = 0;
        for _ in pairs(config.pricing) do count = count + 1; end
        print(chat.header(addon.name):append(chat.message(string.format(
            '%d items priced. Import more: /floos prices import <file>', count
        ))));
        return;
    end

    if args[2]:any('insights', 'insight', 'stats') then
        local insights = require('libs.insights');
        local act = tracker.active_tab or 'mining';
        if #args >= 3 then
            local want = args[3]:lower();
            if want:any('mining', 'mine') then act = 'mining';
            elseif want:any('logging', 'logg', 'log') then act = 'logging';
            elseif want:any('harvest', 'harv') then act = 'harvest';
            elseif want:any('excavate', 'exca') then act = 'excavate';
            elseif want:any('fishing', 'fish') then act = 'fishing';
            elseif want:any('digging', 'dig') then act = 'digging';
            end
        end

        journal.flush();  -- so the analysis includes the last few swings
        -- The journal resolves its own file from the character name, lazily
        -- and safely; asking for the name here again was the bug.
        local a = insights.analyze(journal.current_path(), act);
        for _, line in ipairs(insights.report_lines(a, act)) do
            print(chat.header(addon.name):append(chat.message(line)));
        end
        return;
    end

    if args[2]:any('debug', 'diag') then
        if #args >= 3 and args[3]:any('on', 'off') then
            tracker.debug_echo = args[3]:any('on');
            print(chat.header(addon.name):append(chat.message(
                'Live debug echo ' .. (tracker.debug_echo and 'on.' or 'off.')
            )));
            return;
        end

        local id, name = tracker.refresh_zone();
        print(chat.header(addon.name):append(chat.message(string.format(
            'Zone: %s (%d)   Tab: %s   Awaiting: %s',
            name or 'Unknown', id or 0, tostring(tracker.active_tab),
            tostring(tracker.awaiting or 'nothing')
        ))));

        do
            local wlib = require('libs.weather');
            local wx = wlib.current();
            print(chat.header(addon.name):append(chat.message(string.format(
                'Weather: %s%s',
                wx.known and wx.name or 'unreadable',
                wx.known and string.format('  (%s, via %s)',
                    wx.elemental and wx.element or 'no element', wx.source or '?') or ''
            ))));
            if not wlib.signature_ok() then
                print(chat.header(addon.name):append(chat.error(
                    'Weather signature did not resolve in FFXiMain.dll - falling back'
                )));
                print(chat.header(addon.name):append(chat.error(
                    'to packets, which means it fills in the next time you zone.'
                )));
            end
        end

        local log = tracker.debug_log or {};
        if #log == 0 then
            print(chat.header(addon.name):append(chat.error(
                'Nothing seen yet. If you are gathering and this stays empty, the'
            )));
            print(chat.header(addon.name):append(chat.error(
                'addon is not seeing the trade at all - check the addon is loaded.'
            )));
            return;
        end

        local now = os.time();
        for _, entry in ipairs(log) do
            print(chat.header(addon.name)
                :append(chat.color1(6, string.format('%4ds ago  ', now - (entry.t or now))))
                :append(chat.message(string.format('%-8s %s', entry.kind, entry.detail))));
        end
        return;
    end

    -- Per-item rate by zone. Asked for by Itmejammy: how common is Khroma,
    -- as a share of all swings, broken down by where you were standing.
    -- Babs: "can you make a toggle so it doesn't automatically pop up when
    -- you go to mine". Two separate behaviours, two separate switches.
    -- NOT called "auto": /floos auto already releases the locked panel
    -- height, and it is registered earlier in this handler - so an "auto"
    -- here would never run. That is precisely how /floos zones lost its
    -- lifetime ranking once already.
    if args[2]:any('follow', 'popup', 'autotab') then
        local t = config.settings.tracker;
        local word = args[2]:lower();
        local which = (#args >= 3) and args[3]:lower() or nil;
        if word == 'popup' then
            if which == 'on' then t.auto_show[1] = true;
            elseif which == 'off' then t.auto_show[1] = false;
            else t.auto_show[1] = not t.auto_show[1]; end
        else
            if which == 'on' then t.auto_switch_tab[1] = true;
            elseif which == 'off' then t.auto_switch_tab[1] = false;
            else t.auto_switch_tab[1] = not t.auto_switch_tab[1]; end
        end
        settings.save();
        print(chat.header(addon.name):append(chat.message(string.format(
            'Follow activity: %s.   Pop up when active: %s.',
            t.auto_switch_tab[1] and 'on' or 'off',
            t.auto_show[1] and 'on' or 'off'))));
        print(chat.header(addon.name):append(chat.color1(6,
            '/floos follow  - tab follows the activity.   ' ..
            '/floos popup  - panel appears when you start.')));
        return;
    end

    -- No 'ore' alias here: /floos ore is the elemental ore window and is
    -- registered earlier, so an alias would be dead code - and worse,
    -- /floos ore iron would quietly answer a different question.
    if args[2]:any('item', 'items', 'rate') then
        if #args < 3 then
            print(chat.header(addon.name):append(chat.message(
                'Usage: /floos item <name>   e.g. /floos item khroma')));
            return;
        end
        local q = table.concat({ unpack(args, 3) }, ' ');
        for _, line in ipairs(tracker.item_rate_report(q, nil)) do
            print(chat.header(addon.name):append(chat.message(line)));
        end
        return;
    end

    -- Everything per-zone lives under one command, because "zones" is what
    -- you type whichever of the two you are after: the lifetime ranking of
    -- where you have earned, and today's fatigue counters.
    if args[2]:any('zones', 'zonetrack', 'zonefatigue', 'zf') then
        local want_fatigue = args[2]:any('zonefatigue', 'zf');

        if #args >= 3 and args[3]:any('clear', 'reset') then
            if want_fatigue then
                tracker.zone_fatigue_clear_all();
                settings.save();
                print(chat.header(addon.name):append(chat.message(
                    'Zone fatigue counters cleared. Lifetime history kept.')));
            else
                tracker.clear_zone_stats();
                settings.save();
                print(chat.header(addon.name):append(chat.message(
                    'Lifetime zone history cleared. Fatigue counters kept.')));
            end
            return;
        end

        -- The lifetime ranking first: it is the older report and the one
        -- most people mean. /floos zf skips straight to the counters.
        if not want_fatigue then
            print(tracker.build_zone_report(config.settings, tracker.active_tab));
        end

        for _, line in ipairs(tracker.zone_fatigue_report()) do
            print(chat.header(addon.name):append(chat.message(line)));
        end
        if not want_fatigue then
            print(chat.header(addon.name):append(chat.color1(6,
                '/floos zones clear  wipes the lifetime ranking above.')));
            print(chat.header(addon.name):append(chat.color1(6,
                '/floos zf clear     wipes only the fatigue counters.')));
        end
        return;
    end

    print_help(true);
end);

ashita.events.register('packet_out', 'packet_out_cb', function (e)
    tracker.handle_packet_out(e);
end);

ashita.events.register('packet_in', 'packet_in_cb', function (e)
    tracker.handle_packet_in(e);
end);

ashita.events.register('text_in', 'text_in_cb', function (e)
    tracker.handle_text(e, config.pricing);
end);

ashita.events.register('d3d_present', 'present_cb', function ()
    if not AshitaCore:GetFontManager():GetVisible() then
        return;
    end

    ui.present_frame_start();
    tracker.tick_autosave();
    -- Keeps the backup within five minutes of the live file. Rate limited
    -- inside, so this is a clock read per frame and a file copy per five
    -- minutes.
    backup.refresh();
    tracker.tick_alerts(config.settings);

    -- The config window pushes its own font and scale (it has a size of its
    -- own, independent of the panels), so it is rendered outside the push
    -- below rather than being left at ImGui's default as it once was.
    config.render_editor();

    fonts.push(config.settings);

    -- Full-screen game menus own the screen while they are up. Checked once
    -- per frame - it is a pointer walk, not a scan - and it fails open, so a
    -- signature that stops resolving leaves the panel visible rather than
    -- making it vanish for good. observe() runs even when the feature is off,
    -- so the name history is there for /floos menu recent either way.
    local menu_blocking = menu.observe();
    if config.settings.ui == nil
        or config.settings.ui.hide_on_menu == nil
        or not config.settings.ui.hide_on_menu[1] then
        menu_blocking = false;
    end

    if config.panels_are_shown() and not menu_blocking then
        tracker.render(config.settings, config.pricing, config.editor_open[1] and config.settings.tracker.visible[1]);
    end

    -- Outside the panels_are_shown gate on purpose: a rank arrives six times
    -- in a career and should not be swallowed because the panel is hidden.
    tracker.render_rank_toast(config.settings);


    fonts.pop();
end);
