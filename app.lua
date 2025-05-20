local sdl = require 'sdl3_ffi' -- cp /c/msys64/mingw64/bin/SDL3.dll .
local ffi = require 'ffi'

sdl.init(sdl.INIT_VIDEO)

UseRenderer = false -- Set to false to use SDL3 surface blitting instead of renderer

Window = sdl.createWindow("Hello Lena", 512, 512, 0)
sdl.setWindowResizable(Window, true)

if UseRenderer then
   Renderer = sdl.createRenderer(Window, "software")
   sdl.setRenderDrawBlendMode(Renderer, sdl.BLENDMODE_BLEND)
end

local Surface = {}
Surface[1] = sdl.LoadBMP("assets/lena.bmp")
Surface[2] = sdl.LoadBMP("assets/alpha-blend.bmp")

local Texture = {}
if UseRenderer then
   for key, value in pairs(Surface) do
      Texture[key] = sdl.createTextureFromSurface(Renderer, value)
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
      sdl.renderTexture(Renderer, imageDrawable, nil, RectangleFromXYWH(xywh))
   else
      sdl.BlitSurfaceScaled(imageDrawable, nil, WindowSurface, RectangleFromXYWH(xywh), sdl.SCALEMODE_NEAREST)
   end
end


local function fillRect(xywh, r, g, b, a)
   if UseRenderer then
      sdl.setRenderDrawColor(Renderer, r, g, b, a)
      sdl.renderFillRect(Renderer, RectangleFromXYWH(xywh))
   else
      -- Helper: fill a rectangle with alpha blending using a temp surface
      local rectangle = RectangleFromXYWH(xywh)

      -- Create a temp RGBA surface
      local temp = sdl.createSurface(rectangle.w, rectangle.h, sdl.PIXELFORMAT_RGBA32)
      if temp == nil then return end
      sdl.setSurfaceBlendMode(temp, sdl.BLENDMODE_BLEND)
      local color = sdl.mapSurfaceRGBA(temp, r, g, b, a)
      sdl.fillSurfaceRect(temp, nil, color)

      -- Blit with blending onto target
      sdl.BlitSurface(temp, nil, WindowSurface, rectangle)
      sdl.destroySurface(temp)
   end
end

local running = true
local event = ffi.new('SDL_Event')
while running do
   -- Input events
   while sdl.pollEvent(event) do
      if event.type == sdl.EVENT_QUIT then
         running = false -- Quit from eg window closing
      end
      if event.type == sdl.EVENT_KEY_DOWN then
         if event.key.scancode == sdl.SCANCODE_ESCAPE or event.key.scancode == sdl.SCANCODE_Q then
            running = false -- Quit from keypress ESCAPE or Q
         end
      end
   end

   -- Draw , init and clear

   if UseRenderer then
      -- Clear renderer
      sdl.setRenderDrawColor(Renderer, 128, 128, 128, 255)
      sdl.renderClear(Renderer)
   else
      -- Init window surface
      WindowSurface = sdl.getWindowSurface(Window)
      -- Clear window surface
      local color = sdl.mapSurfaceRGBA(WindowSurface, 128, 128, 128, 255)
      sdl.fillSurfaceRect(WindowSurface, nil, color)
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
      sdl.renderPresent(Renderer)
   else
      sdl.updateWindowSurface(Window)
   end
end

-- Exiting ...

-- Cleanup

for _, surface in pairs(Surface) do
   -- Destroy Surfaces
   sdl.destroySurface(surface)
end

if UseRenderer then
   -- Destroy renderer Textures
   for _, texture in pairs(Texture) do
      sdl.destroyTexture(texture)
   end
end

if UseRenderer then
   -- Destroy Renderer
   sdl.destroyRenderer(Renderer)
end

-- Destroy Window
sdl.destroyWindow(Window)

-- Quit SDL3
sdl.quit()
