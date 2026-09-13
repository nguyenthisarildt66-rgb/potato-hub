local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local TargetSpeed = 120 -- Mốc tốc độ 120 mượt mà, tránh bị server bẫy

local function PhysicalSpeedBypass(character)
    local root = character:WaitForChild("HumanoidRootPart")
    local hum = character:WaitForChild("Humanoid")
    
    -- Xóa BodyVelocity cũ nếu có để tránh xung đột
    if root:FindFirstChild("PhysicsSpeedBV") then
        root.PhysicsSpeedBV:Destroy()
    end
    
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Name = "PhysicsSpeedBV"
    bodyVelocity.MaxForce = Vector3.new(100000, 0, 100000) -- Chỉ tác động lực theo chiều ngang (X, Z)
    bodyVelocity.Velocity = Vector3.zero
    bodyVelocity.Parent = root

    RunService.RenderStepped:Connect(function()
        if hum and hum.Health > 0 and hum.MoveDirection.Magnitude > 0 then
            -- Tạo lực đẩy theo hướng di chuyển mượt mà
            bodyVelocity.Velocity = hum.MoveDirection * TargetSpeed
        else
            bodyVelocity.Velocity = Vector3.zero
        end
    end)
end

if LocalPlayer.Character then
    pcall(PhysicalSpeedBypass, LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.3)
    pcall(PhysicalSpeedBypass, character)
end)