-- AIM LOCK v16.0 | MODERN UI + PERFECT CENTER
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
    Mode = "OBJECTS",  -- "OBJECTS" или "PLAYERS"
    Style = "DOT",     -- "DOT" или "CROSS"
    OffsetX = 0,
    OffsetY = 0,
    OffsetStep = 1,
    SearchInterval = 0.08,
    CacheInterval = 0.5,
    LockThreshold = 4,  -- 2^2
    MaxDistance = 90000, -- 300^2
}

-- ============================================================
-- ================ СОСТОЯНИЕ ==================================
-- ============================================================
local state = {
    enabled = false,
    visible = true,
    target = nil,
    lockedTarget = nil,
    minimized = false,
    maximized = false,
    offsetMenuOpen = false,
}

-- ============================================================
-- ================ КЕШИ =======================================
-- ============================================================
local cache = {
    objects = {},
    players = {},
    center = Vector2.new(0, 0),
    lastObjectUpdate = 0,
    lastTargetSearch = 0,
}

-- ============================================================
-- ================ ЦЕНТР ЭКРАНА ===============================
-- ============================================================
local function getCenter()
    local vp = Camera.ViewportSize
    return Vector2.new(
        vp.X * 0.5 + CONFIG.OffsetX,
        vp.Y * 0.5 + CONFIG.OffsetY
    )
end

-- ============================================================
-- ================ GUI (MODERN) ===============================
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.Name = "AimLock_" .. tostring(math.random(1000, 9999))
gui.ResetOnSpawn = false
gui.Parent = Player.PlayerGui
gui.DisplayOrder = 999

-- ===== ОСНОВНОЙ КОНТЕЙНЕР =====
local container = Instance.new("Frame")
container.Size = UDim2.new(0, 320, 0, 420)
container.Position = UDim2.new(0, 16, 0, 16)
container.BackgroundColor3 = Color3.fromRGB(12, 16, 28)
container.BackgroundTransparency = 0.08
container.BorderSizePixel = 0
container.ClipsDescendants = true
container.Parent = gui

local containerCorner = Instance.new("UICorner")
containerCorner.CornerRadius = UDim.new(0, 12)
containerCorner.Parent = container

-- ===== ТЕНЬ =====
local shadow = Instance.new("Frame")
shadow.Size = UDim2.new(1, 0, 1, 0)
shadow.Position = UDim2.new(0, 0, 0, 0)
shadow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
shadow.BackgroundTransparency = 0.96
shadow.BorderSizePixel = 0
shadow.Parent = container

-- ===== ЗАГОЛОВОК =====
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 36)
header.BackgroundColor3 = Color3.fromRGB(16, 22, 40)
header.BorderSizePixel = 0
header.Parent = container

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = header

-- Заголовок текст
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -90, 1, 0)
title.Position = UDim2.new(0, 14, 0, 0)
title.BackgroundTransparency = 1
title.Text = "AIM LOCK v16"
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

local modeLabel = Instance.new("TextLabel")
modeLabel.Size = UDim2.new(1, -28, 0, 22)
modeLabel.Position = UDim2.new(0, 14, 0, 68)
modeLabel.BackgroundTransparency = 1
modeLabel.Text = "MODE: OBJECTS"
modeLabel.TextColor3 = Color3.fromRGB(80, 180, 255)
modeLabel.TextSize = 11
modeLabel.TextXAlignment = Enum.TextXAlignment.Left
modeLabel.Font = Enum.Font.Gotham
modeLabel.Parent = container

local targetLabel = Instance.new("TextLabel")
targetLabel.Size = UDim2.new(1, -28, 0, 22)
targetLabel.Position = UDim2.new(0, 14, 0, 90)
targetLabel.BackgroundTransparency = 1
targetLabel.Text = "TARGET: NONE"
targetLabel.TextColor3 = Color3.fromRGB(180, 180, 150)
targetLabel.TextSize = 11
targetLabel.TextXAlignment = Enum.TextXAlignment.Left
targetLabel.Font = Enum.Font.Gotham
targetLabel.Parent = container

-- ===== КНОПКИ (MODERN) =====
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

-- Кнопки
local btnToggle = createButton("ACTIVATE", 120, Color3.fromRGB(20, 50, 90))
local btnLock = createButton("LOCK TARGET", 162, Color3.fromRGB(15, 55, 45))
local btnMode = createButton("SWITCH MODE", 204, Color3.fromRGB(20, 40, 70))
local btnStyle = createButton("STYLE: DOT", 246, Color3.fromRGB(20, 40, 70))
local btnHide = createButton("HIDE CROSSHAIR", 288, Color3.fromRGB(20, 40, 70))
local btnOffset = createButton("⚙ OFFSET", 330, Color3.fromRGB(25, 55, 75))
local btnExit = createButton("EXIT SCRIPT", 380, Color3.fromRGB(55, 20, 20))

-- ===== OFFSET MENU =====
local offsetMenu = Instance.new("Frame")
offsetMenu.Size = UDim2.new(1, -28, 0, 0)
offsetMenu.Position = UDim2.new(0, 14, 0, 330)
offsetMenu.BackgroundColor3 = Color3.fromRGB(8, 14, 28)
offsetMenu.BackgroundTransparency = 0.2
offsetMenu.BorderSizePixel = 0
offsetMenu.Visible = false
offsetMenu.ClipsDescendants = true
offsetMenu.Parent = container

local offsetCorner = Instance.new("UICorner")
offsetCorner.CornerRadius = UDim.new(0, 8)
offsetCorner.Parent = offsetMenu

local offsetLabel = Instance.new("TextLabel")
offsetLabel.Size = UDim2.new(1, 0, 0, 20)
offsetLabel.Position = UDim2.new(0, 0, 0, 6)
offsetLabel.BackgroundTransparency = 1
offsetLabel.Text = "X: 0  Y: 0"
offsetLabel.TextColor3 = Color3.fromRGB(180, 210, 255)
offsetLabel.TextSize = 12
offsetLabel.Font = Enum.Font.Gotham
offsetLabel.Parent = offsetMenu

local offsetGrid = Instance.new("Frame")
offsetGrid.Size = UDim2.new(0, 100, 0, 80)
offsetGrid.Position = UDim2.new(0.5, -50, 0, 28)
offsetGrid.BackgroundTransparency = 1
offsetGrid.Parent = offsetMenu

local function createOffsetButton(text, pos, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 28, 0, 28)
    btn.Position = UDim2.new(0, pos.X, 0, pos.Y)
    btn.BackgroundColor3 = color or Color3.fromRGB(25, 55, 75)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    btn.Font = Enum.Font.Gotham
    btn.Parent = offsetGrid
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    
    return btn
end

local btnOffUp = createOffsetButton("▲", Vector2.new(36, 0))
local btnOffDown = createOffsetButton("▼", Vector2.new(36, 52))
local btnOffLeft = createOffsetButton("◄", Vector2.new(0, 26))
local btnOffRight = createOffsetButton("►", Vector2.new(72, 26))

local btnOffSave = createButton("SAVE", 330, Color3.fromRGB(0, 70, 40))
btnOffSave.Size = UDim2.new(0, 80, 0, 28)
btnOffSave.Position = UDim2.new(0.5, -90, 0, 330)
btnOffSave.Parent = container

local btnOffExit = createButton("EXIT", 330, Color3.fromRGB(55, 20, 20))
btnOffExit.Size = UDim2.new(0, 80, 0, 28)
btnOffExit.Position = UDim2.new(0.5, 10, 0, 330)
btnOffExit.Parent = container

-- ===== ПРИЦЕЛ (PERFECT CENTER) =====
local crosshair = Instance.new("Frame")
crosshair.Size = UDim2.new(0, 0, 0, 0)
crosshair.Position = UDim2.new(0.5, 0, 0.5, 0)
crosshair.BackgroundTransparency = 1
crosshair.Parent = gui

local function createDot()
    for _, c in pairs(crosshair:GetChildren()) do c:Destroy() end
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 4, 0, 4)
    dot.Position = UDim2.new(0.5, -2, 0.5, -2)
    dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dot.BorderSizePixel = 0
    dot.Parent = crosshair
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = dot
end

local function createCross()
    for _, c in pairs(crosshair:GetChildren()) do c:Destroy() end
    local size, thick, off = 16, 2, 8
    
    for _, data in ipairs({
        {s = size, x = -off - size/2, y = -thick/2},
        {s = size, x = off - size/2, y = -thick/2},
        {s = size, x = -thick/2, y = -off - size/2},
        {s = size, x = -thick/2, y = off - size/2},
    }) do
        local isVert = data.x == -thick/2
        local part = Instance.new("Frame")
        part.Size = isVert and UDim2.new(0, thick, 0, data.s) or UDim2.new(0, data.s, 0, thick)
        part.Position = isVert and UDim2.new(0.5, data.x, 0.5, data.y) or UDim2.new(0.5, data.x, 0.5, data.y)
        part.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        part.BorderSizePixel = 0
        part.Parent = crosshair
    end
end

local function updateStyle()
    if CONFIG.Style == "DOT" then
        createDot()
        btnStyle.Text = "STYLE: DOT"
    else
        createCross()
        btnStyle.Text = "STYLE: CROSS"
    end
end
updateStyle()

-- ============================================================
-- ================ ОПТИМИЗИРОВАННАЯ ЛОГИКА ===================
-- ============================================================

-- Обновление кеша объектов
local function updateObjectCache()
    local objects = {}
    local playerChars = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Character then
            playerChars[plr.Character] = true
        end
    end
    
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Parent ~= Player.Character then
            local isPlayer = false
            local p = v.Parent
            while p do
                if playerChars[p] then
                    isPlayer = true
                    break
                end
                p = p.Parent
            end
            if not isPlayer then
                table.insert(objects, v)
            end
        end
    end
    cache.objects = objects
end

-- Обновление кеша игроков
local function updatePlayerCache()
    local players = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Character then
            local torso = plr.Character:FindFirstChild("HumanoidRootPart") or plr.Character:FindFirstChild("Torso")
            if torso then
                table.insert(players, plr)
            end
        end
    end
    cache.players = players
end

-- Поиск цели (без sqrt)
local function findTarget()
    local center = getCenter()
    local best = nil
    local bestDist = math.huge
    local list = CONFIG.Mode == "OBJECTS" and cache.objects or cache.players
    
    for _, item in ipairs(list) do
        local pos
        if CONFIG.Mode == "OBJECTS" then
            if not item.Parent then continue end
            pos, _ = Camera:WorldToViewportPoint(item.Position)
        else
            if not item.Character then continue end
            local torso = item.Character:FindFirstChild("HumanoidRootPart") or item.Character:FindFirstChild("Torso")
            if not torso then continue end
            pos, _ = Camera:WorldToViewportPoint(torso.Position)
        end
        
        if pos then
            local dx, dy = pos.X - center.X, pos.Y - center.Y
            local dist = dx*dx + dy*dy
            if dist < CONFIG.MaxDistance and dist < bestDist then
                best = item
                bestDist = dist
            end
        end
    end
    
    return best
end

-- Фиксация
local function lockTarget(target)
    if not target then return false end
    
    local pos
    if CONFIG.Mode == "OBJECTS" then
        if not target.Parent then return false end
        pos, _ = Camera:WorldToViewportPoint(target.Position)
    else
        if not target.Character then return false end
        local torso = target.Character:FindFirstChild("HumanoidRootPart") or target.Character:FindFirstChild("Torso")
        if not torso then return false end
        pos, _ = Camera:WorldToViewportPoint(torso.Position)
    end
    
    if not pos then return false end
    
    local center = getCenter()
    local dx, dy = pos.X - center.X, pos.Y - center.Y
    local dist = dx*dx + dy*dy
    
    if dist > CONFIG.LockThreshold then
        local targetPos = CONFIG.Mode == "OBJECTS" and target.Position or target.Character:FindFirstChild("HumanoidRootPart").Position
        local newCF = CFrame.lookAt(Camera.CFrame.Position, targetPos)
        Camera.CFrame = Camera.CFrame:Lerp(newCF, CONFIG.Speed)
    end
    
    return true
end

-- Основной цикл
local function processAim()
    if not state.enabled then return end
    
    -- Если есть заロックированная цель
    if state.lockedTarget then
        if not lockTarget(state.lockedTarget) then
            state.lockedTarget = nil
            targetLabel.Text = "TARGET: LOST"
            targetLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
        return
    end
    
    -- Поиск цели (раз в 0.08 сек)
    if tick() - cache.lastTargetSearch > CONFIG.SearchInterval then
        cache.lastTargetSearch = tick()
        local newTarget = findTarget()
        if newTarget then
            state.target = newTarget
            local modeText = CONFIG.Mode == "OBJECTS" and "OBJECT" or "PLAYER"
            status.Text = modeText .. " FOUND"
            status.TextColor3 = Color3.fromRGB(100, 255, 200)
            targetLabel.Text = "TARGET: " .. modeText
            targetLabel.TextColor3 = Color3.fromRGB(100, 255, 200)
        elseif not state.target then
            status.Text = CONFIG.Mode == "OBJECTS" and "NO OBJECT" or "NO PLAYER"
            status.TextColor3 = Color3.fromRGB(255, 200, 100)
            targetLabel.Text = "TARGET: NONE"
            targetLabel.TextColor3 = Color3.fromRGB(180, 180, 150)
        end
    end
    
    -- Фиксация
    if state.target then
        lockTarget(state.target)
    end
end

-- ============================================================
-- ================ УПРАВЛЕНИЕ ================================
-- ============================================================

local function toggle()
    state.enabled = not state.enabled
    if state.enabled then
        state.target = findTarget()
        if not state.target then
            state.enabled = false
            status.Text = CONFIG.Mode == "OBJECTS" and "NO OBJECT" or "NO PLAYER"
            status.TextColor3 = Color3.fromRGB(255, 200, 100)
            btnToggle.Text = "RETRY"
            return
        end
        local modeText = CONFIG.Mode == "OBJECTS" and "OBJECT" or "PLAYER"
        status.Text = modeText .. " FOUND"
        status.TextColor3 = Color3.fromRGB(100, 255, 200)
        targetLabel.Text = "TARGET: " .. modeText
        targetLabel.TextColor3 = Color3.fromRGB(100, 255, 200)
        btnToggle.Text = "DEACTIVATE"
        btnToggle.BackgroundColor3 = Color3.fromRGB(0, 80, 40)
        btnToggle.TextColor3 = Color3.fromRGB(200, 255, 200)
    else
        state.target = nil
        state.lockedTarget = nil
        status.Text = "DISABLED"
        status.TextColor3 = Color3.fromRGB(100, 150, 200)
        btnToggle.Text = "ACTIVATE"
        btnToggle.BackgroundColor3 = Color3.fromRGB(20, 50, 90)
        btnToggle.TextColor3 = Color3.fromRGB(200, 215, 240)
        targetLabel.Text = "TARGET: NONE"
        targetLabel.TextColor3 = Color3.fromRGB(180, 180, 150)
        btnLock.Text = "LOCK TARGET"
        btnLock.BackgroundColor3 = Color3.fromRGB(15, 55, 45)
    end
end

local function lockCurrentTarget()
    if not state.enabled then
        status.Text = "ENABLE FIRST"
        status.TextColor3 = Color3.fromRGB(255, 200, 100)
        return
    end
    
    if state.lockedTarget then
        state.lockedTarget = nil
        targetLabel.Text = "TARGET: NONE"
        targetLabel.TextColor3 = Color3.fromRGB(180, 180, 150)
        btnLock.Text = "LOCK TARGET"
        btnLock.BackgroundColor3 = Color3.fromRGB(15, 55, 45)
        status.Text = "UNLOCKED"
        status.TextColor3 = Color3.fromRGB(100, 150, 200)
        return
    end
    
    if state.target then
        state.lockedTarget = state.target
        targetLabel.Text = "TARGET: LOCKED"
        targetLabel.TextColor3 = Color3.fromRGB(100, 255, 200)
        btnLock.Text = "UNLOCK TARGET"
        btnLock.BackgroundColor3 = Color3.fromRGB(55, 20, 20)
        status.Text = CONFIG.Mode == "OBJECTS" and "OBJECT LOCKED" or "PLAYER LOCKED"
        status.TextColor3 = Color3.fromRGB(100, 255, 200)
    else
        status.Text = "NO TARGET TO LOCK"
        status.TextColor3 = Color3.fromRGB(255, 200, 100)
    end
end

local function switchMode()
    CONFIG.Mode = CONFIG.Mode == "OBJECTS" and "PLAYERS" or "OBJECTS"
    modeLabel.Text = "MODE: " .. CONFIG.Mode
    if state.enabled then
        state.enabled = false
        state.target = nil
        state.lockedTarget = nil
        status.Text = "DISABLED"
        status.TextColor3 = Color3.fromRGB(100, 150, 200)
        btnToggle.Text = "ACTIVATE"
        btnToggle.BackgroundColor3 = Color3.fromRGB(20, 50, 90)
        btnToggle.TextColor3 = Color3.fromRGB(200, 215, 240)
        targetLabel.Text = "TARGET: NONE"
        targetLabel.TextColor3 = Color3.fromRGB(180, 180, 150)
        btnLock.Text = "LOCK TARGET"
        btnLock.BackgroundColor3 = Color3.fromRGB(15, 55, 45)
        toggle()
    end
end

local function switchStyle()
    CONFIG.Style = CONFIG.Style == "DOT" and "CROSS" or "DOT"
    updateStyle()
end

local function hideCrosshair()
    state.visible = not state.visible
    crosshair.Visible = state.visible
    btnHide.Text = state.visible and "HIDE CROSSHAIR" or "SHOW CROSSHAIR"
end

-- Offset
local function toggleOffsetMenu()
    state.offsetMenuOpen = not state.offsetMenuOpen
    if state.offsetMenuOpen then
        offsetMenu.Visible = true
        offsetMenu:TweenSize(UDim2.new(1, -28, 0, 80), "Out", "Quad", 0.3, true)
        btnOffset.Text = "⚙ CLOSE"
        btnOffSave.Visible = true
        btnOffExit.Visible = true
    else
        offsetMenu:TweenSize(UDim2.new(1, -28, 0, 0), "Out", "Quad", 0.3, true)
        wait(0.3)
        offsetMenu.Visible = false
        btnOffset.Text = "⚙ OFFSET"
        btnOffSave.Visible = false
        btnOffExit.Visible = false
    end
end

local function updateOffsetLabel()
    offsetLabel.Text = string.format("X: %d  Y: %d", CONFIG.OffsetX, CONFIG.OffsetY)
end

local function changeOffset(dir)
    if dir == "UP" then CONFIG.OffsetY = CONFIG.OffsetY - CONFIG.OffsetStep end
    if dir == "DOWN" then CONFIG.OffsetY = CONFIG.OffsetY + CONFIG.OffsetStep end
    if dir == "LEFT" then CONFIG.OffsetX = CONFIG.OffsetX - CONFIG.OffsetStep end
    if dir == "RIGHT" then CONFIG.OffsetX = CONFIG.OffsetX + CONFIG.OffsetStep end
    updateOffsetLabel()
end

local function saveOffset()
    status.Text = "OFFSET SAVED X:" .. CONFIG.OffsetX .. " Y:" .. CONFIG.OffsetY
    status.TextColor3 = Color3.fromRGB(100, 255, 200)
end

-- ===== ПРИВЯЗКА КНОПОК =====
btnToggle.MouseButton1Click:Connect(toggle)
btnLock.MouseButton1Click:Connect(lockCurrentTarget)
btnMode.MouseButton1Click:Connect(switchMode)
btnStyle.MouseButton1Click:Connect(switchStyle)
btnHide.MouseButton1Click:Connect(hideCrosshair)
btnOffset.MouseButton1Click:Connect(toggleOffsetMenu)

btnOffUp.MouseButton1Click:Connect(function() changeOffset("UP") end)
btnOffDown.MouseButton1Click:Connect(function() changeOffset("DOWN") end)
btnOffLeft.MouseButton1Click:Connect(function() changeOffset("LEFT") end)
btnOffRight.MouseButton1Click:Connect(function() changeOffset("RIGHT") end)
btnOffSave.MouseButton1Click:Connect(saveOffset)
btnOffExit.MouseButton1Click:Connect(function()
    if state.offsetMenuOpen then toggleOffsetMenu() end
end)

-- Окно
winButtons.minimize.MouseButton1Click:Connect(function()
    state.minimized = not state.minimized
    if state.minimized then
        container:TweenSize(UDim2.new(0, 200, 0, 36), "Out", "Quad", 0.3, true)
        status.Visible = false
        modeLabel.Visible = false
        targetLabel.Visible = false
        btnToggle.Visible = false
        btnLock.Visible = false
        btnMode.Visible = false
        btnStyle.Visible = false
        btnHide.Visible = false
        btnOffset.Visible = false
        btnExit.Visible = false
        winButtons.minimize.Text = "□"
    else
        container:TweenSize(UDim2.new(0, 320, 0, 420), "Out", "Quad", 0.3, true)
        status.Visible = true
        modeLabel.Visible = true
        targetLabel.Visible = true
        btnToggle.Visible = true
        btnLock.Visible = true
        btnMode.Visible = true
        btnStyle.Visible = true
        btnHide.Visible = true
        btnOffset.Visible = true
        btnExit.Visible = true
        winButtons.minimize.Text = "─"
    end
end)

winButtons.maximize.MouseButton1Click:Connect(function()
    state.maximized = not state.maximized
    if state.maximized then
        container:TweenSize(UDim2.new(0, 440, 0, 480), "Out", "Quad", 0.3, true)
        container:TweenPosition(UDim2.new(0.5, -220, 0.5, -240), "Out", "Quad", 0.3, true)
    else
        container:TweenSize(UDim2.new(0, 320, 0, 420), "Out", "Quad", 0.3, true)
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
    state.lockedTarget = nil
end)

-- ===== КЛАВИАТУРА =====
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    if input.KeyCode == Enum.KeyCode.One then
        if state.lockedTarget then
            state.lockedTarget = nil
            targetLabel.Text = "TARGET: NONE"
            targetLabel.TextColor3 = Color3.fromRGB(180, 180, 150)
            btnLock.Text = "LOCK TARGET"
            btnLock.BackgroundColor3 = Color3.fromRGB(15, 55, 45)
        end
        toggle()
    elseif input.KeyCode == Enum.KeyCode.Two then
        hideCrosshair()
    elseif input.KeyCode == Enum.KeyCode.Three then
        switchMode()
    elseif input.KeyCode == Enum.KeyCode.Four then
        lockCurrentTarget()
    elseif input.KeyCode == Enum.KeyCode.Five then
        switchStyle()
    elseif input.KeyCode == Enum.KeyCode.Six then
        toggleOffsetMenu()
    end
end)

-- ============================================================
-- ================ ФОНОВЫЕ ЗАДАЧИ ============================
-- ============================================================

task.spawn(function()
    while true do
        updateObjectCache()
        updatePlayerCache()
        task.wait(CONFIG.CacheInterval)
    end
end)

task.spawn(function()
    while true do
        task.wait(CONFIG.CacheInterval * 10)
        local newObjects = {}
        for _, v in ipairs(cache.objects) do
            if v and v.Parent then
                table.insert(newObjects, v)
            end
        end
        cache.objects = newObjects
        updatePlayerCache()
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
    Title = "AIM LOCK v16",
    Text = "1 - Toggle | 4 - Lock | 6 - Offset",
    Duration = 4
})

print("✅ AIM LOCK v16.0 LOADED")
print("📌 1 - Toggle ON/OFF")
print("📌 2 - Hide/Show crosshair")
print("📌 3 - Switch mode (OBJECTS ↔ PLAYERS)")
print("📌 4 - Lock/Unlock target")
print("📌 5 - Switch style (DOT ↔ CROSS)")
print("📌 6 - Open offset settings")
