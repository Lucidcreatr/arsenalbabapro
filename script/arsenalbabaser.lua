if PlaceId == 286090429 then

--!strict

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local UserInput     = game:GetService("UserInputService")
local LocalPlayer   = Players.LocalPlayer
local Mouse         = LocalPlayer:GetMouse()
local Camera        = workspace.CurrentCamera

local Character     = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid      = Character:WaitForChild("Humanoid")
local RootPart      = Character:WaitForChild("HumanoidRootPart")

-- UI KURULUMU
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ArsenalHackUI"
ScreenGui.Parent = game.CoreGui

local Frame = Instance.new("Frame")
Frame.Name = "MainFrame"
Frame.Parent = ScreenGui
Frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
Frame.Position = UDim2.new(0.8,0,0.2,0)
Frame.Size = UDim2.new(0,220,0,350)
Frame.Active = true
Frame.Draggable = true

local UIList = Instance.new("UIListLayout")
UIList.Parent = Frame
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0,5)

-- Durumlar
local states = {
    bunnyHop   = false,
    fly        = false,
    speed      = false,
    hitbox     = false,
    aimAssist  = false,
    esp        = false,
}

-- Hitbox Orijinal Boyutlar
local originalSizes = {}

-- Takım kontrolü
local function isEnemy(pl)
    local lpTeam = LocalPlayer.Team
    return pl.Team ~= lpTeam
end

-- Hitbox büyütme fonksiyonu (RagdollRoot ve Head kontrol)
local function toggleHitbox(on)
    states.hitbox = on
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and pl.Character and isEnemy(pl) then
            local char = pl.Character
            local head = char:FindFirstChild("Head") or char:FindFirstChild("RagdollRoot")
            if head then
                if on then
                    if not originalSizes[head] then
                        originalSizes[head] = head.Size
                        head.Size = head.Size * 3
                    end
                else
                    if originalSizes[head] then
                        head.Size = originalSizes[head]
                        originalSizes[head] = nil
                    end
                end
            end
        end
    end
end

-- Aim Assist: En yakın düşmana bakış
local function getClosestTarget(maxDist)
    maxDist = maxDist or 150
    local closest = nil
    local shortestDist = math.huge
    local mousePos = Vector2.new(Mouse.X, Mouse.Y)
    
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and pl.Character and isEnemy(pl) then
            local char = pl.Character
            local head = char:FindFirstChild("Head") or char:FindFirstChild("RagdollRoot")
            if head then
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < shortestDist and dist <= maxDist then
                        shortestDist = dist
                        closest = head
                    end
                end
            end
        end
    end
    
    return closest
end

-- Aim Assist toggle ve tuşla aktivasyon
local aimLoop
local function toggleAimAssist(on)
    states.aimAssist = on
    if on then
        aimLoop = RunService.RenderStepped:Connect(function()
            -- Sürekli yönlendirme yapılmaz, E tuşuyla tetiklenecek, burası kapalı bırakılabilir
        end)
    else
        if aimLoop then aimLoop:Disconnect() end
    end
end

-- E tuşuna basınca en yakın hedefe bakış at
UserInput.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.E and states.aimAssist then
        local target = getClosestTarget(200)
        if target then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        end
    end
end)

-- ESP — basit kutu kullanımı için Drawing API (2D kutu)
local espBoxes = {}
local function toggleESP(on)
    states.esp = on
    if on then
        RunService.RenderStepped:Connect(function()
            for _, pl in ipairs(Players:GetPlayers()) do
                if pl ~= LocalPlayer and pl.Character and isEnemy(pl) then
                    local char = pl.Character
                    local head = char:FindFirstChild("Head") or char:FindFirstChild("RagdollRoot")
                    if head then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                        if onScreen then
                            local size = 40
                            if not espBoxes[pl] then
                                local box = Drawing.new("Square")
                                box.Color = Color3.new(1,0,0)
                                box.Thickness = 2
                                box.Filled = false
                                espBoxes[pl] = box
                            end
                            local box = espBoxes[pl]
                            box.Position = Vector2.new(screenPos.X - size/2, screenPos.Y - size/2)
                            box.Size = Vector2.new(size, size)
                            box.Visible = true
                        else
                            if espBoxes[pl] then espBoxes[pl].Visible = false end
                        end
                    end
                else
                    if espBoxes[pl] then
                        espBoxes[pl].Visible = false
                    end
                end
            end
        end)
    else
        for _, box in pairs(espBoxes) do
            box.Visible = false
            box:Remove()
        end
        espBoxes = {}
    end
end

-- BunnyHop toggle
local bunnyHopConn
local function toggleBunnyHop(on)
    states.bunnyHop = on
    if on then
        bunnyHopConn = RunService.Heartbeat:Connect(function()
            if Humanoid.FloorMaterial ~= Enum.Material.Air then
                Humanoid.Jump = true
            end
        end)
    else
        if bunnyHopConn then bunnyHopConn:Disconnect() end
    end
end

-- Speed toggle
local defaultSpeed = Humanoid.WalkSpeed
local function toggleSpeed(on)
    states.speed = on
    if on then
        Humanoid.WalkSpeed = defaultSpeed * 2
    else
        Humanoid.WalkSpeed = defaultSpeed
    end
end

-- Fly toggle
local flyLoop
local function toggleFly(on)
    states.fly = on
    if on then
        local bodyVel = Instance.new("BodyVelocity", RootPart)
        bodyVel.Name = "FlyVelocity"
        bodyVel.MaxForce = Vector3.new(1e5,1e5,1e5)
        bodyVel.Velocity = Vector3.new(0,0,0)
        flyLoop = RunService.RenderStepped:Connect(function()
            local camCFrame = Camera.CFrame
            local dir = Vector3.new()
            if UserInput:IsKeyDown(Enum.KeyCode.W) then dir = dir + camCFrame.LookVector end
            if UserInput:IsKeyDown(Enum.KeyCode.S) then dir = dir - camCFrame.LookVector end
            if UserInput:IsKeyDown(Enum.KeyCode.A) then dir = dir - camCFrame.RightVector end
            if UserInput:IsKeyDown(Enum.KeyCode.D) then dir = dir + camCFrame.RightVector end
            if UserInput:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
            if UserInput:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
            bodyVel.Velocity = dir * 50
        end)
    else
        if flyLoop then flyLoop:Disconnect() end
        local bv = RootPart:FindFirstChild("FlyVelocity")
        if bv then bv:Destroy() end
    end
end

-- Toggle UI oluşturucu
local function createToggle(name, callback)
    local btnFrame = Instance.new("Frame", Frame)
    btnFrame.Size = UDim2.new(1,0,0,35)
    btnFrame.BackgroundColor3 = Color3.fromRGB(50,50,50)

    local lbl = Instance.new("TextLabel", btnFrame)
    lbl.Size = UDim2.new(0.6,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = Color3.fromRGB(220,220,220)
    lbl.Font = Enum.Font.SourceSans
    lbl.TextSize = 18
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", btnFrame)
    btn.Size = UDim2.new(0.4,-10,0.8,0)
    btn.Position = UDim2.new(0.6,10,0.1,0)
    btn.BackgroundColor3 = Color3.fromRGB(100,100,100)
    btn.TextColor3 = Color3.fromRGB(220,220,220)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 18
    btn.Text = "OFF"

    local onState = false
    btn.MouseButton1Click:Connect(function()
        onState = not onState
        btn.Text = onState and "ON" or "OFF"
        btn.BackgroundColor3 = onState and Color3.fromRGB(0,170,0) or Color3.fromRGB(100,100,100)
        callback(onState)
    end)
end

-- UI Toggle'ları oluştur
createToggle("Bunny Hop", toggleBunnyHop)
createToggle("Speed", toggleSpeed)
createToggle("Fly", toggleFly)
createToggle("Hitbox", toggleHitbox)
createToggle("Aim Assist (E)", toggleAimAssist)
createToggle("ESP", toggleESP)

-- Karakter değişirse referansları güncelle
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    RootPart = char:WaitForChild("HumanoidRootPart")
    -- Hitbox tekrar uygula açıksa
    if states.hitbox then
        toggleHitbox(false)
        toggleHitbox(true)
    end
end)
