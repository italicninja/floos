--[[
* Floos - a faded picture behind the panel
*
* Drop a PNG in assets/portraits/ and it sits behind the tracker, dimmed,
* clipped to the panel. Your character, your job's artwork, whatever you
* like.
*
* THE HARD PART IS NOT DRAWING IT
* -------------------------------
* Putting an image behind a panel is four lines. Keeping the panel READABLE
* afterwards is the whole job, and it is where this kind of thing usually
* goes wrong: a picture behind text is a contrast problem wearing a costume.
* Three things are done about it.
*
*   THE CAP.    Alpha is limited to 0.30 no matter what the slider or a
*               theme asks for. Past that no scrim saves the text.
*   THE SCRIM.  A dark gradient is drawn OVER the image and UNDER the
*               content, heaviest on the left where the labels and numbers
*               live, clearing toward the right where the art can breathe.
*               This is what every game UI does with character art and it is
*               the difference between "themed" and "unreadable".
*   THE ANCHOR. The image is anchored right and cropped, never stretched.
*               A portrait squashed to a panel's aspect ratio looks broken,
*               and the left third - where the text is - is the part you
*               most want covered by scrim anyway.
*
* NOTHING IS BUNDLED
* ------------------
* Same rule as sounds/. The folder ships with a README and no images. A
* picture of a Final Fantasy XI character - drawn, rendered or generated -
* is derived from Square Enix's designs and is not ours to redistribute.
* Yours on your own machine is entirely your business.
]]--

require('common');
local imgui = require('imgui');
local textures = require('libs.texturemanager');

local M = {};

--- Above this the text stops being readable whatever else is done, so the
--- slider and any theme suggestion are both clamped to it.
M.MAX_ALPHA = 0.30;

--- How wide to draw the image, as a multiple of the panel's height.
---
--- This exists because Ashita's texture manager hands back a pointer and
--- nothing else - no width, no height - so there is no way to ask the image
--- what shape it is. Drawing it into a box of the wrong shape stretches or
--- squashes it, and on a face that is immediately obvious.
---
--- The default is the true ratio of the reference portrait (687 x 1024,
--- so 0.671). Any other image will differ, which is why this is a slider in
--- the Appearance tab rather than a constant: set it to the picture's own
--- width divided by its height and the proportions come out right.
M.DEFAULT_RATIO = 0.671;
M.MIN_RATIO = 0.30;
M.MAX_RATIO = 2.00;

--- Cache of the folder listing, so the disk is not walked every frame.
local file_cache = nil;
local file_cache_at = 0;

--- The portraits folder, as an absolute path.
function M.folder()
    local base = tostring(addon.path or ''):gsub('[/\\]+$', '');
    return base .. '/assets/portraits';
end

--- Every image sitting in the folder. Rescanned at most once every ten
--- seconds, and on demand, because this is called from the draw path.
---@param force boolean|nil
---@return table  array of file names
function M.list(force)
    local now = os.time();
    if not force and file_cache ~= nil and (now - file_cache_at) < 10 then
        return file_cache;
    end
    local out = T{};
    pcall(function ()
        local dir = M.folder();
        for _, ext in ipairs({ 'png', 'jpg', 'jpeg', 'bmp', 'dds', 'tga' }) do
            local p = io.popen('dir /b "' .. dir:gsub('/', '\\') .. '\\*.' .. ext .. '" 2>nul');
            if p ~= nil then
                for line in p:lines() do
                    line = tostring(line):gsub('%s+$', '');
                    if line ~= '' and not line:lower():match('%.txt$') then
                        out:append(line);
                    end
                end
                p:close();
            end
        end
    end);
    table.sort(out);
    file_cache = out;
    file_cache_at = now;
    return out;
end

function M.rescan()
    file_cache = nil;
    return M.list(true);
end

--- Draw the portrait, then the scrim, into the panel rect.
---
--- Called after the panel background and before any content, so it sits
--- between the two. Every failure path returns quietly: a missing or
--- unreadable file must leave the panel exactly as it was, not blank it.
---@param dl userdata     the panel's draw list
---@param x number        panel rect, already including its padding
---@param y number
---@param w number
---@param h number
---@param name string     file name inside assets/portraits
---@param alpha number    0..M.MAX_ALPHA
---@param rounding number|nil
---@param ratio number|nil  image width as a multiple of panel height
function M.draw(dl, x, y, w, h, name, alpha, rounding, ratio)
    if dl == nil or name == nil or name == '' then return; end
    if w == nil or h == nil or w <= 4 or h <= 4 then return; end

    alpha = tonumber(alpha) or 0;
    if alpha <= 0.001 then return; end
    if alpha > M.MAX_ALPHA then alpha = M.MAX_ALPHA; end

    local tex = textures.getFileTexture('portraits/' .. name);
    if tex == nil then return; end
    local ptr = textures.getTexturePtr(tex);
    if ptr == nil then return; end

    -- Clip to the panel first. Without this the image draws over whatever
    -- is beside the window, which looks like a rendering bug rather than a
    -- theme.
    local clipped = pcall(function ()
        dl:PushClipRect({ x, y }, { x + w, y + h }, true);
    end);

    pcall(function ()
        -- Sized to the panel height and anchored to the right edge, at the
        -- caller's ratio. The old code forced a minimum width of 45% of the
        -- panel, which quietly stretched the picture sideways on any wide
        -- panel - exactly the case where a distorted face is most visible.
        -- Better a narrow strip of correct picture than a wide smear.
        local r = tonumber(ratio) or M.DEFAULT_RATIO;
        if r < M.MIN_RATIO then r = M.MIN_RATIO; end
        if r > M.MAX_RATIO then r = M.MAX_RATIO; end

        local iw = h * r;
        local ih = h;

        -- On a tall narrow panel a height-fitted portrait is wider than the
        -- panel, and since it is anchored right the overflow is cut off the
        -- LEFT - which is the side the figure faces. Past roughly h = 2w the
        -- cut reaches the hat. So once the picture would be wider than the
        -- panel, fit it to the width instead and sit it on the bottom edge,
        -- where a standing figure belongs. It still keeps its proportions;
        -- it just leaves panel above it rather than losing an arm.
        if iw > w then
            iw = w;
            ih = w / r;
        end

        local ix = x + w - iw;
        local iy = y + h - ih;

        local tint = imgui.GetColorU32({ 1, 1, 1, alpha });
        dl:AddImage(ptr, { ix, iy }, { ix + iw, iy + ih }, { 0, 0 }, { 1, 1 }, tint);
    end);

    -- The scrim. Heaviest at the left where the numbers are, gone by the
    -- right edge. Drawn as a few bands rather than one gradient call so it
    -- works on builds without AddRectFilledMultiColor.
    pcall(function ()
        local bands = 8;
        local bw = w / bands;
        for i = 0, bands - 1 do
            -- 1 at the left, 0 at the right, eased so the falloff is not a
            -- straight line - a linear scrim reads as a grey wedge.
            local t = 1 - (i / (bands - 1));
            t = t * t;
            local a = 0.10 + (0.72 * t * (alpha / M.MAX_ALPHA));
            dl:AddRectFilled(
                { x + (i * bw), y }, { x + ((i + 1) * bw) + 1, y + h },
                imgui.GetColorU32({ 0.02, 0.03, 0.05, a }), 0);
        end
        -- A last wash over everything, so even the right edge never reaches
        -- full image brightness behind text that happens to run long.
        dl:AddRectFilled({ x, y }, { x + w, y + h },
            imgui.GetColorU32({ 0.02, 0.03, 0.05, 0.18 }), rounding or 0);
    end);

    if clipped then
        pcall(function () dl:PopClipRect(); end);
    end
end

return M;
