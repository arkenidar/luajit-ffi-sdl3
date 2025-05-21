-- This file is part of luajit-ffi-sdl3 and is licensed under the MIT License.
-- See the LICENSE file in the project root for full license information.
--[[
# MIT License

Copyright (c) 2025 Dario Cangialosi ( a.k.a. <https://Arkenidar.com/coder.php> and <https://github.com/arkenidar>)
--]]
---@diagnostic disable: undefined-global

-- This example shows how to use SDL3 with LuaJIT and FFI
-- It uses SDL3 to create a window and draw images and rectangles
-- It uses SDL3 renderer or surface blitting depending on the UseRenderer variable

function Render()
   -- Draw images
   DrawImage(Image['Lena'], { 0, 0, 512, 512 }) -- Full window as sizing

   DrawImage(Image['Lena'], { 40, 40, 50, 50 })
   DrawImage(Image['Lena'], { 140, 40, 150, 150 })

   DrawImage(Image['transparent BMP'], { 40 + 10, 40 + 115, 50, 50 })
   DrawImage(Image['transparent BMP'], { 140 + 10, 40 + 115, 150, 150 })

   -- Fill rectangles
   FillRect({ 40 + 10, 40 + 15, 50, 50 }, 50, 50, 50, 100)
end

local SDL = require 'sdl3_ffi'
local ffi = require 'ffi'

_G = setmetatable(_G, {
   __index = function(self, index)
      if "SDL_" == string.sub(index, 1, 4) then
         local searched = string.sub(index, 5, #index)
         return SDL[searched]
      end
   end
})

SDL_Init(SDL_INIT_VIDEO)

UseRenderer = true -- Set to false to use SDL3 surface blitting instead of renderer

Window = SDL_CreateWindow("Hello Lena", 512, 512, 0)
SDL_SetWindowResizable(Window, true)

if UseRenderer then
   Renderer = SDL_CreateRenderer(Window, "software")
   SDL_SetRenderDrawBlendMode(Renderer, SDL_BLENDMODE_BLEND)
end

local Surface = {}
Surface['Lena'] = SDL_LoadBMP("assets/lena.bmp")
Surface['transparent BMP'] = SDL_LoadBMP("assets/alpha-blend.bmp")

local Texture = {}
if UseRenderer then
   for key, value in pairs(Surface) do
      Texture[key] = SDL_CreateTextureFromSurface(Renderer, value)
   end
end

Image = UseRenderer and Texture or Surface

function RectangleFromXYWH(xywh)
   local rectangle = ffi.new(UseRenderer and 'SDL_FRect' or 'SDL_Rect')
   rectangle.x = xywh[1]
   rectangle.y = xywh[2]
   rectangle.w = xywh[3]
   rectangle.h = xywh[4]
   return rectangle
end

function DrawImage(imageDrawable, xywh)
   if UseRenderer then
      SDL_RenderTexture(Renderer, imageDrawable, nil, RectangleFromXYWH(xywh))
   else
      SDL_BlitSurfaceScaled(imageDrawable, nil, WindowSurface, RectangleFromXYWH(xywh), SDL_SCALEMODE_NEAREST)
   end
end

function FillRect(xywh, r, g, b, a)
   if UseRenderer then
      SDL_SetRenderDrawColor(Renderer, r, g, b, a)
      SDL_RenderFillRect(Renderer, RectangleFromXYWH(xywh))
   else
      -- Helper: fill a rectangle with alpha blending using a temp surface
      local rectangle = RectangleFromXYWH(xywh)

      -- Create a temp RGBA surface
      local temp = SDL_CreateSurface(rectangle.w, rectangle.h, SDL_PIXELFORMAT_RGBA32)
      if temp == nil then return end
      SDL_SetSurfaceBlendMode(temp, SDL_BLENDMODE_BLEND)
      local color = SDL_MapSurfaceRGBA(temp, r, g, b, a)
      SDL_FillSurfaceRect(temp, nil, color)

      -- Blit with blending onto target
      SDL_BlitSurface(temp, nil, WindowSurface, rectangle)
      SDL_DestroySurface(temp)
   end
end

local running = true
local event = ffi.new('SDL_Event')
while running do
   -- Input events
   while SDL_PollEvent(event) do
      if event.type == SDL_EVENT_QUIT then
         running = false -- Quit from eg window closing
      end
      if event.type == SDL_EVENT_KEY_DOWN then
         if event.key.scancode == SDL_SCANCODE_ESCAPE or event.key.scancode == SDL_SCANCODE_Q then
            running = false -- Quit from keypress ESCAPE or Q
         end
      end
   end

   -- Draw , init and clear

   if UseRenderer then
      -- Clear renderer
      SDL_SetRenderDrawColor(Renderer, 128, 128, 128, 255)
      SDL_RenderClear(Renderer)
   else
      -- Init window surface
      WindowSurface = SDL_GetWindowSurface(Window)
      -- Clear window surface
      local color = SDL_MapSurfaceRGBA(WindowSurface, 128, 128, 128, 255)
      SDL_FillSurfaceRect(WindowSurface, nil, color)
   end

   -- After clear

   Render()

   -- End of framebuffer drawing

   -- Present the renderer or update the window surface
   if UseRenderer then
      SDL_RenderPresent(Renderer)
   else
      SDL_UpdateWindowSurface(Window)
   end
end

-- Exiting ...

-- Cleanup

for _, surface in pairs(Surface) do
   -- Destroy Surfaces
   SDL_DestroySurface(surface)
end

if UseRenderer then
   -- Destroy renderer Textures
   for _, texture in pairs(Texture) do
      SDL_DestroyTexture(texture)
   end
end

if UseRenderer then
   -- Destroy Renderer
   SDL_DestroyRenderer(Renderer)
end

-- Destroy Window
SDL_DestroyWindow(Window)

-- Quit SDL3
SDL_Quit()
