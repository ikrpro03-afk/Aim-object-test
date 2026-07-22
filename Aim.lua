-- AIM LOCK v24.0 | INSTANT AIM + ALWAYS ON X-RAY
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local Player = Players.LocalPlayer

-- ============================================================
--  КОНФИГУРАЦИЯ
-- ============================================================
local CONFIG = {
    AimPart = "Head",
    BackupPart = "UpperTorso",
    FOV = 50,
    Smoothness = 0.98,
    DistanceLimit = 250,
    DeadZone = 1,
    LostTimeout = 0.05,
    XRayColor = Color3.fromRGB(0, 255, 100),
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
    lostTimer = 0,
    waitingForTarget = false,
}

-- ============================================================
--  X-RAY СОСТОЯНИЕ
-- ============================================================
local XRayState = {
    enabled = true,
    boxes = {},
    container = nil,
}

-- ============================================================
--  GUI (без изменений)
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.Name = "AimLock_" .. tostring(math.random(1000, 9999))
gui.ResetOnSpawn = false
gui.Parent = Player.PlayerGui
gui.DisplayOrder = 999

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 280, 0, 420)
main.Position = UDim2.new(0, 16, 0, 16)
main.BackgroundColor3 = Color3.fromRGB(12, 16, 28)
main.BackgroundTransparency = 0.08
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = main

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
title.Text = "AIM LOCK v24"
title.TextColor3 = Color3.fromRGB(190, 215, 255)
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamMedium
title.Parent = header

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

local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, -28, 0, 1)
divider.Position = UDim2.new(0, 14, 0, 36)
divider.BackgroundColor3 = Color3.fromRGB(40, 50, 70)
divider.BorderSizePixel = 0
divider.Parent = main

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

local function createButton(text, y, color)
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
    return btn
end

local btnToggle = createButton("ACTIVATE", 142, Color3.fromRGB(20, 50, 90))
local btnAimPart = createButton("SWITCH TO BODY", 184, Color3.fromRGB(15, 55, 45))
local btnXRay = createButton("X-RAY: ON", 226, Color3.fromRGB(20, 60, 40))
local btnExit = createButton("EXIT SCRIPT", 380, Color3.fromRGB(55, 20, 20))

-- ============================================================
--  ВИЗУАЛЫ
-- ============================================================
local fovCircle = Instance.new("ImageLabel")
fovCircle.Size = UDim2.new(0, CONFIG.FOV * 2, 0, CONFIG.FOV * 2)
fovCircle.Position = UDim2.new(0.5, -CONFIG.FOV, 0.5, -CONFIG.FOV)
fovCircle.BackgroundTransparency = 1
fovCircle.Image = "rbxassetid://4911621264"
fovCircle.ImageColor3 = CONFIG.FOVColor
fovCircle.ImageTransparency = 0.6
fovCircle.Visible = false
fovCircle.Parent = gui

local crosshair = Instance.new("Frame")
crosshair.Size = UDim2.new(0, 0, 0, 0)
crosshair.Position = UDim2.new(0.5, 0, 0.5, 0)
crosshair.BackgroundTransparency = 1
crosshair.Visible = false
crosshair.Parent = gui

local function createDot()
    for _, c in pairs(crosshair:GetChildren()) do c:Destroy() end
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 3, 0, 3)
    dot.Position = UDim2.new(0.5, -1.5, 0.5, -1.5)
    dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dot.BorderSizePixel = 0
    dot.Parent = crosshair
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = dot
end

local function createCross()
    for _, c in pairs(crosshair:GetChildren()) do c:Destroy() end
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
        part.Parent = crosshair
    end
end

if CONFIG.CrosshairStyle == "DOT" then createDot() else createCross() end

-- ============================================================
--  УТИЛИТЫ
-- ============================================================
local function getCenter()
    local vp = Camera.ViewportSize
    return Vector2.new(vp.X * 0.5, vp.Y * 0.5)
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

local function getScreenPos(part)
    if not part then return nil end
    local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
    if not onScreen then return nil end
    return Vector2.new(pos.X, pos.Y)
end

local function getWorldDistance(plr)
    local part = getAimPart(plr)
    if not part then return math.huge end
    return (part.Position - Camera.CFrame.Position).Magnitude
end

local function getVelocity(plr)
    if not plr or not plr.Character then return Vector3.new(0, 0, 0) end
    local root = plr.Character:FindFirstChild("HumanoidRootPart")
    if root then return root.Velocity end
    return Vector3.new(0, 0, 0)
end

-- ============================================================
--  VISIBILITY CHECK (КАЖДЫЙ КАДР)
-- ============================================================
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
raycastParams.FilterDescendantsInstances = {Player.Character}

local function isVisible(plr)
    if not plr or not plr.Character then return false end
    
    local part = getAimPart(plr)
    if not part then return false end
    
    local origin = Camera.CFrame.Position
    local targetPos = part.Position
    local direction = (targetPos - origin).Unit
    local distance = (targetPos - origin).Magnitude
    
    if distance > CONFIG.DistanceLimit then return false end
    
    local result = workspace:Raycast(origin, direction * distance, raycastParams)
    if not result then return true end
    
    local hit = result.Instance
    local parent = hit.Parent
    while parent do
        if parent == plr.Character then return true end
        parent = parent.Parent
    end
    
    return false
end

-- ============================================================
--  X-RAY (ВСЕГДА ВКЛЮЧЁН, ВНЕ ЗАВИСИМОСТИ ОТ FOV)
-- ============================================================
local function createBox(plr)
    if XRayState.boxes[plr] then return end
    if not XRayState.container then return end
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 40, 0, 60)
    container.BackgroundTransparency = 1
    container.Parent = XRayState.container
    
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
    
    XRayState.boxes[plr] = {
        container = container,
        border = border,
        outline = outline,
        name = nameLabel,
    }
end

local function updateBox(plr)
    local data = XRayState.boxes[plr]
    if not data then return end
    if not plr or not plr.Character then
        removeBox(plr)
        return
    end
    
    local char = plr.Character
    local modelCF, modelSize = char:GetBoundingBox()
    if modelSize.Magnitude < 0.5 then
        data.container.Visible = false
        return
    end
    
    local center = modelCF.Position
    local sx, sy, sz = modelSize.X/2, modelSize.Y/2, modelSize.Z/2
    local right = modelCF.RightVector
    local up = modelCF.UpVector
    local look = modelCF.LookVector
    
    local corners = {
        center + right*sx + up*sy + look*sz,
        center + right*sx + up*sy - look*sz,
        center + right*sx - up*sy + look*sz,
        center + right*sx - up*sy - look*sz,
        center - right*sx + up*sy + look*sz,
        center - right*sx + up*sy - look*sz,
        center - right*sx - up*sy + look*sz,
        center - right*sx - up*sy - look*sz,
    }
    
    local screenCorners = {}
    for _, cornerPos in ipairs(corners) do
        local screenPos, onScreen = Camera:WorldToViewportPoint(cornerPos)
        if onScreen then
            table.insert(screenCorners, Vector2.new(screenPos.X, screenPos.Y))
        end
    end
    
    if #screenCorners == 0 then
        data.container.Visible = false
        return
    end
    
    local minX, maxX = screenCorners[1].X, screenCorners[1].X
    local minY, maxY = screenCorners[1].Y, screenCorners[1].Y
    
    for i = 2, #screenCorners do
        local p = screenCorners[i]
        if p.X < minX then minX = p.X end
        if p.X > maxX then maxX = p.X end
        if p.Y < minY then minY = p.Y end
        if p.Y > maxY then maxY = p.Y end
    end
    
    local padding = 4
    local width = maxX - minX + padding * 2
    local height = maxY - minY + padding * 2
    
    width = math.max(width, 20)
    height = math.max(height, 30)
    
    data.container.Position = UDim2.new(0, minX - padding, 0, minY - padding)
    data.container.Size = UDim2.new(0, width, 0, height)
    data.container.Visible = true
end

local function removeBox(plr)
    local data = XRayState.boxes[plr]
    if data then
        data.container:Destroy()
        XRayState.boxes[plr] = nil
    end
end

local function clearAllBoxes()
    for plr in pairs(XRayState.boxes) do
        removeBox(plr)
    end
    XRayState.boxes = {}
end

local function updateXRay()
    if not XRayState.enabled then
        clearAllBoxes()
        return
    end
    
    for plr in pairs(XRayState.boxes) do
        if not plr or not isAlive(plr) then
            removeBox(plr)
        end
    end
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Player and isAlive(plr) then
            local part = getAimPart(plr)
            if part then
                local screenPos = getScreenPos(part)
                if screenPos then
                    createBox(plr)
                    updateBox(plr)
                else
                    removeBox(plr)
                end
            end
        end
    end
end

-- ============================================================
--  ПОИСК ЛУЧШЕЙ ЦЕЛИ (КАЖДЫЙ КАДР, БЕЗ ЗАДЕРЖЕК)
-- ============================================================
local function findBestTarget()
    local center = getCenter()
    local best = nil
    local bestDist = math.huge
    local fovSq = CONFIG.FOV ^ 2
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Player and isAlive(plr) then
            -- Проверка видимости
            if not isVisible(plr) then 
                continue 
            end
            
            local part = getAimPart(plr)
            if not part then 
                continue 
            end
            
            local screenPos = getScreenPos(part)
            if not screenPos then 
                continue 
            end
            
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

-- ============================================================
--  ПОЛУЧЕНИЕ ДАННЫХ ЦЕЛИ
-- ============================================================
local function getTargetData(plr)
    if not plr or not isAlive(plr) then return nil end
    
    local part = getAimPart(plr)
    if not part then return nil end
    
    return {
        player = plr,
        part = part,
        position = part.Position,
        velocity = getVelocity(plr),
        screenPos = getScreenPos(part),
        worldDist = getWorldDistance(plr),
    }
end

-- ============================================================
--  ПРЕДИКЦИЯ (АВТОМАТИЧЕСКАЯ)
-- ============================================================
local function calculatePrediction(targetData)
    if not targetData then return nil end
    
    local vel = targetData.velocity
    if vel.Magnitude < 0.1 then 
        return targetData.position 
    end
    
    local dist = targetData.worldDist
    if dist > CONFIG.DistanceLimit then 
        return targetData.position 
    end
    
    -- Автоматический расчёт силы предикции
    local speed = vel.Magnitude
    local baseTime = 0.3
    local predTime = math.min(baseTime * (speed / 20), 1.5)
    
    return targetData.position + vel * predTime
end

-- ============================================================
--  ОСНОВНАЯ ЛОГИКА АИМА (МГНОВЕННАЯ)
-- ============================================================
local function processAim()
    -- X-Ray обновляется всегда
    updateXRay()
    
    if not State.enabled then 
        return 
    end
    
    -- Поиск цели всегда
    local best, bestDist = findBestTarget()
    
    -- Если есть лучшая цель и она видима
    if best and isVisible(best) then
        State.lostTimer = 0
        
        -- Обновляем цель если есть новая или текущая умерла
        if not State.target or not isAlive(State.target) or not isVisible(State.target) then
            State.target = best
            State.targetData = getTargetData(best)
            State.waitingForTarget = false
            
            status.Text = "LOCKED: " .. best.Name
            status.TextColor3 = Color3.fromRGB(100, 255, 200)
            targetLabel.Text = "TARGET: " .. best.Name
            targetLabel.TextColor3 = Color3.fromRGB(100, 255, 200)
        end
        
        -- Если текущая цель не лучшая, но жива и видима - держим её
        if State.target and State.target ~= best and isAlive(State.target) and isVisible(State.target) then
            -- Проверяем, не стала ли новая цель значительно ближе
            local currentData = State.targetData
            local currentDist = currentData and currentData.screenPos and (function()
                local center = getCenter()
                local dx = currentData.screenPos.X - center.X
                local dy = currentData.screenPos.Y - center.Y
                return dx*dx + dy*dy
            end)() or math.huge
            
            if bestDist < currentDist - 50 then
                State.target = best
                State.targetData = getTargetData(best)
                status.Text = "SWITCHED: " .. best.Name
                status.TextColor3 = Color3.fromRGB(100, 255, 200)
                targetLabel.Text = "TARGET: " .. best.Name
                targetLabel.TextColor3 = Color3.fromRGB(100, 255, 200)
            end
        end
    else
        -- Нет целей
        State.lostTimer = State.lostTimer + 0.016
        
        if State.lostTimer > CONFIG.LostTimeout then
            State.target = nil
            State.targetData = nil
            State.waitingForTarget = true
            
            status.Text = "WAITING..."
            status.TextColor3 = Color3.fromRGB(255, 200, 100)
            targetLabel.Text = "SEARCHING..."
            targetLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        end
    end
    
    -- Если цель потеряна, но режим ожидания включён, ищем новую
    if State.waitingForTarget then
        local newTarget, _ = findBestTarget()
        if newTarget and isVisible(newTarget) then
            State.target = newTarget
            State.targetData = getTargetData(newTarget)
            State.waitingForTarget = false
            State.lostTimer = 0
            
            status.Text = "LOCKED: " .. newTarget.Name
            status.TextColor3 = Color3.fromRGB(100, 255, 200)
            targetLabel.Text = "TARGET: " .. newTarget.Name
            targetLabel.TextColor3 = Color3.fromRGB(100, 255, 200)
        end
    end
    
    -- СОПРОВОЖДЕНИЕ (МГНОВЕННОЕ)
    if State.targetData and State.target and isAlive(State.target) and isVisible(State.target) then
        State.targetData = getTargetData(State.target)
        if State.targetData then
            local targetPos = calculatePrediction(State.targetData)
            
            if targetPos then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
                if onScreen then
                    local center = getCenter()
                    local dx = screenPos.X - center.X
                    local dy = screenPos.Y - center.Y
                    local dist = dx*dx + dy*dy
                    
                    if dist > CONFIG.DeadZone then
                        local newCF = CFrame.lookAt(Camera.CFrame.Position, targetPos)
                        Camera.CFrame = Camera.CFrame:Lerp(newCF, CONFIG.Smoothness)
                    end
                end
            end
        end
    end
end

-- ============================================================
--  УПРАВЛЕНИЕ
-- ============================================================
local function toggleAim()
    State.enabled = not State.enabled
    
    if State.enabled then
        local nearest, _ = findBestTarget()
        if not nearest then
            status.Text = "WAITING..."
            status.TextColor3 = Color3.fromRGB(255, 200, 100)
            targetLabel.Text = "SEARCHING..."
            targetLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
            btnToggle.Text = "ACTIVE"
            btnToggle.BackgroundColor3 = Color3.fromRGB(0, 80, 40)
            btnToggle.TextColor3 = Color3.fromRGB(200, 255, 200)
            State.waitingForTarget = true
            
            fovCircle.Visible = CONFIG.ShowFOV
            crosshair.Visible = true
            
            if not XRayState.container then
                XRayState.container = Instance.new("Folder")
                XRayState.container.Name = "XRay"
                XRayState.container.Parent = gui
            end
            return
        end
        
        State.target = nearest
        State.targetData = getTargetData(nearest)
        State.lostTimer = 0
        State.waitingForTarget = false
        
        status.Text = "LOCKED: " .. nearest.Name
        status.TextColor3 = Color3.fromRGB(100, 255, 200)
        targetLabel.Text = "TARGET: " .. nearest.Name
        targetLabel.TextColor3 = Color3.fromRGB(100, 255, 200)
        btnToggle.Text = "DEACTIVATE"
        btnToggle.BackgroundColor3 = Color3.fromRGB(0, 80, 40)
        btnToggle.TextColor3 = Color3.fromRGB(200, 255, 200)
        
        fovCircle.Visible = CONFIG.ShowFOV
        crosshair.Visible = true
        
        if not XRayState.container then
            XRayState.container = Instance.new("Folder")
            XRayState.container.Name = "XRay"
            XRayState.container.Parent = gui
        end
    else
        State.target = nil
        State.targetData = nil
        State.lostTimer = 0
        State.waitingForTarget = false
        State.killCount = 0
        
        status.Text = "DISABLED"
        status.TextColor3 = Color3.fromRGB(100, 150, 200)
        btnToggle.Text = "ACTIVATE"
        btnToggle.BackgroundColor3 = Color3.fromRGB(20, 50, 90)
        btnToggle.TextColor3 = Color3.fromRGB(200, 215, 240)
        targetLabel.Text = "TARGET: NONE"
        targetLabel.TextColor3 = Color3.fromRGB(180, 180, 150)
        killsLabel.Text = "KILLS: 0"
        
        fovCircle.Visible = false
        crosshair.Visible = false
        
        clearAllBoxes()
        if XRayState.container then
            XRayState.container:Destroy()
            XRayState.container = nil
        end
    end
end

local function switchAimPart()
    if CONFIG.AimPart == "Head" then
        CONFIG.AimPart = "HumanoidRootPart"
        CONFIG.BackupPart = "Torso"
        aimLabel.Text = "AIM: BODY"
        btnAimPart.Text = "SWITCH TO HEAD"
        btnAimPart.BackgroundColor3 = Color3.fromRGB(55, 20, 20)
    else
        CONFIG.AimPart = "Head"
        CONFIG.BackupPart = "UpperTorso"
        aimLabel.Text = "AIM: HEAD"
        btnAimPart.Text = "SWITCH TO BODY"
        btnAimPart.BackgroundColor3 = Color3.fromRGB(15, 55, 45)
    end
end

local function toggleXRay()
    XRayState.enabled = not XRayState.enabled
    btnXRay.Text = XRayState.enabled and "X-RAY: ON" or "X-RAY: OFF"
    btnXRay.BackgroundColor3 = XRayState.enabled and Color3.fromRGB(20, 60, 40) or Color3.fromRGB(60, 20, 20)
    
    if not XRayState.enabled then
        clearAllBoxes()
        if XRayState.container then
            XRayState.container:Destroy()
            XRayState.container = nil
        end
    elseif not XRayState.container then
        XRayState.container = Instance.new("Folder")
        XRayState.container.Name = "XRay"
        XRayState.container.Parent = gui
    end
end

-- ============================================================
--  ПРИВЯЗКА КНОПОК
-- ============================================================
btnToggle.MouseButton1Click:Connect(toggleAim)
btnAimPart.MouseButton1Click:Connect(switchAimPart)
btnXRay.MouseButton1Click:Connect(toggleXRay)

winButtons.minimize.MouseButton1Click:Connect(function()
    if State.minimized then
        main:TweenSize(UDim2.new(0, 280, 0, 420), "Out", "Quad", 0.3, true)
        for _, child in ipairs(main:GetChildren()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                child.Visible = true
            end
        end
        winButtons.minimize.Text = "─"
        State.minimized = false
    else
        main:TweenSize(UDim2.new(0, 200, 0, 36), "Out", "Quad", 0.3, true)
        for _, child in ipairs(main:GetChildren()) do
            if child:IsA("TextLabel") or (child:IsA("TextButton") and child ~= header) then
                child.Visible = false
            end
        end
        winButtons.minimize.Text = "□"
        State.minimized = true
    end
end)

winButtons.maximize.MouseButton1Click:Connect(function()
    State.maximized = not State.maximized
    if State.maximized then
        main:TweenSize(UDim2.new(0, 400, 0, 480), "Out", "Quad", 0.3, true)
        main:TweenPosition(UDim2.new(0.5, -200, 0.5, -240), "Out", "Quad", 0.3, true)
    else
        main:TweenSize(UDim2.new(0, 280, 0, 420), "Out", "Quad", 0.3, true)
        main:TweenPosition(UDim2.new(0, 16, 0, 16), "Out", "Quad", 0.3, true)
    end
end)

winButtons.close.MouseButton1Click:Connect(function()
    gui:Destroy()
    if XRayState.container then XRayState.container:Destroy() end
    fovCircle:Destroy()
    crosshair:Destroy()
    State.enabled = false
end)

btnExit.MouseButton1Click:Connect(function()
    gui:Destroy()
    if XRayState.container then XRayState.container:Destroy() end
    fovCircle:Destroy()
    crosshair:Destroy()
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
    elseif input.KeyCode == Enum.KeyCode.Three then
        toggleXRay()
    end
end)

-- ============================================================
--  ГЛАВНЫЙ ЦИКЛ (ОДИН НА ВСЁ)
-- ============================================================
RunService.RenderStepped:Connect(processAim)

-- ============================================================
--  СТАРТ
-- =================================
