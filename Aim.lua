-- =============================================================================
--  AIM LOCK v21.0 | FULL REFACTOR
--  Архитектура: Модульная, оптимизированная, стабильная
-- =============================================================================

-- ============================================================
--  БИБЛИОТЕКИ
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local Player = Players.LocalPlayer

-- ============================================================
--  КОНФИГУРАЦИЯ
-- ============================================================
local CONFIG = {
    -- АИМ
    AimPart = "Head",
    BackupPart = "UpperTorso",
    FOV = 45,
    Smoothness = 0.18,
    DistanceLimit = 200,
    DeadZone = 9,  -- 3^2
    Prediction = true,
    PredictionStrength = 0.55,
    
    -- ПЕРЕКЛЮЧЕНИЕ
    SwitchDelay = 0.06,
    LostTimeout = 0.25,
    MinSwitchDist = 20,
    
    -- X-RAY
    XRay = true,
    XRayColor = Color3.fromRGB(0, 255, 100),
    XRayThickness = 2,
    
    -- ВИЗУАЛ
    ShowFOV = true,
    FOVColor = Color3.fromRGB(255, 255, 255),
    CrosshairStyle = "DOT",
}

-- ============================================================
--  СОСТОЯНИЕ
-- ============================================================
local State = {
    enabled = false,
    target = nil,
    targetData = nil,
    killCount = 0,
    lastSwitchTime = 0,
    lostTimer = 0,
    frameCount = 0,
}

-- ============================================================
--  КЕШИ
-- ============================================================
local Cache = {
    players = {},
    center = Vector2.new(0, 0),
    viewport = Vector2.new(0, 0),
}

-- ============================================================
--  УТИЛИТЫ
-- ============================================================
local function getCenter()
    local vp = Camera.ViewportSize
    if vp ~= Cache.viewport then
        Cache.viewport = vp
        Cache.center = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
    end
    return Cache.center
end

local function isAlive(plr)
    if not plr or not plr.Character then return false end
    local humanoid = plr.Character:FindFirstChild("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function getAimPart(plr)
    if not plr or not plr.Character then return nil end
    local char = plr.Character
    local part = char:FindFirstChild(CONFIG.AimPart)
    if part then return part end
    part = char:FindFirstChild(CONFIG.BackupPart)
    if part then return part end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
end

local function getPartPosition(part)
    if not part then return nil end
    return part.Position
end

local function getWorldDistance(plr)
    local part = getAimPart(plr)
    if not part then return math.huge end
    return (part.Position - Camera.CFrame.Position).Magnitude
end

local function getScreenPos(part)
    if not part then return nil end
    local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
    if not onScreen then return nil end
    return Vector2.new(pos.X, pos.Y)
end

-- ============================================================
--  VISIBILITY CHECK (без утечек)
-- ============================================================
local function isVisible(plr)
    if not plr or not plr.Character then return false end
    
    local part = getAimPart(plr)
    if not part then return false end
    
    local origin = Camera.CFrame.Position
    local targetPos = part.Position
    local direction = (targetPos - origin).Unit
    local distance = (targetPos - origin).Magnitude
    
    if distance > CONFIG.DistanceLimit then return false end
    
    -- Raycast с параметрами
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {Player.Character}
    
    local result = workspace:Raycast(origin, direction * distance, raycastParams)
    
    if not result then return true end
    
    local hit = result.Instance
    local parent = hit.Parent
    while parent do
        if parent == plr.Character then
            return true
        end
        parent = parent.Parent
    end
    
    return false
end

-- ============================================================
--  X-RAY (ESP)
-- ============================================================
local XRay = {}
local xrayContainer = Instance.new("Folder")
xrayContainer.Name = "XRay"
xrayContainer.Parent = Player.PlayerGui

local function createBox(plr)
    if XRay[plr] then return end
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 40, 0, 60)
    container.BackgroundTransparency = 1
    container.Parent = xrayContainer
    
    local border = Instance.new("Frame")
    border.Size = UDim2.new(1, 0, 1, 0)
    border.BackgroundTransparency = 0.85
    border.BackgroundColor3 = CONFIG.XRayColor
    border.BorderSizePixel = 0
    border.Parent = container
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = border
    
    local outline = Instance.new("Frame")
    outline.Size = UDim2.new(1, 0, 1, 0)
    outline.Position = UDim2.new(0, 1, 0, 1)
    outline.Size = UDim2.new(1, -2, 1, -2)
    outline.BackgroundTransparency = 1
    outline.BorderSizePixel = 1
    outline.BorderColor3 = CONFIG.XRayColor
    outline.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    outline.BackgroundTransparency = 0.7
    outline.Parent = container
    
    local outlineCorner = Instance.new("UICorner")
    outlineCorner.CornerRadius = UDim.new(0, 3)
    outlineCorner.Parent = outline
    
    -- Имя игрока
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 16)
    nameLabel.Position = UDim2.new(0, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = plr.Name
    nameLabel.TextColor3 = CONFIG.XRayColor
    nameLabel.TextSize = 10
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Parent = container
    
    XRay[plr] = {
        container = container,
        border = border,
        outline = outline,
        name = nameLabel,
        lastUpdate = 0,
    }
end

local function updateBox(plr)
    local data = XRay[plr]
    if not data then return end
    if not plr or not plr.Character then
        removeBox(plr)
        return
    end
    
    local root = plr.Character:FindFirstChild("HumanoidRootPart") or plr.Character:FindFirstChild("Torso")
    if not root then return end
    
    local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
    if not onScreen then
        data.container.Visible = false
        return
    end
    
    -- Рассчитываем размер бокса
    local dist = (root.Position - Camera.CFrame.Position).Magnitude
    local scale = math.clamp(120 / dist, 0.3, 1.5)
    local size = 40 * scale
    
    -- Обновляем позицию
    data.container.Position = UDim2.new(0, pos.X - size/2, 0, pos.Y - size * 0.8)
    data.container.Size = UDim2.new(0, size, 0, size * 1.6)
    data.container.Visible = true
    data.lastUpdate = tick()
end

local function removeBox(plr)
    local data = XRay[plr]
    if data then
        data.container:Destroy()
        XRay[plr] = nil
    end
end

local function updateXRay()
    if not CONFIG.XRay then
        for plr in pairs(XRay) do
            removeBox(plr)
        end
        return
    end
    
    -- Удаляем мёртвых игроков
    for plr in pairs(XRay) do
        if not plr or not isAlive(plr) then
            removeBox(plr)
        end
    end
    
    -- Обновляем существующие и создаём новые
    local center = getCenter()
    local fovSq = (CONFIG.FOV * 2) ^ 2
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Player and isAlive(plr) then
            local part = getAimPart(plr)
            if part then
                local screenPos = getScreenPos(part)
                if screenPos then
                    local dx = screenPos.X - center.X
                    local dy = screenPos.Y - center.Y
                    local dist = dx*dx + dy*dy
                    
                    if dist < fovSq then
                        createBox(plr)
                        updateBox(plr)
                    else
                        removeBox(plr)
                    end
                end
            end
        end
    end
end

-- ============================================================
--  ВИЗУАЛЫ (FOV + CROSSHAIR)
-- ============================================================
local Visuals = {}

-- FOV Circle
Visuals.fovCircle = Instance.new("ImageLabel")
Visuals.fovCircle.Size = UDim2.new(0, CONFIG.FOV * 2, 0, CONFIG.FOV * 2)
Visuals.fovCircle.Position = UDim2.new(0.5, -CONFIG.FOV, 0.5, -CONFIG.FOV)
Visuals.fovCircle.BackgroundTransparency = 1
Visuals.fovCircle.Image = "rbxassetid://4911621264"
Visuals.fovCircle.ImageColor3 = CONFIG.FOVColor
Visuals.fovCircle.ImageTransparency = 0.6
Visuals.fovCircle.Visible = false
Visuals.fovCircle.Parent = Player.PlayerGui

-- Crosshair
Visuals.crosshair = Instance.new("Frame")
Visuals.crosshair.Size = UDim2.new(0, 0, 0, 0)
Visuals.crosshair.Position = UDim2.new(0.5, 0, 0.5, 0)
Visuals.crosshair.BackgroundTransparency = 1
Visuals.crosshair.Visible = false
Visuals.crosshair.Parent = Player.PlayerGui

local function createDot()
    for _, c in pairs(Visuals.crosshair:GetChildren()) do c:Destroy() end
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 3, 0, 3)
    dot.Position = UDim2.new(0.5, -1.5, 0.5, -1.5)
    dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dot.BorderSizePixel = 0
    dot.Parent = Visuals.crosshair
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = dot
end

local function createCross()
    for _, c in pairs(Visuals.crosshair:GetChildren()) do c:Destroy() end
    local size, thick = 12, 1.5
    local parts = {
        {x = -size/2, y = -thick/2, w = size, h = thick},
        {x = -thick/2, y = -size/2, w = thick, h = size},
    }
    for _, data in ipairs(parts) do
        local part = Instance.new("Frame")
        part.Size = UDim2.new(0, data.w, 0, data.h)
        part.Position = UDim2.new(0.5, data.x, 0.5, data.y)
        part.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        part.BorderSizePixel = 0
        part.Parent = Visuals.crosshair
    end
end

local function updateCrosshair()
    if CONFIG.CrosshairStyle == "DOT" then
        createDot()
    else
        createCross()
    end
end
updateCrosshair()

-- ============================================================
--  GUI (MODERN)
-- ============================================================
local GUI = {}
GUI.container = Instance.new("ScreenGui")
GUI.container.Name = "AimLock_" .. tostring(math.random(1000, 9999))
GUI.container.ResetOnSpawn = false
GUI.container.Parent = Player.PlayerGui
GUI.container.DisplayOrder = 999

-- Основное окно
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 280, 0, 380)
main.Position = UDim2.new(0, 16, 0, 16)
main.BackgroundColor3 = Color3.fromRGB(12, 16, 28)
main.BackgroundTransparency = 0.08
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = GUI.container

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = main

-- Заголовок
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 36)
header.BackgroundColor3 = Color3.fromRGB(16, 22, 40)
header.BorderSizePixel = 0
header.Parent = main

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -90, 1, 0)
title.Position = UDim2.new(0, 14, 0, 0)
title.BackgroundTransparency = 1
title.Text = "AIM LOCK v21"
title.TextColor3 = Color3.fromRGB(190, 215, 255)
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamMedium
title.Parent = header

-- Кнопки окна
local winButtons = {}
for i, data in ipairs({
    {text = "─", pos = 1, color = Color3.fromRGB(180, 210, 255), action = "minimize"},
    {text = "□", pos = 2, color = Color3.fromRGB(180, 210, 255), action = "maximize"},
    {text = "✕", pos = 3, color = Color3.fromRGB(255, 80, 80), action = "close"},
}) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 30, 1, 0)
    btn.Position = UDim2.new(1, -30 * (4 - data.pos), 0, 0)
    btn.BackgroundTransparency = 1
    btn.Text = data.text
    btn.TextColor3 = data.color
    btn.TextSize = 16
    btn.Font = Enum.Font.Gotham
    btn.Parent = header
    winButtons[data.action] = btn
end

-- Разделитель
local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, -28, 0, 1)
divider.Position = UDim2.new(0, 14, 0, 36)
divider.BackgroundColor3 = Color3.fromRGB(40, 50, 70)
divider.BorderSizePixel = 0
divider.Parent = main

-- Статусы
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -28, 0, 22)
status.Position = UDim2.new(0, 14, 0, 46)
status.BackgroundTransparency = 1
status.Text = "DISABLED"
status.TextColor3 = Color3.fromRGB(100, 150, 200)
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left
status.Font = Enum.Font.Gotham
status.Parent = main

local targetLabel = Instance.new("TextLabel")
targetLabel.Size = UDim2.new(1, -28, 0, 22)
targetLabel.Position = UDim2.new(0, 14, 0, 68)
targetLabel.BackgroundTransparency = 1
targetLabel.Text = "TARGET: NONE"
targetLabel.TextColor3 = Color3.fromRGB(180, 180, 150)
targetLabel.TextSize = 11
targetLabel.TextXAlignment = Enum.TextXAlignment.Left
targetLabel.Font = Enum.Font.Gotham
targetLabel.Parent = main

local aimLabel = Instance.new("TextLabel")
aimLabel.Size = UDim2.new(1, -28, 0, 22)
aimLabel.Position = UDim2.new(0, 14, 0, 90)
aimLabel.BackgroundTransparency = 1
aimLabel.Text = "AIM: HEAD"
aimLabel.TextColor3 = Color3.fromRGB(80, 180, 255)
aimLabel.TextSize = 11
aimLabel.TextXAlignment = Enum.TextXAlignment.Left
aimLabel.Font = Enum.Font.Gotham
aimLabel.Parent = main

local killsLabel = Instance.new("TextLabel")
killsLabel.Size = UDim2.new(1, -28, 0, 22)
killsLabel.Position = UDim2.new(0, 14, 0, 112)
killsLabel.BackgroundTransparency = 1
killsLabel.Text = "KILLS: 0"
killsLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
killsLabel.TextSize = 11
killsLabel.TextXAlignment = Enum.TextXAlignment.Left
killsLabel.Font = Enum.Font.Gotham
killsLabel.Parent = main

-- Кнопки
local function createButton(text, y, color, action)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -28, 0, 34)
    btn.Position = UDim2.new(0, 14, 0, y)
    btn.BackgroundColor3 = color or Color3.fromRGB(20, 40, 70)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(200, 215, 240)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamMedium
    btn.Parent = main
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    
    if action then
        btn.MouseButton1Click:Connect(action)
    end
    
    return btn
end

local btnToggle = createButton("ACTIVATE", 142, Color3.fromRGB(20, 50, 90))
local btnAimPart = createButton("SWITCH TO BODY", 184, Color3.fromRGB(15, 55, 45))
local btnExit = createButton("EXIT SCRIPT", 340, Color3.fromRGB(55, 20, 20))

GUI.status = status
GUI.targetLabel = targetLabel
GUI.aimLabel = aimLabel
GUI.killsLabel = killsLabel
GUI.btnToggle = btnToggle
GUI.btnAimPart = btnAimPart
GUI.main = main

-- ============================================================
--  ОСНОВНАЯ ЛОГИКА АИМА
-- ============================================================
local AimLogic = {}

function AimLogic.findBestTarget()
    local center = getCenter()
    local best = nil
    local bestDist = math.huge
    local fovSq = CONFIG.FOV ^ 2
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Player and isAlive(plr) then
            -- Проверка видимости
            if not isVisible(plr) then continue end
            
            local part = getAimPart(plr)
            if not part then continue end
            
            local screenPos = getScreenPos(part)
            if not screenPos then continue end
            
            local dx = screenPos.X - center.X
            local dy = screenPos.Y - center.Y
            local dist = dx*dx + dy*dy
            
            if dist < fovSq and dist < bestDist then
                local worldDist = getWorldDistance(plr)
                if worldDist <= CONFIG.DistanceLimit then
                    best = plr
                    bestDist = dist
                end
            end
        end
    end
    
    return best, bestDist
end

function AimLogic.getTargetData(plr)
    if not plr or not isAlive(plr) then return nil end
    
    local part = getAimPart(plr)
    if not part then return nil end
    
    return {
        player = plr,
        part = part,
        position = part.Position,
        screenPos = getScreenPos(part),
        worldDist = getWorldDistance(plr),
        velocity = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character.HumanoidRootPart.Velocity or Vector3.new(0, 0, 0),
    }
end

function AimLogic.shouldSwitch(current, newData, newDist)
    if not current or not current.player then return true end
    
    -- Проверяем, жив ли текущий
    if not isAlive(current.player) then return true end
    
    -- Текущая дистанция до цели
    local currentPart = getAimPart(current.player)
    if not currentPart then return true end
    
    local currentScreen = getScreenPos(currentPart)
    if not currentScreen then return true end
    
    local center = getCenter()
    local dx = currentScreen.X - center.X
    local dy = currentScreen.Y - center.Y
    local currentDist = dx*dx + dy*dy
    
    -- Переключаемся только если новая цель значительно ближе
    return newDist < currentDist - CONFIG.MinSwitchDist
end

function AimLogic.lockOn(data)
    if not data or not data.part then return end
    
    local targetPos = data.position
    
    -- Предикция
    if CONFIG.Prediction and data.velocity then
        local fps = 60
        local predTime = CONFIG.PredictionStrength / fps
        targetPos = targetPos + data.velocity * predTime
    end
    
    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
    if not onScreen then return end
    
    local center = getCenter()
    local dx = screenPos.X - center.X
    local dy = screenPos.Y - center.Y
    local dist = dx*dx + dy*dy
    
    if dist > CONFIG.DeadZone then
        local newCF = CFrame.lookAt(Camera.CFrame.Position, targetPos)
        Camera.CFrame = Camera.CFrame:Lerp(newCF, CONFIG.Smoothness)
    end
end

-- ============================================================
--  ОСНОВНОЙ ЦИКЛ
-- ============================================================
local function processAim()
    if not State.enabled then return end
    
    State.frameCount = State.frameCount + 1
    
    -- Поиск цели (каждый 2-й кадр для оптимизации)
    local nearest, nearestDist
    if State.frameCount % 2 == 0 then
        nearest, nearestDist = AimLogic.findBestTarget()
    else
        nearest, nearestDist = State.target, State.targetDist or math.huge
    end
    
    -- Нет целей
    if not nearest or not isAlive(nearest) then
        State.lostTimer = State.lostTimer + 0.016
        if State.lostTimer > CONFIG.LostTimeout then
            State.target = nil
            State.targetData = nil
            GUI.status.Text = "TARGET LOST"
            GUI.status.TextColor3 = Color3.fromRGB(255, 200, 100)
            GUI.targetLabel.Text = "SEARCHING..."
            GUI.targetLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        end
        return
    end
    
    State.lostTimer = 0
    
    -- Проверка убийства
    if State.target and not isAlive(State.target) then
        State.killCount = State.killCount + 1
        GUI.killsLabel.Text = "KILLS: " .. State.killCount
        State.target = nil
        State.targetData = nil
    end
    
    -- Переключение цели
    if State.target and nearest ~= State.target then
        if AimLogic.shouldSwitch(State.targetData, nearest, nearestDist) then
            if tick() - State.lastSwitchTime > CONFIG.SwitchDelay then
                State.target = nearest
                State.targetDist = nearestDist
                State.targetData = AimLogic.getTargetData(nearest)
                State.lastSwitchTime = tick()
                
                GUI.status.Text = "SWITCHED: " .. nearest.Name
                GUI.status.TextColor3 = Color3.fromRGB(100, 255, 200)
                GUI.targetLabel.Text = "TARGET: " .. nearest.Name
                GUI.targetLabel.TextColor3 = Color3.fromRGB(100, 255, 200)
            end
        end
    elseif not State.target then
        State.target = nearest
        State.targetDist = nearestDist
        State.targetData = AimLogic.getTargetData(nearest)
        State.lastSwitchTime = tick()
        
        GUI.status.Text = "LOCKED: " .. nearest.Name
        GUI.status.TextColor3 = Color3.fromRGB(100, 255, 200)
        GUI.targetLabel.Text = "TARGET: " .. nearest.Name
        GUI.targetLabel.TextColor3 = Color3.fromRGB(100, 255, 200)
    end
    
    -- Фиксация
    if State.targetData then
        -- Обновляем данные цели
        State.targetData = AimLogic.getTargetData(State.target)
        if State.targetData then
            AimLogic.lockOn(State.targetData)
        end
    end
end

-- ============================================================
--  УПРАВЛЕНИЕ
-- ============================================================
local function toggleAim()
    State.enabled = not State.enabled
    
    if State.enabled then
        local nearest, dist = AimLogic.findBestTarget()
        if not nearest then
            State.enabled = false
            GUI.status.Text = "NO TARGETS"
            GUI.status.TextColor3 = Color3.fromRGB(255, 200, 100)
            GUI.btnToggle.Text = "RETRY"
            return
        end
        
        State.target = nearest
        State.targetDist = dist
        State.targetData = AimLogic.getTargetData(nearest)
        State.lostTimer = 0
        
        GUI.status.Text = "LOCKED: " .. nearest.Name
        GUI.status.TextColor3 = Color3.fromRGB(100, 255, 200)
        GUI.targetLabel.Text = "TARGET: " .. nearest.Name
        GUI.targetLabel.TextColor3 = Color3.fromRGB(100, 255, 200)
        GUI.btnToggle.Text = "DEACTIVATE"
        GUI.btnToggle.BackgroundColor3 = Color3.fromRGB(0, 80, 40)
        GUI.btnToggle.TextColor3 = Color3.fromRGB(200, 255, 200)
        
        Visuals.fovCircle.Visible = CONFIG.ShowFOV
        Visuals.crosshair.Visible = true
    else
        State.target = nil
        State.targetData = nil
        State.lostTimer = 0
        State.killCount = 0
        
        GUI.status.Text = "DISABLED"
        GUI.status.TextColor3 = Color3.fromRGB(100, 150, 200)
        GUI.btnToggle.Text = "ACTIVATE"
        GUI.btnToggle.BackgroundColor3 = Color3.fromRGB(20, 50, 90)
        GUI.btnToggle.TextColor3 = Color3.fromRGB(200, 215, 240)
        GUI.targetLabel.Text = "TARGET: NONE"
        GUI.targetLabel.TextColor3 = Color3.fromRGB(180, 180, 150)
        GUI.killsLabel.Text = "KILLS: 0"
        
        Visuals.fovCircle.Visible = false
        Visuals.crosshair.Visible = false
        
        -- Очистка X-Ray
        for plr in pairs(XRay) do
            removeBox(plr)
        end
    end
end

local function switchAimPart()
    if CONFIG.AimPart == "Head" then
        CONFIG.AimPart = "HumanoidRootPart"
        CONFIG.BackupPart = "Torso"
        GUI.aimLabel.Text = "AIM: BODY"
        GUI.btnAimPart.Text = "SWITCH TO HEAD"
        GUI.btnAimPart.BackgroundColor3 = Color3.fromRGB(55, 20, 20)
    else
        CONFIG.AimPart = "Head"
        CONFIG.BackupPart = "UpperTorso"
        GUI.aimLabel.Text = "AIM: HEAD"
        GUI.btnAimPart.Text = "SWITCH TO BODY"
        GUI.btnAimPart.BackgroundColor3 = Color3.fromRGB(15, 55, 45)
    end
end

-- ============================================================
--  ПРИВЯЗКА КНОПОК
-- ============================================================
GUI.btnToggle.MouseButton1Click:Connect(toggleAim)
GUI.btnAimPart.MouseButton1Click:Connect(switchAimPart)

winButtons.minimize.MouseButton1Click:Connect(function()
    State.minimized = not State.minimized
    if State.minimized then
        main:TweenSize(UDim2.new(0, 200, 0, 36), "Out", "Quad", 0.3, true)
        for _, child in ipairs(main:GetChildren()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") and child ~= header then
                child.Visible = false
            end
        end
        winButtons.minimize.Text = "□"
    else
        main:TweenSize(UDim2.new(0, 280, 0, 380), "Out", "Quad", 0.3, true)
        for _, child in ipairs(main:GetChildren()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                child.Visible = true
            end
        end
        winButtons.minimize.Text = "─"
    end
end)

winButtons.maximize.MouseButton1Click:Connect(function()
    State.maximized = not State.maximized
    if State.maximized then
        main:TweenSize(UDim2.new(0, 400, 0, 440), "Out", "Quad", 0.3, true)
        main:TweenPosition(UDim2.new(0.5, -200, 0.5, -220), "Out", "Quad", 0.3, true)
    else
        main:TweenSize(UDim2.new(0, 280, 0, 380), "Out", "Quad", 0.3, true)
        main:TweenPosition(UDim2.new(0, 16, 0, 16), "Out", "Quad", 0.3, true)
    end
end)

winButtons.close.MouseButton1Click:Connect(function()
    GUI.container:Destroy()
    xrayContainer:Destroy()
    Visuals.fovCircle:Destroy()
    Visuals.crosshair:Destroy()
    State.enabled = false
end)

GUI.btnExit.MouseButton1Click:Connect(function()
    GUI.container:Destroy()
    xrayContainer:Destroy()
    Visuals.fovCircle:Destroy()
    Visuals.crosshair:Destroy()
    State.enabled = false
end)

-- ============================================================
--  КЛАВИАТУРА
-- ============================================================
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    if input.KeyCode == Enum.KeyCode.One then
        toggleAim()
    elseif input.KeyCode == Enum.KeyCode.Two then
        switchAimPart()
    end
end)

-- ============================================================
--  ОБНОВЛЕНИЕ X-RAY (отдельный поток)
-- ============================================================
task.spawn(function()
    while true do
        if State.enabled then
            updateXRay()
        end
        task.wait(0.05)
    end
end)

-- ============================================================
--  ОСНОВНОЙ ЦИКЛ
-- ============================================================
RunService.RenderStepped:Connect(processAim)

-- ============================================================
--  СТАРТ
-- ============================================================
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "AIM LOCK v21",
    Text = "1 - Toggle | 2 - Head/Body",
    Duration = 4
})

print("✅ AIM LOCK v21.0 LOADED")
print("📌 1 - Toggle ON/OFF")
print("📌 2 - Switch aim (HEAD ↔ BODY)")
print("📌 X-Ray: ON (green boxes)")
print("📌 FOV: " .. CONFIG.FOV .. "px")
print("📌 Smoothness: " .. CONFIG.Smoothness)
