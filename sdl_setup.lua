-- sdl_setup.lua
local ffi = require 'ffi'

local M = {}

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
