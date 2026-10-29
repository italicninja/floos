--[[
* Floos - game menu detection.
*
* Reads the name of the top-most in-game menu so the panel can get out of the
* way when you open the map or the main menu, and come back when you close it.
*
* The pointer walk that reads the menu name originates in xitools, reached
* here by way of PetMe and Metrics. See THIRD_PARTY_NOTICES.md.
*   xitools  https://github.com/mousseng/xitools
*   PetMe    https://github.com/m4thmatic/PetMe
*
* The menu-name table shares that lineage, with two corrections of our own:
* fulllog is deliberately absent - it fires whenever you press Enter to type,
* which hid the panel every time you talked - and menuwind was added after
* confirming from a live capture that it is the Commands list.
*
* Nothing here reads or writes anything but FFXiMain's own menu name string.
]]--

require('common');

local M = {};

M.Module  = 'FFXiMain.dll';
M.Pattern = '8B480C85C974??8B510885D274??3B05';
M.Memory  = nil;

--- Menus we hide the panel for. The names are the game's own eight-character
--- internal names, not anything shown on screen.
---
--- The list is deliberately wider than "map and main menu": the main menu is
--- only ever a doorway, and every room behind it (inventory, equipment, the
--- config screens) is a full-screen window that the panel would sit on top of.
--- Anything not listed here - target cursor, chat, battle menus - leaves the
--- panel alone, which is the point of an allow-list rather than "hide whenever
--- any menu exists".
M.Types = T{
    -- Maps
    map0     = true,   -- the regular map
    maplist  = true,   -- picking a map from inside the map
    mapframe = true,   -- transitional state while maps swap
    mapv2    = true,   -- map marker creation
    mapv3    = true,   -- map markers
    scanlist = true,   -- widescan
    cnqframe = true,   -- conquest / besieged / campaign map

    -- Main menu and the screens it opens
    menuwind = true,   -- the Commands list itself - confirmed from a live log,
                       -- raw bytes "menu____menuwind". It also stays resident
                       -- underneath the map, which is why closing the map
                       -- lands back here rather than on blank.
    socialme = true,   -- social / friend list
    equip    = true,   -- equipment
    mnstorag = true,   -- equipment inventory selection
    inventor = true,   -- inventory
    iuse     = true,   -- use item
    itemctrl = true,   -- item count selector
    itmsortw = true,   -- item sort
    sortyn   = true,   -- item sort yes/no
    bank     = true,   -- mog satchel
    evitem   = true,   -- currencies
    statcom2 = true,   -- combat skills
    meritcat = true,   -- merits
    merit1   = true,
    merit2   = true,
    merit3   = true,
    merityn  = true,
    quest00  = true,   -- quests
    quest01  = true,
    miss00   = true,   -- missions
    faqsub   = true,   -- help desk
    inspect  = true,   -- checking equipment
    -- NOT fulllog. The chat log expands every time you press Enter to type,
    -- so hiding for it means the panel vanishes whenever you talk.
    mcr1edlo = true,   -- macro editing
    mcr2edlo = true,
    mcrbedit = true,
    mcresed  = true,   -- equipset editing
    link5    = true,   -- linkshell
    link12   = true,
    link13   = true,
    link3    = true,
    scresult = true,   -- search results

    -- Config
    conf2win = true, cfilter  = true, textcol1 = true, confyn   = true,
    conf5m   = true, conf5win = true, conf5w1  = true, conf5w2  = true,
    conf11m  = true, conf11l  = true, conf11s  = true, conf3win = true,
    conf6win = true, conf12wi = true, conf13wi = true, fxfilter = true,
    conf7    = true, conf4    = true,
};

--- Names that must never hide the panel, whatever any list says. These are
--- not menus you open, they are states the game is in constantly while you
--- play, and hiding for one means the panel disappears during normal use.
---
--- They are enforced ahead of every other list, including the player's own
--- additions, because the failure they cause looks like the addon is broken
--- rather than like a setting that needs changing. `inline` in particular is
--- open the entire time you are typing - and you are always typing when you
--- run the command that would have added it.
M.NEVER_HIDE = T{
    inline   = true,   -- the chat input bar
    fulllog  = true,   -- expanded chat log, open whenever you press Enter
};

--- Reads the raw sixteen bytes the game keeps the menu name in, untouched.
--- Kept separate from name() so that when the tidy-up below guesses wrong -
--- a different prefix length, a null in the middle - there is something to
--- look at instead of an empty string.
---@return string
function M.raw()
    local ok, result = pcall(function ()
        if M.Memory == nil or M.Memory == 0 then
            M.Memory = ashita.memory.find(M.Module, 0, M.Pattern, 16, 0);
        end

        local menu = M.Memory;
        if menu == nil or menu == 0 then
            M.Memory = nil;
            return '';
        end

        local pointer = ashita.memory.read_uint32(menu);
        if pointer == nil or pointer == 0 then return ''; end

        local pointer_value = ashita.memory.read_uint32(pointer);
        if pointer_value == nil or pointer_value == 0 then return ''; end

        local header = ashita.memory.read_uint32(pointer_value + 4);
        if header == nil or header == 0 then return ''; end

        return ashita.memory.read_string(header + 0x46, 16) or '';
    end);

    if not ok then return ''; end
    return result or '';
end

--- Printable form of a raw name, with nulls and spaces made visible so a
--- chat line can show exactly what is in memory.
---@param raw string
---@return string
function M.printable(raw)
    if raw == nil or raw == '' then return '(empty)'; end
    local out = '';
    for i = 1, #raw do
        local c = string.sub(raw, i, i);
        local b = string.byte(c);
        if b == 0 then out = out .. '.';
        elseif b == 32 then out = out .. '_';
        elseif b >= 33 and b <= 126 then out = out .. c;
        else out = out .. string.format('<%02X>', b); end
    end
    return out;
end

--- Turns the raw sixteen bytes into the short menu name.
---
--- The layout is eight bytes of prefix junk, then the name, padded out with
--- spaces. Nulls come out first because some entries are null-padded rather
--- than space-padded.
---@param raw string
---@return string
function M.strip(raw)
    if raw == nil or raw == '' then return ''; end
    local s = string.gsub(raw, '\x00', '');
    s = string.sub(s, 9);
    return (string.gsub(s, ' ', ''));
end

--- Reads the top-most menu's internal name. Returns '' when nothing is open,
--- or when the signature did not resolve.
---@return string
function M.name()
    return M.strip(M.raw());
end

--- True when the signature resolved, so /floos debug can say so plainly
--- instead of the feature looking broken.
---@return boolean
function M.signature_ok()
    if M.Memory == nil or M.Memory == 0 then
        M.name();
    end
    return (M.Memory ~= nil and M.Memory ~= 0);
end

--- Extra names the player added in game with /floos menu add <name>, so a
--- menu I did not know about can be covered without editing this file.
M.extra = T{};

--- The last handful of distinct menu names seen, newest last.
---
--- This exists because you cannot open the chat box while a game menu is up,
--- so "run a command while the menu is open" is not actually a thing you can
--- do. Recording instead means you open the menu, close it, and then ask.
M.recent = T{};
M.RECENT_MAX = 12;
-- Sentinel, not '', so the very first observation is logged even when it is
-- blank. The blank baseline is exactly what needs recording.
M.last_seen = '\1unset';

--- Where the name log goes. Next to the addon, so it is easy to find.
function M.log_path()
    local base = nil;
    pcall(function ()
        base = (addon and addon.path) or nil;
    end);
    if base == nil or base == '' then
        pcall(function ()
            local p = AshitaCore:GetInstallPath();
            if p ~= nil and p ~= '' then
                base = (tostring(p):gsub('[/\\]+$', '')) .. '/addons/floos/';
            end
        end);
    end
    if base == nil or base == '' then base = './'; end
    return (tostring(base):gsub('[/\\]+$', '')) .. '/menu_log.txt';
end

-- Off now that it has done its job. /floos menu log on turns it back on,
-- which is the fastest way to identify any menu this list still misses.
M.log_enabled = false;
M.log_lines = 0;
M.LOG_MAX = 400;   -- a name log, not a diary; stops it growing forever

--- Appends one observation. Silent on failure - a log that cannot be written
--- is not a reason to break the panel.
local function write_log(name, raw, shown)
    if not M.log_enabled or M.log_lines >= M.LOG_MAX then return; end
    pcall(function ()
        local f = io.open(M.log_path(), 'a');
        if f == nil then
            M.log_enabled = false;   -- do not retry every frame
            return;
        end
        f:write(string.format('%s  name="%s"  raw="%s"\n',
            os.date('%Y-%m-%d %H:%M:%S'),
            tostring(name), tostring(shown)));
        f:close();
        M.log_lines = M.log_lines + 1;
    end);
end

--- Called once per frame. Records name changes and answers "hide now?".
---@return boolean
function M.observe()
    -- Keyed on the raw bytes, not the tidied name: if the tidy-up is what is
    -- wrong for a given menu, keying on its output would hide the evidence.
    local raw = M.raw();
    local name = M.strip(raw);

    if raw ~= M.last_seen then
        M.last_seen = raw;
        -- Log every transition, blanks included. The blank state is half the
        -- answer: it says what the walk reports when no menu is open, which
        -- is what decides whether "hide for anything unrecognised" is safe.
        write_log(name, raw, M.printable(raw));
        if raw ~= '' and raw:gsub('[%z ]', '') ~= '' then
            -- Move an already-known entry to the end rather than duplicating,
            -- so a menu you open repeatedly does not flush the list.
            for i = #M.recent, 1, -1 do
                if M.recent[i].raw == raw then
                    table.remove(M.recent, i);
                end
            end
            M.recent[#M.recent + 1] = {
                name = name,
                raw = raw,
                shown = M.printable(raw),
                t = os.time(),
            };
            while #M.recent > M.RECENT_MAX do
                table.remove(M.recent, 1);
            end
        end
    end

    if name == '' then
        return false;   -- fail open: never make the panel disappear for good
    end
    return M.covers(name);
end

--- True when this name is one the panel currently hides for.
---@param name string
---@return boolean
function M.covers(name)
    if M.NEVER_HIDE[name] == true then return false; end
    if M.never[name] == true then return false; end
    return (M.Types[name] == true) or (M.extra[name] == true);
end

--- True for names that must never hide the panel, whatever any list says.
---@param name string
---@return boolean
function M.always_ignored(name)
    return M.NEVER_HIDE[name] == true;
end


---@param names table|nil  list of names from settings
function M.set_extra(names)
    M.extra = T{};
    if names == nil then return; end
    for _, n in ipairs(names) do
        if type(n) == 'string' and n ~= '' then
            M.extra[n] = true;
        end
    end
end

--- Names the player took back out with /floos menu remove. Wins over both
--- the built-in list and the added one, so a wrong built-in entry - fulllog
--- was one - can be dropped in game instead of waiting on a new file.
M.never = T{};

---@param names table|nil  list of names from settings
function M.set_never(names)
    M.never = T{};
    if names == nil then return; end
    for _, n in ipairs(names) do
        if type(n) == 'string' and n ~= '' then
            M.never[n] = true;
        end
    end
end

--- Should the panel step aside right now? Does not record - use observe()
--- from the render loop, this is for one-off checks from commands.
---@return boolean
function M.blocking()
    local name = M.name();
    if name == '' then
        return false;   -- fail open: never make the panel disappear for good
    end
    return M.covers(name);
end

return M;
