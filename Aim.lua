-- AIM LOCK v31.0 | MODERN UI + CENTER FIX
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
    AimPart = "Head",
    BackupPart = "UpperTorso",
    FOV = 50,
    Smoothness = 0.85,
    DistanceLimit = 250,
    PredictionStrength = 0.6,
    BulletSpeed = 1800,
    LostTimeout = 0.1,
    SearchInterval = 0.05,
    XRayUpdateInterval = 0.04,
    ShowFOV = true,
    CrosshairStyle = "DOT",
    XRayColor = Color3.fromRGB(0, 180, 255),
    CenterOffset = Vector2.new(0, 0), -- ← Регулируй здесь (X, Y)
}

local DIST_LIMIT_SQ = CONFIG.DistanceLimit * CONFIG.DistanceLimit

-- ============================================================
--  СОСТОЯНИЕ
-- ============================================================
local State = {
    enabled = false,
    destroyed = false,
    cleaned = false,
    target = nil,
    targetCF = nil,
    smoothCF = nil,
    killCount = 0,
    lostTimer = 0,
    minimized = false,
    maximized = false,
    searchTimer = 0,
    xrayTimer = 0,
    lastStatus = "",
    lastTarget = "",
}

-- ============================================================
--  X-RAY
-- ============================================================
local XRayState = {
    enabled = true,
    boxes = {},
    container = nil,
    partsCache = {},
    cacheTimers = {},
    CACHE_DURATION = 0.5,
}

-- ============================================================
--  GUI (MODERN)
-- ============================================================
local PlayerGui = Player:WaitForChild("PlayerGui")

local function createGradient(color1, color2)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color1),
        ColorSequenceKeypoint.new(1, color2),
    })
    return gradient
end

local function buildGUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "AimLock_" .. tostring(math.random(1000, 9999))
    gui.ResetOnSpawn = false
    gui.Parent = PlayerGui
    gui.DisplayOrder = 999

    -- ОСНОВНОЕ ОКНО
    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 260, 0, 320)
    main.Position = UDim2.new(0, 16, 0, 16)
    main.BackgroundColor3 = Color3.fromRGB(8, 12, 28)
    main.BackgroundTransparency = 0.12
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Parent = gui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = main

    -- ГРАДИЕНТ ФОНА
    local bgGrad = createGradient(
        Color3.fromRGB(10, 16, 36),
        Color3.fromRGB(6, 10, 24)
    )
    bgGrad.Parent = main

    -- ===== ВЕРХНЯЯ ПАНЕЛЬ =====
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 32)
    header.BackgroundColor3 = Color3.fromRGB(12, 18, 38)
    header.BackgroundTransparency = 0.3
    header.BorderSizePixel = 0
    header.Parent = main

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -90, 1, 0)
    title.Position = UDim2.new(0, 14, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "AIM LOCK v31"
    title.TextColor3 = Color3.fromRGB(160, 200, 255)
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamMedium
    title.Parent = header

    -- Кнопки окна
    local winButtons = {}
    for i, data in ipairs({
        {text = "─", pos = 1, color = Color3.fromRGB(160, 200, 255), action = "minimize"},
        {text = "□", pos = 2, color = Color3.fromRGB(160, 200, 255), action = "maximize"},
        {text = "✕", pos = 3, color = Color3.fromRGB(255, 80, 80), action = "close"},
    }) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 28, 1, 0)
        btn.Position = UDim2.new(1, -28 * (4 - data.pos), 0, 0)
        btn.BackgroundTransparency = 1
        btn.Text = data.text
        btn.TextColor3 = data.color
        btn.TextSize = 16
        btn.Font = Enum.Font.Gotham
        btn.Parent = header
        winButtons[data.action] = btn
    end

    -- РАЗДЕЛИТЕЛЬ
    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, -24, 0, 1)
    divider.Position = UDim2.new(0, 12, 0, 32)
    divider.BackgroundColor3 = Color3.fromRGB(40, 60, 100)
    divider.BackgroundTransparency = 0.5
    divider.BorderSizePixel = 0
    divider.Parent = main

    -- ===== СТАТУСЫ =====
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -24, 0, 20)
    status.Position = UDim2.new(0, 12, 0, 40)
    status.BackgroundTransparency = 1
    status.Text = "DISABLED"
    status.TextColor3 = Color3.fromRGB(100, 150, 200)
    status.TextSize = 11
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Font = Enum.Font.Gotham
    status.Parent = main

    local targetLabel = Instance.new("TextLabel")
    targetLabel.Size = UDim2.new(1, -24, 0, 20)
    targetLabel.Position = UDim2.new(0, 12, 0, 60)
    targetLabel.BackgroundTransparency = 1
    targetLabel.Text = "TARGET: NONE"
    targetLabel.TextColor3 = Color3.fromRGB(140, 170, 200)
    targetLabel.TextSize = 11
    targetLabel.TextXAlignment = Enum.TextXAlignment.Left
    targetLabel.Font = Enum.Font.Gotham
    targetLabel.Parent = main

    local aimLabel = Instance.new("TextLabel")
    aimLabel.Size = UDim2.new(1, -24, 0, 20)
    aimLabel.Position = UDim2.new(0, 12, 0, 80)
    aimLabel.BackgroundTransparency = 1
    aimLabel.Text = "AIM: HEAD"
    aimLabel.TextColor3 = Color3.fromRGB(80, 180, 255)
    aimLabel.TextSize = 11
    aimLabel.TextXAlignment = Enum.TextXAlignment.Left
    aimLabel.Font = Enum.Font.Gotham
    aimLabel.Parent = main

    local killsLabel = Instance.new("TextLabel")
    killsLabel.Size = UDim2.new(1, -24, 0, 20)
    killsLabel.Position = UDim2.new(0, 12, 0, 100)
    killsLabel.BackgroundTransparency = 1
    killsLabel.Text = "KILLS: 0"
    killsLabel.TextColor3 = Color3.fromRGB(200, 180, 100)
    killsLabel.TextSize = 11
    killsLabel.TextXAlignment = Enum.TextXAlignment.Left
    killsLabel.Font = Enum.Font.Gotham
    killsLabel.Parent = main

    -- ===== КНОПКИ (ГРАДИЕНТ + АНИМАЦИЯ) =====
    local function createModernButton(text, y, gradColor1, gradColor2, textColor)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -24, 0, 32)
        btn.Position = UDim2.new(0, 12, 0, y)
        btn.BackgroundColor3 = Color3.fromRGB(20, 40, 70)
        btn.BorderSizePixel = 0
        btn.Text = text
        btn.TextColor3 = textColor or Color3.fromRGB(200, 215, 240)
        btn.TextSize = 12
        btn.Font = Enum.Font.GothamMedium
        btn.Parent = main

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = btn

        local grad = createGradient(gradColor1, gradColor2)
        grad.Parent = btn

        -- Свечение (UIStroke)
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(60, 120, 255)
        stroke.Thickness = 1
        stroke.Transparency = 0.8
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = btn

        -- Анимация при наведении
        local tweenHover = TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.1,
            TextColor3 = Color3.fromRGB(255, 255, 255),
        })
        local tweenLeave = TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0,
            TextColor3 = textColor or Color3.fromRGB(200, 215, 240),
        })

        btn.MouseEnter:Connect(function()
            tweenLeave:Cancel()
            tweenHover:Play()
        end)
        btn.MouseLeave:Connect(function()
            tweenHover:Cancel()
            tweenLeave:Play()
        end)

        return btn, stroke, grad
    end

    local btnToggle, strokeToggle, gradToggle = createModernButton(
        "ACTIVATE", 118,
        Color3.fromRGB(0, 60, 150),
        Color3.fromRGB(0, 30, 90),
        Color3.fromRGB(200, 215, 240)
    )
    local btnAimPart, strokeAim, gradAim = createModernButton(
        "SWITCH TO BODY", 158,
        Color3.fromRGB(0, 80, 120),
        Color3.fromRGB(0, 40, 70),
        Color3.fromRGB(200, 215, 240)
    )
    local btnXRay, strokeXRay, gradXRay = createModernButton(
        "X-RAY: ON", 198,
        Color3.fromRGB(0, 90, 100),
        Color3.fromRGB(0, 50, 60),
        Color3.fromRGB(200, 215, 240)
    )
    local btnExit, strokeExit, gradExit = createModernButton(
        "EXIT SCRIPT", 238,
        Color3.fromRGB(120, 20, 30),
        Color3.fromRGB(80, 10, 20),
        Color3.fromRGB(255, 150, 150)
    )

    -- ===== FOV КРУГ =====
    local fovCircle = Instance.new("ImageLabel")
    fovCircle.Size = UDim2.new(0, CONFIG.FOV * 2, 0, CONFIG.FOV * 2)
    fovCircle.Position = UDim2.new(0.5, -CONFIG.FOV, 0.5, -CONFIG.FOV)
    fovCircle.BackgroundTransparency = 1
    fovCircle.Image = "rbxassetid://4911621264"
    fovCircle.ImageColor3 = Color3.fromRGB(255, 255, 255)
    fovCircle.ImageTransparency = 0.6
    fovCircle.Visible = false
    fovCircle.Parent = gui

    -- ===== ПРИЦЕЛ (ЧЕРЕЗ ПИКСЕЛИ) =====
    local crosshair = Instance.new("Frame")
    crosshair.Size = UDim2.new(0, 0, 0, 0)
    crosshair.BackgroundTransparency = 1
    crosshair.Visible = false
    crosshair.Parent = gui

    local function updateCrosshairPosition()
        local vp = Camera.ViewportSize
        crosshair.Position = UDim2.fromOffset(vp.X / 2 + CONFIG.CenterOffset.X, vp.Y / 2 + CONFIG.CenterOffset.Y)
    end

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
    updateCrosshairPosition()

    -- Обновляем при изменении размера экрана
    game:GetService("UserInputService").WindowFocused:Connect(updateCrosshairPosition)

    return {
        gui = gui,
        main = main,
        header = header,
        winButtons = winButtons,
        status = status,
        targetLabel = targetLabel,
        aimLabel = aimLabel,
        killsLabel = killsLabel,
        btnToggle = btnToggle,
        btnAimPart = btnAimPart,
        btnXRay = btnXRay,
        btnExit = btnExit,
        fovCircle = fovCircle,
        crosshair = crosshair,
        strokeToggle = strokeToggle,
        strokeAim = strokeAim,
        strokeXRay = strokeXRay,
        gradToggle = gradToggle,
        gradAim = gradAim,
        gradXRay = gradXRay,
        updateCrosshair = updateCrosshairPosition,
    }
end

local GUI = buildGUI()

-- ============================================================
--  ОБНОВЛЕНИЕ RAYCAST ФИЛЬТРА
-- ============================================================
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

local function updateRaycastFilter(char)
    if char then
        raycastParams.FilterDescendantsInstances = {char}
    end
end
updateRaycastFilter(Player.Character)
Player.CharacterAdded:Connect(updateRaycastFilter)

-- ============================================================
--  ЦЕНТР ЭКРАНА (С ОФФСЕТОМ)
-- ============================================================
local function getCenter()
    local vp = Camera.ViewportSize
    return Vector2.new(
        vp.X * 0.5 + CONFIG.CenterOffset.X,
        vp.Y * 0.5 + CONFIG.CenterOffset.Y
    )
end

-- ============================================================
--  УТИЛИТЫ
-- ============================================================
local function isAlive(plr)
    if not plr or not plr.Parent then return false end
    if not plr.Character or not plr.Character.Parent then return false end
    local humanoid = plr.Character:FindFirstChild("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function getAimPart(plr)
    if not plr or not plr.Character or not plr.Character.Parent then return nil end
    local char = plr.Character
    local part = char:FindFirstChild(CONFIG.AimPart)
    if part then return part end
    part = char:FindFirstChild(CONFIG.BackupPart)
    if part then return part end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
end

local function getScreenPos(part)
    if not part or not part.Parent then return nil end
    local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
    if not onScreen then return nil end
    return Vector2.new(pos.X, pos.Y)
end

local function getVelocity(plr)
    if not plr or not plr.Character or not plr.Character.Parent then return Vector3.new(0, 0, 0) end
    local root = plr.Character:FindFirstChild("HumanoidRootPart")
    if root then return root.AssemblyLinearVelocity end
    return Vector3.new(0, 0, 0)
end

local function isVisible(plr)
    if not plr or not plr.Character or not plr.Character.Parent then return false end
    if not Camera then return false end
    
    local part = getAimPart(plr)
    if not part or not part.Parent then return false end
    
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
--  X-RAY
-- ============================================================
local XRAY_PARTS = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "LeftFoot", "RightFoot", "LeftHand", "RightHand"}

local function getCharacterParts(plr)
    if not plr or not plr.Character or not plr.Character.Parent then return {} end
    
    local cached = XRayState.partsCache[plr]
    if cached and XRayState.cacheTimers[plr] and os.clock() - XRayState.cacheTimers[plr] < XRayState.CACHE_DURATION then
        return cached
    end
    
    local char = plr.Character
    local parts = {}
    for _, name in ipairs(XRAY_PARTS) do
        local part = char:FindFirstChild(name)
        if part and part.Parent then
            table.insert(parts, part)
        end
    end
    if #parts < 3 then
        for _, child in ipairs(char:GetDescendants()) do
            if child:IsA("BasePart") and child.Parent then
                table.insert(parts, child)
            end
        end
    end
    
    XRayState.partsCache[plr] = parts
    XRayState.cacheTimers[plr] = os.clock()
    return parts
end

local function clearPartsCache(plr)
    if plr then
        XRayState.partsCache[plr] = nil
        XRayState.cacheTimers[plr] = nil
    else
        XRayState.partsCache = {}
        XRayState.cacheTimers = {}
    end
end

local function removeBox(plr)
    local data = XRayState.boxes[plr]
    if data then
        if data.container and data.container.Parent then
            data.container:Destroy()
        end
        XRayState.boxes[plr] = nil
    end
end

local function clearAllBoxes()
    for plr in pairs(XRayState.boxes) do
        removeBox(plr)
    end
    XRayState.boxes = {}
end

local function createBox(plr)
    if XRayState.boxes[plr] then return end
    if not XRayState.container or not XRayState.container.Parent then return end
    
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
    if not data.container or not data.container.Parent then
        XRayState.boxes[plr] = nil
        return
    end
    if not plr or not plr.Character or not plr.Character.Parent then
        removeBox(plr)
        return
    end
    if not Camera then return end
    
    local parts = getCharacterParts(plr)
    if #parts == 0 then
        data.container.Visible = false
        return
    end
    
    local minX, maxX, minY, maxY = nil, nil, nil, nil
    
    for _, part in ipairs(parts) do
        if not part or not part.Parent then continue end
        local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if onScreen then
            if minX == nil then
                minX, maxX = pos.X, pos.X
                minY, maxY = pos.Y, pos.Y
            else
                if pos.X < minX then minX = pos.X end
                if pos.X > maxX then maxX = pos.X end
                if pos.Y < minY then minY = pos.Y end
                if pos.Y > maxY then maxY = pos.Y end
            end
        end
    end
    
    if minX == nil then
        data.container.Visible = false
        return
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

local function updateXRay(dt)
    if State.destroyed then return end
    
    if not XRayState.enabled then
        clearAllBoxes()
        return
    end
    
    State.xrayTimer = State.xrayTimer + dt
    if State.xrayTimer < CONFIG.XRayUpdateInterval then
        return
    end
    State.xrayTimer = 0
    
    for plr in pairs(XRayState.boxes) do
        if not plr or not plr.Parent or not isAlive(plr) then
            removeBox(plr)
        end
    end
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Parent and isAlive(plr) then
            createBox(plr)
            updateBox(plr)
        end
    end
end

-- ============================================================
--  ЛОГИКА АИМА
-- ============================================================
local function updateTargetCF(plr)
    if not plr or not isAlive(plr) then return end
    if not Camera then return end
    
    local part = getAimPart(plr)
    if not part or not part.Parent then return end
    
    local pos = part.Position
    local vel = getVelocity(plr)
    local distance = (pos - Camera.CFrame.Position).Magnitude
    
    local targetPos = pos
    if vel.Magnitude >= 0.1 then
        local flyTime = distance / CONFIG.BulletSpeed
        local predTime = flyTime * CONFIG.PredictionStrength
        targetPos = pos + vel * predTime
    end
    
    State.targetCF = CFrame.lookAt(Camera.CFrame.Position, targetPos)
end

local function findBestTarget()
    if not Camera or not Player.Character or not Player.Character.Parent then return nil end
    
    local center = getCenter()
    local best = nil
    local bestDist = math.huge
    local fovSq = CONFIG.FOV ^ 2
    local camPos = Camera.CFrame.Position
    
    local candidates = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Parent and isAlive(plr) then
            local part = getAimPart(plr)
            if part and part.Parent then
                local screenPos = getScreenPos(part)
                if screenPos then
                    local dx = screenPos.X - center.X
                    local dy = screenPos.Y - center.Y
                    local dist = dx*dx + dy*dy
                    
                    if dist < fovSq then
                        local offset = part.Position - camPos
                        local worldDistSq = offset:Dot(offset)
                        if worldDistSq <= DIST_LIMIT_SQ then
                            table.insert(candidates, {
                                player = plr,
                                part = part,
                                screenPos = screenPos,
                                dist = dist,
                            })
                        end
                    end
                end
            end
        end
    end
    
    for _, cand in ipairs(candidates) do
        if isVisible(cand.player) then
            if cand.dist < bestDist then
                best = cand.player
                bestDist = cand.dist
            end
        end
    end
    
    return best
end

local function isTargetInFOV(plr)
    if not plr or not plr.Character or not plr.Character.Parent then return false end
    if not Camera then return false end
    
    local part = getAimPart(plr)
    if not part or not part.Parent then return false end
    
    local screenPos = getScreenPos(part)
    if not screenPos then return false end
    
    local center = getCenter()
    local dx = screenPos.X - center.X
    local dy = screenPos.Y - center.Y
    local dist = dx*dx + dy*dy
    
    return dist < CONFIG.FOV ^ 2
end

local function processAim(dt)
    if State.destroyed then return end
    if not Camera then return end
    
    updateXRay(dt)
    
    if not State.enabled then
        return
    end
    
    State.searchTimer = State.searchTimer + dt
    
    if State.target and State.target.Parent and isAlive(State.target) then
        local part = getAimPart(State.target)
        local visible = part and part.Parent and isVisible(State.target)
        local inFOV = isTargetInFOV(State.target)
        
        if part and visible and inFOV then
            State.lostTimer = 0
            updateTargetCF(State.target)
            
            if State.targetCF then
                if State.smoothCF then
                    State.smoothCF = State.smoothCF:Lerp(State.targetCF, CONFIG.Smoothness)
                else
                    State.smoothCF = State.targetCF
                end
                
                if Camera and State.smoothCF then
                    Camera.CFrame = State.smoothCF
                end
            end
            
            if GUI.status and GUI.status.Parent then
                GUI.status.Text = "LOCKED: " .. State.target.Name
                GUI.status.TextColor3 = Color3.fromRGB(100, 255, 200)
            end
            if GUI.targetLabel and GUI.targetLabel.Parent then
                GUI.targetLabel.Text = "TARGET: " .. State.target.Name
                GUI.targetLabel.TextColor3 = Color3.fromRGB(100, 255, 200)
            end
            return
        end
        
        State.lostTimer = State.lostTimer + dt
        if State.lostTimer > CONFIG.LostTimeout then
            State.target = nil
            State.targetCF = nil
            State.smoothCF = nil
        end
    end
    
    if State.searchTimer < CONFIG.SearchInterval then
        return
    end
    State.searchTimer = 0
    
    local newTarget = findBestTarget()
    
    if newTarget then
        State.target = newTarget
        State.lostTimer = 0
        State.smoothCF = nil
        State.targetCF = nil
        
        updateTargetCF(newTarget)
        if State.targetCF then
            State.smoothCF = State.targetCF
            if Camera then
                Camera.CFrame = State.smoothCF
            end
        end
        
        if GUI.status and GUI.status.Parent then
            GUI.status.Text = "LOCKED: " .. newTarget.Name
            GUI.status.TextColor3 = Color3.fromRGB(100, 255, 200)
        end
        if GUI.targetLabel and GUI.targetLabel.Parent then
            GUI.targetLabel.Text = "TARGET: " .. newTarget.Name
            GUI.targetLabel.TextColor3 = Color3.fromRGB(100, 255, 200)
        end
    else
        if State.target then
            State.target = nil
            State.targetCF = nil
            State.smoothCF = nil
        end
        
        if GUI.status and GUI.status.Parent then
            GUI.status.Text = "NO TARGET"
            GUI.status.TextColor3 = Color3.fromRGB(255, 200, 100)
        end
        if GUI.targetLabel and GUI.targetLabel.Parent then
            GUI.targetLabel.Text = "SEARCHING..."
            GUI.targetLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        end
    end
end

-- ============================================================
--  УПРАВЛЕНИЕ
-- ============================================================
local function toggleAim()
    if State.destroyed then return end
    
    State.enabled = not State.enabled
    
    if State.enabled then
        local target = findBestTarget()
        
        if target then
            State.target = target
            State.lostTimer = 0
            State.targetCF = nil
            State.smoothCF = nil
            State.searchTimer = 0
            State.xrayTimer = 0
            
            updateTargetCF(target)
            if State.targetCF and Camera then
                State.smoothCF = State.targetCF
                Camera.CFrame = State.smoothCF
            end
            
            if GUI.status and GUI.status.Parent then
                GUI.status.Text = "LOCKED: " .. target.Name
                GUI.status.TextColor3 = Color3.fromRGB(100, 255, 200)
            end
            if GUI.targetLabel and GUI.targetLabel.Parent then
                GUI.targetLabel.Text = "TARGET: " .. target.Name
                GUI.targetLabel.TextColor3 = Color3.fromRGB(100, 255, 200)
            end
        else
            State.target = nil
            if GUI.status and GUI.status.Parent then
                GUI.status.Text = "NO TARGET"
                GUI.status.TextColor3 = Color3.fromRGB(255, 200, 100)
            end
            if GUI.targetLabel and GUI.targetLabel.Parent then
                GUI.targetLabel.Text = "SEARCHING..."
                GUI.targetLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
            end
        end
        
        if GUI.btnToggle and GUI.btnToggle.Parent then
            GUI.btnToggle.Text = "DEACTIVATE"
            -- Меняем градиент на зелёный
            if GUI.gradToggle then
                GUI.gradToggle.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 120, 60)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 70, 30)),
                })
            end
            if GUI.strokeToggle then
                GUI.strokeToggle.Color = Color3.fromRGB(0, 255, 100)
                GUI.strokeToggle.Transparency = 0.3
            end
        end
        
        if GUI.fovCircle and GUI.fovCircle.Parent then
            GUI.fovCircle.Visible = CONFIG.ShowFOV
        end
        if GUI.crosshair and GUI.crosshair.Parent then
            GUI.crosshair.Visible = true
        end
        
        if not XRayState.container or not XRayState.container.Parent then
            XRayState.container = Instance.new("Folder")
            XRayState.container.Name = "XRay"
            XRayState.container.Parent = GUI.gui
        end
    else
        State.target = nil
        State.targetCF = nil
        State.smoothCF = nil
        State.lostTimer = 0
        State.searchTimer = 0
        State.xrayTimer = 0
        State.killCount = 0
        
        if GUI.status and GUI.status.Parent then
            GUI.status.Text = "DISABLED"
            GUI.status.TextColor3 = Color3.fromRGB(100, 150, 200)
        end
        if GUI.targetLabel and GUI.targetLabel.Parent then
            GUI.targetLabel.Text = "TARGET: NONE"
            GUI.targetLabel.TextColor3 = Color3.fromRGB(140, 170, 200)
        end
        if GUI.killsLabel and GUI.killsLabel.Parent then
            GUI.killsLabel.Text = "KILLS: 0"
        end
        
        if GUI.btnToggle and GUI.btnToggle.Parent then
            GUI.btnToggle.Text = "ACTIVATE"
            if GUI.gradToggle then
                GUI.gradToggle.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 60, 150)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 30, 90)),
                })
            end
            if GUI.strokeToggle then
                GUI.strokeToggle.Color = Color3.fromRGB(60, 120, 255)
                GUI.strokeToggle.Transparency = 0.8
            end
        end
        
        if GUI.fovCircle and GUI.fovCircle.Parent then
            GUI.fovCircle.Visible = false
        end
        if GUI.crosshair and GUI.crosshair.Parent then
            GUI.crosshair.Visible = false
        end
        
        clearAllBoxes()
        clearPartsCache()
        if XRayState.container and XRayState.container.Parent then
            XRayState.container:Destroy()
            XRayState.container = nil
        end
    end
end

local function switchAimPart()
    if State.destroyed then return end
    
    if CONFIG.AimPart == "Head" then
        CONFIG.AimPart = "HumanoidRootPart"
        CONFIG.BackupPart = "Torso"
        if GUI.aimLabel and GUI.aimLabel.Parent then
            GUI.aimLabel.Text = "AIM: BODY"
        end
        if GUI.btnAimPart and GUI.btnAimPart.Parent then
            GUI.btnAimPart.Text = "SWITCH TO HEAD"
        end
    else
        CONFIG.AimPart = "Head"
        CONFIG.BackupPart = "UpperTorso"
        if GUI.aimLabel and GUI.aimLabel.Parent then
            GUI.aimLabel.Text = "AIM: HEAD"
        end
        if GUI.btnAimPart and GUI.btnAimPart.Parent then
            GUI.btnAimPart.Text = "SWITCH TO BODY"
        end
    end
end

local function toggleXRay()
    if State.destroyed then return end
    
    XRayState.enabled = not XRayState.enabled
    
    if GUI.btnXRay and GUI.btnXRay.Parent then
        GUI.btnXRay.Text = XRayState.enabled and "X-RAY: ON" or "X-RAY: OFF"
    end
    
    if not XRayState.enabled then
        clearAllBoxes()
        clearPartsCache()
        if XRayState.container and XRayState.container.Parent then
            XRayState.container:Destroy()
            XRayState.container = nil
        end
    elseif not XRayState.container or not XRayState.container.Parent then
        XRayState.container = Instance.new("Folder")
        XRayState.container.Name = "XRay"
        XRayState.container.Parent = GUI.gui
    end
end

-- ============================================================
--  ОБРАБОТЧИКИ СОБЫТИЙ
-- ============================================================
local connections = {}
local function connect(obj, event, callback)
    local conn
    if type(obj) == "string" then
        conn = event:Connect(callback)
    else
        conn = obj[event]:Connect(callback)
    end
    table.insert(connections, conn)
    return conn
end

connect(GUI.btnToggle, "MouseButton1Click", toggleAim)
connect(GUI.btnAimPart, "MouseButton1Click", switchAimPart)
connect(GUI.btnXRay, "MouseButton1Click", toggleXRay)

connect(GUI.winButtons.minimize, "MouseButton1Click", function()
    State.minimized = not State.minimized
    if State.minimized then
        GUI.main:TweenSize(UDim2.new(0, 200, 0, 32), "Out", "Quad", 0.3, true)
        for _, child in ipairs(GUI.main:GetChildren()) do
            if child:IsA("TextLabel") or (child:IsA("TextButton") and child ~= GUI.header) then
                child.Visible = false
            end
        end
        GUI.winButtons.minimize.Text = "□"
    else
        GUI.main:TweenSize(UDim2.new(0, 260, 0, 320), "Out", "Quad", 0.3, true)
        for _, child in ipairs(GUI.main:GetChildren()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                child.Visible = true
            end
        end
        GUI.winButtons.minimize.Text = "─"
    end
end)

connect(GUI.winButtons.maximize, "MouseButton1Click", function()
    State.maximized = not State.maximized
    if State.maximized then
        GUI.main:TweenSize(UDim2.new(0, 380, 0, 440), "Out", "Quad", 0.3, true)
        GUI.main:TweenPosition(UDim2.new(0.5, -190, 0.5, -220), "Out", "Quad", 0.3, true)
    else
        GUI.main:TweenSize(UDim2.new(0, 260, 0, 320), "Out", "Quad", 0.3, true)
        GUI.main:TweenPosition(UDim2.new(0, 16, 0, 16), "Out", "Quad", 0.3, true)
    end
end)

-- Клавиатура
local keyConn = UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if State.destroyed then return end
    
    if input.KeyCode == Enum.KeyCode.One then
        toggleAim()
    elseif input.KeyCode == Enum.KeyCode.Two then
        switchAimPart()
    elseif input.KeyCode == Enum.KeyCode.Three then
        toggleXRay()
    end
end)
table.insert(connections, keyConn)

-- Обработка выхода игрока
Players.PlayerRemoving:Connect(function(plr)
    removeBox(plr)
    clearPartsCache(plr)
    if State.target == plr then
        State.target = nil
        State.targetCF = nil
        State.smoothCF = nil
    end
end)

for _, plr in pairs(Players:GetPlayers()) do
    if plr ~= Player then
        plr.CharacterAdded:Connect(function()
            clearPartsCache(plr)
        end)
        plr.CharacterRemoving:Connect(function()
            clearPartsCache(plr)
        end)
    end
end

-- ============================================================
--  CLEANUP
-- ============================================================
local function cleanup()
    if State.cleaned then return end
    State.cleaned = true
    State.destroyed = true
    
    for _, conn in ipairs(connections) do
        if conn and conn.Disconnect then
            pcall(conn.Disconnect, conn)
        end
    end
    connections = {}
    
    if GUI.gui and GUI.gui.Parent then
        pcall(function() GUI.gui:Destroy() end)
    end
    
    if XRayState.container and XRayState.container.Parent then
        pcall(function() XRayState.container:Destroy() end)
        XRayState.container = nil
    end
    
    clearAllBoxes()
    clearPartsCache()
    
    State.enabled = false
    State.target = nil
    State.targetCF = nil
    State.smoothCF = nil
end

connect(GUI.winButtons.close, "MouseButton1Click", cleanup)
connect(GUI.btnExit, "MouseButton1Click", cleanup)

-- ============================================================
--  RENDERSTEP
-- ============================================================
local renderConn = RunService.RenderStepped:Connect(function(dt)
    if State.destroyed then return end
    pcall(processAim, dt)
end)
table.insert(connections, renderConn)

-- ============================================================
--  СТАРТ
-- ============================================================
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "AIM LOCK v31",
    Text = "1 - Toggle | 2 - Head/Body | 3 - X-Ray",
    Duration = 4
})

print("✅ AIM LOCK v31.0 LOADED")
print("📌 1 - Toggle ON/OFF")
print("📌 2 - Switch aim (HEAD ↔ BODY)")
print("📌 3 - Toggle X-RAY")
print("🔧 CenterOffset = (", CONFIG.CenterOffset.X, ",", CONFIG.CenterOffset.Y, ")")
