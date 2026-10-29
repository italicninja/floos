--[[
* Floos - session journal
*
* One JSON line per swing, appended to a file. That is the whole feature, and
* it is the foundation for every question the panel cannot answer: does moon
* phase matter, does the day of the week matter, what is your real drop rate
* with a confidence interval, when do you actually play well.
*
* Writes are buffered and flushed on a timer, so a swing never costs a disk
* round trip inside the render loop.
]]--

require('common');

local M = {};

M.FLUSH_LINES = 12;
M.FLUSH_SECS = 20;
M.MAX_BYTES = 32 * 1024 * 1024;   -- refuse to grow past this

M.enabled = false;
M.path = nil;
M.buffer = {};
M.last_flush = 0;
M.written = 0;
M.dropped = 0;
M.bytes = 0;
M.error = nil;

local function now()
    local ok, t = pcall(os.time);
    if ok and type(t) == 'number' then
        return t;
    end
    return 0;
end

----------------------------------------------------------------------
-- Minimal JSON encoding for flat records
----------------------------------------------------------------------

local ESCAPES = {
    ['"'] = '\\"', ['\\'] = '\\\\', ['\b'] = '\\b',
    ['\f'] = '\\f', ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t',
};

local function esc(s)
    s = tostring(s);
    s = s:gsub('[%c"\\]', function (c)
        local e = ESCAPES[c];
        if e ~= nil then
            return e;
        end
        return string.format('\\u%04x', string.byte(c));
    end);
    return s;
end

local function encode_value(v)
    local t = type(v);
    if v == nil then
        return 'null';
    elseif t == 'boolean' then
        return v and 'true' or 'false';
    elseif t == 'number' then
        if v ~= v or v == math.huge or v == -math.huge then
            return 'null';
        end
        if math.floor(v) == v and math.abs(v) < 1e15 then
            return string.format('%d', v);
        end
        return string.format('%.4f', v);
    end
    return '"' .. esc(v) .. '"';
end

--- Encode a flat table as a JSON object. Key order is fixed by `order` so the
--- file stays diffable and greppable instead of shuffling every line.
function M.encode(record, order)
    local parts = T{};
    local seen = {};
    local function put(k)
        local v = record[k];
        if v == nil or seen[k] then
            return;
        end
        seen[k] = true;
        parts:append('"' .. esc(k) .. '":' .. encode_value(v));
    end
    if order ~= nil then
        for _, k in ipairs(order) do
            put(k);
        end
    end
    local rest = {};
    for k, _ in pairs(record) do
        if not seen[k] then
            rest[#rest + 1] = k;
        end
    end
    table.sort(rest);
    for _, k in ipairs(rest) do
        put(k);
    end
    return '{' .. table.concat(parts, ',') .. '}';
end

M.FIELD_ORDER = {
    't', 'act', 'outcome', 'item', 'qty', 'gil',
    'zone', 'zone_id', 'skill', 'skill_gain', 'skillup',
    'fatigue', 'cap', 'swing', 'tools',
    'moon', 'moon_pct', 'day', 'vana_hour', 'weather', 'char',
};

----------------------------------------------------------------------
-- File handling
----------------------------------------------------------------------

local function install_dir()
    local ok, p = pcall(function ()
        return AshitaCore:GetInstallPath();
    end);
    if ok and p ~= nil and p ~= '' then
        return (tostring(p):gsub('[/\\]+$', '')) .. '/config/addons/floos';
    end
    return nil;
end

local function addon_dir()
    local base = (addon and addon.path) or '.';
    return (tostring(base):gsub('[/\\]+$', ''));
end

--- Journal lives beside the settings, one file per character.
function M.default_path(charname)
    charname = tostring(charname or 'unknown'):gsub('[^%w_%-]', '');
    if charname == '' then
        charname = 'unknown';
    end
    local dir = install_dir() or addon_dir();
    return dir .. '/journal-' .. charname .. '.jsonl';
end

----------------------------------------------------------------------
-- Whose journal is this?
----------------------------------------------------------------------
--
-- THE BUG THIS REPLACES
-- The character's name used to be read at two fixed moments: addon load,
-- and the settings library's character-switch event. Load happens before
-- login for anyone who autoloads, so the name is empty and the journal is
-- pointed at journal-unknown.jsonl. The switch event is meant to correct
-- that, but it fires from the zone-enter packet - and at that instant the
-- client has not always finished filling in the party block from that same
-- packet. Lose that race and the journal stays "unknown" for the whole
-- session, while the insights command, asking later, gets the real name,
-- looks for journal-<name>.jsonl and reports an empty journal. Reported by
-- Tawn, who traced it to the exact lines.
--
-- THE FIX
-- Never trust a name read at a fixed moment. The path is resolved lazily:
-- on the first write, on every flush, whenever it is asked for. A record
-- cannot exist before you are in the game, so by the time one arrives the
-- name is there. Until it is, records wait in memory rather than being
-- written under the wrong name. And the first time a name IS resolved, any
-- journal-unknown.jsonl left by an older version is folded into the named
-- file, so nobody's history stays orphaned in a file they never looked in.

local UNKNOWN = 'unknown';
local merged_unknown = false;

--- The current character's name, or '' if the game cannot say yet.
function M.charname()
    local name = '';
    pcall(function ()
        name = AshitaCore:GetMemoryManager():GetParty():GetMemberName(0) or '';
    end);
    name = tostring(name):gsub('%z', ''):gsub('^%s+', ''):gsub('%s+$', '');
    if name == '' then
        pcall(function ()
            local p = GetPlayerEntity();
            if p ~= nil and p.Name ~= nil then name = tostring(p.Name); end
        end);
    end
    return name;
end

local function is_unknown_path(path)
    return path == nil or tostring(path):lower():find('journal%-' .. UNKNOWN .. '%.jsonl$') ~= nil;
end

local function file_size(path)
    local size = nil;
    pcall(function ()
        local f = io.open(path, 'rb');
        if f == nil then return; end
        size = f:seek('end');
        f:close();
    end);
    return tonumber(size);
end

--- Fold journal-unknown.jsonl into the named file, once. The old file is
--- renamed, not deleted, so the merge is undoable.
local function adopt_unknown(named)
    if merged_unknown then return; end
    merged_unknown = true;
    local unknown = M.default_path(UNKNOWN);
    if unknown == named then return; end
    local size = file_size(unknown);
    if size == nil or size == 0 then return; end
    pcall(function ()
        local src = io.open(unknown, 'rb');
        if src == nil then return; end
        local body = src:read('*all');
        src:close();
        if body == nil or #body == 0 then return; end
        if body:sub(-1) ~= '\n' then body = body .. '\n'; end
        local dst = io.open(named, 'ab');
        if dst == nil then return; end
        dst:write(body);
        dst:close();
        local stamp = os.date('%Y%m%d-%H%M%S');
        os.rename(unknown, (unknown:gsub('%.jsonl$', '')) .. '.merged-' .. stamp .. '.jsonl');
        M.adopted = #body;
    end);
end

--- Make sure M.path names a real character. Returns true when it does.
function M.resolve()
    if not is_unknown_path(M.path) then return true; end
    local name = M.charname();
    if name == '' then return false; end
    M.path = M.default_path(name);
    adopt_unknown(M.path);
    M.bytes = file_size(M.path) or 0;
    return true;
end

--- The path records go to, resolving the name if it can. May still be the
--- unknown path if the game has no name yet - callers reading the journal
--- should treat that as "nothing yet".
function M.current_path()
    M.resolve();
    return M.path;
end

function M.configure(opts)
    opts = opts or {};
    if opts.path ~= nil then
        -- A path built from an empty name is not a path, it is a request to
        -- work it out later.
        if is_unknown_path(opts.path) then
            if not is_unknown_path(M.path) then
                -- Keep the good one we already have.
            else
                M.path = opts.path;
            end
        elseif opts.path ~= M.path then
            M.path = opts.path;
            M.bytes = 0;
        end
    end
    if opts.enabled ~= nil then
        M.enabled = opts.enabled and true or false;
    end
    M.resolve();
    if M.path ~= nil and M.bytes == 0 and not is_unknown_path(M.path) then
        M.bytes = file_size(M.path) or 0;
    end
end

--- While the name is unknown records wait here. This is the ceiling on
--- how many, so a session that somehow never resolves cannot grow without
--- bound.
M.HOLD_MAX = 5000;

--- Queue one record. Cheap: no file access here.
function M.write(record)
    if not M.enabled or record == nil then
        return false;
    end
    if M.bytes >= M.MAX_BYTES then
        M.dropped = M.dropped + 1;
        M.error = 'journal is at the size limit; rename or delete it';
        return false;
    end
    if #M.buffer >= M.HOLD_MAX then
        M.dropped = M.dropped + 1;
        M.error = 'journal is holding too many records without a character name';
        return false;
    end
    M.buffer[#M.buffer + 1] = M.encode(record, M.FIELD_ORDER);
    if #M.buffer >= M.FLUSH_LINES then
        M.flush();
    end
    return true;
end

function M.flush()
    if #M.buffer == 0 then
        return false;
    end
    -- Never write under the wrong name. If the game still has no name for
    -- us, hold the records; they are not lost, only late.
    if not M.resolve() then
        M.error = 'waiting for the character name before writing the journal';
        return false;
    end
    local body = table.concat(M.buffer, '\n') .. '\n';
    local f = io.open(M.path, 'a');
    if f == nil then
        M.error = 'cannot open ' .. tostring(M.path);
        M.buffer = {};
        return false;
    end
    f:write(body);
    f:close();
    M.written = M.written + #M.buffer;
    M.bytes = M.bytes + #body;
    M.buffer = {};
    M.last_flush = now();
    M.error = nil;
    return true;
end

--- Call from the render loop; flushes only when the timer is up.
function M.tick()
    if #M.buffer == 0 then
        return;
    end
    if (now() - (M.last_flush or 0)) >= M.FLUSH_SECS then
        M.flush();
    end
end

function M.stats()
    return {
        enabled = M.enabled,
        path = M.path,
        written = M.written,
        pending = #M.buffer,
        dropped = M.dropped,
        bytes = M.bytes,
        error = M.error,
    };
end

return M;
