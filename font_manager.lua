-- font_manager.lua
local ffi = require 'ffi'
local config = require 'config' -- Assuming config.lua is in the same directory
local SDL = require 'sdl3_ffi'  -- Added
require('global')(SDL)          -- Initialize global SDL functions/constants

local M = {}

-- Localized globals from the original script, now module-scoped
M.FontGlyphs = {}
M.FontHeight = 0
M.FontSurface = nil -- Will hold SDL_Surface for font
M.FontTexture = nil -- Will hold SDL_Texture for font if UseRenderer is true

local EnableDebugPrints = config.EnableDebugPrints
local EnableDebugPrintsDetails = config.EnableDebugPrintsDetails -- Renamed from ENABLE_DEBUG_PRINTS_DETAILS
local FontPath = config.FontPath
local FontCharacterMapString = config.FontCharacterMapString     -- Renamed from FONT_CHARACTER_MAP_STRING

function M.LoadAndProcessCustomFont(renderer_or_nil)             -- Removed SDL parameter
    if M.FontTexture then
        SDL_DestroyTexture(M.FontTexture); M.FontTexture = nil;
    end
    if M.FontSurface then
        SDL_DestroySurface(M.FontSurface); M.FontSurface = nil;
    end

    M.FontSurface = SDL_LoadBMP(FontPath)
    if M.FontSurface == nil then
        print("Error loading font BMP: " .. ffi.string(SDL_GetError()))
        return false
    end

    local pixel_format_details = SDL_GetPixelFormatDetails(M.FontSurface.format)
    if pixel_format_details == nil then
        print("Error: SDL_GetPixelFormatDetails returned NULL for format: " .. M.FontSurface.format)
        SDL_DestroySurface(M.FontSurface); M.FontSurface = nil
        return false
    end

    local format_name_ptr = SDL_GetPixelFormatName(M.FontSurface.format)
    local format_name_str = "Unknown"
    if format_name_ptr ~= nil then format_name_str = ffi.string(format_name_ptr) end

    local actual_bits_per_pixel = pixel_format_details.bits_per_pixel
    local actual_bytes_per_pixel = pixel_format_details.bytes_per_pixel

    if EnableDebugPrints then
        print(string.format("Font: Successfully read BitsPerPixel: %d and BytesPerPixel: %d", actual_bits_per_pixel,
            actual_bytes_per_pixel))
    end

    if actual_bytes_per_pixel ~= math.floor(actual_bits_per_pixel / 8) and EnableDebugPrints then
        print(string.format("Font: Warning: Inconsistency BitsPerPixel=%d, BytesPerPixel=%d", actual_bits_per_pixel,
            actual_bytes_per_pixel))
    end

    if format_name_str ~= "SDL_PIXELFORMAT_ARGB8888" then
        print(string.format("Font Error: Must be SDL_PIXELFORMAT_ARGB8888. Detected: %s", format_name_str))
        SDL_DestroySurface(M.FontSurface); M.FontSurface = nil
        return false
    end

    if actual_bits_per_pixel ~= 32 then
        print(string.format("Font Error: Must be 32 BitsPerPixel. Detected: %d", actual_bits_per_pixel))
        SDL_DestroySurface(M.FontSurface); M.FontSurface = nil
        return false
    end

    if EnableDebugPrints then
        print(string.format("FontSurface loaded. Format Name: %s (Enum: %d)", format_name_str,
            tonumber(M.FontSurface.format)))
        print(string.format("BitsPerPixel: %d, BytesPerPixel: %d", actual_bits_per_pixel, actual_bytes_per_pixel))
        print(string.format("Masks: R=0x%08x G=0x%08x B=0x%08x A=0x%08x",
            tonumber(pixel_format_details.Rmask), tonumber(pixel_format_details.Gmask),
            tonumber(pixel_format_details.Bmask), tonumber(pixel_format_details.Amask)))
        print(string.format("Pitch: %d", M.FontSurface.pitch))
    end

    if not SDL_SetSurfaceBlendMode(M.FontSurface, SDL_BLENDMODE_BLEND) then
        print("Font Error: setting blend mode: " .. ffi.string(SDL_GetError()))
        SDL_DestroySurface(M.FontSurface); M.FontSurface = nil
        return false
    end

    if not SDL_LockSurface(M.FontSurface) then
        print("Font Error: locking surface: " .. ffi.string(SDL_GetError()))
        SDL_DestroySurface(M.FontSurface); M.FontSurface = nil
        return false
    end

    if EnableDebugPrints then print("Font surface locked successfully.") end

    print("Processing font: " ..
        FontPath ..
        " (w:" .. M.FontSurface.w .. ", h:" .. M.FontSurface.h .. ", bpp:" .. (actual_bytes_per_pixel * 8) .. ")")
    M.FontHeight = M.FontSurface.h
    M.FontGlyphs = {}
    local in_glyph_span = false
    local current_glyph_start_x = 0
    local glyph_index_in_map = 0

    local r_val, g_val, b_val, a_val = ffi.new("uint8_t[1]"), ffi.new("uint8_t[1]"), ffi.new("uint8_t[1]"),
        ffi.new("uint8_t[1]")
    local cast_pixels_ptr = ffi.cast("uint32_t*", M.FontSurface.pixels)

    for x = 0, M.FontSurface.w - 1 do
        local current_pixel_value = cast_pixels_ptr[x]
        SDL_GetRGBA(current_pixel_value, pixel_format_details, ffi.NULL, r_val, g_val, b_val, a_val)
        local r, g, b, a = r_val[0], g_val[0], b_val[0], a_val[0]
        local is_separator = (r == 255 and g == 255 and b == 0 and a == 255)

        if not in_glyph_span and not is_separator then
            in_glyph_span = true
            current_glyph_start_x = x
        elseif in_glyph_span and is_separator then
            in_glyph_span = false
            local glyph_w = x - current_glyph_start_x
            if glyph_w > 0 then
                glyph_index_in_map = glyph_index_in_map + 1
                if glyph_index_in_map <= #FontCharacterMapString then                                                 -- Renamed
                    local char_for_glyph = string.sub(FontCharacterMapString, glyph_index_in_map, glyph_index_in_map) -- Renamed
                    M.FontGlyphs[char_for_glyph] = {
                        src_x = current_glyph_start_x,
                        src_y = 0,
                        src_w = glyph_w,
                        src_h = M
                            .FontHeight
                    }
                    if EnableDebugPrintsDetails and EnableDebugPrints then
                        print(string.format("Font: Glyph '%s' (idx %d): x=%d, w=%d, h=%d",
                            char_for_glyph, glyph_index_in_map, current_glyph_start_x, glyph_w, M.FontHeight))
                    end
                else
                    print("Font Warning: More glyphs in image than in FontCharacterMapString."); break -- Renamed
                end
            elseif EnableDebugPrints then
                print(string.format("Font Warning: Zero-width glyph at x=%d", x))
            end
        end
    end

    if in_glyph_span then -- Process last glyph if image doesn't end with a separator
        local glyph_w = M.FontSurface.w - current_glyph_start_x
        if glyph_w > 0 then
            glyph_index_in_map = glyph_index_in_map + 1
            if glyph_index_in_map <= #FontCharacterMapString then                                                 -- Renamed
                local char_for_glyph = string.sub(FontCharacterMapString, glyph_index_in_map, glyph_index_in_map) -- Renamed
                M.FontGlyphs[char_for_glyph] = {
                    src_x = current_glyph_start_x,
                    src_y = 0,
                    src_w = glyph_w,
                    src_h = M
                        .FontHeight
                }
                if EnableDebugPrintsDetails and EnableDebugPrints then
                    print(string.format(
                        "Font: Glyph '%s' (idx %d) (end of image): x=%d, w=%d, h=%d", char_for_glyph, glyph_index_in_map,
                        current_glyph_start_x, glyph_w, M.FontHeight))
                end
            else
                print("Font Warning: Final glyph in image but no more characters in FontCharacterMapString.") -- Renamed
            end
        end
    end

    SDL_UnlockSurface(M.FontSurface)

    if config.UseRenderer then
        if renderer_or_nil == nil then
            print("Font Error: Renderer is nil, cannot create font texture.")
            SDL_DestroySurface(M.FontSurface); M.FontSurface = nil
            return false
        end
        M.FontTexture = SDL_CreateTextureFromSurface(renderer_or_nil, M.FontSurface)
        if M.FontTexture == nil then
            print("Font Error: creating texture: " .. ffi.string(SDL_GetError()))
            SDL_DestroySurface(M.FontSurface); M.FontSurface = nil -- Critical for renderer mode
            return false
        elseif EnableDebugPrints then
            print("Font: Successfully created FontTexture from FontSurface.")
        end
    end

    local glyphs_count = 0; for _ in pairs(M.FontGlyphs) do glyphs_count = glyphs_count + 1 end
    if glyphs_count == 0 then
        print("Font Warning: No glyphs processed. Text will not render.")
        if M.FontTexture then
            SDL_DestroyTexture(M.FontTexture); M.FontTexture = nil;
        end
        if M.FontSurface then
            SDL_DestroySurface(M.FontSurface); M.FontSurface = nil;
        end
        return false
    elseif EnableDebugPrints then
        print("Font processing complete. Glyphs found: " .. glyphs_count)
        if config.UseRenderer and M.FontTexture then
            print("FontTexture is set.")
        elseif not config.UseRenderer and M.FontSurface then
            print("FontSurface is set.")
        end
    end

    return true
end

function M.GetTextWidth(text)
    local total_width = 0
    if not M.FontGlyphs or not text then return 0 end
    for i = 1, #text do
        local char = string.sub(text, i, i)
        local glyph = M.FontGlyphs[char]
        if glyph then
            total_width = total_width + glyph.src_w + 1         -- Add 1 for spacing
        else
            total_width = total_width + (M.FontHeight or 0) / 2 -- Default for unknown
        end
    end
    if #text > 0 and total_width > 0 then total_width = total_width - 1 end -- No trailing space
    return total_width
end

function M.DrawText(renderer_or_window_surface, text, x, y, color_tbl)
    if EnableDebugPrintsDetails and EnableDebugPrints then                           -- DEBUG
        print(string.format("font_manager.DrawText: Received renderer_or_window_surface type: %s, value: %s",
            type(renderer_or_window_surface), tostring(renderer_or_window_surface))) -- DEBUG
    end                                                                              -- DEBUG
    local active_font_resource = config.UseRenderer and M.FontTexture or M.FontSurface
    if not active_font_resource or not M.FontGlyphs or not text or not next(M.FontGlyphs) then
        if EnableDebugPrintsDetails and EnableDebugPrints then
            print(
                "DrawText: Font resources not available or text is nil.")
        end
        return
    end

    local r_mod, g_mod, b_mod, a_mod = 255, 255, 255, 255
    if color_tbl then
        r_mod = color_tbl.r or 255
        g_mod = color_tbl.g or 255
        b_mod = color_tbl.b or 255
        a_mod = color_tbl.a or 255
    end

    if config.UseRenderer then
        SDL_SetTextureColorMod(active_font_resource, r_mod, g_mod, b_mod)
        SDL_SetTextureAlphaMod(active_font_resource, a_mod)
    else
        SDL_SetSurfaceColorMod(active_font_resource, r_mod, g_mod, b_mod)
        SDL_SetSurfaceAlphaMod(active_font_resource, a_mod)
    end

    local current_x = x
    for i = 1, #text do
        local char = string.sub(text, i, i)
        local glyph = M.FontGlyphs[char]
        if glyph then
            if config.UseRenderer then
                local src_frect = ffi.new('SDL_FRect', {
                    x = ffi.cast("float", glyph.src_x),
                    y = ffi.cast("float", glyph.src_y),
                    w = ffi.cast("float", glyph.src_w),
                    h = ffi.cast("float", glyph.src_h)
                })
                local dst_frect = ffi.new('SDL_FRect', {
                    x = ffi.cast("float", current_x),
                    y = ffi.cast("float", y),
                    w = ffi.cast("float", glyph.src_w),
                    h = ffi.cast("float", glyph.src_h)
                })
                SDL_RenderTexture(renderer_or_window_surface, active_font_resource, src_frect, dst_frect)
            else
                local src_rect = ffi.new('SDL_Rect', { glyph.src_x, glyph.src_y, glyph.src_w, glyph.src_h })
                local dst_rect = ffi.new('SDL_Rect', { x = current_x, y = y }) -- w/h ignored by BlitSurface
                SDL_BlitSurface(active_font_resource, src_rect, renderer_or_window_surface, dst_rect)
            end
            current_x = current_x + glyph.src_w + 1 -- Inter-character spacing
        else
            if EnableDebugPrintsDetails and EnableDebugPrints then
                print("DrawText Warning: Char '" ..
                    char .. "' not in FontGlyphs.")
            end
            current_x = current_x + (M.FontHeight or 0) / 2
        end
    end

    -- Reset modulation
    if config.UseRenderer then
        SDL_SetTextureColorMod(active_font_resource, 255, 255, 255)
        SDL_SetTextureAlphaMod(active_font_resource, 255)
    else
        SDL_SetSurfaceColorMod(active_font_resource, 255, 255, 255)
        SDL_SetSurfaceAlphaMod(active_font_resource, 255)
    end
end

function M.Cleanup()
    if M.FontTexture then
        SDL_DestroyTexture(M.FontTexture); M.FontTexture = nil;
    end
    if M.FontSurface then
        SDL_DestroySurface(M.FontSurface); M.FontSurface = nil;
    end
    if EnableDebugPrints then print("Font manager cleaned up.") end
end

return M
