--[[
* Floos - sound alerts.
*
* Plays a .wav from the addon's own sounds/ folder when something worth
* looking up for happens.
*
* No audio ships with the addon, deliberately. The folder starts empty and
* whatever you drop in it becomes selectable in the config - so the sounds
* are yours, and nothing here redistributes anyone else's audio.
]]--

require('common');

local M = {};

--- Files found in sounds/, sorted. Populated by scan().
M.files = T{};
M.scanned = false;
M.scan_error = nil;

--- Two alerts inside this window would just be noise on top of noise -
--- a rank-up arrives in the same instant as the skill-up that caused it.
local MIN_GAP_MS = 400;
M.last_play_ms = 0;

--- Where the .wav files live.
function M.dir()
    local base = nil;
    pcall(function ()
        base = (addon and addon.path) or nil;
    end);
    if base == nil or base == '' then
        return 'sounds\\';
    end
    return (tostring(base):gsub('[/\\]+$', '')) .. '\\sounds\\';
end

--- True if the named file is actually there. Ashita's play_sound is happy
--- to be handed a missing path and simply does nothing, so this is what
--- lets the config say "missing" instead of the feature seeming broken.
---@param file string
---@return boolean
function M.exists(file)
    if file == nil or file == '' then return false; end
    local ok, present = pcall(function ()
        local f = io.open(M.dir() .. file, 'rb');
        if f == nil then return false; end
        f:close();
        return true;
    end);
    return ok and present or false;
end

--- Read the folder. Uses a directory listing because Lua has no readdir and
--- Ashita exposes none either; it runs once at load and on demand, never
--- per frame, because it spawns a shell.
function M.scan()
    M.files = T{};
    M.scan_error = nil;

    local ok, err = pcall(function ()
        local cmd = string.format('dir "%s" /b', (M.dir():gsub('\\+$', '')));
        local pipe = io.popen(cmd);
        if pipe == nil then
            M.scan_error = 'could not read the sounds folder';
            return;
        end
        for line in pipe:lines() do
            local name = tostring(line):match('^%s*(.-)%s*$');
            if name ~= nil and name ~= '' and name:lower():match('%.wav$') then
                M.files[#M.files + 1] = name;
            end
        end
        pipe:close();
    end);

    if not ok then
        M.scan_error = tostring(err);
    end

    table.sort(M.files, function (a, b) return a:lower() < b:lower(); end);
    M.scanned = true;
    return M.files;
end

--- Milliseconds, only used for the throttle. Deliberately its own small
--- clock rather than a reach into the tracker: this library has no other
--- reason to know about the tracker, and the composed-clock bug that made
--- the banners blink came from exactly that kind of shared timing code.
local last_seen = 0;
local function now_ms()
    local out = nil;
    local ok, c = pcall(os.clock);
    if ok and type(c) == 'number' then
        out = math.floor(c * 1000);
    else
        out = os.time() * 1000;
    end
    if out < last_seen then out = last_seen; end
    last_seen = out;
    return out;
end

--- Play a file by name. Returns false when there was nothing to play, so a
--- caller can say why rather than failing silently.
---@param file string
---@param force boolean|nil  skip the throttle (the config's Test button)
---@return boolean, string|nil
function M.play(file, force)
    if file == nil or file == '' then
        return false, 'no file set';
    end
    if not force then
        local t = now_ms();
        if (t - M.last_play_ms) < MIN_GAP_MS then
            return false, 'throttled';
        end
        M.last_play_ms = t;
    end
    if not M.exists(file) then
        return false, 'file not found: ' .. tostring(file);
    end

    local ok = pcall(function ()
        ashita.misc.play_sound(M.dir() .. file);
    end);
    if not ok then
        return false, 'play_sound failed';
    end
    return true, nil;
end

--- Play whatever is configured for an event key.
---@param settings table  the addon settings table
---@param key string      'rank_up' | 'skill_up' | 'big_drop' | 'fatigue_cap'
---@return boolean
function M.event(settings, key)
    if settings == nil or settings.sounds == nil then
        return false;
    end
    local s = settings.sounds;
    if s.enabled == nil or not s.enabled[1] then
        return false;
    end
    local slot = s[key];
    if slot == nil then
        return false;
    end
    local file = slot[1];
    if file == nil or file == '' then
        return false;
    end
    return (M.play(file));
end

--- Step to the next discovered file, for the config's cycle button. Wraps
--- around, and the first press from an unset slot picks the first file.
---@param current string|nil
---@param step number|nil  1 forward, -1 back
---@return string
function M.next_file(current, step)
    if not M.scanned then M.scan(); end
    step = step or 1;

    local n = #M.files;
    if n == 0 then
        return '';
    end

    -- '' is a real choice (the event stays silent), so the ring the buttons
    -- walk is the files plus that empty slot at the end.
    local idx = 0;   -- 0 means "none"
    for i, f in ipairs(M.files) do
        if f == current then idx = i; break; end
    end

    local next_idx = idx + step;
    if next_idx > n then next_idx = 0; end
    if next_idx < 0 then next_idx = n; end
    if next_idx == 0 then return ''; end
    return M.files[next_idx];
end

return M;
