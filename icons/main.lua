local a = { IconsType = "lucide", New = nil, IconThemeTag = nil, Icons = {} }
local b = false

local function c()
    if b then return end
    b = true

    local b = "lucide-icons.lua"
    local b = pcall(function()
        if not isfile(b) then
            local a = game:HttpGet("https://raw.githubusercontent.com/nexusnpm/lib/main/icons/icons.lua")
            if type(a) ~= "string" or #a < 10 then
                error("invalid or empty content")
            end
            writefile(b, a)
        end
        local b = loadstring(readfile(b))()
        a.Icons.lucide = (type(b) == "table") and b or {}
    end)

    if not b then
        warn("[IconModule] Failed to load Icons (executor without file or network support)")
        a.Icons.lucide = a.Icons.lucide or {}
    end
end

local function b(a)
    if type(a) == "string" then
        local b = a:find(":")
        if b then
            return a:sub(1, b - 1), a:sub(b + 1)
        end
    end
    return nil, a
end

function a.AddIcons(b, c)
    if type(b) ~= "string" or type(c) ~= "table" then
        error("AddIcons: packName must be string, iconsData must be table")
    end

    a.Icons[b] = a.Icons[b] or { Icons = {}, Spritesheets = {} }
    local a = a.Icons[b]

    for b, c in pairs(c) do
        if type(c) == "number" then
            c = "rbxassetid://" .. tostring(c)
        end

        if type(c) == "string" and c:match("^rbxassetid://") then
            a.Icons[b] = {
                Image = c,
                ImageRectSize = Vector2.new(0, 0),
                ImageRectPosition = Vector2.new(0, 0),
            }
            a.Spritesheets[c] = c

        elseif type(c) == "table" and c.Image and c.ImageRectSize and c.ImageRectPosition then
            local d = c.Image
            if type(d) == "number" then
                d = "rbxassetid://" .. tostring(d)
            end
            a.Icons[b] = {
                Image = d,
                ImageRectSize = c.ImageRectSize,
                ImageRectPosition = c.ImageRectPosition,
                Parts = c.Parts,
            }
            a.Spritesheets[d] = d

        else
            warn("AddIcons: invalid format for '" .. b .. "'")
        end
    end
end

function a.SetIconsType(b)
    a.IconsType = b
end

function a.Init(b, c)
    a.New = b
    a.IconThemeTag = c
    return a
end

function a.Icon(d, e, f)
    local b, d = b(d)
    local b = b or e or a.IconsType

    if b == "lucide" then
        c()
    end

    local a = a.Icons[b]
    if not a then return nil end

    local b = a.Icons and a.Icons[d]
    if b then
        return { a.Spritesheets[tostring(b.Image)], b }
    end

    local a = a[d]
    if type(a) == "string" and a:find("rbxassetid://") then
        return { a, { ImageRectSize = Vector2.new(0, 0), ImageRectPosition = Vector2.new(0, 0) } }
    end

    return nil
end

function a.Image(b)
    local b = {
        Icon = b.Icon or nil,
        Type = b.Type,
        Colors = b.Colors or { (a.IconThemeTag or Color3.new(1, 1, 1)), Color3.new(1, 1, 1) },
        Size = b.Size or UDim2.new(0, 24, 0, 24),
        IconFrame = nil,
    }

    local c = {}
    for a, b in next, b.Colors do
        c[a] = {
            ThemeTag = typeof(b) == "string" and b or nil,
            Color = typeof(b) == "Color3" and b or nil,
        }
    end

    local d = a.Icon(b.Icon, b.Type)
    if not d then
        warn("[IconModule.Image] Icon not found:", tostring(b.Icon))
        return b
    end

    local e = typeof(d) == "string" and string.find(d, "rbxassetid://")

    local function f(b)
        if a.New then
            return a.New("ImageLabel", b)
        end
        local a = Instance.new("ImageLabel")
        for b, c in pairs(b) do
            if b ~= "Parent" then
                a[b] = c
            end
        end
        if b.Parent then
            a.Parent = b.Parent
        end
        return a
    end

    local g = f({
        Size = b.Size,
        BackgroundTransparency = 1,
        ImageColor3 = c[1].Color,
        ThemeTag = c[1].ThemeTag and { ImageColor3 = c[1].ThemeTag } or nil,
        Image = e and d or d[1],
        ImageRectSize = e and nil or d[2].ImageRectSize,
        ImageRectOffset = e and nil or d[2].ImageRectPosition,
    })

    if not e and d[2].Parts then
        for d, e in next, d[2].Parts do
            local a = a.Icon(e, b.Type)
            if a then
                f({
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    ImageColor3 = c[1 + d] and c[1 + d].Color or nil,
                    ThemeTag = c[1 + d] and c[1 + d].ThemeTag and { ImageColor3 = c[1 + d].ThemeTag } or nil,
                    Image = a[1],
                    ImageRectSize = a[2].ImageRectSize,
                    ImageRectOffset = a[2].ImageRectPosition,
                    Parent = g,
                })
            end
        end
    end

    b.IconFrame = g
    return b
end

return a
