-- AIM LOCK v35.1 | FULLY FIXED
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
    XRayUpdateInterval = 0.025,
    ShowFOV = true,
    CrosshairStyle = "DOT",
    CenterOffset = Vector2.new(0, 0),
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
    hue = 0,
    lastStatus = "",
    lastTarget = "",
}

-- ============================================================
--  X-RAY СОСТОЯНИЕ
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
--  ЦЕНТР ЭКРАНА (ОПРЕДЕЛЯЕТСЯ ДО GUI)
-- ============================================================
local function getCenter()
    local vp = Camera.ViewportSize
    return Vector2.new(
        vp.X / 2 + CONFIG.CenterOffset.X,
        vp.Y / 2 + CONFIG.CenterOffset.Y
    )
end

-- ============================================================
--  GUI (ЯРКИЙ, СОВРЕМЕННЫЙ)
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
    gui.IgnoreGuiInset = true
    gui.Parent = PlayerGui
    gui.DisplayOrder = 999

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 220, 0, 280)
    main.Position = UDim2.new(0, 16, 0, 16)
    main.BackgroundColor3 = Color3.fromRGB(10, 20, 60)
    main.BackgroundTransparency = 0.02
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Parent = gui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 16)
    mainCorner.Parent = main

    local bgGrad = createGradient(
        Color3.fromRGB(30, 60, 160),
        Color3.fromRGB(10, 20, 80)
    )
    bgGrad.Parent = main

    local glowBorder = Instance.new("Frame")
    glowBorder.Size = UDim2.new(1, 0, 1, 0)
    glowBorder.Position = UDim2.new(0, 0, 0, 0)
    glowBorder.BackgroundTransparency = 1
    glowBorder.BorderSizePixel = 2
    glowBorder.BorderColor3 = Color3.fromRGB(120, 200, 255)
    glowBorder.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    glowBorder.BackgroundTransparency = 1
    glowBorder.Parent = main
    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(0, 16)
    glowCorner.Parent = glowBorder

    local innerGlow = Instance.new("UIStroke")
    innerGlow.Color = Color3.fromRGB(100, 200, 255)
    innerGlow.Thickness = 2
    innerGlow.Transparency = 0.2
    innerGlow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    innerGlow.Parent = main

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 30)
    header.BackgroundColor3 = Color3.fromRGB(20, 40, 100)
    header.BackgroundTransparency = 0.05
    header.BorderSizePixel = 0
    header.Parent = main

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 16)
    headerCorner.Parent = header

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -80, 1, 0)
    title.Position = UDim2.new(0, 12, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "AIM LOCK"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamMedium
    title.Parent = header

    local winButtons = {}
    for i, data in ipairs({
        {text = "─", pos = 1, color = Color3.fromRGB(255, 255, 255), action = "minimize"},
        {text = "□", pos = 2, color = Color3.fromRGB(255, 255, 255), action = "maximize"},
        {text = "✕", pos = 3, color = Color3.fromRGB(255, 80, 80), action = "close"},
    }) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 24, 1, 0)
        btn.Position = UDim2.new(1, -24 * (4 - data.pos), 0, 0)
        btn.BackgroundTransparency = 1
        btn.Text = data.text
        btn.TextColor3 = data.color
        btn.TextSize = 14
        btn.Font = Enum.Font.Gotham
        btn.Parent = header
        winButtons[data.action] = btn
    end

    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, -20, 0, 1)
    divider.Position = UDim2.new(0, 10, 0, 30)
    divider.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
    divider.BackgroundTransparency = 0.2
    divider.BorderSizePixel = 0
    divider.Parent = main

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -20, 0, 18)
    status.Position = UDim2.new(0, 10, 0, 36)
    status.BackgroundTransparency = 1
    status.Text = "DISABLED"
    status.TextColor3 = Color3.fromRGB(255, 255, 255)
    status.TextSize = 10
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Font = Enum.Font.Gotham
    status.Parent = main

    local targetLabel = Instance.new("TextLabel")
    targetLabel.Size = UDim2.new(1, -20, 0, 18)
    targetLabel.Position = UDim2.new(0, 10, 0, 54)
    targetLabel.BackgroundTransparency = 1
    targetLabel.Text = "TARGET: NONE"
    targetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    targetLabel.TextSize = 10
    targetLabel.TextXAlignment = Enum.TextXAlignment.Left
    targetLabel.Font = Enum.Font.Gotham
    targetLabel.Parent = main

    local aimLabel = Instance.new("TextLabel")
    aimLabel.Size = UDim2.new(1, -20, 0, 18)
    aimLabel.Position = UDim2.new(0, 10, 0, 72)
    aimLabel.BackgroundTransparency = 1
    aimLabel.Text = "AIM: HEAD"
    aimLabel.TextColor3 = Color3.fromRGB(180, 240, 255)
    aimLabel.TextSize = 10
    aimLabel.TextXAlignment = Enum.TextXAlignment.Left
    aimLabel.Font = Enum.Font.Gotham
    aimLabel.Parent = main

    local killsLabel = Instance.new("TextLabel")
    killsLabel.Size = UDim2.new(1, -20, 0, 18)
    killsLabel.Position = UDim2.new(0, 10, 0, 90)
    killsLabel.BackgroundTransparency = 1
    killsLabel.Text = "KILLS: 0"
    killsLabel.TextColor3 = Color3.fromRGB(255, 240, 180)
    killsLabel.TextSize = 10
    killsLabel.TextXAlignment = Enum.TextXAlignment.Left
    killsLabel.Font = Enum.Font.Gotham
    killsLabel.Parent = main

    local function createModernButton(text, y, gradColor1, gradColor2)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -20, 0, 28)
        btn.Position = UDim2.new(0, 10, 0, y)
        btn.BackgroundColor3 = Color3.fromRGB(20, 40, 80)
        btn.BorderSizePixel = 0
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 11
        btn.Font = Enum.Font.GothamMedium
        btn.Parent = main

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = btn

        local grad = createGradient(gradColor1, gradColor2)
        grad.Parent = btn

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(120, 200, 255)
        stroke.Thickness = 2
        stroke.Transparency = 0.2
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = btn

        local tweenHover = TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.1,
        })
        local tweenLeave = TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0,
        })

        local tweenPress = TweenService:Create(btn, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, -22, 0, 26),
        })
        local tweenRelease = TweenService:Create(btn, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, -20, 0, 28),
        })

        btn.MouseEnter:Connect(function()
            tweenLeave:Cancel()
            tweenHover:Play()
        end)
        btn.MouseLeave:Connect(function()
            tweenHover:Cancel()
            tweenLeave:Play()
        end)
        btn.MouseButton1Down:Connect(function()
            tweenRelease:Cancel()
            tweenPress:Play()
        end)
        btn.MouseButton1Up:Connect(function()
            tweenPress:Cancel()
            tweenRelease:Play()
        end)

        return btn, stroke, grad
    end

    local btnToggle, strokeToggle, gradToggle = createModernButton(
        "ACTIVATE", 108,
        Color3.fromRGB(0, 120, 255),
        Color3.fromRGB(0, 60, 200)
    )
    local btnAimPart, strokeAim, gradAim = createModernButton(
        "SWITCH TO BODY", 142,
        Color3.fromRGB(0, 150, 220),
        Color3.fromRGB(0, 80, 160)
    )
    local btnXRay, strokeXRay, gradXRay = createModernButton(
        "X-RAY: ON", 176,
        Color3.fromRGB(0, 180, 180),
        Color3.fromRGB(0, 100, 120)
    )
    local btnExit, strokeExit, gradExit = createModernButton(
        "EXIT", 210,
        Color3.fromRGB(200, 40, 50),
        Color3.fromRGB(140, 20, 30)
    )

    local fovCircle = Instance.new("ImageLabel")
    fovCircle.Size = UDim2.new(0, CONFIG.FOV * 2, 0, CONFIG.FOV * 2)
    fovCircle.Position = UDim2.new(0.5, -CONFIG.FOV, 0.5, -CONFIG.FOV)
    fovCircle.BackgroundTransparency = 1
    fovCircle.Image = "rbxassetid://4911621264"
    fovCircle.ImageColor3 = Color3.fromRGB(255, 255, 255)
    fovCircle.ImageTransparency = 0.6
    fovCircle.Visible = false
    fovCircle.Parent = gui

    local crosshair = Instance.new("Frame")
    crosshair.Size = UDim2.new(0, 0, 0, 0)
    crosshair.BackgroundTransparency = 1
    crosshair.Visible = false
    crosshair.Parent = gui

    local function updateCrosshairPosition()
        local center = getCenter()
        crosshair.Position = UDim2.fromOffset(center.X, center.Y)
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

-- ============================================================
--  СОЗДАНИЕ GUI (ПОСЛЕ ОПРЕДЕЛЕНИЯ getCenter)
-- ============================================================
local GUI = buildGUI()

-- ============================================================
--  ОБНОВЛЕНИЕ ПРИЦЕЛА ПРИ СМЕНЕ РАЗМЕРА
-- ============================================================
local function onScreenSizeChanged()
    if GUI and GUI.updateCrosshair then
        GUI.updateCrosshair()
    end
end
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(onScreenSizeChanged)
UserInputService.WindowFocused:Connect(onScreenSizeChanged)

-- ============================================================
--  RAYCAST
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
--  X-RAY (ЯРКИЙ RGB)
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
    border.BackgroundTransparency = 0.7
    border.BackgroundColor3 = Color3.fromHSV(0, 1, 1)
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
    outline.BorderSizePixel = 2
    outline.BorderColor3 = Color3.fromHSV(0, 1, 1)
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
    nameLabel.TextColor3 = Color3.fromHSV(0, 1, 1)
    nameLabel.TextSize = 11
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextStrokeTransparency = 0.2
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Parent = container
    
    XRayState.boxes[plr] = {
        container = container,
        border = border,
        outline = outline,
        name = nameLabel,
    }
end

local function updateBox(plr, hue)
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
    
    local color = Color3.fromHSV(hue, 1, 1)
    
    if data.border then data.border.BackgroundColor3 = color end
    if data.outline then data.outline.BorderColor3 = color end
    if data.name then data.name.TextColor3 = color end
    
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
    
    State.hue = (State.hue + dt * 0.2) % 1
    
    State.xrayTimer = State.xrayTimer + dt
    local shouldUpdatePos = State.xrayTimer >= CONFIG.XRayUpdateInterval
    if shouldUpdatePos then
        State.xrayTimer = 0
    end
    
    for plr, data in pairs(XRayState.boxes) do
        if data and data.container and data.container.Parent then
            local color = Color3.fromHSV(State.hue, 1, 1)
            if data.border then data.border.BackgroundColor3 = color end
            if data.outline then data.outline.BorderColor3 = color end
            if data.name then data.name.TextColor3 = color end
        end
    end
    
    if not shouldUpdatePos then
        return
    end
    
    for plr in pairs(XRayState.boxes) do
        if not plr or not plr.Parent or not isAlive(plr) then
            removeBox(plr)
        end
    end
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Parent and isAlive(plr) then
            createBox(plr)
            updateBox(plr, State.hue)
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
            if GUI.gradToggle then
                GUI.gradToggle.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 200, 100)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 140, 60)),
                })
            end
            if GUI.strokeToggle then
                GUI.strokeToggle.Color = Color3.fromRGB(0, 255, 100)
                GUI.strokeToggle.Transparency = 0.2
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
            GUI.status.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
        if GUI.targetLabel and GUI.targetLabel.Parent then
            GUI.targetLabel.Text = "TARGET: NONE"
            GUI.targetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
        if GUI.killsLabel and GUI.killsLabel.Parent then
            GUI.killsLabel.Text = "KILLS: 0"
        end
        
        if GUI.btnToggle and GUI.btnToggle.Parent then
            GUI.btnToggle.Text = "ACTIVATE"
            if GUI.gradToggle then
                GUI.gradToggle.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 120, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 60, 200)),
                })
            end
            if GUI.strokeToggle then
                GUI.strokeToggle.Color = Color3.fromRGB(120, 200, 255)
                GUI.strokeToggle.Transparency = 0.2
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
        GUI.main:TweenSize(UDim2.new(0, 180, 0, 30), "Out", "Quad", 0.3, true)
        for _, child in ipairs(GUI.main:GetChildren()) do
            if child:IsA("TextLabel") or (child:IsA("TextButton") and child ~= GUI.header) then
                child.Visible = false
            end
        end
        GUI.winButtons.minimize.Text = "□"
    else
        GUI.main:TweenSize(UDim2.new(0, 220, 0, 280), "Out", "Quad", 0.3, true)
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
        GUI.main:TweenSize(UDim2.new(0, 320, 0, 360), "Out", "Quad", 0.3, true)
        GUI.main:TweenPosition(UDim2.new(0.5, -160, 0.5, -180), "Out", "Quad", 0.3, true)
    else
        GUI.main:TweenSize(UDim2.new(0, 220, 0, 280), "Out", "Quad", 0.3, true)
        GUI.main:TweenPosition(UDim2.new(0, 16, 0, 16), "Out", "Quad", 0.3, true)
    end
end)

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
    Title = "AIM LOCK v35",
    Text = "1 - Toggle | 2 - Head/Body | 3 - X-Ray",
    Duration = 4
})

print("✅ AIM LOCK v35.1 FULLY LOADED")
print("📌 1 - Toggle ON/OFF")
print("📌 2 - Switch aim (HEAD ↔ BODY)")
print("📌 3 - Toggle X-RAY (RGB)")
print("🔧 CenterOffset = (", CONFIG.CenterOffset.X, ",", CONFIG.CenterOffset.Y, ")")
