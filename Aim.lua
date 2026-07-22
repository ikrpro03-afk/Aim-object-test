-- AIM LOCK v17.0 | PVP EDITION
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
    Speed = 0.92,
    AimPart = "Head",        -- "Head" или "HumanoidRootPart" (Torso)
    SearchRadius = 350,      -- Радиус поиска цели (в пикселях)
    LockThreshold = 4,       -- Точность доведения
    AutoSwitch = true,       -- Авто-смена цели после убийства
    SwitchDelay = 0.3,       -- Задержка перед сменой цели
}

-- ============================================================
-- ================ СОСТОЯНИЕ ==================================
-- ============================================================
local state = {
    enabled = false,
    target = nil,
    lockedTarget = nil,
    lastTarget = nil,
    minimized = false,
    maximized = false,
    killDetected = false,
    switchCooldown = 0,
}

-- ============================================================
-- ================ GUI (БЕЗ ПРИЦЕЛА) =========================
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.Name = "AimLock_" .. tostring(math.random(1000, 9999))
gui.ResetOnSpawn = false
gui.Parent = Player.PlayerGui
gui.DisplayOrder = 999

-- ===== ОСНОВНОЙ КОНТЕЙНЕР =====
local container = Instance.new("Frame")
container.Size = UDim2.new(0, 280, 0, 380)
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
title.Text = "AIM LOCK v17"
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

-- Кнопки (только нужные)
local btnToggle = createButton("ACTIVATE", 142, Color3.fromRGB(20, 50, 90))
local btnAimPart = createButton("SWITCH TO BODY", 184, Color3.fromRGB(15, 55, 45))
local btnExit = createButton("EXIT SCRIPT", 340, Color3.fromRGB(55, 20, 20))

-- ============================================================
-- ================ ЛОГИКА ПОИСКА ЦЕЛИ ========================
-- ============================================================

-- Получение центра экрана
local function getCenter()
    local vp = Camera.ViewportSize
    return Vector2.new(vp.X * 0.5, vp.Y * 0.5)
end

-- Проверка, жив ли игрок
local function isPlayerAlive(plr)
    if not plr or not plr.Character then return false end
    local humanoid = plr.Character:FindFirstChild("Humanoid")
    return humanoid and humanoid.Health > 0
end

-- Получение части тела для прицеливания
local function getAimPart(plr)
    if not plr or not plr.Character then return nil end
    if CONFIG.AimPart == "Head" then
        return plr.Character:FindFirstChild("Head")
    else
        return plr.Character:FindFirstChild("HumanoidRootPart") or plr.Character:FindFirstChild("Torso")
    end
end

-- Поиск ближайшего игрока (с большой зоной)
local function findNearestPlayer()
    local center = getCenter()
    local best = nil
    local bestDist = math.huge
    local searchRadius = CONFIG.SearchRadius ^ 2
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Player and isPlayerAlive(plr) then
            local part = getAimPart(plr)
            if part then
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dx, dy = pos.X - center.X, pos.Y - center.Y
                    local dist = dx*dx + dy*dy
                    if dist < searchRadius and dist < bestDist then
                        best = plr
                        bestDist = dist
                    end
                end
            end
        end
    end
    
    return best
end

-- Поиск следующей цели (рядом с игроком)
local function findNextTarget()
    local center = getCenter()
    local best = nil
    local bestDist = math.huge
    local searchRadius = CONFIG.SearchRadius ^ 2
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Player and plr ~= state.target and isPlayerAlive(plr) then
            local part = getAimPart(plr)
            if part then
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dx, dy = pos.X - center.X, pos.Y - center.Y
                    local dist = dx*dx + dy*dy
                    if dist < searchRadius and dist < bestDist then
                        best = plr
                        bestDist = dist
                    end
                end
            end
        end
    end
    
    return best
end

-- ============================================================
-- ================ ФИКСАЦИЯ КАМЕРЫ ===========================
-- ============================================================

local function lockOnTarget(plr)
    if not plr or not isPlayerAlive(plr) then return false end
    
    local part = getAimPart(plr)
    if not part then return false end
    
    local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
    if not onScreen then return false end
    
    local center = getCenter()
    local dx, dy = pos.X - center.X, pos.Y - center.Y
    local dist = dx*dx + dy*dy
    
    if dist > CONFIG.LockThreshold then
        local newCF = CFrame.lookAt(Camera.CFrame.Position, part.Position)
        Camera.CFrame = Camera.CFrame:Lerp(newCF, CONFIG.Speed)
        return true
    end
    
    return true
end

-- ============================================================
-- ================ ОСНОВНАЯ ЛОГИКА ===========================
-- ============================================================

local killCount = 0
local lastHealth = {}
local switchTimer = 0

-- Отслеживание убийств
local function checkKills()
    if not state.enabled or not state.target then return end
    
    if not isPlayerAlive(state.target) then
        killCount = killCount + 1
        killsLabel.Text = "KILLS: " .. killCount
        
        -- Ищем следующую цель
        state.target = nil
        state.switchCooldown = CONFIG.SwitchDelay
        
        -- Уведомление
        status.Text = "TARGET ELIMINATED"
        status.TextColor3 = Color3.fromRGB(255, 200, 100)
        targetLabel.Text = "SEARCHING..."
        targetLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    end
end

-- Основной цикл
local function processAim()
    if not state.enabled then return end
    
    -- Обновление таймеров
    if state.switchCooldown > 0 then
        state.switchCooldown = state.switchCooldown - 0.016
        return
    end
    
    -- Проверка убийства
    checkKills()
    
    -- Поиск цели
    if not state.target or not isPlayerAlive(state.target) then
        state.target = findNearestPlayer()
        if state.target then
            local name = state.target.Name
            status.Text = "LOCKED: " .. name
            status.TextColor3 = Color3.fromRGB(100, 255, 200)
            targetLabel.Text = "TARGET: " .. name
            targetLabel.TextColor3 = Color3.fromRGB(100, 255, 200)
        else
            status.Text = "SEARCHING..."
            status.TextColor3 = Color3.fromRGB(255, 200, 100)
            targetLabel.Text = "TARGET: NONE"
            targetLabel.TextColor3 = Color3.fromRGB(180, 180, 150)
            return
        end
    end
    
    -- Фиксация
    if state.target and isPlayerAlive(state.target) then
        lockOnTarget(state.target)
    end
end

-- ============================================================
-- ================ УПРАВЛЕНИЕ ================================
-- ============================================================

local function toggle()
    state.enabled = not state.enabled
    if state.enabled then
        state.target = findNearestPlayer()
        if not state.target then
            state.enabled = false
            status.Text = "NO PLAYERS"
            status.TextColor3 = Color3.fromRGB(255, 200, 100)
            btnToggle.Text = "RETRY"
            return
        end
        local name = state.target.Name
        status.Text = "LOCKED: " .. name
        status.TextColor3 = Color3.fromRGB(100, 255, 200)
        targetLabel.Text = "TARGET: " .. name
        targetLabel.TextColor3 = Color3.fromRGB(100, 255, 200)
        btnToggle.Text = "DEACTIVATE"
        btnToggle.BackgroundColor3 = Color3.fromRGB(0, 80, 40)
        btnToggle.TextColor3 = Color3.fromRGB(200, 255, 200)
    else
        state.target = nil
        status.Text = "DISABLED"
        status.TextColor3 = Color3.fromRGB(100, 150, 200)
        btnToggle.Text = "ACTIVATE"
        btnToggle.BackgroundColor3 = Color3.fromRGB(20, 50, 90)
        btnToggle.TextColor3 = Color3.fromRGB(200, 215, 240)
        targetLabel.Text = "TARGET: NONE"
        targetLabel.TextColor3 = Color3.fromRGB(180, 180, 150)
        killCount = 0
        killsLabel.Text = "KILLS: 0"
    end
end

local function switchAimPart()
    if CONFIG.AimPart == "Head" then
        CONFIG.AimPart = "HumanoidRootPart"
        aimLabel.Text = "AIM: BODY"
        btnAimPart.Text = "SWITCH TO HEAD"
        btnAimPart.BackgroundColor3 = Color3.fromRGB(55, 20, 20)
    else
        CONFIG.AimPart = "Head"
        aimLabel.Text = "AIM: HEAD"
        btnAimPart.Text = "SWITCH TO BODY"
        btnAimPart.BackgroundColor3 = Color3.fromRGB(15, 55, 45)
    end
    if state.enabled and state.target then
        status.Text = "AIM SWITCHED"
        status.TextColor3 = Color3.fromRGB(255, 200, 100)
    end
end

-- ===== ПРИВЯЗКА КНОПОК =====
btnToggle.MouseButton1Click:Connect(toggle)
btnAimPart.MouseButton1Click:Connect(switchAimPart)

-- Окно
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
        container:TweenSize(UDim2.new(0, 280, 0, 380), "Out", "Quad", 0.3, true)
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
        container:TweenSize(UDim2.new(0, 400, 0, 440), "Out", "Quad", 0.3, true)
        container:TweenPosition(UDim2.new(0.5, -200, 0.5, -220), "Out", "Quad", 0.3, true)
    else
        container:TweenSize(UDim2.new(0, 280, 0, 380), "Out", "Quad", 0.3, true)
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
-- ================ ФОНОВЫЕ ЗАДАЧИ ============================
-- ============================================================

-- Очистка мёртвых целей
task.spawn(function()
    while true do
        task.wait(1)
        if state.target and not isPlayerAlive(state.target) then
            state.target = nil
            status.Text = "TARGET LOST"
            status.TextColor3 = Color3.fromRGB(255, 200, 100)
            targetLabel.Text = "TARGET: NONE"
            targetLabel.TextColor3 = Color3.fromRGB(180, 180, 150)
        end
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
    Title = "AIM LOCK v17",
    Text = "1 - Toggle | 2 - Head/Body",
    Duration = 4
})

print("✅ AIM LOCK v17.0 LOADED (PVP EDITION)")
print("📌 1 - Toggle ON/OFF")
print("📌 2 - Switch aim (HEAD ↔ BODY)")
print("📌 Auto-switch target after kill")
print("📌 Large search radius")
