local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- UI 
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 200, 0, 500) -- Increased height for extra toggles
MainFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "Sheikhs Admin Tools"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)

-- States
local settings = { 
    fly = false, 
    noclip = false, 
    esp = false, 
    aimbot = false, 
    
    -- Speed/Jump Logic
    speedEnabled = false,
    speedVal = 60,
    jumpEnabled = false,
    jumpVal = 200,
    
    espColor = Color3.new(0, 1, 0),
    fov = 150,
    holdKey = Enum.UserInputType.MouseButton2 
}
local keys = {}
local uiVisible = true

-- FOV Circle
local Circle = Drawing.new("Circle")
Circle.Radius = settings.fov
Circle.Thickness = 1
Circle.Color = Color3.fromRGB(255, 0, 0)
Circle.Visible = false 
Circle.Transparency = 0.5
Circle.Filled = false

-- Toggle ONLY UI Visibility (Mods stay active)
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.RightShift then
        uiVisible = not uiVisible
        MainFrame.Visible = uiVisible
    end
end)

-- Aimbot Logic
local function getNearestPlayer()
    local closestPlayer = nil
    local shortestDistance = settings.fov
    local ScreenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            local head = plr.Character.Head
            local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen and pos.Z > 0 then
                local magnitude = (Vector2.new(pos.X, pos.Y) - ScreenCenter).Magnitude
                if magnitude < shortestDistance then
                    closestPlayer = plr
                    shortestDistance = magnitude
                end
            end
        end
    end
    return closestPlayer
end

-- ESP Setup
local boxes = {}
local function createESP(plr)
    local box = Drawing.new("Square")
    box.Visible = false
    box.Thickness = 1.5
    box.Filled = false
    boxes[plr] = box
end

UserInputService.InputBegan:Connect(function(k, gpe) if not gpe then keys[k.KeyCode.Name] = true end end)
UserInputService.InputEnded:Connect(function(k, gpe) keys[k.KeyCode.Name] = false end)

-- Main Render Loop
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    local ScreenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    -- Visuals stay active if toggled on, even if menu is hidden
    Circle.Position = ScreenCenter
    Circle.Visible = settings.aimbot

    -- Noclip
    if settings.noclip and char then
        for _, p in pairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end

    -- Super Speed Toggle Logic
    if hum then
        hum.WalkSpeed = settings.speedEnabled and settings.speedVal or 16
        hum.JumpPower = settings.jumpEnabled and settings.jumpVal or 50
        hum.UseJumpPower = true 
    end

    -- Aimbot Lock
    if settings.aimbot and UserInputService:IsMouseButtonPressed(settings.holdKey) then
        local target = getNearestPlayer()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, target.Character.Head.Position)
        end
    end

    -- Flight
    if settings.fly and hrp then
        local move = Vector3.new(0, 0, 0)
        if keys.W then move = move + Camera.CFrame.LookVector end
        if keys.S then move = move - Camera.CFrame.LookVector end
        if keys.A then move = move - Camera.CFrame.RightVector end
        if keys.D then move = move + Camera.CFrame.RightVector end
        hrp.Velocity = move * (settings.speedEnabled and settings.speedVal or 60)
        if move.Magnitude == 0 then hrp.Velocity = Vector3.new(0, 0.1, 0) end 
    end

    -- ESP Rendering
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            if not boxes[plr] then createESP(plr) end
            local targetHrp = plr.Character.HumanoidRootPart
            local pos, onScreen = Camera:WorldToViewportPoint(targetHrp.Position)
            
            if onScreen and settings.esp then
                local dist = (Camera.CFrame.Position - targetHrp.Position).Magnitude
                local sizeX, sizeY = 4000/dist, 6000/dist
                boxes[plr].Visible = true
                boxes[plr].Color = settings.espColor
                boxes[plr].Size = Vector2.new(sizeX, sizeY)
                boxes[plr].Position = Vector2.new(pos.X - (sizeX/2), pos.Y - (sizeY/2))
            else
                boxes[plr].Visible = false
            end
        elseif boxes[plr] then
            boxes[plr].Visible = false
        end
    end
end)

-- UI Helper
local function createBtn(t, callback, order)
    local btn = Instance.new("TextButton", MainFrame)
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.Position = UDim2.new(0.05, 0, 0, 40 + (order * 40))
    btn.Text = t
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.BorderSizePixel = 0
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Controls
createBtn("Toggle Fly", function() settings.fly = not settings.fly end, 0)
createBtn("Toggle Noclip", function() settings.noclip = not settings.noclip end, 1)
createBtn("Toggle ESP", function() settings.esp = not settings.esp end, 2)
createBtn("Toggle Aimbot", function() settings.aimbot = not settings.aimbot end, 3)

local speedBtn = createBtn("Speed: ON/OFF", function(self) 
    settings.speedEnabled = not settings.speedEnabled 
    self.Text = settings.speedEnabled and "Speed: ON" or "Speed: OFF"
    self.BackgroundColor3 = settings.speedEnabled and Color3.fromRGB(45, 80, 45) or Color3.fromRGB(60, 60, 60)
end, 4)

local jumpBtn = createBtn("Jump: ON/OFF", function(self) 
    settings.jumpEnabled = not settings.jumpEnabled 
    self.Text = settings.jumpEnabled and "Jump: ON" or "Jump: OFF"
    self.BackgroundColor3 = settings.jumpEnabled and Color3.fromRGB(80, 45, 45) or Color3.fromRGB(60, 60, 60)
end, 5)

-- Speed Input Box
local SpeedInput = Instance.new("TextBox", MainFrame)
SpeedInput.Size = UDim2.new(0.9, 0, 0, 35)
SpeedInput.Position = UDim2.new(0.05, 0, 0, 40 + (6 * 40))
SpeedInput.Text = "Value: 60"
SpeedInput.PlaceholderText = "Set Speed Num"
SpeedInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
SpeedInput.TextColor3 = Color3.new(1, 1, 1)
SpeedInput.FocusLost:Connect(function()
    local val = tonumber(SpeedInput.Text:match("%d+"))
    if val then settings.speedVal = val SpeedInput.Text = "Value: "..val end
end)

-- Jump Input Box
local JumpInput = Instance.new("TextBox", MainFrame)
JumpInput.Size = UDim2.new(0.9, 0, 0, 35)
JumpInput.Position = UDim2.new(0.05, 0, 0, 40 + (7 * 40))
JumpInput.Text = "Value: 200"
JumpInput.PlaceholderText = "Set Jump Num"
JumpInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
JumpInput.TextColor3 = Color3.new(1, 1, 1)
JumpInput.FocusLost:Connect(function()
    local val = tonumber(JumpInput.Text:match("%d+"))
    if val then settings.jumpVal = val JumpInput.Text = "Value: "..val end
end)

-- Info Label
local Info = Instance.new("TextLabel", MainFrame)
Info.Size = UDim2.new(1, 0, 0, 20)
Info.Position = UDim2.new(0, 0, 1, -20)
Info.Text = "RightShift = Hide Menu Only"
Info.TextColor3 = Color3.new(0.7, 0.7, 0.7)
Info.BackgroundTransparency = 1
Info.TextSize = 11
