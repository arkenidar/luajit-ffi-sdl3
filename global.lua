local function Init(SDL)
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
end

return Init
