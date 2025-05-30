local config = {
    -- Rendering Mode
    UseRenderer = true, -- Set to true for SDL Renderer, false for Surface blitting

    -- Debugging
    EnableDebugPrints = true, -- Enable/disable verbose debug prints

    -- Font Parameters
    FontPath = "assets/font.bmp", -- Path to the font bitmap
    FontStartAscii = 32,          -- ASCII value of the first character in the font image
    -- 84 characters :
    FontCharacterMapString =
    [=[ abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,!?-+/():;%&`'*#=[]"]=],

    -- Window Parameters
    WindowTitle = "LuaJIT-FFI SDL3 Demo",
    WindowWidth = 512,
    WindowHeight = 512,

    -- Colors (example, can be expanded)
    Colors = {
        Red = { r = 255, g = 0, b = 0, a = 255 },
        Yellow = { r = 255, g = 255, b = 0, a = 255 },
        White = { r = 255, g = 255, b = 255, a = 255 },
        ButtonHoverBg = { r = 220, g = 220, b = 220, a = 255 },
        ButtonBg = { r = 200, g = 200, b = 200, a = 255 },
        ButtonBorder = { r = 100, g = 100, b = 100, a = 255 },
    }
}

return config
