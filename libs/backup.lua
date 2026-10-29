--[[
* floos - settings backup
*
* Ashita's settings library reverts to defaults and OVERWRITES the file if it
* ever fails to parse one:
*
*     "Settings have been reverted to default values."
*
* That is one truncated write, one bad character, or one addon left in a
* half-installed state away from losing every lifetime total, every price and
* every zone counter you have. There is no undo and no second copy.
*
* So this keeps one. On load, once the settings have come back and been
* sanity-checked, the live file is copied to settings.bak.lua beside it. The
* copy is only ever taken from a file that looked healthy, so a wipe cannot
* propagate into the backup on the next start.
*
* Restore with /floos restore, which puts the backup back and reloads.
]]--

require('common');
local settings = require('settings');

local M = {};

local function dir()
    local p = nil;
    pcall(function () p = settings.settings_path(); end);
    return p;
end

function M.live_path()
    local d = dir();
    if d == nil then return nil; end
    return d .. 'settings.lua';
end

function M.backup_path()
    local d = dir();
    if d == nil then return nil; end
    return d .. 'settings.bak.lua';
end

local function read_all(path)
    local out = nil;
    pcall(function ()
        local f = io.open(path, 'rb');
        if f == nil then return; end
        out = f:read('*all');
        f:close();
    end);
    return out;
end

local function write_all(path, data)
    local ok = false;
    pcall(function ()
        local f = io.open(path, 'wb');
        if f == nil then return; end
        f:write(data);
        f:close();
        ok = true;
    end);
    return ok;
end

--- Does this look like a real settings file rather than a fresh default one?
---
--- The test is deliberately about SIZE and SHAPE rather than content: a file
--- Ashita has just reverted is small and has no lifetime block, while a real
--- one carries hundreds of lines of history. Backing up a reverted file would
--- destroy the only good copy, so when in doubt this says no.
---@param data string
---@return boolean
local function looks_healthy(data)
    if data == nil or #data < 400 then return false; end
    if data:find('return settings', 1, true) == nil then return false; end
    -- Any one of these means real accumulated data rather than defaults.
    return data:find('lifetime', 1, true) ~= nil
        or data:find('zstats', 1, true) ~= nil
        or data:find('helm', 1, true) ~= nil;
end

--- Take a backup, if the live file is worth backing up.
---@return boolean, string  taken, reason
function M.backup()
    local live, bak = M.live_path(), M.backup_path();
    if live == nil or bak == nil then
        return false, 'no settings path';
    end

    local data = read_all(live);
    if data == nil then
        return false, 'no settings file yet';
    end
    if not looks_healthy(data) then
        return false, 'settings file looks empty or freshly reset - not overwriting the backup';
    end

    -- Never replace a larger backup with a smaller live file without saying
    -- so. Shrinkage is the signature of the exact failure this exists for.
    local old = read_all(bak);
    if old ~= nil and #old > (#data * 2) then
        return false, string.format(
            'live settings (%d bytes) are far smaller than the backup (%d) - backup kept',
            #data, #old);
    end

    if write_all(bak, data) then
        return true, string.format('%d bytes', #data);
    end
    return false, 'could not write the backup';
end

--- Put the backup back. The addon must be reloaded afterwards; the caller
--- does that so this stays a file operation and nothing more.
---@return boolean, string
function M.restore()
    local live, bak = M.live_path(), M.backup_path();
    if live == nil or bak == nil then
        return false, 'no settings path';
    end

    local data = read_all(bak);
    if data == nil then
        return false, 'no backup found at ' .. tostring(bak);
    end
    if not looks_healthy(data) then
        return false, 'the backup does not look like a valid settings file';
    end

    -- Keep whatever is there now, so restoring is itself undoable.
    local cur = read_all(live);
    if cur ~= nil then
        write_all(dir() .. 'settings.before-restore.lua', cur);
    end

    if write_all(live, data) then
        return true, string.format('%d bytes restored', #data);
    end
    return false, 'could not write the settings file';
end

--- What state the settings are in, checked on load.
---
--- The point is that a wipe announces itself. Ashita's own revert message
--- scrolls past in a wall of load spam, and without this you find out weeks
--- later when you notice your lifetime gil is zero - by which time the
--- backup may have been taken over the top of the loss on some later start.
---
---@return string reason  'ok' | 'fresh' | 'wiped' | 'wiped_no_backup'
function M.check()
    local live, bak = M.live_path(), M.backup_path();
    if live == nil then return 'fresh'; end

    local ld = read_all(live);
    if ld == nil then return 'fresh'; end

    if looks_healthy(ld) then
        return 'ok';
    end

    -- The live file is small or shapeless. If there is a healthy backup, this
    -- is a wipe and not a first run.
    local bd = bak and read_all(bak) or nil;
    if bd ~= nil and looks_healthy(bd) then
        return 'wiped';
    end
    -- No backup to compare against. A genuinely new install looks the same as
    -- a wipe, so say the weaker thing.
    if #ld > 0 and #ld < 400 then
        return 'wiped_no_backup';
    end
    return 'fresh';
end

----------------------------------------------------------------------
-- Pre-flight: catch the wipe BEFORE it happens
----------------------------------------------------------------------
--
-- Everything above is after-the-fact: it notices a file that has already
-- been reverted and asks the player to restore. That leaves two holes.
--
--   The original is gone. Ashita overwrites the unparseable file with the
--   defaults, so by the time check() runs there is nothing left to repair
--   and nothing to learn what went wrong from.
--
--   The wrong folder. Ashita loads addons before you log in, when the
--   settings path points at 'defaults'. The character's own file is only
--   opened at login, by the library's packet handler, which runs before
--   ours. A crash mid-write last session leaves that file truncated, and it
--   is reverted the moment you log in with nobody watching.
--
-- So this runs FIRST, before the settings library has parsed anything, and
-- looks at every settings file this addon owns - every character folder and
-- defaults. Any file that will not parse is copied aside as evidence, then
-- repaired if it can be, or restored from its backup if not. Ashita then
-- loads a good file and never gets the chance to revert.
--
-- WHY REPAIR WORKS
-- The library writes one statement per line and ends with 'return settings;'.
-- The realistic corruption is a truncated write - the game died while the
-- file was half out - which leaves a partial last line and no return. Drop
-- lines off the end until what is left parses, put the return back, and
-- everything up to the moment of the crash comes back. A file that was
-- truncated to nothing cannot be repaired that way and falls to the backup.

--- Does this text parse as a settings file and return a table?
---@param text string
---@return boolean ok, string|nil err
local function parses(text)
    if text == nil then return false, 'no data'; end
    local chunk, err = loadstring(text, '=settings');
    if chunk == nil then return false, tostring(err); end
    local ok, result = pcall(chunk);
    if not ok then return false, tostring(result); end
    if type(result) ~= 'table' then return false, 'did not return a table'; end
    return true, nil;
end

--- Try to bring a truncated file back by trimming its tail.
---@param text string
---@return string|nil repaired, number dropped  nil if it cannot be saved
local function repair(text)
    if text == nil or #text == 0 then return nil, 0; end
    local lines = {};
    for line in (text .. '\n'):gmatch('([^\n]*)\n') do lines[#lines + 1] = line; end
    -- The return line, if present, is not data; drop it and re-add it.
    while #lines > 0 and (lines[#lines]:match('^%s*$') or lines[#lines]:match('^%s*return settings;%s*$')) do
        lines[#lines] = nil;
    end
    local dropped = 0;
    -- 200 lines is far more than any single write could leave half done,
    -- and keeps this from eating a file that is simply not a settings file.
    while #lines > 3 and dropped <= 200 do
        local candidate = table.concat(lines, '\n') .. '\nreturn settings;\n';
        if parses(candidate) and looks_healthy(candidate) then
            return candidate, dropped;
        end
        lines[#lines] = nil;
        dropped = dropped + 1;
    end
    return nil, dropped;
end

M.parses = parses;
M.repair = repair;

--- Every folder that could hold a settings file for this addon.
local function settings_folders()
    local out = {};
    pcall(function ()
        local base = ('%s\\config\\addons\\%s\\'):fmt(AshitaCore:GetInstallPath(), addon.name);
        local p = io.popen('dir /b /ad "' .. base .. '" 2>nul');
        if p == nil then return; end
        for line in p:lines() do
            line = tostring(line):gsub('%s+$', '');
            if line ~= '' then out[#out + 1] = base .. line .. '\\'; end
        end
        p:close();
    end);
    return out;
end

--- Check every settings file this addon owns and mend any that would be
--- reverted. Call BEFORE the settings library is asked to load anything.
---@return table  one report line per file that needed attention
function M.preflight()
    local report = {};
    for _, folder in ipairs(settings_folders()) do
        local live = folder .. 'settings.lua';
        local data = read_all(live);
        if data ~= nil then
            local ok, err = parses(data);
            if not ok then
                local who = folder:match('([^\\]+)\\$') or folder;
                -- Evidence first. Never overwrite an earlier corrupt copy.
                local stamp = os.date('%Y%m%d-%H%M%S');
                local evidence = folder .. ('settings.corrupt-%s.lua'):fmt(stamp);
                write_all(evidence, data);

                local fixed, dropped = repair(data);
                if fixed ~= nil then
                    write_all(live, fixed);
                    report[#report + 1] = ('%s: settings file was damaged (%s). Repaired - %d broken line%s dropped, everything else kept. Damaged copy saved as %s'):fmt(
                        who, err:gsub('^.-:%d+: ', ''), dropped, dropped == 1 and '' or 's', evidence:match('[^\\]+$'));
                else
                    local bd = read_all(folder .. 'settings.bak.lua');
                    if bd ~= nil and parses(bd) and looks_healthy(bd) then
                        write_all(live, bd);
                        report[#report + 1] = ('%s: settings file was damaged beyond repair (%s). Restored from backup. Damaged copy saved as %s'):fmt(
                            who, err:gsub('^.-:%d+: ', ''), evidence:match('[^\\]+$'));
                    else
                        report[#report + 1] = ('%s: settings file is damaged (%s) and there is no backup. Ashita will reset it. The damaged copy is saved as %s - keep it.'):fmt(
                            who, err:gsub('^.-:%d+: ', ''), evidence:match('[^\\]+$'));
                    end
                end
            end
        end
    end
    return report;
end

----------------------------------------------------------------------
-- Keep the backup current
----------------------------------------------------------------------
--
-- A backup taken only at load is a backup of the START of the session.
-- Everything gathered since lives in one file, and if that file is the one
-- that gets truncated, a whole night is gone. So after the addon's own
-- periodic save the backup is refreshed too - rate limited, written to a
-- temporary name and renamed into place so the backup itself can never be
-- left half written.

local last_refresh = 0;
local REFRESH_EVERY = 300;   -- seconds

--- Refresh the backup from the live file if it is healthy and enough time
--- has passed. Cheap enough to call after every save.
function M.refresh()
    local now = os.time();
    if (now - last_refresh) < REFRESH_EVERY then return false; end
    last_refresh = now;

    local live, bak = M.live_path(), M.backup_path();
    if live == nil or bak == nil then return false; end
    local data = read_all(live);
    if data == nil or not looks_healthy(data) or not parses(data) then return false; end

    local old = read_all(bak);
    if old ~= nil and #old > (#data * 2) then return false; end

    local tmp = bak .. '.tmp';
    if not write_all(tmp, data) then return false; end
    pcall(function () os.remove(bak); end);
    local ok = pcall(function ()
        local r = os.rename(tmp, bak);
        if not r then error('rename failed'); end
    end);
    if not ok then
        -- Fall back to a direct write rather than leave no backup at all.
        write_all(bak, data);
        pcall(function () os.remove(tmp); end);
    end
    return true;
end

--- Where the files are and how big, for the status command.
function M.status()
    local live, bak = M.live_path(), M.backup_path();
    local ld = live and read_all(live) or nil;
    local bd = bak and read_all(bak) or nil;
    return {
        live_path = live,
        backup_path = bak,
        live_bytes = ld and #ld or 0,
        backup_bytes = bd and #bd or 0,
        healthy = ld ~= nil and looks_healthy(ld),
    };
end

return M;
