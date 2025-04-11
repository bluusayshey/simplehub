-- Simple Hub! - V2.6 (Cleaned Up and Improved)
--( -Added Walkspeed and JumpPower Clamps- )
--( -Redundant Code Removed- )
--( -Added Settings Save/Load- )
--( -Added ESP- )

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local noclip = false
local flying = false
local fullbright = false
local infiniteJump = false
local clearsky = false
local esp = false
local spin = false

local walkspeed = 16
local jumppower = 50

local function safeGetHumanoid()
    character = player.Character or player.CharacterAdded:Wait()
    return character:FindFirstChildOfClass("Humanoid")
end

local gui = Instance.new("ScreenGui")
gui.Name = "SimpleHubGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local container = Instance.new("Frame")
container.Size = UDim2.new(0, 300, 0, 450)
container.Position = UDim2.new(0, 50, 0.5, -225)
container.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
container.Active = true
container.Draggable = true
container.ZIndex = 2
container.Parent = gui

Instance.new("UICorner", container).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", container).Color = Color3.fromRGB(100, 100, 100)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.J then
        container.Visible = not container.Visible
    end
end)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 40)
title.Position = UDim2.new(0, 10, 0, 5)
title.Text = "Simple Hub [J = Hide/Show]"
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 20
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 3
title.Parent = container

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -60)
scroll.Position = UDim2.new(0, 10, 0, 50)
scroll.CanvasSize = UDim2.new(0, 0, 0, 800)
scroll.ScrollBarThickness = 6
scroll.BackgroundTransparency = 1
scroll.ZIndex = 2
scroll.Parent = container

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

local function createToggle(name, defaultState, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 40)
    button.BackgroundColor3 = defaultState and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(231, 76, 60)
    button.Text = name .. ": " .. (defaultState and "ON" or "OFF")
    button.Font = Enum.Font.GothamBold
    button.TextColor3 = Color3.new(1,1,1)
    button.TextSize = 16
    button.AutoButtonColor = false
    button.ZIndex = 3
    button.Parent = scroll
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

    local state = defaultState
    button.MouseButton1Click:Connect(function()
        state = not state
        button.Text = name .. ": " .. (state and "ON" or "OFF")
        button.BackgroundColor3 = state and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(231, 76, 60)
        callback(state)
    end)
end

local function createStatInput(name, defaultVal, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 40)
    frame.BackgroundTransparency = 1
    frame.Parent = scroll

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.4, 0, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Text = name
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = Color3.new(1,1,1)
    label.TextSize = 14
    label.BackgroundTransparency = 1
    label.ZIndex = 3
    label.Parent = frame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.55, 0, 0.6, 0)
    box.Position = UDim2.new(0.42, 0, 0.2, 0)
    box.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    box.Text = tostring(defaultVal)
    box.Font = Enum.Font.Gotham
    box.TextColor3 = Color3.new(1,1,1)
    box.TextSize = 14
    box.ZIndex = 3
    box.ClearTextOnFocus = false
    box.Parent = frame
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

    box.FocusLost:Connect(function()
        local val = tonumber(box.Text)
        if val then
            val = math.clamp(val, 0, 1000)
            callback(val)
        else
            box.Text = tostring(defaultVal)
        end
    end)
end

-- Save and Load Preferences

local settings = {}

local function saveSettings()
    settings = {
        walkspeed = walkspeed,
        jumppower = jumppower,
        esp = esp,
        noclip = noclip,
        flying = flying,
        fullbright = fullbright,
        infiniteJump = infiniteJump,
        clearsky = clearsky,
        spin = spin
    }
    writefile("SimpleHubSettings.json", game:GetService("HttpService"):JSONEncode(settings))
end

local function loadSettings()
    if isfile("SimpleHubSettings.json") then
        settings = game:GetService("HttpService"):JSONDecode(readfile("SimpleHubSettings.json"))
        walkspeed = settings.walkspeed or walkspeed
        jumppower = settings.jumppower or jumppower
        esp = settings.esp or esp
        noclip = settings.noclip or noclip
        flying = settings.flying or flying
        fullbright = settings.fullbright or fullbright
        infiniteJump = settings.infiniteJump or infiniteJump
        clearsky = settings.clearsky or clearsky
        spin = settings.spin or spin
    end
end

loadSettings()

-- Fly System
local flyVelocity, flyGyro
local function enableFly()
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not flyVelocity then
        flyVelocity = Instance.new("BodyVelocity")
        flyVelocity.Velocity = Vector3.new(0, 0, 0)
        flyVelocity.MaxForce = Vector3.new(1, 1, 1) * 1e6
        flyVelocity.P = 1250
        flyVelocity.Name = "FlyVelocity"
        flyVelocity.Parent = hrp
    end
    if not flyGyro then
        flyGyro = Instance.new("BodyGyro")
        flyGyro.CFrame = hrp.CFrame
        flyGyro.MaxTorque = Vector3.new(1, 1, 1) * 1e6
        flyGyro.P = 3000
        flyGyro.Name = "FlyGyro"
        flyGyro.Parent = hrp
    end
end

local function disableFly()
    if flyVelocity then flyVelocity:Destroy() flyVelocity = nil end
    if flyGyro then flyGyro:Destroy() flyGyro = nil end
end

RunService.RenderStepped:Connect(function()
    if flying and character and character:FindFirstChild("HumanoidRootPart") then
        enableFly()
        local hrp = character.HumanoidRootPart
        local cam = workspace.CurrentCamera
        local moveDir = Vector3.new(0, 0, 0)

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += cam.CFrame.UpVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir -= cam.CFrame.UpVector end

        if flyVelocity and moveDir.Magnitude > 0 then
            flyVelocity.Velocity = moveDir.Unit * walkspeed * 2
        elseif flyVelocity then
            flyVelocity.Velocity = Vector3.new(0, 0, 0)
        end

        if flyGyro then flyGyro.CFrame = cam.CFrame end
    else
        disableFly()
    end
end)

-- ESP System
local function updateESP(player)
    if esp then
        if not player.Character then
            player.CharacterAdded:Wait()
        end
        local highlight = Instance.new("Highlight")
        local teamColor = player.TeamColor.Color
        highlight.Adornee = player.Character
        highlight.FillColor = Color3.fromRGB(teamColor.r * 255, teamColor.g * 255, teamColor.b * 255)
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.Parent = player.Character
    else
        if player.Character then
            for _, child in ipairs(player.Character:GetChildren()) do
                if child:IsA("Highlight") then
                    child:Destroy()
                end
            end
        end
    end
end

game.Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        updateESP(player)
    end)
    updateESP(player)
end)

game.Players.PlayerRemoving:Connect(function(player)
    if player.Character then
        for _, child in ipairs(player.Character:GetChildren()) do
            if child:IsA("Highlight") then
                child:Destroy()
            end
        end
    end
end)

if not pcall(function() Instance.new("Highlight") end) then
    warn("ESP not supported in this game.")
    esp = false
end

-- Toggle Buttons
createToggle("ESP Boxes", false, function(state)
    esp = state
    for _, player in ipairs(game.Players:GetPlayers()) do
        updateESP(player)
    end
end)
createToggle("Noclip", false, function(state) noclip = state end)
createToggle("Fly", false, function(state) flying = state end)
createToggle("FullBright", false, function(state)
    fullbright = state
    if state then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
    else
        Lighting.Brightness = 1
        Lighting.ClockTime = 12
        Lighting.FogEnd = 1000
        Lighting.GlobalShadows = true
    end
end)
createToggle("Infinite Jump", false, function(state) infiniteJump = state end)
createToggle("Clear Sky", false, function(state)
    clearsky = state
    Lighting.FogEnd = state and 100000 or 1000
end)
createToggle("Spin", false, function(state) spin = state end)
createToggle("Save Preferences", false, function(state)
    if state then
        saveSettings()
    end
end)

-- Input Fields
createStatInput("WalkSpeed", walkspeed, function(val)
    walkspeed = math.clamp(val, 0, 1000)
    local hum = safeGetHumanoid()
    if hum then hum.WalkSpeed = walkspeed end
end)

createStatInput("JumpPower", jumppower, function(val)
    jumppower = val
    local hum = safeGetHumanoid()
    if hum then
        hum.JumpPower = jumppower
    end
end)

-- Runtime Loops
RunService.Stepped:Connect(function()
    if noclip and character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
    if spin and character:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart.CFrame *= CFrame.Angles(0, math.rad(3), 0)
    end
end)

UserInputService.JumpRequest:Connect(function()
    local hum = safeGetHumanoid()
    if infiniteJump and hum then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)
