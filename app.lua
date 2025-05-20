local sdl = require 'sdl3_ffi' -- cp /c/msys64/mingw64/bin/SDL3.dll .
local ffi = require 'ffi'
local C = ffi.C

sdl.init(sdl.INIT_VIDEO)

local window = sdl.createWindow("Hello Lena", 512, 512, 0)
sdl.setWindowResizable(window, true)

local imageSurface1 = sdl.LoadBMP("assets/lena.bmp")
local imageSurface2 = sdl.LoadBMP("assets/alpha-blend.bmp")

local function rectangle_from_xywh(xywh)
   local rectangle = ffi.new('SDL_Rect')
   rectangle.x = xywh[1]
   rectangle.y = xywh[2]
   rectangle.w = xywh[3]
   rectangle.h = xywh[4]
   return rectangle
end

local function drawImage(imageSurface, xywh)
   sdl.BlitSurfaceScaled(imageSurface, nil, windowsurface, rectangle_from_xywh(xywh), sdl.SCALEMODE_NEAREST)
end

-- Helper: fill a rectangle with alpha blending using a temp surface
local function fillRectAlphaBlend(xywh, r, g, b, a, targetSurface)
   if targetSurface == nil then
      targetSurface = windowsurface
   end
   if xywh == nil then
      xywh = { 0, 0, targetSurface.w, targetSurface.h }
   end
   local rect = rectangle_from_xywh(xywh)
   -- Create a temp RGBA surface
   local temp = sdl.createSurface(rect.w, rect.h, sdl.PIXELFORMAT_RGBA32)
   if temp == nil then return end
   sdl.setSurfaceBlendMode(temp, sdl.BLENDMODE_BLEND)
   local color = sdl.mapSurfaceRGBA(temp, r, g, b, a)
   sdl.fillSurfaceRect(temp, nil, color)
   -- Blit with blending onto target
   sdl.BlitSurface(temp, nil, targetSurface, rect)
   sdl.destroySurface(temp)
end

-- Create renderer and texture from surface example
local renderer = sdl.createRenderer(window, "software")

local function textureFromSurface(surface)
   return sdl.createTextureFromSurface(renderer, surface)
end

-- Example usage:
-- local lenaTexture = textureFromSurface(imageSurface1)
-- sdl.renderCopy(renderer, lenaTexture, nil, nil)
-- sdl.renderPresent(renderer)
-- sdl.destroyTexture(lenaTexture)

local running = true
local event = ffi.new('SDL_Event')
while running do
   -- input events

   while sdl.pollEvent(event) do
      if event.type == sdl.EVENT_QUIT then
         running = false
      end
      if event.type == sdl.EVENT_KEY_DOWN then
         if event.key.scancode == sdl.SCANCODE_ESCAPE or event.key.scancode == sdl.SCANCODE_Q then
            running = false
         end
      end
   end

   -- draw init

   windowsurface = sdl.getWindowSurface(window)

   -- fill background with grey
   local grey = sdl.mapSurfaceRGBA(windowsurface, 128, 128, 128, 255)
   sdl.fillSurfaceRect(windowsurface, nil, grey)

   -- surfaces

   drawImage(imageSurface1, { 40, 40, 50, 50 })
   drawImage(imageSurface1, { 140, 40, 150, 150 })

   drawImage(imageSurface2, { 40 + 10, 40 + 115, 50, 50 })
   drawImage(imageSurface2, { 140 + 10, 40 + 115, 150, 150 })

   -- rectangles

   fillRectAlphaBlend({ 40 + 10, 40 + 15, 50, 50 }, 50, 50, 50, 100)

   -- end

   sdl.updateWindowSurface(window)

   --[[
   -- render

   sdl.setRenderDrawColor(renderer, 255, 0, 0, 255)
   sdl.renderClear(renderer)

   -- after clear

   -- NOTE is loadtextture available ? maybe not

   sdl.setRenderDrawColor(renderer, 100, 100, 0, 255)
   sdl.renderFillRect(renderer, rect_from_xywh({40, 40, 50, 50}))

   -- end render

   sdl.renderPresent(renderer)
   --]]
end

sdl.destroySurface(imageSurface1)
sdl.destroySurface(imageSurface2)

-- sdl.destroyRenderer(renderer)
sdl.destroyWindow(window)
sdl.quit()
