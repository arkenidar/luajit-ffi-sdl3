-- sdl_setup.lua
local ffi = require 'ffi'

local M = {}

function M.init_sdl_global(SDL_target_table)
    _G = setmetatable(_G, {
        __index = function(self, index)
            if type(index) == "string" and "SDL_" == string.sub(index, 1, 4) then
                local searched = string.sub(index, 5, #index)
                if SDL_target_table[searched] ~= nil then
                    return SDL_target_table[searched]
                else
                    if SDL_target_table[index] ~= nil then
                        return SDL_target_table[index]
                    end
                end
            end
            return rawget(self, index) -- Fallback for non-SDL globals
        end
    })
    return SDL_target_table -- Return the SDL table itself for direct use if needed
end

function M.init_video(SDL)
    if SDL.Init(SDL.INIT_VIDEO) < 0 then
        print("SDL could not initialize! SDL_Error: " .. ffi.string(SDL.GetError()))
        os.exit(1)
    end
end

function M.create_window(SDL, title, width, height)
    local window = SDL.CreateWindow(title, width, height, 0)
    if window == nil then
        print("Window could not be created! SDL_Error: " .. ffi.string(SDL.GetError()))
        SDL.Quit()
        os.exit(1)
    end
    SDL.SetWindowResizable(window, true)
    return window
end

function M.create_renderer(SDL, window)
    local renderer = SDL.CreateRenderer(window, "software")
    if renderer == nil then
        print("Renderer could not be created! SDL_Error: " .. ffi.string(SDL.GetError()))
        SDL.DestroyWindow(window)
        SDL.Quit()
        os.exit(1)
    end
    SDL.SetRenderDrawBlendMode(renderer, SDL.BLENDMODE_BLEND)
    return renderer
end

function M.get_window_surface(SDL, window)
    local surface = SDL.GetWindowSurface(window)
    if surface == nil then
        print("Window surface could not be retrieved! SDL_Error: " .. ffi.string(SDL.GetError()))
        SDL.DestroyWindow(window)
        SDL.Quit()
        os.exit(1)
    end
    return surface
end

return M
