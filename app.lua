-- This file is part of luajit-ffi-sdl3 and is licensed under the MIT License.
-- See the LICENSE.md file in the project root for full license information.
--[[
# MIT License

Copyright (c) 2025 Dario Cangialosi ( a.k.a. <https://Arkenidar.com/coder.php> and <https://github.com/arkenidar>)
--]]
---@diagnostic disable: undefined-global

-- This example shows how to use SDL3 with LuaJIT and FFI
-- It uses SDL3 to create a window and draw images and rectangles
-- It uses SDL3 renderer or surface blitting depending on the UseRenderer variable

local counter = 0 -- Initialize counter

function Render()
   -- Draw Lena image
   if Image and Image['Lena'] then
      local w_lena, h_lena
      if UseRenderer then
         local w_ptr, h_ptr = ffi.new("int[1]"), ffi.new("int[1]")
         if SDL_QueryTexture(Image['Lena'], nil, nil, w_ptr, h_ptr) == 0 then
            w_lena, h_lena = w_ptr[0], h_ptr[0]
            Image['Lena'].w, Image['Lena'].h = w_lena, h_lena
         end
      end

      -- Draw images
      DrawImage(Image['Lena'], { 0, 0, Image['Lena'].w, Image['Lena'].h }) -- Full window as sizing

      DrawImage(Image['Lena'], { 40, 40, 50, 50 })
      DrawImage(Image['Lena'], { 140, 40, 150, 150 })

      DrawImage(Image['transparent BMP'], { 40 + 10, 40 + 115, 50, 50 })
      DrawImage(Image['transparent BMP'], { 140 + 10, 40 + 115, 150, 150 })

      -- Fill rectangles
      FillRect({ 40 + 10, 40 + 15, 50, 50 }, 50, 50, 50, 100)
   end

   -- Draw all buttons
   if Buttons then
      for _, btn in ipairs(Buttons) do
         DrawButton(btn)
      end
   end

   -- Draw the counter
   DrawText("Counter: " .. tostring(counter), 10, 10, { r = 255, g = 0, b = 0, a = 255 }) -- Red text
end

local SDL = require 'sdl3_ffi'
local ffi = require 'ffi'

-- Metatable to allow calling SDL functions/constants globally
_G = setmetatable(_G, {
   __index = function(self, index)
      if type(index) == "string" and "SDL_" == string.sub(index, 1, 4) then
         local searched = string.sub(index, 5, #index)
         if SDL[searched] ~= nil then
            return SDL[searched]
         else
            -- Fallback for SDL_ prefixed keys not found in SDL table after stripping prefix
            -- This could indicate an issue or a constant defined elsewhere.
            -- For now, we'll try the original index in the SDL table as a last resort for SDL_ prefixed keys.
            if SDL[index] ~= nil then
               return SDL[index]
            end
         end
      end
      return rawget(self, index) -- Fallback for non-SDL globals or if SDL is not loaded
   end
})

SDL_Init(SDL_INIT_VIDEO)

local EnableDebugPrints = true -- Set to true to enable debug prints for font processing

-- Font parameters
local FontPath = "assets/font.bmp" -- Your 32-bit BMP with alpha and yellow separators
local FontStartASCII = 32          -- ASCII value of the first character in your font image

-- Globals for font resources and metrics
_G.FontGlyphs = {} -- Changed to global
-- Removed local FontSurface and FontTexture, as they will be managed in Surface['font'] and Texture['font']
_G.FontHeight = 0  -- Changed to global

-- 84 characters :
local FONT_CHARACTER_MAP_STRING =
[[ abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,!?-+/():;%&`'*#=[]"]] -- User's specific 84 characters
--local FONT_CHARACTER_MAP_STRING = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,!?-+/():;%&\'*#=[]\\\""

-- Function to load a BMP into a surface
function LoadBMPSurface(filePath, surfaceKey)
   if not filePath or not surfaceKey then
      if EnableDebugPrints then
         print("LoadBMPSurface: Error - filePath or surfaceKey is nil.")
      end
      return false
   end
   Surface[surfaceKey] = SDL_LoadBMP(filePath)
   if Surface[surfaceKey] == nil then
      if EnableDebugPrints then
         print(string.format("LoadBMPSurface: Failed to load BMP '%s' for key '%s': %s", filePath, surfaceKey,
            ffi.string(SDL_GetError())))
      end
      return false
   elseif EnableDebugPrints then
      print(string.format("LoadBMPSurface: Successfully loaded BMP '%s' into Surface['%s'].", filePath, surfaceKey))
   end
   return true
end

-- New function to load and process the custom font
function LoadAndProcessCustomFont(path, startASCII)
   -- Ensure Surface and Texture tables exist (should be initialized before this call)
   Surface = Surface or {}
   Texture = Texture or {}

   -- Clear any previous font resources from the global tables
   if Texture['font'] then
      SDL_DestroyTexture(Texture['font']); Texture['font'] = nil;
   end
   if Surface['font'] then
      SDL_DestroySurface(Surface['font']); Surface['font'] = nil;
   end

   Surface['font'] = SDL_LoadBMP(path)
   if Surface['font'] == nil then
      print("Error loading font BMP: " .. ffi.string(SDL_GetError()))
      return false
   end

   local pixel_format_details = SDL_GetPixelFormatDetails(Surface['font'].format)
   if pixel_format_details == nil then
      print("Error: SDL_GetPixelFormatDetails returned NULL for format: " .. Surface['font'].format)
      SDL_DestroySurface(Surface['font']); Surface['font'] = nil
      return false
   end

   local format_name_ptr = SDL_GetPixelFormatName(Surface['font'].format)
   local format_name_str = "Unknown"
   if format_name_ptr ~= nil then
      format_name_str = ffi.string(format_name_ptr)
   end

   -- Attempt to get BitsPerPixel and BytesPerPixel directly from the FFI struct
   local actual_bits_per_pixel
   local actual_bytes_per_pixel

   local pcall_success_bpp, bpp_value_or_error = pcall(function() return pixel_format_details.bits_per_pixel end)  -- Changed to lowercase
   local pcall_success_Bpp, Bpp_value_or_error = pcall(function() return pixel_format_details.bytes_per_pixel end) -- Changed to lowercase

   if pcall_success_bpp and pcall_success_Bpp then
      actual_bits_per_pixel = bpp_value_or_error
      actual_bytes_per_pixel = Bpp_value_or_error
      if EnableDebugPrints then
         print(string.format("Successfully read BitsPerPixel: %d and BytesPerPixel: %d directly from FFI struct.",
            actual_bits_per_pixel, actual_bytes_per_pixel))
      end
   else
      if EnableDebugPrints then
         if not pcall_success_bpp then
            print("Error reading BitsPerPixel: " .. tostring(bpp_value_or_error))
         end
         if not pcall_success_Bpp then
            print("Error reading BytesPerPixel: " .. tostring(Bpp_value_or_error))
         end
         print(
            "CRITICAL ERROR: Could not read BitsPerPixel or BytesPerPixel directly from FFI struct. FFI definition might still be incorrect or the pointer is invalid.")
      end
      SDL_DestroySurface(Surface['font']); Surface['font'] = nil
      return false
   end

   -- Validate that BytesPerPixel is consistent with BitsPerPixel
   if actual_bytes_per_pixel ~= math.floor(actual_bits_per_pixel / 8) then
      if EnableDebugPrints then
         print(string.format(
            "Warning: Inconsistency detected. BitsPerPixel = %d, BytesPerPixel = %d. Expected BytesPerPixel = %d",
            actual_bits_per_pixel, actual_bytes_per_pixel, math.floor(actual_bits_per_pixel / 8)))
         print("Proceeding with FFI provided BytesPerPixel, but this might indicate an issue.")
      end
      -- Depending on strictness, you might choose to fail here or trust the FFI-provided BytesPerPixel.
      -- For now, we'll trust the FFI's BytesPerPixel if it was successfully read.
   end

   -- Validate format: must be ARGB8888 and 32bpp for the current glyph processing logic
   if format_name_str ~= "SDL_PIXELFORMAT_ARGB8888" then
      print(string.format(
         "Error: Font BMP must be SDL_PIXELFORMAT_ARGB8888 for current processing logic. Detected format name: %s",
         format_name_str))
      SDL_DestroySurface(Surface['font']); Surface['font'] = nil
      return false
   end

   if actual_bits_per_pixel ~= 32 then
      print(string.format("Error: Font BMP (identified as ARGB8888) must be 32 BitsPerPixel. Detected BitsPerPixel: %d",
         actual_bits_per_pixel))
      SDL_DestroySurface(Surface['font']); Surface['font'] = nil
      return false
   end

   if EnableDebugPrints then
      print(string.format("FontSurface loaded. Format Name: %s (Enum: %d)", format_name_str,
         tonumber(Surface['font'].format)))
      print(string.format("BitsPerPixel: %d, BytesPerPixel: %d", actual_bits_per_pixel, actual_bytes_per_pixel))
      print(string.format("Masks from pixel_format_details: R=0x%08x G=0x%08x B=0x%08x A=0x%08x",
         tonumber(pixel_format_details.Rmask), tonumber(pixel_format_details.Gmask),
         tonumber(pixel_format_details.Bmask), tonumber(pixel_format_details.Amask)))
      print(string.format("Pitch: %d", Surface['font'].pitch))
   end

   local blend_ret = SDL_SetSurfaceBlendMode(Surface['font'], SDL.BLENDMODE_BLEND)
   if not blend_ret then
      local err_msg = ffi.string(SDL_GetError())
      print("Error setting font surface blend mode: " .. err_msg)
      SDL_DestroySurface(Surface['font']); Surface['font'] = nil
      return false
   elseif EnableDebugPrints then
      print("Font surface blend mode set successfully.")
   end

   local lock_ret = SDL_LockSurface(Surface['font'])
   if not lock_ret then
      local err_msg = ffi.string(SDL_GetError())
      print("Error locking font surface: " .. err_msg)
      SDL_DestroySurface(Surface['font']); Surface['font'] = nil
      return false
   elseif EnableDebugPrints then
      print("Font surface locked successfully.")
   end

   print("Processing font (revised logic for custom char map): " ..
      path ..
      " (w:" .. Surface['font'].w .. ", h:" .. Surface['font'].h .. ", bpp:" .. (actual_bytes_per_pixel * 8) .. ")") -- Use actual_bytes_per_pixel
   _G.FontHeight = Surface['font'].h
   _G.FontGlyphs = {}                                                                                                -- Reset glyphs table
   local in_glyph_span = false
   local current_glyph_start_x = 0
   local glyph_index_in_map = 0

   local r_val = ffi.new("uint8_t[1]")
   local g_val = ffi.new("uint8_t[1]")
   local b_val = ffi.new("uint8_t[1]")
   local a_val = ffi.new("uint8_t[1]")

   local cast_pixels_ptr = ffi.cast("uint32_t*", Surface['font'].pixels)

   for x = 0, Surface['font'].w - 1 do
      local current_pixel_value = cast_pixels_ptr[x]
      -- Corrected: Pass pixel_format_details (the SDL_PixelFormat*) not Surface['font'].format (the enum)
      SDL_GetRGBA(current_pixel_value, pixel_format_details, ffi.NULL, r_val, g_val, b_val, a_val)
      local r, g, b, a = r_val[0], g_val[0], b_val[0], a_val[0]

      local is_separator = (r == 255 and g == 255 and b == 0 and a == 255)

      if not in_glyph_span and not is_separator then
         in_glyph_span = true
         current_glyph_start_x = x
      elseif in_glyph_span and is_separator then
         in_glyph_span = false
         local glyph_w = x - current_glyph_start_x
         if glyph_w > 0 then
            glyph_index_in_map = glyph_index_in_map + 1
            if glyph_index_in_map <= #FONT_CHARACTER_MAP_STRING then
               local char_for_glyph = string.sub(FONT_CHARACTER_MAP_STRING, glyph_index_in_map, glyph_index_in_map)
               _G.FontGlyphs[char_for_glyph] = {
                  src_x = current_glyph_start_x,
                  src_y = 0, -- Glyphs are on the first row
                  src_w = glyph_w,
                  src_h = _G.FontHeight
               }
               if EnableDebugPrints then
                  print(string.format("Font: Glyph \'%s\' (idx %d): x=%d, w=%d, h=%d",
                     char_for_glyph, glyph_index_in_map, current_glyph_start_x, glyph_w, _G.FontHeight))
               end
            else
               print("Warning: Found glyph in font image but no more characters in FONT_CHARACTER_MAP_STRING.")
               break -- Stop processing if map is exhausted
            end
         else
            print(string.format("Warning: Zero-width glyph detected at x=%d after separator. Skipping.", x))
         end
      end
   end

   if in_glyph_span then
      local glyph_w = Surface['font'].w - current_glyph_start_x
      if glyph_w > 0 then
         glyph_index_in_map = glyph_index_in_map + 1
         if glyph_index_in_map <= #FONT_CHARACTER_MAP_STRING then
            local char_for_glyph = string.sub(FONT_CHARACTER_MAP_STRING, glyph_index_in_map, glyph_index_in_map)
            _G.FontGlyphs[char_for_glyph] = {
               src_x = current_glyph_start_x,
               src_y = 0,
               src_w = glyph_w,
               src_h = _G.FontHeight
            }
            if EnableDebugPrints then
               print(string.format("Font: Glyph \'%s\' (idx %d) (at end of image): x=%d, w=%d, h=%d",
                  char_for_glyph, glyph_index_in_map, current_glyph_start_x, glyph_w, _G.FontHeight))
            end
         else
            print("Warning: Found final glyph in font image but no more characters in FONT_CHARACTER_MAP_STRING.")
         end
      end
   end

   SDL_UnlockSurface(Surface['font'])

   if UseRenderer then
      if Renderer == nil then
         print("Error in LoadAndProcessCustomFont: Renderer is nil. Cannot create font texture.")
         SDL_DestroySurface(Surface['font']); Surface['font'] = nil
         return false
      end

      Texture['font'] = SDL_CreateTextureFromSurface(Renderer, Surface['font'])
      if Texture['font'] == nil then
         print("Error creating font texture from surface: " .. ffi.string(SDL_GetError()))
         -- Surface['font'] is kept for surface mode if texture creation fails,
         -- but for renderer mode, this is a failure.
         -- However, the overall strategy is to have Surface['font'] always,
         -- and Texture['font'] only if UseRenderer. So if Texture['font'] fails,
         -- we might still want to proceed if a fallback to surface rendering for font is acceptable,
         -- or treat it as a hard error for renderer mode font setup.
         -- For now, let's treat it as a hard error for renderer mode font setup.
         SDL_DestroySurface(Surface['font']); Surface['font'] = nil
         return false
      elseif EnableDebugPrints then
         print("Successfully created Texture['font'] from Surface['font'].")
      end
      -- In renderer mode, the original Surface['font'] is still kept,
      -- as it's the source of glyph data and could be useful for other things,
      -- or if we later decide to switch modes dynamically.
      -- It will be cleaned up with other surfaces at Quit.
   end

   local glyphs_actually_added = 0
   for _ in pairs(_G.FontGlyphs) do glyphs_actually_added = glyphs_actually_added + 1 end

   if glyphs_actually_added == 0 then
      print("Warning: No glyphs found/processed in font image " .. path .. ". Text might not render.")
      -- If no glyphs, font is unusable. Clean up and fail.
      if Texture['font'] then
         SDL_DestroyTexture(Texture['font']); Texture['font'] = nil;
      end
      if Surface['font'] then
         SDL_DestroySurface(Surface['font']); Surface['font'] = nil;
      end
      return false
   elseif EnableDebugPrints then
      print("Font processing complete. Glyphs found: " .. tostring(glyphs_actually_added))
      if UseRenderer and Texture['font'] then
         print("Texture['font'] is set.")
      elseif not UseRenderer and Surface['font'] then
         print("Surface['font'] is set.")
      end
   end

   return true -- Success
end

-- Global/Top-level application variables
local UseRenderer = false -- Set to false to use SDL3 surface blitting instead of renderer
local Window = nil
local Renderer = nil
local WindowSurface = nil          -- For surface blitting if UseRenderer is false
Surface = {}                       -- Holds SDL_Surface objects, ensure it's global or accessible
Texture = {}                       -- Holds SDL_Texture objects if UseRenderer is true, ensure it's global
Image = nil                        -- Points to either Surface or Texture table based on UseRenderer
Buttons = {}                       -- Table to hold button definitions
local Event = ffi.new('SDL_Event') -- For event polling
local Running = true               -- Controls the main loop

-- Main application setup
Window = SDL_CreateWindow("LuaJIT-FFI SDL3 Demo", 512, 512, 0)
if Window == nil then
   print("Window could not be created! SDL_Error: " .. ffi.string(SDL_GetError()))
   SDL_Quit()
   os.exit(1)
end
SDL_SetWindowResizable(Window, true)

if UseRenderer then
   Renderer = SDL_CreateRenderer(Window, "software")
   if Renderer == nil then
      print("Renderer could not be created! SDL_Error: " .. ffi.string(SDL_GetError()))
      SDL_DestroyWindow(Window)
      SDL_Quit()
      os.exit(1)
   end
   SDL_SetRenderDrawBlendMode(Renderer, SDL.BLENDMODE_BLEND)
else
   WindowSurface = SDL_GetWindowSurface(Window)
   if WindowSurface == nil then
      print("Window surface could not be retrieved! SDL_Error: " .. ffi.string(SDL_GetError()))
      SDL_DestroyWindow(Window)
      SDL_Quit()
      os.exit(1)
   end
end

-- Call the font loading function AFTER Renderer/WindowSurface is initialized
if not LoadAndProcessCustomFont(FontPath, FontStartASCII) then
   print("Failed to load and process custom font. Text rendering may not work or app will exit.")
   -- Depending on how critical font is, might exit here
   -- For now, continue, but DrawText/DrawButton will likely fail or do nothing.
   -- Consider SDL_DestroyWindow(Window), SDL_Quit(), os.exit(1) if font is critical
end

-- Initialize Surface and Texture tables
Surface = Surface or {}
Texture = Texture or {}
-- Load the font surface into Surface table
Surface['font'] = Surface['font'] or SDL_LoadBMP(FontPath)
if Surface['font'] == nil then
   print("Failed to load font surface from " .. FontPath .. ": " .. ffi.string(SDL_GetError()))
   SDL_DestroyWindow(Window)
   SDL_Quit()
   os.exit(1)
else
   if EnableDebugPrints then
      print("Font surface loaded successfully into Surface['font'].")
   end
end
-- Create Texture for font if using renderer

-- Load other surfaces
LoadBMPSurface("assets/lena.bmp", "Lena")
LoadBMPSurface("assets/alpha-blend.bmp", "transparent BMP")

-- Create textures from surfaces if using renderer
if UseRenderer then
   for key, surf_value in pairs(Surface) do
      if surf_value then
         if key ~= 'font' then -- Font texture is already created by LoadAndProcessCustomFont
            Texture[key] = SDL_CreateTextureFromSurface(Renderer, surf_value)
            if Texture[key] == nil then
               print("Failed to create texture for " .. key .. ": " .. ffi.string(SDL_GetError()))
            end
         end
      end
   end
end
-- If using renderer, ensure Texture['font'] is created
if UseRenderer and not Texture['font'] then
   Texture['font'] = SDL_CreateTextureFromSurface(Renderer, Surface['font'])
   if Texture['font'] == nil then
      print("Failed to create texture for font: " .. ffi.string(SDL_GetError()))
      SDL_DestroyWindow(Window)
      SDL_Quit()
      os.exit(1)
   else
      if EnableDebugPrints then
         print("Texture['font'] created successfully from Surface['font'].")
      end
   end
end
-- If using renderer, ensure Texture table is not empty
if UseRenderer and next(Texture) == nil then
   print("Error: No textures created for renderer mode. Check Surface loading or texture creation.")
   SDL_DestroyWindow(Window)
   SDL_Quit()
   os.exit(1)
end
-- Assign Image to point to the correct table (Surface or Texture)
Image = UseRenderer and Texture or Surface

-- Define some buttons
Buttons = {
   { id = "btnExit", text = "Exit", x = 10,  y = WindowSurface and WindowSurface.h - 40 or (UseRenderer and 512 - 40 or 472), w = 100, h = 30, isHovered = false },
   { id = "btnTest", text = "Test", x = 120, y = 10,                                                                          w = 100, h = 30, isHovered = false } -- Moved near counter text
}

-- Define DrawImage function
function DrawImage(imageDrawable, xywh)
   if not imageDrawable then
      if EnableDebugPrints then print("DrawImage: imageDrawable is nil.") end
      return
   end
   local dest_rect = RectangleFromXYWH(xywh)
   if UseRenderer then
      SDL_RenderTexture(Renderer, imageDrawable, nil, dest_rect)
   else
      if WindowSurface then
         -- For SDL_BlitSurfaceScaled, the destination rect (SDL_Rect) is used for scaling.
         -- Ensure it's an SDL_Rect, RectangleFromXYWH should handle this.
         SDL_BlitSurfaceScaled(imageDrawable, nil, WindowSurface, dest_rect, SDL.SDL_SCALEMODE_NEAREST)
      elseif EnableDebugPrints then
         print("DrawImage (Surface): WindowSurface is nil, cannot blit image.")
      end
   end
end

-- Define FillRect function
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

function GetTextWidth(text)
   local total_width = 0
   if not _G.FontGlyphs or not text then return 0 end
   for i = 1, #text do
      local char = string.sub(text, i, i)
      local glyph = _G.FontGlyphs[char]              -- Use global FontGlyphs
      if glyph then
         total_width = total_width + glyph.src_w + 1 -- Add 1 for spacing between chars
      else
         -- Optionally, add a default width for unknown characters or print a warning
         -- print("Warning: Character \'" .. char .. "\' not found in font.")
         total_width = total_width + (_G.FontHeight or 0) / 2 -- Default width for unknown char, use global FontHeight
      end
   end
   if #text > 0 and total_width > 0 then
      total_width = total_width - 1 -- No spacing after the last character
   end
   return total_width
end

function DrawText(text, x, y, color)
   if not Image or not Image['font'] or not _G.FontGlyphs or not text then -- Check Image['font']
      if EnableDebugPrints then print("DrawText: Image['font'] or FontGlyphs not available or text is nil.") end
      return
   end

   local current_x = x
   local r_mod, g_mod, b_mod, a_mod = 255, 255, 255, 255 -- Default white opaque
   if color then
      r_mod = color.r or 255
      g_mod = color.g or 255
      b_mod = color.b or 255
      a_mod = color.a or 255
   end

   if Image and Image['font'] then -- Check if Image['font'] is valid before trying to modulate
      if UseRenderer then
         -- For renderer, Image['font'] is Texture['font']. Set modulation.
         SDL_SetTextureColorMod(Image['font'], r_mod, g_mod, b_mod) -- Use Image['font']
         SDL_SetTextureAlphaMod(Image['font'], a_mod)               -- Use Image['font']
      else
         -- For surface mode, Image['font'] is Surface['font']. Set modulation.
         SDL_SetSurfaceColorMod(Image['font'], r_mod, g_mod, b_mod)
         SDL_SetSurfaceAlphaMod(Image['font'], a_mod)
         -- The old warning about surface mode tinting is removed as we are now attempting it.
      end
   end

   for i = 1, #text do
      local char = string.sub(text, i, i)
      local glyph = _G.FontGlyphs[char] -- Use global FontGlyphs

      if glyph then
         if UseRenderer then
            local src_frect = ffi.new('SDL_FRect')
            src_frect.x = glyph.src_x
            src_frect.y = glyph.src_y
            src_frect.w = glyph.src_w
            src_frect.h = glyph.src_h

            local dst_frect = ffi.new('SDL_FRect')
            dst_frect.x = current_x
            dst_frect.y = y
            dst_frect.w = glyph.src_w
            dst_frect.h = glyph.src_h
            SDL_RenderTexture(Renderer, Image['font'], src_frect, dst_frect) -- Use src_frect
         else
            local src_rect = ffi.new('SDL_Rect',                             -- Glyphs are from Surface['font'] (pixel data), so SDL_Rect
               { glyph.src_x, glyph.src_y, glyph.src_w, glyph.src_h })
            local dst_rect = ffi.new('SDL_Rect')
            dst_rect.x = current_x
            dst_rect.y = y
            -- dst_rect.w/h are ignored by SDL_BlitSurface if src_rect is not NULL.
            if WindowSurface then
               SDL_BlitSurface(Image['font'], src_rect, WindowSurface, dst_rect) -- Use Image['font']
            elseif EnableDebugPrints then
               print("DrawText (Surface): WindowSurface is nil, cannot blit text.")
            end
         end
         current_x = current_x + glyph.src_w + 1 -- Add 1 for inter-character spacing
      else
         if EnableDebugPrints then print("Warning: Character '" .. char .. "' not found in FontGlyphs for drawing.") end
         current_x = current_x + ((_G.FontHeight or 0) / 2) -- Advance by a default width, use global FontHeight
      end
   end

   if Image and Image['font'] then -- Check if Image['font'] is valid before trying to reset modulation
      if UseRenderer then
         -- Reset texture modulation to default (white, opaque)
         SDL_SetTextureColorMod(Image['font'], 255, 255, 255) -- Use Image['font']
         SDL_SetTextureAlphaMod(Image['font'], 255)           -- Use Image['font']
      else
         -- Reset surface modulation to default (white, opaque)
         SDL_SetSurfaceColorMod(Image['font'], 255, 255, 255)
         SDL_SetSurfaceAlphaMod(Image['font'], 255)
      end
   end
end

function RectangleFromXYWH(xywh)
   local rectangle = ffi.new(UseRenderer and 'SDL_FRect' or 'SDL_Rect')
   rectangle.x = xywh[1]
   rectangle.y = xywh[2]
   rectangle.w = xywh[3]
   rectangle.h = xywh[4]
   return rectangle
end

function DrawButton(btn)
   -- Draw button background (example: light grey)
   if btn.isHovered then
      FillRect({ btn.x, btn.y, btn.w, btn.h }, 220, 220, 220, 255) -- Lighter background on hover
   else
      FillRect({ btn.x, btn.y, btn.w, btn.h }, 200, 200, 200, 255)
   end

   -- Draw button border (example: dark grey)
   if UseRenderer then
      SDL_SetRenderDrawColor(Renderer, 100, 100, 100, 255)
      local border_frect = ffi.new('SDL_FRect', { x = btn.x, y = btn.y, w = btn.w, h = btn.h }) -- Define border_frect
      SDL_RenderRect(Renderer, border_frect)
   else
      -- Draw button border using FillRect for surface mode (1px border)
      local border_color = { r = 100, g = 100, b = 100, a = 255 }
      -- Top border
      FillRect({ btn.x, btn.y, btn.w, 1 }, border_color.r, border_color.g, border_color.b, border_color.a)
      -- Bottom border
      FillRect({ btn.x, btn.y + btn.h - 1, btn.w, 1 }, border_color.r, border_color.g, border_color.b, border_color.a)
      -- Left border
      FillRect({ btn.x, btn.y + 1, 1, btn.h - 2 }, border_color.r, border_color.g, border_color.b, border_color.a)
      -- Right border
      FillRect({ btn.x + btn.w - 1, btn.y + 1, 1, btn.h - 2 }, border_color.r, border_color.g, border_color.b,
         border_color.a)
   end

   -- Draw button text
   -- Ensure font resources are loaded and btn.text exists
   if btn.text and Image and Image['font'] and _G.FontGlyphs and next(_G.FontGlyphs or {}) and _G.FontHeight and _G.FontHeight > 0 then -- Check Image['font']
      local text_width = GetTextWidth(btn.text)
      local text_height = _G
          .FontHeight -- Use global FontHeight
      -- Center text in button
      local text_x = btn.x + (btn.w - text_width) / 2
      local text_y = btn.y + (btn.h - text_height) / 2
      DrawText(btn.text, text_x, text_y, { r = 255, g = 255, b = 0, a = 255 }) -- White text
   else
      if EnableDebugPrints then
         print(string.format("DrawButton: Cannot draw text for button ID '%s'. Font resources missing or text is nil.",
            btn.id or "N/A"))
         if not (Image and Image['font']) then print("Reason: Image or Image['font'] is nil.") end
         if not (_G.FontGlyphs and next(_G.FontGlyphs or {})) then print("Reason: _G.FontGlyphs is nil or empty.") end
         if not (_G.FontHeight and _G.FontHeight > 0) then print("Reason: _G.FontHeight is nil or zero.") end
      end
   end
end

-- Main event loop
print("Starting main loop...")
while Running do
   while SDL_PollEvent(Event) do
      if Event.type == SDL_EVENT_QUIT then
         Running = false -- Quit from eg window closing
      end
      if Event.type == SDL_EVENT_KEY_DOWN then
         if Event.key.scancode == SDL_SCANCODE_ESCAPE or Event.key.scancode == SDL_SCANCODE_Q then
            Running = false -- Quit from keypress ESCAPE or Q
         end
      end
      if Event.type == SDL_EVENT_MOUSE_BUTTON_DOWN then
         -- Explicitly use SDL.SDL_BUTTON_LEFT to bypass potential metatable issues for this constant
         if Event.button.button == SDL.SDL_BUTTON_LEFT then
            print(string.format("Mouse button down: LEFT at (%d, %d)", Event.button.x, Event.button.y))
            -- Check if any button was clicked
            for _, btn in ipairs(Buttons) do
               if Event.button.x >= btn.x and Event.button.x <= btn.x + btn.w and
                   Event.button.y >= btn.y and Event.button.y <= btn.y + btn.h then
                  print("Button clicked: " .. btn.text .. " (ID: " .. btn.id .. ")")
                  if btn.id == "btnExit" then
                     Running = false
                  elseif btn.id == "btnTest" then
                     print("Test button pressed!") -- Example action
                     counter = counter + 1         -- Increment counter
                     if EnableDebugPrints then print("Counter is now: " .. tostring(counter)) end
                  end
                  -- Add other button actions here based on btn.id
               end
            end
         elseif Event.button.button == SDL.SDL_BUTTON_RIGHT then
            print(string.format("Mouse button down: RIGHT at (%d, %d)", Event.button.x, Event.button.y))
            -- Add other button types if needed (e.g., SDL.SDL_BUTTON_MIDDLE)
         end
      elseif Event.type == SDL_EVENT_MOUSE_MOTION then
         for _, btn in ipairs(Buttons) do
            if Event.motion.x >= btn.x and Event.motion.x <= btn.x + btn.w and
                Event.motion.y >= btn.y and Event.motion.y <= btn.y + btn.h then
               btn.isHovered = true
            else
               btn.isHovered = false
            end
         end
      elseif Event.type == SDL_EVENT_WINDOW_RESIZED then
         if UseRenderer then
            -- If using a renderer, it typically handles resizing automatically or you might re-query window size.
            -- For this basic example, we might not need to do anything specific unless content scaling is manual.
            print(string.format("Window resized to %d x %d", Event.window.data1, Event.window.data2))
         else
            -- If using surface blitting, the window surface needs to be re-obtained.
            WindowSurface = SDL_GetWindowSurface(Window)
            if WindowSurface == nil then
               print("Window surface could not be retrieved after resize! SDL_Error: " .. ffi.string(SDL_GetError())) -- Added print
               Running = false                                                                                        -- Critical error
            else
               print(string.format("Window resized to %d x %d, new window surface obtained.", Event.window.data1,
                  Event.window.data2)) -- Added print
            end
         end
         -- Add other event types to handle: SDL_EVENT_KEY_DOWN, etc.
      end
   end

   -- Rendering logic
   if UseRenderer then
      SDL_SetRenderDrawColor(Renderer, 0, 0, 0, 255) -- Clear to black
      SDL_RenderClear(Renderer)
      Render()                                       -- Call the main render function
      SDL_RenderPresent(Renderer)
   else
      if WindowSurface then
         SDL_FillSurfaceRect(WindowSurface, nil, 0) -- Clear to black (0 is black for default format)
         Render()                                   -- Call the main render function
         SDL_UpdateWindowSurface(Window)
      end
   end

   SDL_Delay(16) -- Aim for ~60 FPS
end
print("Exiting main loop...")

-- Cleanup
print("Starting cleanup...")

if UseRenderer then
   -- Destroy renderer Textures from the Texture table
   if Texture then -- Check if Texture table exists
      for key, texture_resource in pairs(Texture) do
         if texture_resource then
            if EnableDebugPrints then print("Destroying Texture: " .. key) end
            SDL_DestroyTexture(texture_resource)
            Texture[key] = nil -- Good practice to nil out to prevent accidental reuse
         end
      end
   end
   if Renderer then
      if EnableDebugPrints then print("Destroying Renderer") end
      SDL_DestroyRenderer(Renderer)
      Renderer = nil
   end
else
   -- WindowSurface is managed by the window if not using a renderer, no need to destroy it separately here.
   -- It becomes invalid when the window is destroyed.
   if WindowSurface and EnableDebugPrints then
      print("WindowSurface will be released with window (surface mode).")
   end
end

-- Destroy Surfaces from the Surface table
if Surface then -- Check if Surface table exists
   for key, surface_resource in pairs(Surface) do
      if surface_resource then
         if EnableDebugPrints then print("Destroying Surface: " .. key) end
         SDL_DestroySurface(surface_resource)
         Surface[key] = nil -- Good practice
      end
   end
end

if Window then
   if EnableDebugPrints then print("Destroying Window") end
   SDL_DestroyWindow(Window)
   Window = nil
end

if EnableDebugPrints then print("Quitting SDL") end
SDL_Quit()
print("Cleanup complete.")
