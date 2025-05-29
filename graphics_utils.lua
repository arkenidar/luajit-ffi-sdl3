-- graphics_utils.lua
local ffi = require 'ffi'
local config = require 'config'

local M = {}

-- Helper to access SDL functions via _G or a passed SDL table
local function _SDL(func_name)
    return _G["SDL_" .. func_name]
end

-- Store Renderer and WindowSurface globally within this module after they are initialized
M.Renderer = nil
M.WindowSurface = nil

function M.init_renderer_surface(renderer, window_surface)
    M.Renderer = renderer
    M.WindowSurface = window_surface
end

function M.rectangleFromXYWH(xywh)
    local rect_type = config.UseRenderer and 'SDL_FRect' or 'SDL_Rect'
    local rectangle = ffi.new(rect_type)
    rectangle.x = xywh[1]
    rectangle.y = xywh[2]
    rectangle.w = xywh[3]
    rectangle.h = xywh[4]
    return rectangle
end

function M.loadBMPSurface(SDL, filePath, surfaceKey, targetSurfaceTable)
    if not filePath or not surfaceKey then
        if config.EnableDebugPrints then print("LoadBMPSurface: Error - filePath or surfaceKey is nil.") end
        return false
    end
    targetSurfaceTable[surfaceKey] = SDL.LoadBMP(filePath)
    if targetSurfaceTable[surfaceKey] == nil then
        if config.EnableDebugPrints then
            print(string.format("LoadBMPSurface: Failed to load BMP '%s' for key '%s': %s", filePath, surfaceKey,
                ffi.string(SDL.GetError())))
        end
        return false
    elseif config.EnableDebugPrints then
        print(string.format("LoadBMPSurface: Successfully loaded BMP '%s' into Surface['%s'].", filePath, surfaceKey))
    end
    return true
end

function M.drawImage(imageDrawable, xywh)
    if not imageDrawable then
        if config.EnableDebugPrints then print("DrawImage: imageDrawable is nil.") end
        return
    end
    local dest_rect = M.rectangleFromXYWH(xywh)
    if config.UseRenderer then
        if not M.Renderer then
            print("DrawImage Error: Renderer not initialized in graphics_utils.")
            return
        end
        _SDL("RenderTexture")(M.Renderer, imageDrawable, nil, dest_rect)
    else
        if not M.WindowSurface then
            print("DrawImage Error: WindowSurface not initialized in graphics_utils.")
            return
        end
        _SDL("BlitSurfaceScaled")(imageDrawable, nil, M.WindowSurface, dest_rect, _SDL("SCALEMODE_NEAREST"))
    end
end

function M.fillRect(xywh, r, g, b, a)
    local rectangle = M.rectangleFromXYWH(xywh)
    if config.UseRenderer then
        if not M.Renderer then
            print("FillRect Error: Renderer not initialized in graphics_utils.")
            return
        end
        _SDL("SetRenderDrawColor")(M.Renderer, r, g, b, a)
        _SDL("RenderFillRect")(M.Renderer, rectangle)
    else
        if not M.WindowSurface then
            print("FillRect Error: WindowSurface not initialized in graphics_utils.")
            return
        end
        -- Create a temp RGBA surface for blending
        local temp_surface = _SDL("CreateSurface")(rectangle.w, rectangle.h, _SDL("PIXELFORMAT_RGBA32"))
        if temp_surface == nil then
            if config.EnableDebugPrints then print("FillRect Error: Could not create temp surface: " ..
                ffi.string(_SDL("GetError")())) end
            return
        end
        _SDL("SetSurfaceBlendMode")(temp_surface, _SDL("BLENDMODE_BLEND"))
        local color = _SDL("MapSurfaceRGBA")(temp_surface, r, g, b, a)
        _SDL("FillSurfaceRect")(temp_surface, nil, color)
        _SDL("BlitSurface")(temp_surface, nil, M.WindowSurface, rectangle)
        _SDL("DestroySurface")(temp_surface)
    end
end

return M
