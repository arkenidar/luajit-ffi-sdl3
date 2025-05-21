# ReadMe with useful information

## GeminiAI analyzes app.lua file

Okay, I've analyzed the app.lua file. Here's a summary of its functionality:

This Lua script uses `sdl3_ffi` (SDL3 bindings for LuaJIT FFI) to create a window and render graphics. It demonstrates two rendering approaches: using the SDL Renderer API or direct surface blitting, controlled by the `UseRenderer` boolean variable.

**Key Features:**

1. **SDL3 Initialization and Window Creation:**
    * Initializes SDL video subsystem (`SDL_Init(SDL_INIT_VIDEO)`).
    * Creates a 512x512 window titled "Hello Lena" (`SDL_CreateWindow`).
    * Makes the window resizable (`SDL_SetWindowResizable`).

2. **Global SDL Function Access:**
    * It modifies the global environment `_G` with a metatable. This allows calling SDL functions like `SDL_Init` directly, instead of `SDL.Init`, by automatically looking them up in the `SDL` table if they start with "SDL_".

3. **Conditional Rendering Path (`UseRenderer`):**
    * If `UseRenderer` is `true` (default):
        * An "software" SDL renderer is created (`SDL_CreateRenderer`).
        * Blend mode is set to `SDL_BLENDMODE_BLEND`.
        * Images are loaded as BMP surfaces (`SDL_LoadBMP`) and then converted to SDL textures (`SDL_CreateTextureFromSurface`).
        * Drawing uses renderer functions (`SDL_RenderTexture`, `SDL_RenderFillRect`).
    * If `UseRenderer` is `false`:
        * Images are loaded and used directly as SDL surfaces.
        * Drawing uses surface blitting functions (`SDL_BlitSurfaceScaled`, and a custom `FillRect` implementation using temporary surfaces for alpha blending).

4. **Resource Loading and Management:**
    * Loads "assets/lena.bmp" and "assets/alpha-blend.bmp".
    * The `Image` table dynamically points to either the `Texture` table or the `Surface` table based on `UseRenderer`.
    * `RectangleFromXYWH` is a helper function to create `SDL_FRect` (for renderer) or `SDL_Rect` (for surface) structures from a Lua table `{x, y, w, h}`.

5. **Drawing Functions:**
    * `Render()`: This function orchestrates the drawing of several images (Lena and a transparent BMP at different positions and scales) and a semi-transparent filled rectangle.
    * `DrawImage()`: Abstracts the image drawing logic for both renderer and surface paths.
    * `FillRect()`: Abstracts the rectangle filling logic. For the surface path, it manually creates a temporary surface, fills it with the specified color and alpha, and then blits it to the window surface to achieve alpha blending.

6. **Main Loop:**
    * Handles events: `SDL_EVENT_QUIT` (window close) and `SDL_EVENT_KEY_DOWN` (Escape or Q key to quit).
    * Clears the screen to a gray color.
    * Calls the `Render()` function to draw the scene.
    * Presents the rendered frame (`SDL_RenderPresent` for renderer) or updates the window surface (`SDL_UpdateWindowSurface` for surface blitting).

7. **Cleanup:**
    * Properly destroys all loaded surfaces.
    * If the renderer was used, it destroys all created textures and the renderer itself.
    * Destroys the window.
    * Quits SDL (`SDL_Quit()`).

In essence, the script is a demonstration of basic 2D rendering with SDL3 in Lua, showcasing how to handle images and primitive shapes with and without the SDL Renderer API, and managing resources correctly. The `Render()` function specifically draws multiple instances of "Lena" and a transparent BMP, along with a filled rectangle.
