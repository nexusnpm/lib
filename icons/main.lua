local IconModule = {
    IconsType = "lucide",
    New = nil,
    IconThemeTag = nil,
    Icons = {},
}

-- ============================================================
-- Carga lazy y cacheada de Lucide
-- ============================================================
local lucideLoaded = false

local function ensureLucide()
    if lucideLoaded then return end
    lucideLoaded = true

    local FILE = "lucide-icons.lua"

    local ok = pcall(function()
        -- Descargar solo si no existe el archivo
        if not isfile(FILE) then
            local content = game:HttpGet(
                "https://raw.githubusercontent.com/nexusnpm/lib/main/icons/icons.lua"
            )
            if type(content) ~= "string" or #content < 10 then
                error("contenido inválido o vacío")
            end
            writefile(FILE, content)
        end

        -- Cargar el contenido cacheado
        local data = loadstring(readfile(FILE))()
        IconModule.Icons.lucide = (type(data) == "table") and data or {}
    end)

    if not ok then
        warn("[IconModule] Falló la carga de Lucide (executor sin soporte de archivos o red)")
        IconModule.Icons.lucide = IconModule.Icons.lucide or {}
    end
end

-- ============================================================
-- Utilidades
-- ============================================================
local function parseIconString(s)
    if type(s) == "string" then
        local i = s:find(":")
        if i then
            return s:sub(1, i - 1), s:sub(i + 1)
        end
    end
    return nil, s
end

-- ============================================================
-- API pública
-- ============================================================
function IconModule.AddIcons(packName, iconsData)
    if type(packName) ~= "string" or type(iconsData) ~= "table" then
        error("AddIcons: packName must be string, iconsData must be table")
    end

    IconModule.Icons[packName] = IconModule.Icons[packName] or {
        Icons = {},
        Spritesheets = {},
    }
    local pack = IconModule.Icons[packName]

    for name, value in pairs(iconsData) do
        -- Número → rbxassetid://
        if type(value) == "number" then
            value = "rbxassetid://" .. tostring(value)
        end

        if type(value) == "string" and value:match("^rbxassetid://") then
            pack.Icons[name] = {
                Image = value,
                ImageRectSize = Vector2.new(0, 0),
                ImageRectPosition = Vector2.new(0, 0),
            }
            pack.Spritesheets[value] = value

        elseif type(value) == "table"
            and value.Image
            and value.ImageRectSize
            and value.ImageRectPosition
        then
            local id = value.Image
            if type(id) == "number" then
                id = "rbxassetid://" .. tostring(id)
            end

            pack.Icons[name] = {
                Image = id,
                ImageRectSize = value.ImageRectSize,
                ImageRectPosition = value.ImageRectPosition,
                Parts = value.Parts,
            }
            pack.Spritesheets[id] = id

        else
            warn("AddIcons: formato inválido para '" .. name .. "'")
        end
    end
end

function IconModule.SetIconsType(t)
    IconModule.IconsType = t
end

function IconModule.Init(New, IconThemeTag)
    IconModule.New = New
    IconModule.IconThemeTag = IconThemeTag
    return IconModule
end

function IconModule.Icon(Icon, Type, DefaultFormat)
    local iconType, iconName = parseIconString(Icon)
    local targetType = iconType or Type or IconModule.IconsType

    if targetType == "lucide" then
        ensureLucide()
    end

    local pack = IconModule.Icons[targetType]
    if not pack then return nil end

    -- Formato nuevo: { Icons = {...}, Spritesheets = {...} }
    local entry = pack.Icons and pack.Icons[iconName]
    if entry then
        return {
            pack.Spritesheets[tostring(entry.Image)],
            entry,
        }
    end

    -- Formato plano: pack[iconName] = "rbxassetid://..."
    local flat = pack[iconName]
    if type(flat) == "string" and flat:find("rbxassetid://") then
        return {
            flat,
            { ImageRectSize = Vector2.new(0, 0), ImageRectPosition = Vector2.new(0, 0) },
        }
    end

    return nil
end

function IconModule.Image(IconConfig)
    local Icon = {
        Icon = IconConfig.Icon or nil,
        Type = IconConfig.Type,
        Colors = IconConfig.Colors or { (IconModule.IconThemeTag or Color3.new(1, 1, 1)), Color3.new(1, 1, 1) },
        Size = IconConfig.Size or UDim2.new(0, 24, 0, 24),
        IconFrame = nil,
    }

    -- Normalizar colores (Color3 o ThemeTag string)
    local Colors = {}
    for i, color in next, Icon.Colors do
        Colors[i] = {
            ThemeTag = typeof(color) == "string" and color or nil,
            Color = typeof(color) == "Color3" and color or nil,
        }
    end

    local IconLabel = IconModule.Icon(Icon.Icon, Icon.Type)
    if not IconLabel then
        warn("[IconModule.Image] Icono no encontrado:", tostring(Icon.Icon))
        return Icon
    end

    local isrbxassetid = typeof(IconLabel) == "string" and string.find(IconLabel, "rbxassetid://")

    -- Helper para crear un ImageLabel (con New o Instance.new)
    local function makeLabel(props)
        if IconModule.New then
            return IconModule.New("ImageLabel", props)
        end
        local lbl = Instance.new("ImageLabel")
        for k, v in pairs(props) do
            if k ~= "Parent" then
                lbl[k] = v
            end
        end
        if props.Parent then lbl.Parent = props.Parent end
        return lbl
    end

    local IconFrame = makeLabel({
        Size = Icon.Size,
        BackgroundTransparency = 1,
        ImageColor3 = Colors[1].Color,
        ThemeTag = Colors[1].ThemeTag and { ImageColor3 = Colors[1].ThemeTag } or nil,
        Image = isrbxassetid and IconLabel or IconLabel[1],
        ImageRectSize = isrbxassetid and nil or IconLabel[2].ImageRectSize,
        ImageRectOffset = isrbxassetid and nil or IconLabel[2].ImageRectPosition,
    })

    -- Iconos multicapa
    if not isrbxassetid and IconLabel[2].Parts then
        for i, part in next, IconLabel[2].Parts do
            local IconPartLabel = IconModule.Icon(part, Icon.Type)
            if IconPartLabel then
                makeLabel({
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    ImageColor3 = Colors[1 + i] and Colors[1 + i].Color or nil,
                    ThemeTag = Colors[1 + i] and Colors[1 + i].ThemeTag
                        and { ImageColor3 = Colors[1 + i].ThemeTag } or nil,
                    Image = IconPartLabel[1],
                    ImageRectSize = IconPartLabel[2].ImageRectSize,
                    ImageRectOffset = IconPartLabel[2].ImageRectPosition,
                    Parent = IconFrame,
                })
            end
        end
    end

    Icon.IconFrame = IconFrame
    return Icon
end

return IconModule
