-- AIM LOCK v20.0 | PRO EDITION
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local Player = Players.LocalPlayer

-- ============================================================
-- ================ НАСТРОЙКИ ==================================
-- ============================================================
local CONFIG = {
    -- АИМ
    AimPart = "Head",
    BackupPart = "UpperTorso",
    FOV = 45,                    -- Радиус поиска в пикселях
    Smoothness = 0.16,           -- Плавность (0.12-0.20)
    DistanceLimit = 200,         -- Макс. дистанция в студиях
    DeadZone = 3,                -- Мёртвая зона (пиксели)
    Prediction = true,           -- Предсказание движения
    PredictionStrength = 0.55,   -- Сила предсказания
    
    -- ПЕРЕКЛЮЧЕНИЕ
    SwitchDelay = 0.08,          -- Задержка перед сменой
    LostTimeout = 0.3,           -- Таймаут потери цели
    MinSwitchDist = 15,          -- Мин. разница для смены (квадрат)
    
    -- X-RAY
    XRay = true,
    XRayColor = Color3.fromRGB(0, 255, 100),
    XRayTransparency = 0.15,
    XRayThickness = 1.5,
    
    -- ВИЗУАЛ
    ShowFOV = true,
    FOVColor = Color3.fromRGB(255, 255, 255),
    FOVTransparency = 0.6,
    CrosshairStyle = "DOT",      -- "DOT" или "CROSS"
    CrosshairColor = Color3.fromRGB(255, 255, 255),
}

-- ============================================================
-- ================ СОСТОЯНИЕ ==================================
-- ============================================================
local state = {
    enabled = false,
    target = nil,
    targetPos = nil,
    targetDist = math.huge,
    targetScreenPos = nil,
    lostTimer = 0,
    switchCooldown = 0,
    killCount = 0,
    minimized = false,
    maximized = false,
    playersCache = {},
}

-- ============================================================
-- ================ GUI ========================================
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.Name = "AimLock_" .. tostring(math.random(1000, 9999))
gui.ResetOnSpawn = false
gui.Parent = Player.PlayerGui
gui.DisplayOrder = 999

-- ===== ОСНОВНОЕ МЕНЮ =====
local container = Instance.new("Frame")
container.Size = UDim2.new(0, 280, 0, 400)
container.Position = UDim2.new(0, 16, 0, 16)
container.BackgroundColor3 = Color3.fromRGB(12, 16, 28)
container.BackgroundTransparency = 0.08
container.BorderSizePixel = 0
container.ClipsDescendants = true
container.Parent = gui

local containerCorner = Instance.new("UICorner")
containerCorner.CornerRadius = UDim.new(0, 12)
containerCorner.Parent = container

-- ===== ЗАГОЛОВОК =====
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 36)
header.BackgroundColor3 = Color3.fromRGB(16, 22, 40)
header.BorderSizePixel = 0
header.Parent = container

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -90, 1, 0)
title.Position = UDim2.new(0, 14, 0, 0)
title.BackgroundTransparency = 1
title.Text = "AIM LOCK v20"
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

-- ===== РАЗДЕЛИТЕЛЬ =====
local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, -28, 0, 1)
divider.Position = UDim2.new(0, 14, 0, 36)
divider.BackgroundColor3 = Color3.fromRGB(40, 50, 70)
divider.BorderSizePixel = 0
divider.Parent = container

-- ===== СТАТУСЫ =====
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -28, 0, 22)
status.Position = UDim2.new(0, 14, 0, 46)
status.BackgroundTransparency = 1
status.Text = "DISABLED"
status.TextColor3 = Color3.fromRGB(100, 150, 200)
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left
status.Font = Enum.Font.Gotham
status.Parent = container

local targetLabel = Instance.new("TextLabel")
targetLabel.Size = UDim2.new(1, -28, 0, 22)
targetLabel.Position = UDim2.new(0, 14, 0, 68)
targetLabel.BackgroundTransparency = 1
targetLabel.Text = "TARGET: NONE"
targetLabel.TextColor3 = Color3.fromRGB(180, 180, 150)
targetLabel.TextSize = 11
targetLabel.TextXAlignment = Enum.TextXAlignment.Left
targetLabel.Font = Enum.Font.Gotham
targetLabel.Parent = container

local aimLabel = Instance.new("TextLabel")
aimLabel.Size = UDim2.new(1, -28, 0, 22)
aimLabel.Position = UDim2.new(0, 14, 0, 90)
aimLabel.BackgroundTransparency = 1
aimLabel.Text = "AIM: HEAD"
aimLabel.TextColor3 = Color3.fromRGB(80, 180, 255)
aimLabel.TextSize = 11
aimLabel.TextXAlignment = Enum.TextXAlignment.Left
aimLabel.Font = Enum.Font.Gotham
aimLabel.Parent = container

local killsLabel = Instance.new("TextLabel")
killsLabel.Size = UDim2.new(1, -28, 0, 22)
killsLabel.Position = UDim2.new(0, 14, 0, 112)
killsLabel.BackgroundTransparency = 1
killsLabel.Text = "KILLS: 0"
killsLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
killsLabel.TextSize = 11
killsLabel.TextXAlignment = Enum.TextXAlignment.Left
killsLabel.Font = Enum.Font.Gotham
killsLabel.Parent = container

-- ===== КНОПКИ =====
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
    btn.Parent = container
    
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
local btnExit = createButton("EXIT SCRIPT", 360, Color3.fromRGB(55, 20, 20))

-- ============================================================
-- ================ X-RAY ======================================
-- ============================================================
local xrayContainer = Instance.new("Folder")
xrayContainer.Name = "XRay"
xrayContainer.Parent = gui

local xrayLines = {}

local function createXRay(player)
    if not CONFIG.XRay then return end
    if xrayLines[player] then return end
    
    local line = Instance.new("Frame")
    line.Size = UDim2.new(0, 0, 0, 0)
    line.BackgroundColor3 = CONFIG.XRayColor
    line.BackgroundTransparency = CONFIG.XRayTransparency
    line.BorderSizePixel = 0
    line.Parent = xrayContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = line
    
    xrayLines[player] = line
end

local function removeXRay(player)
    if xrayLines[player] then
        xrayLines[player]:Destroy()
        xrayLines[player] = nil
    end
end

local function updateXRay()
    if not CONFIG.XRay then
        for _, line in pairs(xrayLines) do
            line:Destroy()
        end
        xrayLines = {}
        return
    end
    
    local center = getCenter()
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Character then
            local torso = plr.Character:FindFirstChild("HumanoidRootPart") or plr.Character:FindFirstChild("Torso")
            if torso then
                local pos, onScreen = Camera:WorldToViewportPoint(torso.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if dist < CONFIG.FOV * 2 then
                        createXRay(plr)
                        local line = xrayLines[plr]
                        if line then
                            line.Size = UDim2.new(0, 12, 0, 12)
                            line.Position = UDim2.new(0, pos.X - 6, 0, pos.Y - 6)
                            line.Visible = plr == state.target
                        end
                    else
                        removeXRay(plr)
                    end
                else
                    removeXRay(plr)
                end
            end
        end
    end
end

-- ============================================================
-- ================ FOV CIRCLE ================================
-- ============================================================
local fovCircle = Instance.new("ImageLabel")
fovCircle.Size = UDim2.new(0, CONFIG.FOV * 2, 0, CONFIG.FOV * 2)
fovCircle.Position = UDim2.new(0.5, -CONFIG.FOV, 0.5, -CONFIG.FOV)
fovCircle.BackgroundTransparency = 1
fovCircle.Image = "rbxassetid://4911621264"
fovCircle.ImageColor3 = CONFIG.FOVColor
fovCircle.ImageTransparency = CONFIG.FOVTransparency
fovCircle.Visible = false
fovCircle.Parent = gui

-- ============================================================
-- ================ CROSSHAIR ==================================
-- ============================================================
local crosshair = Instance.new("Frame")
crosshair.Size = UDim2.new(0, 0, 0, 0)
crosshair.Position = UDim2.new(0.5, 0, 0.5, 0)
crosshair.BackgroundTransparency = 1
crosshair.Parent = gui

local function createDot()
    for _, c in pairs(crosshair:GetChildren()) do c:Destroy() end
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 3, 0, 3)
    dot.Position = UDim2.new(0.5, -1.5, 0.5, -1.5)
    dot.BackgroundColor3 = CONFIG.CrosshairColor
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
        {s = size, x = -size/2, y = -thick/2, w = size, h = thick},
        {s = size, x = -thick/2, y = -size/2, w = thick, h = size},
    }
    for _, data in ipairs(parts) do
        local part = Instance.new("Frame")
        part.Size = UDim2.new(0, data.w, 0, data.h)
        part.Position = UDim2.new(0.5, data.x, 0.5, data.y)
        part.BackgroundColor3 = CONFIG.CrosshairColor
        part.BorderSizePixel = 0
        part.Parent = crosshair
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
-- ================ ЛОГИКА ====================================
-- ============================================================

local function getCenter()
    local vp = Camera.ViewportSize
    return Vector2.new(vp.X * 0.5, vp.Y * 0.5)
end

local function isPlayerAlive(plr)
    if not plr or not plr.Character then return false end
    local humanoid = plr.Character:FindFirstChild("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function getAimPart(plr)
    if not plr or not plr.Character then return nil end
    
    -- Сначала пытаемся взять основную часть
    local part = plr.Character:FindFirstChild(CONFIG.AimPart)
    if part then return part end
    
    -- Если нет, берём запасную
    part = plr.Character:FindFirstChild(CONFIG.BackupPart)
    if part then return part end
    
    -- Если ничего нет, берём HumanoidRootPart
    return plr.Character:FindFirstChild("HumanoidRootPart") or plr.Character:FindFirstChild("Torso")
end

-- Проверка видимости (через Raycast)
local function isVisible(plr)
    if not plr or not plr.Character then return false end
    
    local part = getAimPart(plr)
    if not part then return false end
    
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin).Unit
    local distance = (part.Position - origin).Magnitude
    
    if distance > CONFIG.DistanceLimit then return false end
    
    local ray = Ray.new(origin, direction * distance)
    local hit, pos = workspace:FindPartOnRay(ray, Player.Character)
    
    if hit then
        local parent = hit.Parent
        while parent do
            if parent == plr.Character then
                return true
            end
            parent = parent.Parent
        end
        return false
    end
    
    return true
end

-- Получение позиции цели на экране
local function getTargetScreenPos(plr)
    if not plr or not plr.Character then return nil end
    local part = getAimPart(plr)
    if not part then return nil end
    
    local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
    if not onScreen then return nil end
    
    return Vector2.new(pos.X, pos.Y)
end

-- Получение скорости цели (для предикции)
local function getTargetVelocity(plr)
    if not plr or not plr.Character then return Vector3.new(0, 0, 0) end
    local root = plr.Character:FindFirstChild("HumanoidRootPart")
    if not root then return Vector3.new(0, 0, 0) end
    return root.Velocity
end

-- Поиск лучшей цели
local function findBestTarget()
    local center = getCenter()
    local best = nil
    local bestDist = math.huge
    local fovSq = CONFIG.FOV ^ 2
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Player and isPlayerAlive(plr) then
            -- Проверка видимости
            if not isVisible(plr) then continue end
            
            local screenPos = getTargetScreenPos(plr)
            if screenPos then
                local dx, dy = screenPos.X - center.X, screenPos.Y - center.Y
                local dist = dx*dx + dy*dy
                
                -- Проверка на FOV
                if dist < fovSq and dist < bestDist then
                    -- Доп. проверка на расстояние
                    local part = getAimPart(plr)
                    if part then
                        local worldDist = (part.Position - Camera.CFrame.Position).Magnitude
                        if worldDist <= CONFIG.DistanceLimit then
                            best = plr
                            bestDist = dist
                        end
                    end
                end
            end
        end
    end
    
    return best, bestDist
end

-- ============================================================
-- ================ ОСНОВНАЯ ЛОГИКА ===========================
-- ============================================================

local lastTargetSwitch = 0

local function processAim()
    if not state.enabled then return end
    
    -- Поиск цели
    local nearest, nearestDist = findBestTarget()
    
    -- Если есть цель и она жива
    if nearest and isPlayerAlive(nearest) then
        state.lostTimer = 0
        
        -- Проверка на убийство
        if state.target and not isPlayerAlive(state.target) then
            state.killCount = state.killCount + 1
            killsLabel.Text = "KILLS: " .. state.killCount
            state.target = nil
        end
        
        -- Переключение на новую цель
        if state.target and nearest ~= state.target then
            local currentDist = getTargetScreenPos(state.target)
            if currentDist then
                local center = getCenter()
                local dx, dy = currentDist.X - center.X, currentDist.Y - center.Y
                local curDistSq = dx*dx + dy*dy
                
                -- Переключаемся только если новая цель значительно ближе
                if nearestDist < curDistSq - CONFIG.MinSwitchDist then
                    if tick() - lastTargetSwitch > CONFIG.SwitchDelay then
                        state.target = nearest
                        state.targetDist = nearestDist
                        lastTargetSwitch = tick()
                        local name = nearest.Name
                        status.Text = "SWITCHED: " .. name
                        status.TextColor3 = Color3.fromRGB(100, 255, 200)
                        targetLabel.Text = "TARGET: " .. name
                        targetLabel.TextColor3 = Color3.fromRGB(100, 255, 200)
                    end
                end
            else
                state.target = nearest
                state.targetDist = nearestDist
                lastTargetSwitch = tick()
            end
        elseif not state.target then
            state.target = nearest
            state.targetDist = nearestDist
            lastTargetSwitch = tick()
            local name = nearest.Name
            status.Text = "LOCKED: " .. name
            status.TextColor3 = Color3.fromRGB(100, 255, 200)
            targetLabel.Text = "TARGET: " .. name
            targetLabel.TextColor3 = Color3.fromRGB(100, 255, 200)
        end
    else
        -- Нет целей
        state.lostTimer = state.lostTimer + 0.016
        if state.lostTimer > CONFIG.LostTimeout then
            state.target = nil
            status.Text = "TARGET LOST"
            status.TextColor3 = Color3.fromRGB(255, 200, 100)
            targetLabel.Text = "SEARCHING..."
            targetLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        end
    end
    
    -- Фиксация камеры
    if state.target and isPlayerAlive(state.target) then
        local part = getAimPart(state.target)
        if part then
            local targetWorldPos = part.Position
            
            -- Предикция
            if CONFIG.Prediction then
                local vel = getTargetVelocity(state.target)
                local fps = 1 / (RunService.Heartbeat:Wait() or 0.016)
                local predTime = CONFIG.PredictionStrength / math.max(fps, 30)
                targetWorldPos = targetWorldPos + vel * predTime
            end
            
            local screenPos, onScreen = Camera:WorldToViewportPoint(targetWorldPos)
            if onScreen then
                local center = getCenter()
                local dx, dy = screenPos.X - center.X, screenPos.Y - center.Y
                local dist = dx*dx + dy*dy
                
                -- Мёртвая зона
                if dist > CONFIG.DeadZone ^ 2 then
                    local newCF = CFrame.lookAt(Camera.CFrame.Position, targetWorldPos)
                    Camera.CFrame = Camera.CFrame:Lerp(newCF, CONFIG.Smoothness)
                end
            end
        end
    end
    
    -- Обновление X-Ray
    updateXRay()
    
    -- FOV Circle
    fovCircle.Visible = state.enabled and CONFIG.ShowFOV
    fovCircle.Size = UDim2.new(0, CONFIG.FOV * 2, 0, CONFIG.FOV * 2)
    fovCircle.Position = UDim2.new(0.5, -CONFIG.FOV, 0.5, -CONFIG.FOV)
end

-- ============================================================
-- ================ УПРАВЛЕНИЕ ================================
-- ============================================================

local function toggle()
    state.enabled = not state.enabled
    if state.enabled then
        local nearest, dist = findBestTarget()
        if not nearest then
            state.enabled = false
            status.Text = "NO TARGETS"
            status.TextColor3 = Color3.fromRGB(255, 200, 100)
            btnToggle.Text = "RETRY"
            return
        end
        state.target = nearest
        state.targetDist = dist
        state.lostTimer = 0
        
        local name = nearest.Name
        status.Text = "LOCKED: " .. name
        status.TextColor3 = Color3.fromRGB(100, 255, 200)
        targetLabel.Text = "TARGET: " .. name
        targetLabel.TextColor3 = Color3.fromRGB(100, 255, 200)
        btnToggle.Text = "DEACTIVATE"
        btnToggle.BackgroundColor3 = Color3.fromRGB(0, 80, 40)
        btnToggle.TextColor3 = Color3.fromRGB(200, 255, 200)
        
        fovCircle.Visible = true
        crosshair.Visible = true
    else
        state.target = nil
        state.targetDist = math.huge
        state.lostTimer = 0
        status.Text = "DISABLED"
        status.TextColor3 = Color3.fromRGB(100, 150, 200)
        btnToggle.Text = "ACTIVATE"
        btnToggle.BackgroundColor3 = Color3.fromRGB(20, 50, 90)
        btnToggle.TextColor3 = Color3.fromRGB(200, 215, 240)
        targetLabel.Text = "TARGET: NONE"
        targetLabel.TextColor3 = Color3.fromRGB(180, 180, 150)
        state.killCount = 0
        killsLabel.Text = "KILLS: 0"
        
        fovCircle.Visible = false
        crosshair.Visible = false
        
        for _, line in pairs(xrayLines) do
            line:Destroy()
        end
        xrayLines = {}
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

-- ===== ПРИВЯЗКА =====
btnToggle.MouseButton1Click:Connect(toggle)
btnAimPart.MouseButton1Click:Connect(switchAimPart)

winButtons.minimize.MouseButton1Click:Connect(function()
    state.minimized = not state.minimized
    if state.minimized then
        container:TweenSize(UDim2.new(0, 200, 0, 36), "Out", "Quad", 0.3, true)
        status.Visible = false
        targetLabel.Visible = false
        aimLabel.Visible = false
        killsLabel.Visible = false
        btnToggle.Visible = false
        btnAimPart.Visible = false
        btnExit.Visible = false
        winButtons.minimize.Text = "□"
    else
        container:TweenSize(UDim2.new(0, 280, 0, 400), "Out", "Quad", 0.3, true)
        status.Visible = true
        targetLabel.Visible = true
        aimLabel.Visible = true
        killsLabel.Visible = true
        btnToggle.Visible = true
        btnAimPart.Visible = true
        btnExit.Visible = true
        winButtons.minimize.Text = "─"
    end
end)

winButtons.maximize.MouseButton1Click:Connect(function()
    state.maximized = not state.maximized
    if state.maximized then
        container:TweenSize(UDim2.new(0, 400, 0, 460), "Out", "Quad", 0.3, true)
        container:TweenPosition(UDim2.new(0.5, -200, 0.5, -230), "Out", "Quad", 0.3, true)
    else
        container:TweenSize(UDim2.new(0, 280, 0, 400), "Out", "Quad", 0.3, true)
        container:TweenPosition(UDim2.new(0, 16, 0, 16), "Out", "Quad", 0.3, true)
    end
end)

winButtons.close.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

btnExit.MouseButton1Click:Connect(function()
    gui:Destroy()
    state.enabled = false
    state.target = nil
end)

-- ===== КЛАВИАТУРА =====
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    if input.KeyCode == Enum.KeyCode.One then
        toggle()
    elseif input.KeyCode == Enum.KeyCode.Two then
        switchAimPart()
    end
end)

-- ============================================================
-- ================ ГЛАВНЫЙ ЦИКЛ ==============================
-- ============================================================

RunService.RenderStepped:Connect(processAim)

-- ============================================================
-- ================ СТАРТ ======================================
-- ============================================================

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "AIM LOCK v20 PRO",
    Text = "1 - Toggle | 2 - Head/Body",
    Duration = 4
})

print("✅ AIM LOCK v20.0 LOADED (PRO EDITION)")
print("📌 1 - Toggle ON/OFF")
print("📌 2 - Switch aim (HEAD ↔ BODY)")
print("📌 X-Ray: ON (green boxes)")
print("📌 FOV: " .. CONFIG.FOV .. "px")
print("📌 Smoothness: " .. CONFIG.Smoothness)
