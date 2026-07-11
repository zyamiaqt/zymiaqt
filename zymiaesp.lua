--[[
    Optimized & Cleaned ESP Script with Name & Distance
    Features: Box, Fill, Skeleton, Health, Chams, Names/Distance, Smooth UI Dragging (Insert to Toggle)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local ESP_Config = {
    Box = false,
    Fill = false,
    Skeleton = false,
    Health = false,
    Chams = false,
    Names = false, -- New Name & Distance toggle
    
    BoxColor = Color3.fromRGB(255, 0, 0),
    FillColor = Color3.fromRGB(255, 0, 0),
    SkeletonColor = Color3.fromRGB(255, 255, 255),
    HealthColor = Color3.fromRGB(0, 255, 0),
    ChamsColor = Color3.fromRGB(255, 0, 255),
    NamesColor = Color3.fromRGB(255, 255, 255),
    
    FillTransparency = 0.5,
    ChamsTransparency = 0.5
}

local PresetColors = {
    Color3.fromRGB(255, 0, 0),
    Color3.fromRGB(0, 255, 0),
    Color3.fromRGB(0, 0, 255),
    Color3.fromRGB(255, 255, 0),
    Color3.fromRGB(255, 0, 255),
    Color3.fromRGB(0, 255, 255),
    Color3.fromRGB(255, 255, 255)
}

local Cache = {}

local function CreateDrawing(class, properties)
    local draw = Drawing.new(class)
    for prop, val in pairs(properties) do
        draw[prop] = val
    end
    return draw
end

local function ClearESP(player)
    if Cache[player] then
        for _, obj in pairs(Cache[player].Drawings) do
            obj:Remove()
        end
        if Cache[player].Highlight then
            Cache[player].Highlight:Destroy()
        end
        Cache[player] = nil
    end
end

local function SetupESP(player)
    if player == LocalPlayer then return end
    
    Cache[player] = {
        Drawings = {
            Box = CreateDrawing("Square", {Thickness = 1.5, Filled = false, Visible = false, ZIndex = 2}),
            BoxOutline = CreateDrawing("Square", {Thickness = 2.5, Filled = false, Visible = false, Color = Color3.new(0,0,0), ZIndex = 1}),
            BoxFill = CreateDrawing("Square", {Filled = true, Visible = false, ZIndex = 0}),
            HealthBar = CreateDrawing("Square", {Filled = true, Visible = false, Color = ESP_Config.HealthColor, ZIndex = 2}),
            HealthBg = CreateDrawing("Square", {Filled = true, Visible = false, Color = Color3.new(0,0,0), ZIndex = 1}),
            
            HeadTorso = CreateDrawing("Line", {Thickness = 1.5, Visible = false}),
            TorsoLeftArm = CreateDrawing("Line", {Thickness = 1.5, Visible = false}),
            TorsoRightArm = CreateDrawing("Line", {Thickness = 1.5, Visible = false}),
            TorsoLeftLeg = CreateDrawing("Line", {Thickness = 1.5, Visible = false}),
            TorsoRightLeg = CreateDrawing("Line", {Thickness = 1.5, Visible = false}),
            
            NameTag = CreateDrawing("Text", {Size = 13, Center = true, Outline = true, Visible = false, Color = ESP_Config.NamesColor, ZIndex = 3})
        },
        Highlight = nil
    }
end

-- Render Connection
RunService.RenderStepped:Connect(function()
    local localChar = LocalPlayer.Character
    local localHrp = localChar and localChar:FindFirstChild("HumanoidRootPart")

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not Cache[player] then SetupESP(player) end
        
        local data = Cache[player]
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        
        if hrp and hum and hum.Health > 0 then
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            
            if onScreen then
                local head = char:FindFirstChild("Head")
                local headPos = head and Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0)) or Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 2, 0))
                local legPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                
                local height = math.abs(headPos.Y - legPos.Y)
                local width = height * 0.6
                local tlX = pos.X - (width / 2)
                local tlY = headPos.Y
                
                -- Box Drawing Logic
                if ESP_Config.Box then
                    data.Drawings.Box.Size = Vector2.new(width, height)
                    data.Drawings.Box.Position = Vector2.new(tlX, tlY)
                    data.Drawings.Box.Color = ESP_Config.BoxColor
                    data.Drawings.Box.Visible = true
                    
                    data.Drawings.BoxOutline.Size = data.Drawings.Box.Size
                    data.Drawings.BoxOutline.Position = data.Drawings.Box.Position
                    data.Drawings.BoxOutline.Visible = true
                else
                    data.Drawings.Box.Visible = false
                    data.Drawings.BoxOutline.Visible = false
                end
                
                -- Box Fill Logic
                if ESP_Config.Fill then
                    data.Drawings.BoxFill.Size = Vector2.new(width, height)
                    data.Drawings.BoxFill.Position = Vector2.new(tlX, tlY)
                    data.Drawings.BoxFill.Color = ESP_Config.FillColor
                    data.Drawings.BoxFill.Transparency = ESP_Config.FillTransparency
                    data.Drawings.BoxFill.Visible = true
                else
                    data.Drawings.BoxFill.Visible = false
                end
                
                -- Health Bar Logic
                if ESP_Config.Health then
                    local healthPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    local barHeight = height * healthPercent
                    
                    data.Drawings.HealthBg.Size = Vector2.new(3, height)
                    data.Drawings.HealthBg.Position = Vector2.new(tlX - 6, tlY)
                    data.Drawings.HealthBg.Visible = true
                    
                    data.Drawings.HealthBar.Size = Vector2.new(2, barHeight)
                    data.Drawings.HealthBar.Position = Vector2.new(tlX - 5, tlY + (height - barHeight))
                    data.Drawings.HealthBar.Color = ESP_Config.HealthColor
                    data.Drawings.HealthBar.Visible = true
                else
                    data.Drawings.HealthBar.Visible = false
                    data.Drawings.HealthBg.Visible = false
                end
                
                -- Name & Distance Logic
                if ESP_Config.Names then
                    local distance = localHrp and math.round((localHrp.Position - hrp.Position).Magnitude) or 0
                    data.Drawings.NameTag.Text = string.format("%s [%d studs]", player.Name, distance)
                    data.Drawings.NameTag.Position = Vector2.new(pos.X, tlY - 15)
                    data.Drawings.NameTag.Color = ESP_Config.NamesColor
                    data.Drawings.NameTag.Visible = true
                else
                    data.Drawings.NameTag.Visible = false
                end
                
                -- Skeleton Logic
                if ESP_Config.Skeleton then
                    local function DrawBone(line, p1, p2)
                        if p1 and p2 then
                            local w2p1, os1 = Camera:WorldToViewportPoint(p1.Position)
                            local w2p2, os2 = Camera:WorldToViewportPoint(p2.Position)
                            if os1 and os2 then
                                line.From = Vector2.new(w2p1.X, w2p1.Y)
                                line.To = Vector2.new(w2p2.X, w2p2.Y)
                                line.Color = ESP_Config.SkeletonColor
                                line.Visible = true
                                return
                            end
                        end
                        line.Visible = false
                    end
                    
                    local upperTorso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
                    local leftArm = char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")
                    local rightArm = char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")
                    local leftLeg = char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg")
                    local rightLeg = char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg")
                    
                    DrawBone(data.Drawings.HeadTorso, head, upperTorso)
                    DrawBone(data.Drawings.TorsoLeftArm, upperTorso, leftArm)
                    DrawBone(data.Drawings.TorsoRightArm, upperTorso, rightArm)
                    DrawBone(data.Drawings.TorsoLeftLeg, upperTorso, leftLeg)
                    DrawBone(data.Drawings.TorsoRightLeg, upperTorso, rightLeg)
                else
                    for _, bone in pairs({data.Drawings.HeadTorso, data.Drawings.TorsoLeftArm, data.Drawings.TorsoRightArm, data.Drawings.TorsoLeftLeg, data.Drawings.TorsoRightLeg}) do
                        bone.Visible = false
                    end
                end
                
                -- Chams Logic
                if ESP_Config.Chams then
                    if not data.Highlight then
                        local hl = Instance.new("Highlight")
                        hl.Adornee = char
                        hl.Parent = char
                        data.Highlight = hl
                    end
                    data.Highlight.FillColor = ESP_Config.ChamsColor
                    data.Highlight.FillTransparency = ESP_Config.ChamsTransparency
                    data.Highlight.OutlineTransparency = 1
                    data.Highlight.Enabled = true
                elseif data.Highlight then
                    data.Highlight.Enabled = false
                end
            else
                for _, obj in pairs(data.Drawings) do obj.Visible = false end
                if data.Highlight then data.Highlight.Enabled = false end
            end
        else
            for _, obj in pairs(data.Drawings) do obj.Visible = false end
            if data.Highlight then data.Highlight.Enabled = false end
        end
    end
end)

Players.PlayerRemoving:Connect(ClearESP)

-- GUI SETUP
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AjnurHubESP"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Adjusted height to 345 to fit the extra name option perfectly
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 340, 0, 345)
frame.Position = UDim2.new(0.5, -170, 0.5, -172)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 0, 45)
label.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
label.Text = "Ajnur Hub - Click to Cycle Colors"
label.TextColor3 = Color3.fromRGB(255, 215, 0)
label.Font = Enum.Font.GothamBold
label.TextSize = 14
label.Parent = frame

local corner2 = Instance.new("UICorner")
corner2.CornerRadius = UDim.new(0, 10)
corner2.Parent = label

-- Modern UI Dragging Implementation
local dragging, dragInput, dragStart, startPos
label.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

label.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local function makeToggle(text, pos, configKey)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 130, 0, 35)
    btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    btn.Text = text .. " [OFF]"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.Parent = frame
    
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        ESP_Config[configKey] = not ESP_Config[configKey]
        if ESP_Config[configKey] then
            btn.Text = text .. " [ON]"
            btn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        else
            btn.Text = text .. " [OFF]"
            btn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        end
    end)
end

local function makeColorCycleButton(text, pos, configKey)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 130, 0, 35)
    btn.Position = pos
    btn.BackgroundColor3 = ESP_Config[configKey]
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(0, 0, 0)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.Parent = frame
    
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn
    
    local currentIndex = 1
    btn.MouseButton1Click:Connect(function()
        currentIndex = currentIndex + 1
        if currentIndex > #PresetColors then currentIndex = 1 end
        local selectedColor = PresetColors[currentIndex]
        ESP_Config[configKey] = selectedColor
        btn.BackgroundColor3 = selectedColor
        
        if selectedColor.R + selectedColor.G + selectedColor.B < 1.2 then
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.TextColor3 = Color3.fromRGB(0, 0, 0)
        end
    end)
end

-- Component Initialization (Added Names to array)
local features = {"Box", "Fill", "Skeleton", "Health", "Chams", "Names"}
local displayNames = {"BOX", "BOX FILL", "SKELETON", "HEALTH", "CHAMS", "NAMES & DIST"}

for i, feature in ipairs(features) do
    local yPos = 65 + ((i - 1) * 45)
    makeToggle(displayNames[i], UDim2.new(0, 20, 0, yPos), feature)
    makeColorCycleButton("CHANGE COLOR", UDim2.new(0, 180, 0, yPos), feature .. "Color")
end

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, 0, 0, 25)
info.Position = UDim2.new(0, 0, 1, -25)
info.BackgroundTransparency = 1
info.Text = "Press Insert to hide UI"
info.TextColor3 = Color3.fromRGB(140, 140, 150)
info.Font = Enum.Font.Gotham
info.TextSize = 10
info.Parent = frame

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Insert then
        frame.Visible = not frame.Visible
    end
end)
