--[[
* Floos - Overlay font helpers
*
* Loads TTFs via imgui.AddFontFromFileTTF (same approach as XIUI). Fonts are
* prewarmed on load - never added mid-frame, which can crash the atlas.
*
* Lookup order per font: the Windows font folder first, then the addon's own
* assets/fonts/ if it has one, then Agave, which needs no file. Windows comes
* first because Tahoma, Segoe UI, Consolas and Verdana are Microsoft's and are
* not ours to redistribute - the public build ships none of them.
]]--

require('common');
local imgui = require('imgui');

local M = {};

-- Friendly label -> filename under assets/fonts/
-- "Agave" keeps Ashita's current ImGui font (no PushFont).
-- "Tahoma Bold (Default)" is the addon default for overlays.
M.OPTIONS = T{
    { label = 'Tahoma Bold (Default)', file = 'tahomabd.ttf' },
    { label = 'Agave',                 file = nil },
    { label = 'Tahoma',                file = 'tahoma.ttf' },
    { label = 'Segoe UI',              file = 'segoeui.ttf' },
    { label = 'Consolas',              file = 'consola.ttf' },
    { label = 'Verdana',               file = 'verdana.ttf' },
};

local cache = T{}; -- label -> ImFont* or false
local pushed = false;
local warned = T{};
local prewarmed = false;

-- Pixel size passed to AddFontFromFileTTF (matches XIUI). Runtime Font Size
-- and per-module scale apply via begin_scale (legacy SetWindowFontScale or ImGui 1.92+).
M.BASE_SIZE = 20;

--- Where the addon's own copies would live, if there are any.
local function fonts_dir()
    local base = (addon and addon.path) or '';
    base = base:gsub('[/\\]+$', '');
    return base .. '/assets/fonts/';
end

--- The Windows font folder, read from the environment rather than hardcoded
--- to C:, because Windows is not always installed on C:.
local function windows_fonts_dir()
    local root = nil;
    pcall(function ()
        root = os.getenv('SystemRoot') or os.getenv('windir') or nil;
    end);
    if root == nil or root == '' then
        root = 'C:\\Windows';
    end
    return (tostring(root):gsub('[/\\]+$', '')) .. '\\Fonts\\';
end

--- Does the file exist and open? Checked before handing a path to ImGui:
--- AddFontFromFileTTF asserts on a missing file in some builds rather than
--- returning nil, and an assert inside the font atlas takes Ashita with it.
---@param path string
---@return boolean
local function readable(path)
    local ok, present = pcall(function ()
        local f = io.open(path, 'rb');
        if f == nil then return false; end
        f:close();
        return true;
    end);
    return ok and present or false;
end

--- Every place a given font file might be, best first.
---
--- Windows comes first on purpose. Tahoma, Segoe UI, Consolas and Verdana are
--- Microsoft's, licensed with Windows and not ours to redistribute, so the
--- public build ships none of them and reads the copies already on the
--- machine instead. The addon-local folder is still checked second, so a
--- build that does carry its own TTFs - or anyone who drops one in - keeps
--- working unchanged. Agave needs no file at all and is the floor under both.
---@param file string
---@return table
local function font_candidates(file)
    return {
        windows_fonts_dir() .. file,
        fonts_dir() .. file,
    };
end

local function clamp_size(size)
    size = tonumber(size) or 13;
    if size < 6 then return 6; end
    if size > 30 then return 30; end
    return math.floor(size + 0.5);
end

function M.get_size(settings)
    if settings ~= nil and settings.font_size ~= nil then
        return clamp_size(settings.font_size[1]);
    end
    return 13;
end

-- Call after PushFont. Scale so on-screen size matches the Font Size setting.
function M.get_scale(settings)
    local desired = M.get_size(settings);
    local base = imgui.GetFontSize();
    if base == nil or base <= 0 then
        base = M.BASE_SIZE;
    end
    return desired / base;
end

-- Per-window/module font scale. Ashita 4.3 (ImGui 1.92+) removed SetWindowFontScale;
-- use PushFontSize / PushFont(font, size) there and Pop on end_scale.
function M.begin_scale(scale)
    scale = tonumber(scale) or 1.0;
    if scale <= 0 then
        scale = 1.0;
    end

    -- Older Ashita: prefer the classic API when the binding still exists.
    if imgui.SetWindowFontScale ~= nil then
        local ok = pcall(function()
            imgui.SetWindowFontScale(scale);
        end);
        if ok then
            M._current_scale = scale;
            return { mode = 'legacy' };
        end
    end

    local base = imgui.GetFontSize();
    if base == nil or base <= 0 then
        base = M.BASE_SIZE;
    end
    local size = base * scale;

    if imgui.PushFontSize ~= nil then
        local ok = pcall(function()
            imgui.PushFontSize(size);
        end);
        if ok then
            return { mode = 'font_size' };
        end
    end

    local font = nil;
    pcall(function()
        font = imgui.GetFont();
    end);
    local ok = pcall(function()
        imgui.PushFont(font, size);
    end);
    if ok then
        return { mode = 'push_font' };
    end

    return { mode = 'none' };
end

--- Nested, relative font scale (e.g. a 1.5x hero number inside a scaled panel).
--- Always pair with pop_scale. Safe to call inside begin_scale/end_scale.
function M.push_scale(mult)
    mult = tonumber(mult) or 1.0;
    if mult <= 0 then
        mult = 1.0;
    end

    if imgui.SetWindowFontScale ~= nil then
        local prev = M._current_scale or 1.0;
        local ok = pcall(function()
            imgui.SetWindowFontScale(prev * mult);
        end);
        if ok then
            M._current_scale = prev * mult;
            return { mode = 'legacy', prev = prev };
        end
    end

    local base = imgui.GetFontSize();
    if base == nil or base <= 0 then
        base = M.BASE_SIZE;
    end

    if imgui.PushFontSize ~= nil then
        local ok = pcall(function()
            imgui.PushFontSize(base * mult);
        end);
        if ok then
            return { mode = 'font_size' };
        end
    end

    local font = nil;
    pcall(function()
        font = imgui.GetFont();
    end);
    local ok = pcall(function()
        imgui.PushFont(font, base * mult);
    end);
    if ok then
        return { mode = 'push_font' };
    end

    return { mode = 'none' };
end

function M.pop_scale(tag)
    if tag == nil then
        return;
    end

    if tag.mode == 'legacy' then
        local prev = tag.prev or 1.0;
        pcall(function()
            imgui.SetWindowFontScale(prev);
        end);
        M._current_scale = prev;
        return;
    end

    if tag.mode == 'font_size' then
        pcall(function()
            if imgui.PopFontSize ~= nil then
                imgui.PopFontSize();
            else
                imgui.PopFont();
            end
        end);
        return;
    end

    if tag.mode == 'push_font' then
        pcall(function()
            imgui.PopFont();
        end);
    end
end

function M.end_scale(tag)
    if tag == nil then
        return;
    end

    if tag.mode == 'legacy' then
        if imgui.SetWindowFontScale ~= nil then
            pcall(function()
                imgui.SetWindowFontScale(1.0);
            end);
        end
        M._current_scale = 1.0;
        return;
    end

    if tag.mode == 'font_size' then
        pcall(function()
            if imgui.PopFontSize ~= nil then
                imgui.PopFontSize();
            else
                imgui.PopFont();
            end
        end);
        return;
    end

    if tag.mode == 'push_font' then
        pcall(function()
            imgui.PopFont();
        end);
    end
end

local function find_option(label)
    -- Migrate older saved labels.
    if label == 'Tahoma Bold' then
        label = 'Tahoma Bold (Default)';
    elseif label == 'Default (Agave)' then
        label = 'Agave';
    end
    for _, opt in ipairs(M.OPTIONS) do
        if opt.label == label then
            return opt;
        end
    end
    return M.OPTIONS[1];
end

local function try_add_font(path)
    -- XIUI uses imgui.AddFontFromFileTTF directly (Ashita binding).
    local size = M.BASE_SIZE;
    local attempts = T{
        function()
            return imgui.AddFontFromFileTTF(path, size);
        end,
        function()
            return imgui.GetIO().Fonts:AddFontFromFileTTF(path, size);
        end,
        function()
            return imgui.io.Fonts:AddFontFromFileTTF(path, size);
        end,
    };

    for _, attempt in ipairs(attempts) do
        local ok, font = pcall(attempt);
        if ok and font ~= nil and font ~= false then
            return font;
        end
    end
    return nil;
end

function M.resolve_label(label)
    return find_option(label).label;
end

function M.get_font(label)
    label = M.resolve_label(label);
    local opt = find_option(label);

    if opt.file == nil then
        return nil;
    end

    if cache[label] ~= nil then
        return (cache[label] ~= false) and cache[label] or nil;
    end

    local font = nil;
    local tried = T{};
    for _, path in ipairs(font_candidates(opt.file)) do
        tried[#tried + 1] = path;
        if readable(path) then
            font = try_add_font(path);
            if font ~= nil then
                break;
            end
        end
    end

    if font == nil then
        cache[label] = false;
        if not warned[label] then
            warned[label] = true;
            print(string.format(
                '[floos] Could not load font "%s". Using Agave instead. Looked in: %s',
                label,
                table.concat(tried, '  and  ')
            ));
        end
        return nil;
    end

    cache[label] = font;
    return font;
end

-- Call from addon load (NOT from d3d_present). Mutating the ImGui font atlas
-- mid-frame can crash Ashita (see XIUI imtext.PrewarmFonts).
-- Load every bundled TTF once at addon load (AddFontFromFileTTF is unsafe mid-frame).
function M.prewarm()
    if prewarmed then
        return;
    end
    prewarmed = true;

    for _, opt in ipairs(M.OPTIONS) do
        if opt.file ~= nil then
            M.get_font(opt.label);
        end
    end
end

-- Push the chosen TTF at BASE_SIZE; callers apply Font Size / module scale via begin_scale.
function M.push(settings)
    if pushed then
        return;
    end

    local label = 'Tahoma Bold (Default)';
    if settings ~= nil and settings.ui ~= nil and settings.ui.font_family ~= nil then
        label = settings.ui.font_family[1] or label;
    end
    label = M.resolve_label(label);

    local font = M.get_font(label);
    if font == nil then
        return;
    end

    -- ImGui 1.92+: second arg sets size. Fall back to single-arg PushFont on older Ashita.
    local ok = pcall(function()
        imgui.PushFont(font, M.BASE_SIZE);
    end);
    if not ok then
        ok = pcall(function()
            imgui.PushFont(font);
        end);
    end
    if ok then
        pushed = true;
    end
end

function M.pop()
    if not pushed then
        return;
    end
    pcall(function()
        imgui.PopFont();
    end);
    pushed = false;
end

function M.render_combo(settings_ref)
    local current = M.resolve_label(settings_ref[1]);
    if imgui.BeginCombo('Font', current) then
        for _, opt in ipairs(M.OPTIONS) do
            local selected = (opt.label == current);
            if imgui.Selectable(opt.label, selected) then
                settings_ref[1] = opt.label;
            end
            if selected then
                imgui.SetItemDefaultFocus();
            end
        end
        imgui.EndCombo();
    end
end

return M;
