-- AIM LOCK v13.0 | XIAOMI PAD 6 EDITION
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local Player = Players.LocalPlayer

-- ===== НАСТРОЙКИ =====
local SPEED = 0.92
local MODE_OBJECTS = "OBJECTS"
local MODE_PLAYERS = "PLAYERS"
local CROSSHAIR_STYLE = "DOT"

-- ===== СОСТОЯНИЕ =====
local mode = MODE_OBJECTS
local enabled = false
local visible = true
local target = nil
local lockedTarget = nil
local minimized = false
local maximized = false

-- ===== ЦЕНТР ЭКРАНА (АДАПТАЦИЯ ПОД ПЛАНШЕТ) =====
local function getCenter()
    local viewport = Camera.ViewportSize
    return Vector2.new(viewport.X / 2, viewport.Y / 2)
end

-- ===== СОЗДАНИЕ GUI =====
local gui = Instance.new("ScreenGui")
gui.Name = "AimLock_" .. tostring(math.random(1000, 9999))
gui.ResetOnSpawn = false
gui.Parent = Player.PlayerGui
gui.DisplayOrder = 999

-- ===== МЕНЮ =====
local menu = Instance.new("Frame")
menu.Size = UDim2.new(0, 320, 0, 310)
menu.Position = UDim2.new(0, 20, 0, 20)
menu.BackgroundColor3 = Color3.fromRGB(10, 15, 26)
menu.BackgroundTransparency = 0.05
menu.BorderSizePixel = 0
menu.ClipsDescendants = true
menu.Parent = gui

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 8)
menuCorner.Parent = menu

-- ===== ЗАГОЛОВОК =====
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 32)
titleBar.BackgroundColor3 = Color3.fromRGB(0, 20, 40)
titleBar.BorderSizePixel = 0
titleBar.Parent = menu

local titleBarCorner = Instance.new("UICorner")
titleBarCorner.CornerRadius = UDim.new(0, 8)
titleBarCorner.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -100, 1, 0)
titleText.Position = UDim2.new(0, 12, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "AIM LOCK v13.0"
titleText.TextColor3 = Color3.fromRGB(180, 210, 255)
titleText.TextSize = 13
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Font = Enum.Font.GothamMedium
titleText.Parent = titleBar

-- КНОПКИ ОКНА
local btnMin = Instance.new("TextButton")
btnMin.Size = UDim2.new(0, 28, 1, 0)
btnMin.Position = UDim2.new(1, -84, 0, 0)
btnMin.BackgroundTransparency = 1
btnMin.Text = "─"
btnMin.TextColor3 = Color3.fromRGB(180, 210, 255)
btnMin.TextSize = 20
btnMin.Font = Enum.Font.Gotham
btnMin.Parent = titleBar

local btnMax = Instance.new("TextButton")
btnMax.Size = UDim2.new(0, 28, 1, 0)
btnMax.Position = UDim2.new(1, -56, 0, 0)
btnMax.BackgroundTransparency = 1
btnMax.Text = "□"
btnMax.TextColor3 = Color3.fromRGB(180, 210, 255)
btnMax.TextSize = 18
btnMax.Font = Enum.Font.Gotham
btnMax.Parent = titleBar

local btnClose = Instance.new("TextButton")
btnClose.Size = UDim2.new(0, 28, 1, 0)
btnClose.Position = UDim2.new(1, -28, 0, 0)
btnClose.BackgroundTransparency = 1
btnClose.Text = "✕"
btnClose.TextColor3 = Color3.fromRGB(255, 60, 60)
btnClose.TextSize = 18
btnClose.Font = Enum.Font.Gotham
btnClose.Parent = titleBar

-- СТАТУС
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -24, 0, 22)
status.Position = UDim2.new(0, 12, 0, 44)
status.BackgroundTransparency = 1
status.Text = "DISABLED"
status.TextColor3 = Color3.fromRGB(100, 150, 200)
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left
status.Font = Enum.Font.Gotham
status.Parent = menu

-- РЕЖИМ
local modeLabel = Instance.new("TextLabel")
modeLabel.Size = UDim2.new(1, -24, 0, 22)
modeLabel.Position = UDim2.new(0, 12, 0, 66)
modeLabel.BackgroundTransparency = 1
modeLabel.Text = "MODE: OBJECTS"
modeLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
modeLabel.TextSize = 11
modeLabel.TextXAlignment = Enum.TextXAlignment.Left
modeLabel.Font = Enum.Font.Gotham
modeLabel.Parent = menu

-- ЦЕЛЬ
local targetLabel = Instance.new("TextLabel")
targetLabel.Size = UDim2.new(1, -24, 0, 22)
targetLabel.Position = UDim2.new(0, 12, 0, 88)
targetLabel.BackgroundTransparency = 1
targetLabel.Text = "TARGET: NONE"
targetLabel.TextColor3 = Color3.fromRGB(200, 200, 150)
targetLabel.TextSize = 11
targetLabel.TextXAlignment = Enum.TextXAlignment.Left
targetLabel.Font = Enum.Font.Gotham
targetLabel.Parent = menu

-- КНОПКА ВКЛ
local btnToggle = Instance.new("TextButton")
btnToggle.Size = UDim2.new(1, -24, 0, 34)
btnToggle.Position = UDim2.new(0, 12, 0, 116)
btnToggle.BackgroundColor3 = Color3.fromRGB(0, 40, 80)
btnToggle.BorderSizePixel = 0
btnToggle.Text = "ACTIVATE"
btnToggle.TextColor3 = Color3.fromRGB(180, 210, 255)
btnToggle.TextSize = 12
btnToggle.Font = Enum.Font.GothamMedium
btnToggle.Parent = menu

local btnCorner1 = Instance.new("UICorner")
btnCorner1.CornerRadius = UDim.new(0, 6)
btnCorner1.Parent = btnToggle

-- КНОПКА ФИКСАЦИИ ЦЕЛИ
local btnLock = Instance.new("TextButton")
btnLock.Size = UDim2.new(1, -24, 0, 30)
btnLock.Position = UDim2.new(0, 12, 0, 156)
btnLock.BackgroundColor3 = Color3.fromRGB(0, 50, 40)
btnLock.BorderSizePixel = 0
btnLock.Text = "LOCK TARGET"
btnLock.TextColor3 = Color3.fromRGB(180, 255, 200)
btnLock.TextSize = 11
btnLock.Font = Enum.Font.GothamMedium
btnLock.Parent = menu

local btnCorner2 = Instance.new("UICorner")
btnCorner2.CornerRadius = UDim.new(0, 6)
btnCorner2.Parent = btnLock

-- КНОПКА СМЕНЫ РЕЖИМА
local btnMode = Instance.new("TextButton")
btnMode.Size = UDim2.new(1, -24, 0, 30)
btnMode.Position = UDim2.new(0, 12, 0, 192)
btnMode.BackgroundColor3 = Color3.fromRGB(0, 30, 60)
btnMode.BorderSizePixel = 0
btnMode.Text = "SWITCH MODE"
btnMode.TextColor3 = Color3.fromRGB(180, 210, 255)
btnMode.TextSize = 11
btnMode.Font = Enum.Font.GothamMedium
btnMode.Parent = menu

local btnCorner3 = Instance.new("UICorner")
btnCorner3.CornerRadius = UDim.new(0, 6)
btnCorner3.Parent = btnMode

-- КНОПКА СТИЛЯ
local btnStyle = Instance.new("TextButton")
btnStyle.Size = UDim2.new(1, -24, 0, 30)
btnStyle.Position = UDim2.new(0, 12, 0, 228)
btnStyle.BackgroundColor3 = Color3.fromRGB(0, 30, 60)
btnStyle.BorderSizePixel = 0
btnStyle.Text = "STYLE: DOT"
btnStyle.TextColor3 = Color3.fromRGB(180, 210, 255)
btnStyle.TextSize = 11
btnStyle.Font = Enum.Font.GothamMedium
btnStyle.Parent = menu

local btnCorner4 = Instance.new("UICorner")
btnCorner4.CornerRadius = UDim.new(0, 6)
btnCorner4.Parent = btnStyle

-- КНОПКА СКРЫТЬ ПРИЦЕЛ
local btnHide = Instance.new("TextButton")
btnHide.Size = UDim2.new(1, -24, 0, 30)
btnHide.Position = UDim2.new(0, 12, 0, 264)
btnHide.BackgroundColor3 = Color3.fromRGB(0, 40, 80)
btnHide.BorderSizePixel = 0
btnHide.Text = "HIDE CROSSHAIR"
btnHide.TextColor3 = Color3.fromRGB(180, 210, 255)
btnHide.TextSize = 11
btnHide.Font = Enum.Font.GothamMedium
btnHide.Parent = menu

local btnCorner5 = Instance.new("UICorner")
btnCorner5.CornerRadius = UDim.new(0, 6)
btnCorner5.Parent = btnHide

-- КНОПКА ВЫХОДА
local btnExit = Instance.new("TextButton")
btnExit.Size = UDim2.new(1, -24, 0, 34)
btnExit.Position = UDim2.new(0, 12, 0, 300)
btnExit.BackgroundColor3 = Color3.fromRGB(40, 10, 10)
btnExit.BorderSizePixel = 0
btnExit.Text = "EXIT SCRIPT"
btnExit.TextColor3 = Color3.fromRGB(255, 150, 150)
btnExit.TextSize = 12
btnExit.Font = Enum.Font.GothamMedium
btnExit.Parent = menu

local btnCorner6 = Instance.new("UICorner")
btnCorner6.CornerRadius = UDim.new(0, 6)
btnCorner6.Parent = btnExit

-- ===== ПРИЦЕЛ (ЦЕНТР ЭКРАНА) =====
local crosshair = Instance.new("Frame")
crosshair.Size = UDim2.new(0, 0, 0, 0)
crosshair.Position = UDim2.new(0.5, 0, 0.5, 0)
crosshair.BackgroundTransparency = 1
crosshair.Parent = gui

-- Принудительное обновление позиции прицела
local function updateCrosshair()
    crosshair.Position = UDim2.new(0.5, 0, 0.5, 0)
end

-- Создание стилей
local function createDot()
    for _, c in pairs(crosshair:GetChildren()) do c:Destroy() end
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 4, 0, 4)
    dot.Position = UDim2.new(0.5, -2, 0.5, -2)
    dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dot.BorderSizePixel = 0
    dot.Parent = crosshair
    local dCorner = Instance.new("UICorner")
    dCorner.CornerRadius = UDim.new(1, 0)
    dCorner.Parent = dot
end

local function createCross()
    for _, c in pairs(crosshair:GetChildren()) do c:Destroy() end
    local size = 16
    local thickness = 2
    local offset = 8
    
    local h1 = Instance.new("Frame")
    h1.Size = UDim2.new(0, size, 0, thickness)
    h1.Position = UDim2.new(0.5, -offset - size/2, 0.5, -thickness/2)
    h1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    h1.BorderSizePixel = 0
    h1.Parent = crosshair
    
    local h2 = Instance.new("Frame")
    h2.Size = UDim2.new(0, size, 0, thickness)
    h2.Position = UDim2.new(0.5, offset - size/2, 0.5, -thickness/2)
    h2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    h2.BorderSizePixel = 0
    h2.Parent = crosshair
    
    local v1 = Instance.new("Frame")
    v1.Size = UDim2.new(0, thickness, 0, size)
    v1.Position = UDim2.new(0.5, -thickness/2, 0.5, -offset - size/2)
    v1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    v1.BorderSizePixel = 0
    v1.Parent = crosshair
    
    local v2 = Instance.new("Frame")
    v2.Size = UDim2.new(0, thickness, 0, size)
    v2.Position = UDim2.new(0.5, -thickness/2, 0.5, offset - size/2)
    v2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    v2.BorderSizePixel = 0
    v2.Parent = crosshair
end

local function setStyle(style)
    CROSSHAIR_STYLE = style
    btnStyle.Text = "STYLE: " .. (style == "DOT" and "DOT" or "CROSS")
    if style == "DOT" then
        createDot()
    else
        createCross()
    end
    updateCrosshair()
end

setStyle("DOT")

-- ===== ПОИСК ОБЪЕКТА (ОПТИМИЗИРОВАННЫЙ) =====
local function findObject()
    local center = getCenter()
    local best = nil
    local bestDist = math.huge
    local count = 0
    
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Parent ~= Player.Character then
            local isPlayer = false
            local p = v.Parent
            while p do
                if p:IsA("Model") and Players:GetPlayerFromCharacter(p) then
                    isPlayer = true
                    break
                end
                p = p.Parent
            end
            
            if not isPlayer then
                local pos, onScreen = Camera:WorldToViewportPoint(v.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if dist < 300 and dist < bestDist then
                        best = v
                        bestDist = dist
                        count = count + 1
                    end
                end
            end
        end
    end
    
    return best
end

-- ===== ПОИСК ИГРОКА (TORSO) =====
local function findPlayer()
    local center = getCenter()
    local best = nil
    local bestDist = math.huge
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Character then
            local torso = plr.Character:FindFirstChild("HumanoidRootPart") or plr.Character:FindFirstChild("Torso")
            if torso then
                local pos, onScreen = Camera:WorldToViewportPoint(torso.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if dist < 300 and dist < bestDist then
                        best = plr
                        bestDist = dist
                    end
                end
            end
        end
    end
    
    return best
end

-- ===== ФИКСАЦИЯ НА ОБЪЕКТЕ =====
local function lockObject(obj)
    if not obj or not obj.Parent then return false end
    
    local pos, onScreen = Camera:WorldToViewportPoint(obj.Position)
    if not onScreen then return false end
    
    local center = getCenter()
    local offset = (Vector2.new(pos.X, pos.Y) - center).Magnitude
    
    if offset > 0.5 then
        local newCF = CFrame.lookAt(Camera.CFrame.Position, obj.Position)
        Camera.CFrame = Camera.CFrame:Lerp(newCF, SPEED)
        return true
    end
    
    return true
end

-- ===== ФИКСАЦИЯ НА ИГРОКЕ (TORSO) =====
local function lockPlayer(plr)
    if not plr or not plr.Character then return false end
    
    local torso = plr.Character:FindFirstChild("HumanoidRootPart") or plr.Character:FindFirstChild("Torso")
    if not torso then return false end
    
    local pos, onScreen = Camera:WorldToViewportPoint(torso.Position)
    if not onScreen then return false end
    
    local center = getCenter()
    local offset = (Vector2.new(pos.X, pos.Y) - center).Magnitude
    
    if offset > 0.5 then
        local newCF = CFrame.lookAt(Camera.CFrame.Position, torso.Position)
        Camera.CFrame = Camera.CFrame:Lerp(newCF, SPEED)
        return true
    end
    
    return true
end

-- ===== ОСНОВНАЯ ЛОГИКА =====
local function processAim()
    if not enabled then return end
    
    -- Если есть зафиксированная цель — используем её
    if lockedTarget then
        if mode == MODE_OBJECTS then
            if not lockedTarget.Parent then
                lockedTarget = nil
                targetLabel.Text = "TARGET: LOST"
                targetLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                return
            end
            lockObject(lockedTarget)
            targetLabel.Text = "TARGET: LOCKED"
            targetLabel.TextColor3 = Color3.fromRGB(100, 255, 200)
        else
            if not lockedTarget.Character or not lockedTarget.Character:FindFirstChild("HumanoidRootPart") then
                lockedTarget = nil
                targetLabel.Text = "TARGET: LOST"
                targetLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                return
            end
            lockPlayer(lockedTarget)
            targetLabel.Text = "TARGET: LOCKED"
            targetLabel.TextColor3 = Color3.fromRGB(100, 255, 200)
        end
        return
    end
    
    -- Иначе ищем автоматически
    if mode == MODE_OBJECTS then
        if not target or not target.Parent then
            target = findObject()
            if not target then
                status.Text = "NO OBJECT"
                status.TextColor3 = Color3.fromRGB(255, 200, 100)
                targetLabel.Text = "TARGET: NONE"
                targetLabel.TextColor3 = Color3.fromRGB(200, 200, 150)
                return
            end
            status.Text = "OBJECT FOUND"
            status.TextColor3 = Color3.fromRGB(100, 255, 200)
            targetLabel.Text = "TARGET: OBJECT"
            targetLabel.TextColor3 = Color3.fromRGB(100, 255, 200)
        end
        lockObject(target)
    else
        if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
            target = findPlayer()
            if not target then
                status.Text = "NO PLAYER"
                status.TextColor3 = Color3.fromRGB(255, 200, 100)
                targetLabel.Text = "TARGET: NONE"
                targetLabel.TextColor3 = Color3.fromRGB(200, 200, 150)
                return
            end
            status.Text = "PLAYER FOUND"
            status.TextColor3 = Color3.fromRGB(100, 255, 200)
            targetLabel.Text = "TARGET: PLAYER"
            targetLabel.TextColor3 = Color3.fromRGB(100, 255, 200)
        end
        lockPlayer(target)
    end
end

-- ===== УПРАВЛЕНИЕ =====

-- ФИКСАЦИЯ ТЕКУЩЕЙ ЦЕЛИ
local function lockCurrentTarget()
    if not enabled then
        status.Text = "ENABLE FIRST"
        status.TextColor3 = Color3.fromRGB(255, 200, 100)
        return
    end
    
    if mode == MODE_OBJECTS then
        if target and target.Parent then
            lockedTarget = target
            targetLabel.Text = "TARGET: LOCKED"
            targetLabel.TextColor3 = Color3.fromRGB(100, 255, 200)
            btnLock.Text = "UNLOCK TARGET"
            btnLock.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
            status.Text = "OBJECT LOCKED"
            status.TextColor3 = Color3.fromRGB(100, 255, 200)
        else
            status.Text = "NO TARGET TO LOCK"
            status.TextColor3 = Color3.fromRGB(255, 200, 100)
        end
    else
        if target and target.Character then
            lockedTarget = target
            targetLabel.Text = "TARGET: LOCKED"
            targetLabel.TextColor3 = Color3.fromRGB(100, 255, 200)
            btnLock.Text = "UNLOCK TARGET"
            btnLock.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
            status.Text = "PLAYER LOCKED"
            status.TextColor3 = Color3.fromRGB(100, 255, 200)
        else
            status.Text = "NO TARGET TO LOCK"
            status.TextColor3 = Color3.fromRGB(255, 200, 100)
        end
    end
end

-- РАЗБЛОКИРОВКА ЦЕЛИ
local function unlockTarget()
    lockedTarget = nil
    targetLabel.Text = "TARGET: NONE"
    targetLabel.TextColor3 = Color3.fromRGB(200, 200, 150)
    btnLock.Text = "LOCK TARGET"
    btnLock.BackgroundColor3 = Color3.fromRGB(0, 50, 40)
    status.Text = "UNLOCKED"
    status.TextColor3 = Color3.fromRGB(100, 150, 200)
end

-- ОСНОВНОЙ ТОГГЛ
local function toggle()
    enabled = not enabled
    if enabled then
        if mode == MODE_OBJECTS then
            target = findObject()
            if not target then
                enabled = false
                status.Text = "NO OBJECT"
                status.TextColor3 = Color3.fromRGB(255, 200, 100)
                btnToggle.Text = "RETRY"
                return
            end
            status.Text = "OBJECT FOUND"
            status.TextColor3 = Color3.fromRGB(100, 255, 200)
            targetLabel.Text = "TARGET: OBJECT"
            targetLabel.TextColor3 = Color3.fromRGB(100, 255, 200)
        else
            target = findPlayer()
            if not target then
                enabled = false
                status.Text = "NO PLAYER"
                status.TextColor3 = Color3.fromRGB(255, 200, 100)
                btnToggle.Text = "RETRY"
                return
            end
            status.Text = "PLAYER FOUND"
            status.TextColor3 = Color3.fromRGB(100, 255, 200)
            targetLabel.Text = "TARGET: PLAYER"
            targetLabel.TextColor3 = Color3.fromRGB(100, 255, 200)
        end
        btnToggle.Text = "DEACTIVATE"
        btnToggle.BackgroundColor3 = Color3.fromRGB(0, 80, 40)
        btnToggle.TextColor3 = Color3.fromRGB(200, 255, 200)
    else
        target = nil
        lockedTarget = nil
        status.Text = "DISABLED"
        status.TextColor3 = Color3.fromRGB(100, 150, 200)
        btnToggle.Text = "ACTIVATE"
        btnToggle.BackgroundColor3 = Color3.fromRGB(0, 40, 80)
        btnToggle.TextColor3 = Color3.fromRGB(180, 210, 255)
        targetLabel.Text = "TARGET: NONE"
        targetLabel.TextColor3 = Color3.fromRGB(200, 200, 150)
        btnLock.Text = "LOCK TARGET"
        btnLock.BackgroundColor3 = Color3.fromRGB(0, 50, 40)
    end
end

-- СМЕНА РЕЖИМА
local function switchMode()
    if mode == MODE_OBJECTS then
        mode = MODE_PLAYERS
        modeLabel.Text = "MODE: PLAYERS"
    else
        mode = MODE_OBJECTS
        modeLabel.Text = "MODE: OBJECTS"
    end
    if enabled then
        enabled = false
        target = nil
        lockedTarget = nil
        status.Text = "DISABLED"
        status.TextColor3 = Color3.fromRGB(100, 150, 200)
        btnToggle.Text = "ACTIVATE"
        btnToggle.BackgroundColor3 = Color3.fromRGB(0, 40, 80)
        btnToggle.TextColor3 = Color3.fromRGB(180, 210, 255)
        targetLabel.Text = "TARGET: NONE"
        targetLabel.TextColor3 = Color3.fromRGB(200, 200, 150)
        btnLock.Text = "LOCK TARGET"
        btnLock.BackgroundColor3 = Color3.fromRGB(0, 50, 40)
        toggle()
    end
end

-- СТИЛЬ
local function switchStyle()
    if CROSSHAIR_STYLE == "DOT" then
        setStyle("CROSS")
    else
        setStyle("DOT")
    end
end

-- СКРЫТЬ ПРИЦЕЛ
local function hideCrosshair()
    visible = not visible
    crosshair.Visible = visible
    btnHide.Text = visible and "HIDE CROSSHAIR" or "SHOW CROSSHAIR"
end

-- СВЕРНУТЬ
local function minimizeMenu()
    minimized = not minimized
    if minimized then
        menu:TweenSize(UDim2.new(0, 200, 0, 32), "Out", "Quad", 0.3, true)
        status.Visible = false
        modeLabel.Visible = false
        targetLabel.Visible = false
        btnToggle.Visible = false
        btnLock.Visible = false
        btnMode.Visible = false
        btnStyle.Visible = false
        btnHide.Visible = false
        btnExit.Visible = false
        btnMin.Text = "□"
    else
        menu:TweenSize(UDim2.new(0, 320, 0, 320), "Out", "Quad", 0.3, true)
        status.Visible = true
        modeLabel.Visible = true
        targetLabel.Visible = true
        btnToggle.Visible = true
        btnLock.Visible = true
        btnMode.Visible = true
        btnStyle.Visible = true
        btnHide.Visible = true
        btnExit.Visible = true
        btnMin.Text = "─"
    end
end

-- ===== ПРИВЯЗКА =====
btnToggle.MouseButton1Click:Connect(function()
    if lockedTarget then
        unlockTarget()
    end
    toggle()
end)

btnLock.MouseButton1Click:Connect(function()
    if lockedTarget then
        unlockTarget()
    else
        lockCurrentTarget()
    end
end)

btnMode.MouseButton1Click:Connect(switchMode)
btnStyle.MouseButton1Click:Connect(switchStyle)
btnHide.MouseButton1Click:Connect(hideCrosshair)
btnMin.MouseButton1Click:Connect(minimizeMenu)

btnMax.MouseButton1Click:Connect(function()
    maximized = not maximized
    if maximized then
        menu:TweenSize(UDim2.new(0, 450, 0, 380), "Out", "Quad", 0.3, true)
        menu:TweenPosition(UDim2.new(0.5, -225, 0.5, -190), "Out", "Quad", 0.3, true)
    else
        menu:TweenSize(UDim2.new(0, 320, 0, 320), "Out", "Quad", 0.3, true)
        menu:TweenPosition(UDim2.new(0, 20, 0, 20), "Out", "Quad", 0.3, true)
    end
end)

btnClose.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

btnExit.MouseButton1Click:Connect(function()
    gui:Destroy()
    enabled = false
    target = nil
    lockedTarget = nil
end)

-- ===== КЛАВИАТУРА =====
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    if input.KeyCode == Enum.KeyCode.One then
        if lockedTarget then
            unlockTarget()
        end
        toggle()
    end
    
    if input.KeyCode == Enum.KeyCode.Two then
        hideCrosshair()
    end
    
    if input.KeyCode == Enum.KeyCode.Three then
        switchMode()
    end
    
    if input.KeyCode == Enum.KeyCode.Four then
        if lockedTarget then
            unlockTarget()
        else
            lockCurrentTarget()
        end
    end
    
    if input.KeyCode == Enum.KeyCode.Five then
        switchStyle()
    end
end)

-- ===== ГЛАВНЫЙ ЦИКЛ (ОПТИМИЗИРОВАННЫЙ) =====
RunService.RenderStepped:Connect(function()
    updateCrosshair()
    processAim()
end)

-- ===== УВЕДОМЛЕНИЕ =====
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "AIM LOCK v13.0",
    Text = "1 - Toggle | 4 - Lock | 3 - Mode | 5 - Style",
    Duration = 4
})

print("✅ AIM LOCK v13.0 LOADED")
print("📌 1 - Toggle ON/OFF")
print("📌 2 - Hide/Show crosshair")
print("📌 3 - Switch mode (OBJECTS ↔ PLAYERS)")
print("📌 4 - Lock/Unlock current target")
print("📌 5 - Switch style (DOT ↔ CROSS)")
