-- graphics_utils.lua
local ffi = require 'ffi'
local SDL = require 'sdl3_ffi'              -- Added SDL require
local config = require 'config'
local font_manager = require 'font_manager' -- Required for drawing text on buttons

local M = {}

-- Store Renderer and WindowSurface globally within this module after they are initialized
M.Renderer = nil
M.WindowSurface = nil

function M.InitRendererSurface(renderer, window_surface) -- Renamed
    M.Renderer = renderer
    M.WindowSurface = window_surface
end

function M.RectangleFromXYWH(xywh) -- Renamed
    local rect_type = config.UseRenderer and 'SDL_FRect' or 'SDL_Rect'
    local rectangle = ffi.new(rect_type)
    rectangle.x = xywh[1]
    rectangle.y = xywh[2]
    rectangle.w = xywh[3]
    rectangle.h = xywh[4]
    return rectangle
end

function M.DrawImage(imageDrawable, xywh) -- Renamed
    if not imageDrawable then
        if config.EnableDebugPrints then print("DrawImage: imageDrawable is nil.") end
        return
    end
    local dest_rect = M.RectangleFromXYWH(xywh) -- Updated call
    if config.UseRenderer then
        if not M.Renderer then
            print("DrawImage Error: Renderer not initialized in graphics_utils.")
            return
        end
        SDL_RenderTexture(M.Renderer, imageDrawable, nil, dest_rect)
    else
        if not M.WindowSurface then
            print("DrawImage Error: WindowSurface not initialized in graphics_utils.")
            return
        end
        SDL_BlitSurfaceScaled(imageDrawable, nil, M.WindowSurface, dest_rect, SDL_SCALEMODE_NEAREST)
    end
end

function M.FillRect(xywh, r, g, b, a)           -- Renamed
    local rectangle = M.RectangleFromXYWH(xywh) -- Updated call
    if config.UseRenderer then
        if not M.Renderer then
            print("FillRect Error: Renderer not initialized in graphics_utils.")
            return
        end
        SDL_SetRenderDrawColor(M.Renderer, r, g, b, a)
        SDL_RenderFillRect(M.Renderer, rectangle)
    else
        if not M.WindowSurface then
            print("FillRect Error: WindowSurface not initialized in graphics_utils.")
            return
        end
        -- Create a temp RGBA surface for blending
        local temp_surface = SDL_CreateSurface(rectangle.w, rectangle.h, SDL_PIXELFORMAT_RGBA32)
        if temp_surface == nil then
            if config.EnableDebugPrints then
                print("FillRect Error: Could not create temp surface: " ..
                    ffi.string(SDL_GetError()))
            end
            return
        end
        SDL_SetSurfaceBlendMode(temp_surface, SDL_BLENDMODE_BLEND)
        local color = SDL_MapSurfaceRGBA(temp_surface, r, g, b, a)
        SDL_FillSurfaceRect(temp_surface, nil, color)
        SDL_BlitSurface(temp_surface, nil, M.WindowSurface, rectangle)
        SDL_DestroySurface(temp_surface)
    end
end

-- Button functions
function M.CreateButton(text, x, y, w, h, onClick_fn, colorNormal_tbl, colorHover_tbl, colorPressed_tbl)
    local default_normal_color = { r = 200, g = 200, b = 200, a = 255 }
    local default_hover_color = { r = 220, g = 220, b = 220, a = 255 }
    local default_pressed_color = { r = 180, g = 180, b = 180, a = 255 }

    return {
        text = text or "Button",
        rect = { x or 0, y or 0, w or 100, h or 30 }, -- Store as a table {x, y, w, h}
        onClick = onClick_fn,
        isHovered = false,
        isPressed = false,
        colors = {
            normal = colorNormal_tbl or default_normal_color,
            hover = colorHover_tbl or default_hover_color,
            pressed = colorPressed_tbl or default_pressed_color
        }
    }
end

function M.DrawButton(button)
    if not button or not button.rect or not button.colors then
        if config.EnableDebugPrints then print("DrawButton: Invalid button object provided.") end
        return
    end

    local current_color_tbl
    if button.isPressed and button.colors.pressed then
        current_color_tbl = button.colors.pressed
    elseif button.isHovered and button.colors.hover then
        current_color_tbl = button.colors.hover
    elseif button.colors.normal then
        current_color_tbl = button.colors.normal
    else
        current_color_tbl = { r = 200, g = 200, b = 200, a = 255 } -- Fallback
    end

    M.FillRect(button.rect, current_color_tbl.r, current_color_tbl.g, current_color_tbl.b, current_color_tbl.a or 255) -- Updated call

    local text_color = { r = 255, g = 255, b = 255, a = 255 }                                                          -- Changed to white text by default
    -- Adjust text position for simple padding. Proper centering would need text width/height.
    local text_x = button.rect[1] + 5
    local text_y = button.rect[2] +
        (button.rect[4] - (font_manager.FontHeight or 16)) /
        2 -- Try to vertically center a bit if FontHeight known

    local target_drawable = config.UseRenderer and M.Renderer or M.WindowSurface
    if not target_drawable then
        if config.EnableDebugPrints then
            print(
                "DrawButton Error: Target drawable (Renderer/Surface) not set in graphics_utils.")
        end
        return
    end

    if font_manager and font_manager.DrawText then                                      -- Renamed to PascalCase
        font_manager.DrawText(target_drawable, button.text, text_x, text_y, text_color) -- Renamed to PascalCase
    elseif config.EnableDebugPrintsDetails and config.EnableDebugPrints then
        print("DrawButton Warning: font_manager.DrawText not available.")               -- Renamed to PascalCase
    end
end

return M
