local SDL = require 'sdl3_ffi' -- cp /c/msys64/mingw64/bin/SDL3.dll .
local ffi = require 'ffi'

SDL.init(SDL.INIT_VIDEO)

UseRenderer = true -- Set to false to use SDL3 surface blitting instead of renderer

Window = SDL.createWindow("Hello Lena", 512, 512, 0)
SDL.setWindowResizable(Window, true)

if UseRenderer then
   Renderer = SDL.createRenderer(Window, "software")
   SDL.setRenderDrawBlendMode(Renderer, SDL.BLENDMODE_BLEND)
end

local Surface = {}
Surface[1] = SDL.LoadBMP("assets/lena.bmp")
Surface[2] = SDL.LoadBMP("assets/alpha-blend.bmp")

local Texture = {}
if UseRenderer then
   for key, value in pairs(Surface) do
      Texture[key] = SDL.createTextureFromSurface(Renderer, value)
   end
end

local Image = UseRenderer and Texture or Surface

function RectangleFromXYWH(xywh)
   local rectangle = ffi.new(UseRenderer and 'SDL_FRect' or 'SDL_Rect')
   rectangle.x = xywh[1]
   rectangle.y = xywh[2]
   rectangle.w = xywh[3]
   rectangle.h = xywh[4]
   return rectangle
end

local function drawImage(imageDrawable, xywh)
   if UseRenderer then
      SDL.renderTexture(Renderer, imageDrawable, nil, RectangleFromXYWH(xywh))
   else
      SDL.BlitSurfaceScaled(imageDrawable, nil, WindowSurface, RectangleFromXYWH(xywh), SDL.SCALEMODE_NEAREST)
   end
end


local function fillRect(xywh, r, g, b, a)
   if UseRenderer then
      SDL.setRenderDrawColor(Renderer, r, g, b, a)
      SDL.renderFillRect(Renderer, RectangleFromXYWH(xywh))
   else
      -- Helper: fill a rectangle with alpha blending using a temp surface
      local rectangle = RectangleFromXYWH(xywh)

      -- Create a temp RGBA surface
      local temp = SDL.createSurface(rectangle.w, rectangle.h, SDL.PIXELFORMAT_RGBA32)
      if temp == nil then return end
      SDL.setSurfaceBlendMode(temp, SDL.BLENDMODE_BLEND)
      local color = SDL.mapSurfaceRGBA(temp, r, g, b, a)
      SDL.fillSurfaceRect(temp, nil, color)

      -- Blit with blending onto target
      SDL.BlitSurface(temp, nil, WindowSurface, rectangle)
      SDL.destroySurface(temp)
   end
end

local running = true
local event = ffi.new('SDL_Event')
while running do
   -- Input events
   while SDL.pollEvent(event) do
      if event.type == SDL.EVENT_QUIT then
         running = false -- Quit from eg window closing
      end
      if event.type == SDL.EVENT_KEY_DOWN then
         if event.key.scancode == SDL.SCANCODE_ESCAPE or event.key.scancode == SDL.SCANCODE_Q then
            running = false -- Quit from keypress ESCAPE or Q
         end
      end
   end

   -- Draw , init and clear

   if UseRenderer then
      -- Clear renderer
      SDL.setRenderDrawColor(Renderer, 128, 128, 128, 255)
      SDL.renderClear(Renderer)
   else
      -- Init window surface
      WindowSurface = SDL.getWindowSurface(Window)
      -- Clear window surface
      local color = SDL.mapSurfaceRGBA(WindowSurface, 128, 128, 128, 255)
      SDL.fillSurfaceRect(WindowSurface, nil, color)
   end

   -- After clear

   -- Draw images
   drawImage(Image[1], { 0, 0, 512, 512 }) -- Full window as sizing

   drawImage(Image[1], { 40, 40, 50, 50 })
   drawImage(Image[1], { 140, 40, 150, 150 })

   drawImage(Image[2], { 40 + 10, 40 + 115, 50, 50 })
   drawImage(Image[2], { 140 + 10, 40 + 115, 150, 150 })


   -- Fill rectangles
   fillRect({ 40 + 10, 40 + 15, 50, 50 }, 50, 50, 50, 100)

   -- End of framebuffer drawing

   -- Present the renderer or update the window surface
   if UseRenderer then
      SDL.renderPresent(Renderer)
   else
      SDL.updateWindowSurface(Window)
   end
end

-- Exiting ...

-- Cleanup

for _, surface in pairs(Surface) do
   -- Destroy Surfaces
   SDL.destroySurface(surface)
end

if UseRenderer then
   -- Destroy renderer Textures
   for _, texture in pairs(Texture) do
      SDL.destroyTexture(texture)
   end
end

if UseRenderer then
   -- Destroy Renderer
   SDL.destroyRenderer(Renderer)
end

-- Destroy Window
SDL.destroyWindow(Window)

-- Quit SDL3
SDL.quit()
