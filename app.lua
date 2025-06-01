-- This file is part of luajit-ffi-sdl3 and is licensed under the MIT License.
-- See the LICENSE.md file in the project root for full license information.
--[[
# MIT License

Copyright (c) 2025 Dario Cangialosi ( a.k.a. <https://Arkenidar.com/coder.php> and <https://github.com/arkenidar>)
--]]

-- Moved module requires and initial setup to the top for correct scoping
local ffi = require 'ffi'
local SDL = require 'sdl3_ffi' -- Store the original library under a new name

local config = require 'config'
local font_manager = require 'font_manager'
local graphics_utils = require 'graphics_utils'

-- Update UseRenderer from config
local UseRenderer = config.UseRenderer
local EnableDebugPrints = config.EnableDebugPrints               -- Use debug print setting from config
local EnableDebugPrintsDetails = config.EnableDebugPrintsDetails -- Use detailed debug print setting from config
-- This example shows how to use SDL3 with LuaJIT and FFI
-- It uses SDL3 to create a window and draw images and rectangles
-- It uses SDL3 renderer or surface blitting depending on the UseRenderer variable

local GlobalCounter = 0                                                                                     -- Initialize GlobalCounter (Renamed from counter)

function RenderScene()                                                                                      -- Renamed from Render
   -- Draw images
   graphics_utils.DrawImage(ActiveImages['Lena'], { 0, 0, ActiveImages['Lena'].w, ActiveImages['Lena'].h }) -- Renamed Image

   graphics_utils.DrawImage(ActiveImages['Lena'], { 40, 40, 50, 50 })                                       -- Renamed Image
   graphics_utils.DrawImage(ActiveImages['Lena'], { 140, 40, 150, 150 })                                    -- Renamed Image

   graphics_utils.DrawImage(ActiveImages['transparent BMP'], { 40 + 10, 40 + 115, 50, 50 })                 -- Renamed Image
   graphics_utils.DrawImage(ActiveImages['transparent BMP'], { 140 + 10, 40 + 115, 150, 150 })              -- Renamed Image

   -- Fill rectangles
   graphics_utils.FillRect({ 40 + 10, 40 + 15, 50, 50 }, 50, 50, 50, 100)

   -- Draw all buttons
   if ApplicationButtons then                     -- Renamed Buttons
      for _, btn in ipairs(ApplicationButtons) do -- Renamed Buttons
         graphics_utils.DrawButton(btn)
      end
   end

   -- Draw the counter
   font_manager.DrawText(UseRenderer and AppRenderer or AppWindowSurface, "Counter: " .. tostring(GlobalCounter), 10, 10, -- Renamed counter
      { r = 255, g = 255, b = 255, a = 255 })                                                                             -- White text
end

SDL_Init(SDL_INIT_VIDEO)

-- REMOVE Font parameters and Globals for font resources and metrics
-- These are now managed by font_manager.lua and configured in config.lua
-- local FontPath = "assets/font.bmp"
-- local FontStartASCII = 32
-- _G.FontGlyphs = {}
-- _G.FontHeight = 0
-- local FONT_CHARACTER_MAP_STRING = ...

-- Function to load a BMP into a surface
function LoadBitmapSurface(filePath, surfaceKey) -- Renamed from LoadBMPSurface
   if not filePath or not surfaceKey then
      if EnableDebugPrints then
         print("LoadBitmapSurface: Error - filePath or surfaceKey is nil.") -- Renamed
      end
      return false
   end
   Surfaces[surfaceKey] = SDL_LoadBMP(filePath)                                                                   -- Renamed Surface
   if Surfaces[surfaceKey] == nil then                                                                            -- Renamed Surface
      if EnableDebugPrints then
         print(string.format("LoadBitmapSurface: Failed to load BMP '%s' for key '%s': %s", filePath, surfaceKey, -- Renamed
            ffi.string(SDL_GetError())))
      end
      return false
   elseif EnableDebugPrints then
      print(string.format("LoadBitmapSurface: Successfully loaded BMP '%s' into Surfaces['%s'].", filePath, surfaceKey)) -- Renamed
   end
   return true
end

-- REMOVE LoadAndProcessCustomFont function (it's now in font_manager.lua)

-- REMOVE DrawText function (it\\\'s now in font_manager.lua)

-- REMOVE GetTextWidth function (it\\\'s now in font_manager.lua)

-- Global/Top-level application variables
-- local UseRenderer = false -- Now sourced from config.lua
local AppWindow = nil                 -- Renamed Window
AppRenderer = nil                     -- Renamed Renderer
AppWindowSurface = nil                -- For surface blitting if UseRenderer is false (Renamed WindowSurface)
Surfaces = {}                         -- Holds SDL_Surface objects, ensure it's global or accessible (Renamed Surface)
Textures = {}                         -- Holds SDL_Texture objects if UseRenderer is true, ensure it's global (Renamed Texture)
ActiveImages = nil                    -- Points to either Surface or Texture table based on UseRenderer (Renamed Image)
ApplicationButtons = {}               -- Table to hold button definitions (Renamed Buttons)
local SdlEvent = ffi.new('SDL_Event') -- For event polling (Renamed Event)
local IsRunning = true                -- Controls the main loop (Renamed Running)

-- Main application setup
function InitializeApplication()                                                                -- Renamed from Setup
   AppWindow = SDL_CreateWindow(config.WindowTitle, config.WindowWidth, config.WindowHeight, 0) -- Renamed Window, used config
   if AppWindow == nil then                                                                     -- Renamed Window
      print("Error creating window: " .. ffi.string(SDL_GetError()))
      os.exit(1)
   end
   SDL_SetWindowResizable(AppWindow, true) -- Renamed Window

   if UseRenderer then
      AppRenderer = SDL_CreateRenderer(AppWindow, nil) -- Renamed Renderer, Window
      if AppRenderer == nil then                       -- Renamed Renderer
         print("Error creating renderer: " .. ffi.string(SDL_GetError()))
         SDL_DestroyWindow(AppWindow)                  -- Renamed Window
         SDL_Quit()
         os.exit(1)
      end
      SDL_SetRenderDrawBlendMode(AppRenderer, SDL_BLENDMODE_BLEND) -- Renamed Renderer
      graphics_utils.InitRendererSurface(AppRenderer, nil)         -- Initialize graphics_utils (Renamed Renderer)
      ActiveImages =
          Textures                                                 -- Use Textures table for images (Renamed Image, Texture)
      if EnableDebugPrints then
         print(string.format("InitializeApplication: UseRenderer=true. AppRenderer Ptr: %s",
            tostring(AppRenderer)))
      end
   else
      AppWindowSurface = SDL_GetWindowSurface(AppWindow) -- Renamed WindowSurface, Window
      if EnableDebugPrints then
         print(string.format(
            "InitializeApplication: SDL_GetWindowSurface called. AppWindowSurface Ptr: %s", tostring(AppWindowSurface)))
      end                             -- DEBUG
      if AppWindowSurface == nil then -- Renamed WindowSurface
         print("Error getting window surface: " .. ffi.string(SDL_GetError()))
         SDL_DestroyWindow(AppWindow) -- Renamed Window
         SDL_Quit()
         os.exit(1)
      end
      graphics_utils.InitRendererSurface(nil, AppWindowSurface) -- Initialize graphics_utils (Renamed WindowSurface)
      ActiveImages = Surfaces                                   -- Use Surfaces table for images (Renamed Image, Surface)
      if EnableDebugPrints then
         print(string.format(
            "InitializeApplication: UseRenderer=false. AppWindowSurface FINAL Ptr: %s", tostring(AppWindowSurface)))
      end
   end

   -- Load font
   -- The call to LoadAndProcessCustomFont was passing SDL as the first argument,
   -- but the function signature was changed to only accept renderer_or_nil.
   if not font_manager.LoadAndProcessCustomFont(UseRenderer and AppRenderer or nil) then
      print("Failed to load font, exiting.")
      SDL_Quit()
      os.exit(1)
   else
      if EnableDebugPrints then print("Font loaded successfully via font_manager.") end
   end

   -- Load images
   if not LoadBitmapSurface("assets/lena.bmp", "Lena") then -- Renamed LoadBMPSurface
      print("Failed to load Lena.bmp")
   end
   if not LoadBitmapSurface("assets/alpha-blend.bmp", "transparent BMP") then -- Renamed LoadBMPSurface
      print("Failed to load alpha-blend.bmp")
   end

   -- Create textures if using renderer
   if UseRenderer then
      if Surfaces["Lena"] then                                                                                          -- Renamed Surface
         Textures["Lena"] = SDL_CreateTextureFromSurface(AppRenderer, Surfaces["Lena"])                                 -- Renamed Texture, Renderer, Surface
         if Textures["Lena"] == nil then print("Failed to create texture for Lena: " .. ffi.string(SDL_GetError())) end -- Renamed Texture
         -- SDL_DestroySurface(Surfaces["Lena"]); Surfaces["Lena"] = nil -- Original surface can be freed (Renamed Surface)
      end
      if Surfaces["transparent BMP"] then                                                                     -- Renamed Surface
         Textures["transparent BMP"] = SDL_CreateTextureFromSurface(AppRenderer, Surfaces["transparent BMP"]) -- Renamed Texture, Renderer, Surface
         if Textures["transparent BMP"] == nil then                                                           -- Renamed Texture
            print("Failed to create texture for transparent BMP: " ..
               ffi.string(SDL_GetError()))
         end
         -- SDL_DestroySurface(Surfaces["transparent BMP"]); Surfaces["transparent BMP"] = nil (Renamed Surface)
      end
   end

   -- Initialize ActiveImages['Lena'] dimensions (example) (Renamed Image)
   if ActiveImages and ActiveImages['Lena'] then                                -- Renamed Image
      if UseRenderer then
         local w_ptr, h_ptr = ffi.new("float[1]"), ffi.new("float[1]")          -- Changed to float
         if SDL_GetTextureSize(ActiveImages['Lena'], w_ptr, h_ptr) then         -- Use SDL_GetTextureSize, returns true on success
            ActiveImages['Lena'].w, ActiveImages['Lena'].h = w_ptr[0], h_ptr[0] -- Renamed Image
         else
            ActiveImages['Lena'].w, ActiveImages['Lena'].h = 0, 0               -- fallback (Renamed Image)
            if EnableDebugPrints then
               print("Warning: SDL_GetTextureSize failed for ActiveImages['Lena'] in Init: " ..
                  ffi.string(SDL_GetError()))
            end
         end
      else                                              -- Surface
         if Surfaces['Lena'] then                       -- Ensure surface exists before accessing w/h
            ActiveImages['Lena'].w = Surfaces['Lena'].w -- Renamed Image
            ActiveImages['Lena'].h = Surfaces['Lena'].h -- Renamed Image
         else
            ActiveImages['Lena'].w = 0 / 0              -- Indicate unset if surface missing
            ActiveImages['Lena'].h = 0 / 0
            if EnableDebugPrints then print("Warning: Surfaces['Lena'] is nil in Init when setting dimensions.") end
         end
      end
   else
      -- Handle case where ActiveImages['Lena'] might not be loaded (Renamed Image)
      if EnableDebugPrints then print("Warning: ActiveImages['Lena'] not available for dimension setup.") end -- Renamed Image
   end


   -- Define buttons (example)
   -- Note: graphics_utils.CreateButton now expects x, y, w, h as separate arguments, not a table for rect.
   -- It also expects color tables for normal, hover, and pressed states.
   local button1X = 400
   local button1W = 100
   ApplicationButtons[1] = graphics_utils.CreateButton("Quit App", button1X, 10, button1W, 30, -- Renamed Buttons
      function() IsRunning = false end,                                                        -- Renamed Running
      { r = 100, g = 100, b = 100, a = 255 },                                                  -- Normal color
      { r = 150, g = 150, b = 150, a = 255 },                                                  -- Hover color
      { r = 200, g = 80, b = 80, a = 255 }                                                     -- Pressed color
   )
   ApplicationButtons[1].anchorToRight = true
   ApplicationButtons[1].offsetFromWindowRightEdge = config.WindowWidth - (button1X + button1W)


   local button2X = 400
   local button2W = 100
   ApplicationButtons[2] = graphics_utils.CreateButton("Test Cnt", button2X, 50, button2W, 30, -- Renamed Buttons
      function()
         GlobalCounter = GlobalCounter + 1
         if EnableDebugPrints then print("GlobalCounter incremented to: " .. GlobalCounter) end -- DEBUG LINE
      end,
      { r = 100, g = 100, b = 100, a = 255 },                                                   -- Normal color
      { r = 150, g = 150, b = 150, a = 255 },                                                   -- Hover color
      { r = 80, g = 200, b = 80, a = 255 }                                                      -- Pressed color
   )
   ApplicationButtons[2].anchorToRight = true
   ApplicationButtons[2].offsetFromWindowRightEdge = config.WindowWidth - (button2X + button2W)
end

SDL_Init(SDL_INIT_VIDEO) -- Ensure SDL_Init is called before InitializeApplication
InitializeApplication()  -- Call InitializeApplication to initialize SDL, window, renderer, load assets etc. (Renamed Setup)

-- Main event loop
print("Starting main loop...")
while IsRunning do                  -- Renamed Running
   while SDL_PollEvent(SdlEvent) do -- Renamed Event
      if EnableDebugPrintsDetails and EnableDebugPrints then
         print(string.format("Event: type=0x%X (%d)", SdlEvent.type,
            SdlEvent.type))
      end                                                                                                -- DEBUG EVENT TYPES
      if SdlEvent.type == SDL_EVENT_QUIT then                                                            -- Renamed Event
         IsRunning = false                                                                               -- Quit from eg window closing (Renamed Running)
      end
      if SdlEvent.type == SDL_EVENT_KEY_DOWN then                                                        -- Renamed Event
         if SdlEvent.key.scancode == SDL_SCANCODE_ESCAPE or SdlEvent.key.scancode == SDL_SCANCODE_Q then -- Renamed Event
            IsRunning = false                                                                            -- Quit from keypress ESCAPE or Q (Renamed Running)
         end
      end
      if SdlEvent.type == SDL_EVENT_MOUSE_BUTTON_DOWN then                                                  -- Renamed Event
         if SdlEvent.button.button == SDL_BUTTON_LEFT then                                                  -- Explicitly use SDL_BUTTON_LEFT (Renamed Event)
            -- print(string.format("Mouse button down: LEFT at (%d, %d)", SdlEvent.button.x, SdlEvent.button.y)) (Renamed Event)
            for _, btn in ipairs(ApplicationButtons) do                                                     -- Renamed Buttons
               if SdlEvent.button.x >= btn.rect[1] and SdlEvent.button.x <= btn.rect[1] + btn.rect[3] and   -- Use btn.rect[1] for x, btn.rect[3] for w (Renamed Event)
                   SdlEvent.button.y >= btn.rect[2] and SdlEvent.button.y <= btn.rect[2] + btn.rect[4] then -- Use btn.rect[2] for y, btn.rect[4] for h (Renamed Event)
                  btn.isPressed = true                                                                      -- Set pressed state
                  if btn.onClick then
                     btn.onClick()                                                                          -- Execute the button's action
                     if EnableDebugPrints then print("Button clicked: " .. btn.text) end
                  end
               end
            end
         end
      elseif SdlEvent.type == SDL_EVENT_MOUSE_BUTTON_UP then -- Handle mouse button release (Renamed Event)
         if SdlEvent.button.button == SDL_BUTTON_LEFT then   -- Renamed Event
            for _, btn in ipairs(ApplicationButtons) do      -- Renamed Buttons
               btn.isPressed = false                         -- Reset pressed state
            end
         end
      elseif SdlEvent.type == SDL_EVENT_MOUSE_MOTION then                                                -- Renamed Event
         for _, btn in ipairs(ApplicationButtons) do                                                     -- Renamed Buttons
            if SdlEvent.motion.x >= btn.rect[1] and SdlEvent.motion.x <= btn.rect[1] + btn.rect[3] and   -- Use btn.rect[1] for x, btn.rect[3] for w (Renamed Event)
                SdlEvent.motion.y >= btn.rect[2] and SdlEvent.motion.y <= btn.rect[2] + btn.rect[4] then -- Use btn.rect[2] for y, btn.rect[4] for h (Renamed Event)
               btn.isHovered = true
            else
               btn.isHovered = false
            end
         end
      elseif SdlEvent.type == SDL_EVENT_WINDOW_RESIZED then -- Renamed Event
         local new_window_width = SdlEvent.window.data1
         local new_window_height = SdlEvent.window.data2    -- Though not used for current X anchoring

         if EnableDebugPrints then
            print("Window resized to: " ..
               new_window_width ..
               "x" .. new_window_height .. string.format(" (Window Event Type: %d)", tonumber(SdlEvent.window.type)))
         end -- Log window event type

         -- Update positions of buttons anchored to the right
         for _, btn in ipairs(ApplicationButtons) do
            if btn.anchorToRight and btn.offsetFromWindowRightEdge then
               btn.rect[1] = new_window_width - btn.rect[3] - btn.offsetFromWindowRightEdge
               -- Ensure button doesn't go off-screen to the left if window becomes too small
               if btn.rect[1] < 0 then btn.rect[1] = 0 end
            end
         end

         if not UseRenderer then
            local new_surface = SDL_GetWindowSurface(AppWindow) -- Renamed Window
            if EnableDebugPrints then
               print(string.format(
                  "Resize Handler: SDL_GetWindowSurface called. New Surface Ptr: %s", tostring(new_surface)))
            end -- DEBUG
            if new_surface == nil then
               print("Error getting window surface after resize: " .. ffi.string(SDL_GetError()))
               IsRunning = false -- Critical error (Renamed Running)
            else
               AppWindowSurface =
                   new_surface                                           -- Renamed WindowSurface
               graphics_utils.InitRendererSurface(nil, AppWindowSurface) -- Re-initialize graphics_utils
               if EnableDebugPrints then
                  print(string.format("Resize Handler: AppWindowSurface updated. New Ptr: %s",
                     tostring(AppWindowSurface)))
               end -- Renamed WindowSurface
            end
         end
      end
   end

   -- Rendering logic
   if UseRenderer then
      SDL_SetRenderDrawColor(AppRenderer, 0, 0, 0, 255) -- Clear to black (Renamed Renderer)
      SDL_RenderClear(AppRenderer)                      -- Renamed Renderer
      RenderScene()                                     -- Call the main render function (Renamed Render)
      SDL_RenderPresent(AppRenderer)                    -- Renamed Renderer
   else
      if EnableDebugPrints then
         print(string.format("MainLoop Pre-Render (Surface Mode): AppWindowSurface Ptr: %s, IsRunning: %s",
            tostring(AppWindowSurface), tostring(IsRunning))) -- DEBUG
      end
      if AppWindowSurface then                                -- Renamed WindowSurface
         SDL_FillSurfaceRect(AppWindowSurface, nil, 0)        -- Clear to black (0 is black for default format) (Renamed WindowSurface)
         RenderScene()                                        -- Call the main render function (Renamed Render)
         SDL_UpdateWindowSurface(AppWindow)                   -- Renamed Window
      end
   end

   SDL_Delay(16) -- Aim for ~60 FPS
end
print("Exiting main loop...")

-- Cleanup (ShutdownApplication function will print its own "Starting cleanup..." message) (Renamed Quit)
-- print("Starting cleanup...") -- This line is redundant as ShutdownApplication() handles it. (Renamed Quit)

function ShutdownApplication() -- Renamed from Quit
   if EnableDebugPrints then print("Starting cleanup...") end

   font_manager.Cleanup() -- Cleanup font resources

   -- Destroy textures
   if Textures then                                      -- Renamed Texture
      for key, tex in pairs(Textures) do                 -- Renamed Texture
         if tex and tex ~= font_manager.FontTexture then -- Avoid double-free if font_manager also puts its texture here
            if EnableDebugPrints then print("Destroying texture: " .. key) end
            SDL_DestroyTexture(tex)
            Textures[key] = nil -- Renamed Texture
         end
      end
      if EnableDebugPrints then print("Textures destroyed.") end
   else
      if EnableDebugPrints then print("Textures table was nil or empty.") end -- Renamed Texture
   end
   Textures = nil                                                             -- Clear the table itself (Renamed Texture)

   -- Destroy surfaces
   if Surfaces then                                        -- Renamed Surface
      for key, surf in pairs(Surfaces) do                  -- Renamed Surface
         if surf and surf ~= font_manager.FontSurface then -- Avoid double-free
            if EnableDebugPrints then print("Destroying surface: " .. key) end
            SDL_DestroySurface(surf)                       -- Added SDL_ prefix
            Surfaces[key] = nil                            -- Renamed Surface
         end
      end
      if EnableDebugPrints then print("Surfaces destroyed.") end
   else
      if EnableDebugPrints then print("Surface table was nil or empty.") end -- Renamed Surface
   end
   Surfaces = nil                                                            -- Clear the table itself (Renamed Surface)

   if AppRenderer then                                                       -- Renamed Renderer
      if EnableDebugPrints then print("Destroying renderer...") end
      SDL_DestroyRenderer(AppRenderer)                                       -- Renamed Renderer
      AppRenderer = nil                                                      -- Renamed Renderer
      if EnableDebugPrints then print("Renderer destroyed.") end
   end
   -- AppWindowSurface is typically not destroyed manually if obtained from SDL.GetWindowSurface, (Renamed WindowSurface)
   -- as SDL manages it with the window.

   if AppWindow then               -- Renamed Window
      if EnableDebugPrints then print("Destroying window...") end
      SDL_DestroyWindow(AppWindow) -- Renamed Window
      AppWindow = nil              -- Renamed Window
      if EnableDebugPrints then print("Window destroyed.") end
   end

   SDL_Quit()
   if EnableDebugPrints then print("SDL_Quit() called. Exiting application.") end
end

ShutdownApplication() -- Call ShutdownApplication to clean up resources and shut down SDL (Renamed Quit)
