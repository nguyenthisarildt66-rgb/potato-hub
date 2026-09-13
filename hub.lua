local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Clean UI cũ
if CoreGui:FindFirstCoreGui("FoxnameCyberUltimate") then
    CoreGui.FoxnameCyberUltimate:Destroy()
end

-- SYSTEM SETTINGS
local Settings = {
    -- Movement
    Speed = 16,
    JumpPower = 50,
    Gravity = 196.2,
    Fly = false,
    FlySpeed = 50,
    Noclip = false,
    InfiniteJump = false,
    
    -- Visuals
    ESP_Players = false,
    ESP_Boxes = false,
    ESP_Tracers = false,
    
    -- Combat
    Aimbot = false,
    AimFOV = 100,
    ShowFOV = false,
    
    -- Auto & Util
    FastPrompt = false,
    InstantBrake = false,
    ClickTP = false,
    AntiAFK = true
}

-- 1. COMBAT LOGIC (AIMBOT & FOV)
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(255, 130, 0)
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 64
FOVCircle.Filled = false
FOVCircle.Transparency = 0.8

local function GetClosestPlayer()
    local closest, maxDist = nil, Settings.AimFOV
    local mousePos = UserInputService:GetMouseLocation()

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
            local head = plr.Character.Head
            local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                if dist < maxDist then
                    maxDist = dist
                    closest = head
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    FOVCircle.Visible = Settings.ShowFOV
    FOVCircle.Radius = Settings.AimFOV
    FOVCircle.Position = UserInputService:GetMouseLocation()

    if Settings.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = GetClosestPlayer()
        if target then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        end
    end
end)

-- 2. MOVEMENT & PHYSICS LOGIC
local flyBodyVel, flyBodyGyro
RunService.Stepped:Connect(function()
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

        if hum then
            hum.WalkSpeed = Settings.Speed
            hum.JumpPower = Settings.JumpPower
        end

        workspace.Gravity = Settings.Gravity

        if Settings.Noclip then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end

        if Settings.InstantBrake and hum and root and hum.MoveDirection.Magnitude == 0 then
            root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
        end

        -- Fly Logic
        if Settings.Fly and root then
            if not flyBodyVel then
                flyBodyVel = Instance.new("BodyVelocity")
                flyBodyVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
                flyBodyVel.Parent = root
                flyBodyGyro = Instance.new("BodyGyro")
                flyBodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
                flyBodyGyro.P = 9e4
                flyBodyGyro.Parent = root
            end
            
            flyBodyGyro.CFrame = Camera.CFrame
            local moveDir = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end
            
            flyBodyVel.Velocity = moveDir * Settings.FlySpeed
        else
            if flyBodyVel then flyBodyVel:Destroy() flyBodyVel = nil end
            if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
        end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if Settings.InfiniteJump and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Click TP Logic
local mouse = LocalPlayer:GetMouse()
mouse.Button1Down:Connect(function()
    if Settings.ClickTP and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = mouse.Hit + Vector3.new(0, 3, 0)
    end
end)

-- 3. VISUALS LOGIC (ESP)
local ESPFolder = Instance.new("Folder", CoreGui)
ESPFolder.Name = "FoxnameCyberUltimateESP"

RunService.RenderStepped:Connect(function()
    ESPFolder:ClearAllChildren()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local myRoot = LocalPlayer.Character.HumanoidRootPart

        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local root = plr.Character.HumanoidRootPart
                local dist = math.floor((root.Position - myRoot.Position).Magnitude)
                local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)

                if Settings.ESP_Players then
                    local bb = Instance.new("BillboardGui", ESPFolder)
                    bb.Adornee = root
                    bb.Size = UDim2.new(0, 120, 0, 40)
                    bb.AlwaysOnTop = true

                    local txt = Instance.new("TextLabel", bb)
                    txt.Size = UDim2.new(1, 0, 1, 0)
                    txt.BackgroundTransparency = 1
                    txt.Font = Enum.Font.GothamBold
                    txt.Text = plr.DisplayName .. "\n<font color=\"rgb(255,130,0)\">[" .. dist .. "m]</font>"
                    txt.RichText = true
                    txt.TextColor3 = Color3.fromRGB(255, 255, 255)
                    txt.TextSize = 10
                end

                if Settings.ESP_Boxes then
                    local highlight = Instance.new("Highlight", ESPFolder)
                    highlight.Adornee = plr.Character
                    highlight.FillColor = Color3.fromRGB(255, 130, 0)
                    highlight.FillTransparency = 0.6
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                end
            end
        end
    end
end)

-- 4. UTILS & AUTOMATION LOGIC
workspace.DescendantAdded:Connect(function(obj)
    if Settings.FastPrompt and obj:IsA("ProximityPrompt") then obj.HoldDuration = 0 end
end)

RunService.RenderStepped:Connect(function()
    if Settings.FastPrompt then
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then obj.HoldDuration = 0 end
        end
    end
end)

local vu = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    if Settings.AntiAFK then
        vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end
end)

-- 5. CYBER UI FRAMEWORK SETUP
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "FoxnameCyberUltimate"

local MainShadow = Instance.new("ImageLabel", ScreenGui)
MainShadow.AnchorPoint = Vector2.new(0.5, 0.5)
MainShadow.BackgroundTransparency = 1
MainShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
MainShadow.Size = UDim2.new(0, 680, 0, 440)
MainShadow.Image = "rbxassetid://6014261993"
MainShadow.ImageColor3 = Color3.fromRGB(255, 110, 0)
MainShadow.ImageTransparency = 0.6
MainShadow.ScaleType = Enum.ScaleType.Slice
MainShadow.SliceCenter = Rect.new(49, 49, 459, 459)

local MainFrame = Instance.new("Frame", MainShadow)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(13, 13, 18)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.Size = UDim2.new(0, 640, 0, 400)
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.Draggable = true

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Thickness = 1.5
MainStroke.Color = Color3.fromRGB(255, 130, 0)

-- Header
local Header = Instance.new("Frame", MainFrame)
Header.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
Header.Size = UDim2.new(1, 0, 0, 42)

local Title = Instance.new("TextLabel", Header)
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 15, 0, 0)
Title.Size = UDim2.new(0, 350, 1, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "FOXNAME <font color=\"rgb(255, 130, 0)\">ULTIMATE</font> HUB <font color=\"rgb(120, 120, 140)\">| ALL IN ONE</font>"
Title.RichText = true
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 11
Title.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
CloseBtn.Position = UDim2.new(1, -28, 0.5, -9)
CloseBtn.Size = UDim2.new(0, 18, 0, 18)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 13
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(1, 0)

CloseBtn.MouseButton1Click:Connect(function() MainShadow.Visible = false end)
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.RightControl then
        MainShadow.Visible = not MainShadow.Visible
    end
end)

-- Sidebar
local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
Sidebar.Position = UDim2.new(0, 0, 0, 43)
Sidebar.Size = UDim2.new(0, 145, 1, -43)

local TabListLayout = Instance.new("UIListLayout", Sidebar)
TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabListLayout.Padding = UDim.new(0, 4)

local TabPadding = Instance.new("UIPadding", Sidebar)
TabPadding.PaddingTop = UDim.new(0, 8)
TabPadding.PaddingLeft = UDim.new(0, 6)
TabPadding.PaddingRight = UDim.new(0, 6)

local ContentFolder = Instance.new("Folder", MainFrame)

local function CreateTabFrame(name)
    local Frame = Instance.new("ScrollingFrame", ContentFolder)
    Frame.Name = name .. "TabFrame"
    Frame.BackgroundTransparency = 1
    Frame.Position = UDim2.new(0, 155, 0, 50)
    Frame.Size = UDim2.new(1, -165, 1, -60)
    Frame.CanvasSize = UDim2.new(0, 0, 0, 420)
    Frame.ScrollBarThickness = 3
    Frame.ScrollBarImageColor3 = Color3.fromRGB(255, 130, 0)
    Frame.Visible = false

    local ListLayout = Instance.new("UIListLayout", Frame)
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Padding = UDim.new(0, 6)
    return Frame
end

local TabMovement = CreateTabFrame("Movement")
local TabVisuals  = CreateTabFrame("Visuals")
local TabCombat   = CreateTabFrame("Combat")
local TabAuto     = CreateTabFrame("Automation")
local TabTeleport = CreateTabFrame("Teleport")
local TabUtils    = CreateTabFrame("Utilities")

TabMovement.Visible = true

local Tabs = {}
local function AddTab(name, icon, targetFrame)
    local Btn = Instance.new("TextButton", Sidebar)
    Btn.BackgroundColor3 = (#Tabs == 0) and Color3.fromRGB(255, 130, 0) or Color3.fromRGB(20, 20, 28)
    Btn.Size = UDim2.new(1, 0, 0, 30)
    Btn.Font = Enum.Font.GothamBold
    Btn.Text = " " .. icon .. " " .. name
    Btn.TextColor3 = (#Tabs == 0) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 130, 150)
    Btn.TextSize = 10
    Btn.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 5)

    table.insert(Tabs, {Button = Btn, Frame = targetFrame})

    Btn.MouseButton1Click:Connect(function()
        for _, tab in ipairs(Tabs) do
            tab.Frame.Visible = false
            TweenService:Create(tab.Button, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(20, 20, 28), TextColor3 = Color3.fromRGB(130, 130, 150)}):Play()
        end
        targetFrame.Visible = true
        TweenService:Create(Btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(255, 130, 0), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    end)
end

AddTab("Movement", "🏃", TabMovement)
AddTab("Visuals", "👁️", TabVisuals)
AddTab("Combat", "⚔️", TabCombat)
AddTab("Automation", "⚡", TabAuto)
AddTab("Teleport", "🌐", TabTeleport)
AddTab("Utilities", "⚙️", TabUtils)

-- COMPONENT BUILDERS
local function AddSection(parent, titleText)
    local Frame = Instance.new("Frame", parent)
    Frame.BackgroundTransparency = 1
    Frame.Size = UDim2.new(1, -10, 0, 16)
    local Label = Instance.new("TextLabel", Frame)
    Label.BackgroundTransparency = 1
    Label.Size = UDim2.new(1, 0, 1, 0)
    Label.Font = Enum.Font.GothamBold
    Label.Text = string.upper(titleText)
    Label.TextColor3 = Color3.fromRGB(255, 140, 0)
    Label.TextSize = 9
    Label.TextXAlignment = Enum.TextXAlignment.Left
end

local function AddToggle(parent, text, defaultState, callback)
    local Container = Instance.new("Frame", parent)
    Container.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    Container.Size = UDim2.new(1, -10, 0, 32)
    Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 5)

    local Label = Instance.new("TextLabel", Container)
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.Size = UDim2.new(0.7, 0, 1, 0)
    Label.Font = Enum.Font.GothamMedium
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(220, 220, 235)
    Label.TextSize = 10
    Label.TextXAlignment = Enum.TextXAlignment.Left

    local Switch = Instance.new("TextButton", Container)
    Switch.BackgroundColor3 = defaultState and Color3.fromRGB(255, 130, 0) or Color3.fromRGB(35, 35, 50)
    Switch.Position = UDim2.new(1, -40, 0.5, -7)
    Switch.Size = UDim2.new(0, 30, 0, 14)
    Switch.Text = ""
    Instance.new("UICorner", Switch).CornerRadius = UDim.new(1, 0)

    local Dot = Instance.new("Frame", Switch)
    Dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Dot.Position = defaultState and UDim2.new(1, -12, 0.5, -4) or UDim2.new(0, 2, 0.5, -4)
    Dot.Size = UDim2.new(0, 8, 0, 8)
    Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

    local state = defaultState
    Switch.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(Switch, TweenInfo.new(0.12), {BackgroundColor3 = state and Color3.fromRGB(255, 130, 0) or Color3.fromRGB(35, 35, 50)}):Play()
        TweenService:Create(Dot, TweenInfo.new(0.12), {Position = state and UDim2.new(1, -12, 0.5, -4) or UDim2.new(0, 2, 0.5, -4)}):Play()
        callback(state)
    end)
end

local function AddSlider(parent, text, minVal, maxVal, defaultVal, callback)
    local Container = Instance.new("Frame", parent)
    Container.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    Container.Size = UDim2.new(1, -10, 0, 42)
    Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 5)

    local Label = Instance.new("TextLabel", Container)
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 10, 0, 3)
    Label.Size = UDim2.new(0.6, 0, 0, 15)
    Label.Font = Enum.Font.GothamMedium
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(220, 220, 235)
    Label.TextSize = 10
    Label.TextXAlignment = Enum.TextXAlignment.Left

    local ValueDisplay = Instance.new("TextLabel", Container)
    ValueDisplay.BackgroundTransparency = 1
    ValueDisplay.Position = UDim2.new(1, -55, 0, 3)
    ValueDisplay.Size = UDim2.new(0, 45, 0, 15)
    ValueDisplay.Font = Enum.Font.GothamBold
    ValueDisplay.Text = tostring(defaultVal)
    ValueDisplay.TextColor3 = Color3.fromRGB(255, 140, 0)
    ValueDisplay.TextSize = 10
    ValueDisplay.TextXAlignment = Enum.TextXAlignment.Right

    local SliderBar = Instance.new("Frame", Container)
    SliderBar.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    SliderBar.Position = UDim2.new(0, 10, 0, 25)
    SliderBar.Size = UDim2.new(1, -20, 0, 5)
    Instance.new("UICorner", SliderBar).CornerRadius = UDim.new(1, 0)

    local Fill = Instance.new("Frame", SliderBar)
    Fill.BackgroundColor3 = Color3.fromRGB(255, 130, 0)
    Fill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

    local isDragging = false
    local function Update(input)
        local pos = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
        local val = math.floor(minVal + (maxVal - minVal) * pos)
        Fill.Size = UDim2.new(pos, 0, 1, 0)
        ValueDisplay.Text = tostring(val)
        callback(val)
    end

    SliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then isDragging = true Update(input) end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then Update(input) end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then isDragging = false end
    end)
end

local function AddButton(parent, text, callback)
    local Btn = Instance.new("TextButton", parent)
    Btn.BackgroundColor3 = Color3.fromRGB(25, 25, 36)
    Btn.Size = UDim2.new(1, -10, 0, 30)
    Btn.Font = Enum.Font.GothamMedium
    Btn.Text = text
    Btn.TextColor3 = Color3.fromRGB(240, 240, 240)
    Btn.TextSize = 10
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 5)
    local Stroke = Instance.new("UIStroke", Btn)
    Stroke.Thickness = 1
    Stroke.Color = Color3.fromRGB(45, 45, 60)
    Btn.MouseButton1Click:Connect(callback)
end

-- POPULATING TABS

-- 1. MOVEMENT
AddSection(TabMovement, "Physics & Locomotion")
AddSlider(TabMovement, "WalkSpeed (Tốc độ)", 16, 500, Settings.Speed, function(v) Settings.Speed = v end)
AddSlider(TabMovement, "JumpPower (Lực nhảy)", 50, 400, Settings.JumpPower, function(v) Settings.JumpPower = v end)
AddSlider(TabMovement, "Gravity (Trọng lực)", 0, 196, Settings.Gravity, function(v) Settings.Gravity = v end)
AddToggle(TabMovement, "Noclip (Xuyên tường)", Settings.Noclip, function(v) Settings.Noclip = v end)
AddToggle(TabMovement, "Infinite Jump (Nhảy vô hạn)", Settings.InfiniteJump, function(v) Settings.InfiniteJump = v end)
AddSection(TabMovement, "Flight Controls")
AddToggle(TabMovement, "Enable Fly (Bật bay)", Settings.Fly, function(v) Settings.Fly = v end)
AddSlider(TabMovement, "Fly Speed (Tốc độ bay)", 10, 300, Settings.FlySpeed, function(v) Settings.FlySpeed = v end)

-- 2. VISUALS
AddSection(TabVisuals, "ESP System")
AddToggle(TabVisuals, "Player Name Tags (Hiện tên)", Settings.ESP_Players, function(v) Settings.ESP_Players = v end)
AddToggle(TabVisuals, "Chams / Box ESP (Hiện khung)", Settings.ESP_Boxes, function(v) Settings.ESP_Boxes = v end)

-- 3. COMBAT
AddSection(TabCombat, "Aimbot Assistance")
AddToggle(TabCombat, "Camera Aimbot (Giữ chuột phải)", Settings.Aimbot, function(v) Settings.Aimbot = v end)
AddToggle(TabCombat, "Show FOV Circle (Hiện vòng FOV)", Settings.ShowFOV, function(v) Settings.ShowFOV = v end)
AddSlider(TabCombat, "Aimbot FOV (Phạm vi)", 10, 500, Settings.AimFOV, function(v) Settings.AimFOV = v end)

-- 4. AUTOMATION
AddSection(TabAuto, "Automation Tools")
AddToggle(TabAuto, "Fast Prompt (Tương tác nhanh)", Settings.FastPrompt, function(v) Settings.FastPrompt = v end)
AddToggle(TabAuto, "Instant Brake (Dừng tức thì)", Settings.InstantBrake, function(v) Settings.InstantBrake = v end)
AddToggle(TabAuto, "Anti-AFK (Chống AFK)", Settings.AntiAFK, function(v) Settings.AntiAFK = v end)

-- 5. TELEPORT
AddSection(TabTeleport, "Teleport Controls")
AddToggle(TabTeleport, "Click TP (Ctrl + Click)", Settings.ClickTP, function(v) Settings.ClickTP = v end)

-- 6. UTILITIES
AddSection(TabUtils, "System Info")
AddButton(TabUtils, "Close UI (Tắt giao diện)", function() MainShadow.Visible = false end)
AddButton(TabUtils, "Destroy UI (Xóa UI)", function() CoreGui.FoxnameCyberUltimate:Destroy() end)