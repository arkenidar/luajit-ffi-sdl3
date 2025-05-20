local sdl = require 'sdl3_ffi' -- cp /c/msys64/mingw64/bin/SDL3.dll .
local ffi = require 'ffi'
local C = ffi.C

sdl.init(sdl.INIT_VIDEO)

local window = sdl.createWindow("Hello Lena", 512, 512, 0)
sdl.setWindowResizable(window, true)
-- sdl.setWindowFullscreen(window, sdl.WINDOW_FULLSCREEN_DESKTOP)
-- sdl.setWindowFullscreen(window, sdl.WINDOW_FULLSCREEN)
-- sdl.setWindowOpacity(window, 0.5)

---local windowsurface = sdl.getWindowSurface(window)

local imageSurface1 = sdl.LoadBMP("assets/lena.bmp")        -- sdl.destroySurface(imageSurface1)
local imageSurface2 = sdl.LoadBMP("assets/alpha-blend.bmp") -- sdl.destroySurface(imageSurface2)
-- sdl.setSurfaceBlendMode(imageSurface1, sdl.BLENDMODE_BLEND)
-- sdl.setSurfaceBlendMode(imageSurface1, sdl.BLENDMODE_NONE)

local function rect_from_xywh(xywh)
   ---if xywh == nil then return nil end
   local rect = ffi.new('SDL_Rect')
   rect.x = xywh[1]
   rect.y = xywh[2]
   rect.w = xywh[3] -- or 1
   rect.h = xywh[4] -- or 1
   return rect
end

local function drawImage(imageSurface, xywh)
   sdl.BlitSurfaceScaled(imageSurface, nil, windowsurface, rect_from_xywh(xywh), sdl.SCALEMODE_NEAREST)
end

-- Helper: fill a rectangle with alpha blending using a temp surface
local function fillRectAlphaBlend(targetSurface, xywh, r, g, b, a)
   if xywh == nil then
      xywh = { 0, 0, targetSurface.w, targetSurface.h }
   end
   local rect = rect_from_xywh(xywh)
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

   -- sdl.BlitSurface(imageSurface1, nil, windowsurface, rect_from_xywh({40, 40, 50, 50}))

   -- sdl.BlitSurfaceScaled(imageSurface1, nil, windowsurface, rect_from_xywh({40, 40, 50, 50}), sdl.SCALEMODE_NEAREST)

   drawImage(imageSurface1, { 40, 40, 50, 50 })
   drawImage(imageSurface1, { 140, 40, 150, 150 })

   drawImage(imageSurface2, { 40 + 10, 40 + 115, 50, 50 })
   drawImage(imageSurface2, { 140 + 10, 40 + 115, 150, 150 })

   -- rectangles

   fillRectAlphaBlend(windowsurface, { 40 + 10, 40 + 15, 50, 50 }, 50, 50, 50, 100)

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
