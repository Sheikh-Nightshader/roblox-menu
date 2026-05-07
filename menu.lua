local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- UI 
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 200, 0, 350)
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
    speed = 60,
    espColor = Color3.new(0, 1, 0) -- Default Green
}
local keys = {}
local uiVisible = true

-- Toggle UI with RightShift
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.RightShift then
        uiVisible = not uiVisible
        MainFrame.Visible = uiVisible
    end
end)

-- Aimbot Logic (Crosshair Lock)
local function getNearestPlayer()
    local closestPlayer = nil
    local shortestDistance = 400
    local mousePos = UserInputService:GetMouseLocation()

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            local head = plr.Character.Head
            local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
            
            if onScreen and pos.Z > 0 then
                local screenPos = Vector2.new(pos.X, pos.Y)
                local magnitude = (screenPos - mousePos).Magnitude
                
                if magnitude < shortestDistance then
                    closestPlayer = plr
                    shortestDistance = magnitude
                end
            end
        end
    end
    return closestPlayer
end

-- ESP Rendering
local boxes = {}
local function createESP(plr)
    local box = Drawing.new("Square")
    box.Visible = false
    box.Thickness = 1.5
    box.Filled = false
    boxes[plr] = box
end

-- In/Listeners
UserInputService.InputBegan:Connect(function(k, gpe) if not gpe then keys[k.KeyCode.Name] = true end end)
UserInputService.InputEnded:Connect(function(k, gpe) keys[k.KeyCode.Name] = false end)

-- Main Loop
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    -- Noclip
    if settings.noclip and char then
        for _, p in pairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end

    -- Aimbot (Follows Crosshair)
    if settings.aimbot then
        local target = getNearestPlayer()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Character.Head.Position)
        end
    end

    -- Flight
    if settings.fly and hrp then
        local move = Vector3.new(0, 0, 0)
        if keys.W then move = move + Camera.CFrame.LookVector end
        if keys.S then move = move - Camera.CFrame.LookVector end
        if keys.A then move = move - Camera.CFrame.RightVector end
        if keys.D then move = move + Camera.CFrame.RightVector end
        hrp.Velocity = move * settings.speed
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


local function createBtn(t, callback, order)
    local btn = Instance.new("TextButton", MainFrame)
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.Position = UDim2.new(0.05, 0, 0, 40 + (order * 40))
    btn.Text = t
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.BorderSizePixel = 0
    btn.MouseButton1Click:Connect(callback)
end

createBtn("Toggle Fly", function() settings.fly = not settings.fly end, 0)
createBtn("Toggle Noclip", function() settings.noclip = not settings.noclip end, 1)
createBtn("Toggle ESP", function() settings.esp = not settings.esp end, 2)
createBtn("ESP: Green/Red", function() 
    if settings.espColor == Color3.new(0, 1, 0) then
        settings.espColor = Color3.new(1, 0, 0)
    else
        settings.espColor = Color3.new(0, 1, 0)
    end
end, 3)
createBtn("Toggle Aimbot", function() settings.aimbot = not settings.aimbot end, 4)

-- Info Label
local Info = Instance.new("TextLabel", MainFrame)
Info.Size = UDim2.new(1, 0, 0, 20)
Info.Position = UDim2.new(0, 0, 1, -20)
Info.Text = "Press RightShift to Hide/Show"
Info.TextColor3 = Color3.new(0.7, 0.7, 0.7)
Info.BackgroundTransparency = 1
Info.TextSize = 12