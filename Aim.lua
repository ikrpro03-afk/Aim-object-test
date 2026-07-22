-- AIM LOCK v9.0 | FULLY WORKING
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local Player = Players.LocalPlayer

-- ===== НАСТРОЙКИ =====
local SPEED = 0.92
local MODE_OBJECTS = "OBJECTS"
local MODE_PLAYERS = "PLAYERS"

-- ===== СОСТОЯНИЕ =====
local mode = MODE_OBJECTS          -- OBJECTS или PLAYERS
local aimPart = "Head"             -- Head или HumanoidRootPart
local enabled = false
local visible = true
local target = nil
local minimized = false
local maximized = false

-- ===== СОЗДАНИЕ GUI =====
local gui = Instance.new("ScreenGui")
gui.Name = "AimLock"
gui.ResetOnSpawn = false
gui.Parent = Player.PlayerGui

local menu = Instance.new("Frame")
menu.Size = UDim2.new(0, 280, 0, 270)
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
titleText.Text = "AIM LOCK v9.0"
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
local partLabel = Instance.new("TextLabel")
partLabel.Size = UDim2.new(1, -24, 0, 22)
partLabel.Position = UDim2.new(0, 12, 0, 88)
partLabel.BackgroundTransparency = 1
partLabel.Text = "AIM: HEAD"
partLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
partLabel.TextSize = 11
partLabel.TextXAlignment = Enum.TextXAlignment.Left
partLabel.Font = Enum.Font.Gotham
partLabel.Parent = menu

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

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = btnToggle

-- КНОПКА СМЕНЫ РЕЖИМА
local btnMode = Instance.new("TextButton")
btnMode.Size = UDim2.new(0, 135, 0, 30)
btnMode.Position = UDim2.new(0, 12, 0, 156)
btnMode.BackgroundColor3 = Color3.fromRGB(0, 30, 60)
btnMode.BorderSizePixel = 0
btnMode.Text = "SWITCH MODE"
btnMode.TextColor3 = Color3.fromRGB(180, 210, 255)
btnMode.TextSize = 11
btnMode.Font = Enum.Font.GothamMedium
btnMode.Parent = menu

local btnCorner2 = Instance.new("UICorner")
btnCorner2.CornerRadius = UDim.new(0, 6)
btnCorner2.Parent = btnMode

-- КНОПКА СМЕНЫ ЧАСТИ
local btnPart = Instance.new("TextButton")
btnPart.Size = UDim2.new(0, 125, 0, 30)
btnPart.Position = UDim2.new(1, -137, 0, 156)
btnPart.BackgroundColor3 = Color3.fromRGB(0, 30, 60)
btnPart.BorderSizePixel = 0
btnPart.Text = "SWITCH BODY"
btnPart.TextColor3 = Color3.fromRGB(180, 210, 255)
btnPart.TextSize = 11
btnPart.Font = Enum.Font.GothamMedium
btnPart.Parent = menu

local btnCorner3 = Instance.new("UICorner")
btnCorner3.CornerRadius = UDim.new(0, 6)
btnCorner3.Parent = btnPart

-- КНОПКА СКРЫТЬ
local btnHide = Instance.new("TextButton")
btnHide.Size = UDim2.new(1, -24, 0, 34)
btnHide.Position = UDim2.new(0, 12, 0, 194)
btnHide.BackgroundColor3 = Color3.fromRGB(0, 40, 80)
btnHide.BorderSizePixel = 0
btnHide.Text = "HIDE CROSSHAIR"
btnHide.TextColor3 = Color3.fromRGB(180, 210, 255)
btnHide.TextSize = 12
btnHide.Font = Enum.Font.GothamMedium
btnHide.Parent = menu

local btnCorner4 = Instance.new("UICorner")
btnCorner4.CornerRadius = UDim.new(0, 6)
btnCorner4.Parent = btnHide

-- КНОПКА ВЫХОДА
local btnExit = Instance.new("TextButton")
btnExit.Size = UDim2.new(1, -24, 0, 34)
btnExit.Position = UDim2.new(0, 12, 0, 234)
btnExit.BackgroundColor3 = Color3.fromRGB(40, 10, 10)
btnExit.BorderSizePixel = 0
btnExit.Text = "EXIT SCRIPT"
btnExit.TextColor3 = Color3.fromRGB(255, 150, 150)
btnExit.TextSize = 12
btnExit.Font = Enum.Font.GothamMedium
btnExit.Parent = menu

local btnCorner5 = Instance.new("UICorner")
btnCorner5.CornerRadius = UDim.new(0, 6)
btnCorner5.Parent = btnExit

-- ===== ПРИЦЕЛ (ТОЧКА) =====
local crosshair = Instance.new("Frame")
crosshair.Size = UDim2.new(0, 4, 0, 4)
crosshair.Position = UDim2.new(0.5, -2, 0.5, -2)
crosshair.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
crosshair.BorderSizePixel = 0
crosshair.Parent = gui

local glow = Instance.new("Frame")
glow.Size = UDim2.new(0, 12, 0, 12)
glow.Position = UDim2.new(0.5, -6, 0.5, -6)
glow.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
glow.BackgroundTransparency = 0.8
glow.BorderSizePixel = 0
glow.Parent = crosshair

local glowCorner = Instance.new("UICorner")
glowCorner.CornerRadius = UDim.new(1, 0)
glowCorner.Parent = glow

-- ===== ФУНКЦИИ =====

-- Поиск объекта
local function findObject()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local best = nil
    local bestDist = math.huge
    
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
                    if dist < 200 and dist < bestDist then
                        best = v
                        bestDist = dist
                    end
                end
            end
        end
    end
    
    return best
end

-- Поиск игрока
local function findPlayer()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local best = nil
    local bestDist = math.huge
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Character and plr.Character:FindFirstChild(aimPart) then
            local part = plr.Character[aimPart]
            local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
            
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                if dist < 250 and dist < bestDist then
                    best = plr
                    bestDist = dist
                end
            end
        end
    end
    
    return best
end

-- Фиксация на объекте
local function lockObject(obj)
    if not obj or not obj.Parent then return false end
    
    local pos, onScreen = Camera:WorldToViewportPoint(obj.Position)
    if not onScreen then return false end
    
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local offset = (Vector2.new(pos.X, pos.Y) - center).Magnitude
    
    if offset < 0.5 then return true end
    
    local newCF = CFrame.lookAt(Camera.CFrame.Position, obj.Position)
    Camera.CFrame = Camera.CFrame:Lerp(newCF, SPEED)
    
    return true
end

-- Фиксация на игроке
local function lockPlayer(plr)
    if not plr or not plr.Character or not plr.Character:FindFirstChild(aimPart) then
        return false
    end
    
    local part = plr.Character[aimPart]
    local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
    if not onScreen then return false end
    
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local offset = (Vector2.new(pos.X, pos.Y) - center).Magnitude
    
    if offset < 0.5 then return true end
    
    local newCF = CFrame.lookAt(Camera.CFrame.Position, part.Position)
    Camera.CFrame = Camera.CFrame:Lerp(newCF, SPEED)
    
    return true
end

-- ===== КНОПКИ =====

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
            status.Text = "OBJECT LOCKED"
            status.TextColor3 = Color3.fromRGB(100, 255, 200)
        else
            target = findPlayer()
            if not target then
                enabled = false
                status.Text = "NO PLAYER"
                status.TextColor3 = Color3.fromRGB(255, 200, 100)
                btnToggle.Text = "RETRY"
                return
            end
            status.Text = "PLAYER LOCKED"
            status.TextColor3 = Color3.fromRGB(100, 255, 200)
        end
        btnToggle.Text = "DEACTIVATE"
    else
        target = nil
        status.Text = "DISABLED"
        status.TextColor3 = Color3.fromRGB(100, 150, 200)
        btnToggle.Text = "ACTIVATE"
    end
end

local function switchMode()
    if mode == MODE_OBJECTS then
        mode = MODE_PLAYERS
        modeLabel.Text = "MODE: PLAYERS"
        partLabel.Visible = true
        btnPart.Visible = true
    else
        mode = MODE_OBJECTS
        modeLabel.Text = "MODE: OBJECTS"
        partLabel.Visible = false
        btnPart.Visible = false
    end
    if enabled then
        enabled = false
        target = nil
        status.Text = "DISABLED"
        status.TextColor3 = Color3.fromRGB(100, 150, 200)
        btnToggle.Text = "ACTIVATE"
        toggle()
    end
end

local function switchPart()
    if aimPart == "Head" then
        aimPart = "HumanoidRootPart"
        partLabel.Text = "AIM: BODY"
        btnPart.Text = "SWITCH HEAD"
    else
        aimPart = "Head"
        partLabel.Text = "AIM: HEAD"
        btnPart.Text = "SWITCH BODY"
    end
    if enabled and mode == MODE_PLAYERS then
        enabled = false
        target = nil
        status.Text = "DISABLED"
        status.TextColor3 = Color3.fromRGB(100, 150, 200)
        btnToggle.Text = "ACTIVATE"
        toggle()
    end
end

local function hideCrosshair()
    visible = not visible
    crosshair.Visible = visible
    btnHide.Text = visible and "HIDE CROSSHAIR" or "SHOW CROSSHAIR"
end

local function minimizeMenu()
    minimized = not minimized
    if minimized then
        menu:TweenSize(UDim2.new(0, 200, 0, 32), "Out", "Quad", 0.3, true)
        status.Visible = false
        modeLabel.Visible = false
        partLabel.Visible = false
        btnToggle.Visible = false
        btnMode.Visible = false
        btnPart.Visible = false
        btnHide.Visible = false
        btnExit.Visible = false
        btnMin.Text = "□"
    else
        menu:TweenSize(UDim2.new(0, 280, 0, 270), "Out", "Quad", 0.3, true)
        status.Visible = true
        modeLabel.Visible = true
        if mode == MODE_PLAYERS then partLabel.Visible = true end
        btnToggle.Visible = true
        btnMode.Visible = true
        if mode == MODE_PLAYERS then btnPart.Visible = true end
        btnHide.Visible = true
        btnExit.Visible = true
        btnMin.Text = "─"
    end
end

-- ===== ПРИВЯЗКА КНОПОК =====
btnToggle.MouseButton1Click:Connect(toggle)
btnMode.MouseButton1Click:Connect(switchMode)
btnPart.MouseButton1Click:Connect(switchPart)
btnHide.MouseButton1Click:Connect(hideCrosshair)
btnMin.MouseButton1Click:Connect(minimizeMenu)

btnMax.MouseButton1Click:Connect(function()
    maximized = not maximized
    if maximized then
        menu:TweenSize(UDim2.new(0, 400, 0, 320), "Out", "Quad", 0.3, true)
        menu:TweenPosition(UDim2.new(0.5, -200, 0.5, -160), "Out", "Quad", 0.3, true)
    else
        menu:TweenSize(UDim2.new(0, 280, 0, 270), "Out", "Quad", 0.3, true)
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
end)

-- ===== КЛАВИАТУРА =====
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    if input.KeyCode == Enum.KeyCode.One then
        toggle()
    end
    
    if input.KeyCode == Enum.KeyCode.Two then
        hideCrosshair()
    end
    
    if input.KeyCode == Enum.KeyCode.Three then
        switchMode()
    end
    
    if input.KeyCode == Enum.KeyCode.Four then
        if mode == MODE_PLAYERS then
            switchPart()
        end
    end
end)

-- ===== ГЛАВНЫЙ ЦИКЛ =====
RunService.RenderStepped:Connect(function()
    if not enabled then return end
    
    if mode == MODE_OBJECTS then
        if not target or not target.Parent then
            target = findObject()
            if not target then
                status.Text = "NO OBJECT"
                status.TextColor3 = Color3.fromRGB(255, 200, 100)
                return
            end
            status.Text = "OBJECT LOCKED"
            status.TextColor3 = Color3.fromRGB(100, 255, 200)
        end
        if not lockObject(target) then
            target = nil
        end
    else
        if not target or not target.Character or not target.Character:FindFirstChild(aimPart) then
            target = findPlayer()
            if not target then
                status.Text = "NO PLAYER"
                status.TextColor3 = Color3.fromRGB(255, 200, 100)
                return
            end
            status.Text = "PLAYER LOCKED"
            status.TextColor3 = Color3.fromRGB(100, 255, 200)
        end
        if not lockPlayer(target) then
            target = nil
        end
    end
end)

-- ===== УВЕДОМЛЕНИЕ =====
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "AIM LOCK v9.0",
    Text = "1 - Toggle | 3 - Mode | 4 - Head/Body",
    Duration = 4
})

print("✅ AIM LOCK v9.0 LOADED")
print("📌 1 - Toggle ON/OFF")
print("📌 2 - Hide/Show crosshair")
print("📌 3 - Switch mode (OBJECTS ↔ PLAYERS)")
print("📌 4 - Switch aim (HEAD ↔ BODY) [PLAYERS mode]")
