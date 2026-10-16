local IconModule = {
    IconsType = "lucide",
    New = nil,
    IconThemeTag = nil,
    Icons = {},
}

local lucideLoaded = false
local function ensureLucide()
    if lucideLoaded then return end
    lucideLoaded = true

    local FILE = "novaicon.lua"
    if not isfile(FILE) then
        local ok, content = pcall(game.HttpGet, game,
            "https://raw.githubusercontent.com/nexusnpm/lib/main/icons/icons.lua")
        if not ok or type(content) ~= "string" or #content < 10 then
            warn("[IconModule] No se pudieron descargar los iconos")
            IconModule.Icons.lucide = {}
            return
        end
        writefile(FILE, content)
    end

    local ok, data = pcall(function() return loadstring(readfile(FILE))() end)
    IconModule.Icons.lucide = (ok and type(data) == "table") and data or {}
end

local function parseIconString(s)
    if type(s) == "string" then
        local i = s:find(":")
        if i then return s:sub(1, i - 1), s:sub(i + 1) end
    end
    return nil, s
end

function IconModule.AddIcons(packName, iconsData)
    if type(packName) ~= "string" or type(iconsData) ~= "table" then
        error("AddIcons: packName must be string, iconsData must be table")
    end
    IconModule.Icons[packName] = IconModule.Icons[packName] or { Icons = {}, Spritesheets = {} }
    local pack = IconModule.Icons[packName]

    for name, value in pairs(iconsData) do
        if type(value) == "number" then value = "rbxassetid://" .. value end
        if type(value) == "string" and value:match("^rbxassetid://") then
            pack.Icons[name] = { Image = value, ImageRectSize = Vector2.new(), ImageRectPosition = Vector2.new() }
            pack.Spritesheets[value] = value
        elseif type(value) == "table" and value.Image and value.ImageRectSize and value.ImageRectPosition then
            local id = type(value.Image) == "number" and ("rbxassetid://" .. value.Image) or value.Image
            pack.Icons[name] = { Image = id, ImageRectSize = value.ImageRectSize, ImageRectPosition = value.ImageRectPosition, Parts = value.Parts }
            pack.Spritesheets[id] = id
        else
            warn("AddIcons: formato inválido para '" .. name .. "'")
        end
    end
end

function IconModule.SetIconsType(t) IconModule.IconsType = t end

function IconModule.Init(New, IconThemeTag)
    IconModule.New = New
    IconModule.IconThemeTag = IconThemeTag
    return IconModule
end

function IconModule.Icon(Icon, Type, DefaultFormat)
    local iconType, iconName = parseIconString(Icon)
    local targetType = iconType or Type or IconModule.IconsType
    if targetType == "lucide" then ensureLucide() end

    local pack = IconModule.Icons[targetType]
    if not pack then return nil end

    local entry = pack.Icons and pack.Icons[iconName]
    if entry then
        return { pack.Spritesheets[entry.Image], entry }
    end
    local flat = pack[iconName]
    if type(flat) == "string" and flat:find("rbxassetid://") then
        return { flat, { ImageRectSize = Vector2.new(), ImageRectPosition = Vector2.new() } }
    end
    return nil
end