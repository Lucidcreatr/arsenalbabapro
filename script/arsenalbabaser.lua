--!strict
-- Arsenal Utility  (286090429)
if game.PlaceId ~= 286090429 then return end

local S,RS,UIS,Players = game:GetService, game:GetService("RunService"), game:GetService("UserInputService"), game:GetService("Players")
local LPlr, Cam = Players.LocalPlayer, workspace.CurrentCamera
local Char = LPlr.Character or LPlr.CharacterAdded:Wait()
local Hum = Char:WaitForChild("Humanoid"); local Root = Char:WaitForChild("HumanoidRootPart")

---------------------------------------------------------------------
-- GUI --------------------------------------------------------------
---------------------------------------------------------------------
local gui = Instance.new("ScreenGui", game.CoreGui) gui.Name="ArsenalHack"
local frame = Instance.new("Frame",gui) frame.Size=UDim2.new(0,200,0,260) frame.Position=UDim2.new(0.8,0,0.2,0)
frame.BackgroundColor3=Color3.fromRGB(28,28,28) frame.Active=true frame.Draggable=true
local layout = Instance.new("UIListLayout",frame) layout.Padding=UDim.new(0,4)

local toggleStates = {Bunny=false,Speed=false,Fly=false,Hitbox=false,Aim=false,ESP=false}
local connections:any = {}
local espBoxes:{[Model]:Drawing} = {}; local hitboxRepo:{[BasePart]:Vector3}={}

local function newToggle(text,cb)
    local hld=Instance.new("TextButton",frame) hld.Size=UDim2.new(1,0,0,28) hld.BackgroundColor3=Color3.fromRGB(60,60,60)
    local on=false; hld.Text=text.." : OFF"; hld.TextColor3=Color3.new(1,1,1)
    hld.MouseButton1Click:Connect(function()
        on=not on; hld.Text=text.." : "..(on and "ON" or "OFF"); hld.BackgroundColor3=on and Color3.fromRGB(0,130,0) or Color3.fromRGB(60,60,60)
        cb(on)
    end)
end

---------------------------------------------------------------------
-- HELPERS ----------------------------------------------------------
---------------------------------------------------------------------
local function isEnemy(p:Player) return p.Team ~= LPlr.Team end
local function getHead(model:Model)
    return model:FindFirstChild("Head") or model:FindFirstChild("RagdollRoot")
end

---------------------------------------------------------------------
-- BUNNY HOP --------------------------------------------------------
---------------------------------------------------------------------
local function toggleBunny(on)
    toggleStates.Bunny=on
    if on then
        connections.bhop = RS.Heartbeat:Connect(function()
            if Hum.FloorMaterial~=Enum.Material.Air then Hum.Jump=true end
        end)
    elseif connections.bhop then connections.bhop:Disconnect(); connections.bhop=nil end
end

---------------------------------------------------------------------
-- SPEED ------------------------------------------------------------
---------------------------------------------------------------------
local baseSpeed = Hum.WalkSpeed
local function toggleSpeed(on)
    toggleStates.Speed=on; Hum.WalkSpeed = on and baseSpeed*1.8 or baseSpeed
end

---------------------------------------------------------------------
-- FLY --------------------------------------------------------------
---------------------------------------------------------------------
local flyBV:BodyVelocity?
local function toggleFly(on)
    toggleStates.Fly=on
    if on then
        flyBV=Instance.new("BodyVelocity",Root); flyBV.MaxForce=Vector3.new(1e5,1e5,1e5)
        connections.fly = RS.RenderStepped:Connect(function()
            local v=Vector3.zero
            if UIS:IsKeyDown(Enum.KeyCode.W) then v+=Cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then v-=Cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then v-=Cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then v+=Cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then v+=Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then v-=Vector3.new(0,1,0) end
            flyBV.Velocity = v.Magnitude>0 and v.Unit*60 or Vector3.zero
        end)
    else
        if connections.fly then connections.fly:Disconnect() end
        if flyBV then flyBV:Destroy() flyBV=nil end
    end
end

---------------------------------------------------------------------
-- HITBOX -----------------------------------------------------------
---------------------------------------------------------------------
local function applyHitbox(char:Model,on:boolean)
    local hd=getHead(char) if not hd then return end
    if on then
        if not hitboxRepo[hd] then hitboxRepo[hd]=hd.Size; hd.Size=hd.Size*3 end
    elseif hitboxRepo[hd] then hd.Size=hitboxRepo[hd]; hitboxRepo[hd]=nil end
end
local function toggleHitbox(on)
    toggleStates.Hitbox=on
    for _,p in ipairs(Players:GetPlayers()) do if p~=LPlr then applyHitbox(p.Character or p.CharacterAdded:Wait(),on) end end
end

---------------------------------------------------------------------
-- AIM ASSIST -------------------------------------------------------
---------------------------------------------------------------------
local function closestEnemy(maxDist:number)
    local tgt,dist=nil,maxDist
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LPlr and isEnemy(p) and p.Character then
            local head=getHead(p.Character) if head then
                local scr,vis=Cam:WorldToViewportPoint(head.Position)
                if vis then local d=(Vector2.new(scr.X,scr.Y)-Vector2.new(Mouse.X,Mouse.Y)).Magnitude
                    if d<dist then dist,tgt=d,head end
                end
            end
        end
    end
    return tgt
end
local function toggleAim(on)
    toggleStates.Aim=on
end
UIS.InputBegan:Connect(function(inp,gp)
    if gp then return end
    if inp.KeyCode==Enum.KeyCode.E and toggleStates.Aim then
        local tgt=closestEnemy(180)
        if tgt then Cam.CFrame = CFrame.new(Cam.CFrame.Position,tgt.Position) end
    end
end)

---------------------------------------------------------------------
-- ESP --------------------------------------------------------------
---------------------------------------------------------------------
local function createESP(char:Model)
    if espBoxes[char] then return end
    local box=Drawing.new("Square"); box.Color=Color3.new(1,0,0); box.Thickness=2; box.Filled=false
    espBoxes[char]=box
    connections["esp"..char:GetDebugId()]=RS.RenderStepped:Connect(function()
        if not toggleStates.ESP or not char or not char:FindFirstChild("HumanoidRootPart") or not isEnemy(Players:GetPlayerFromCharacter(char)) then box.Visible=false return end
        local pos,vis=Cam:WorldToViewportPoint(char.HumanoidRootPart.Position)
        if vis then local size=2000/pos.Z; box.Size=Vector2.new(size,size); box.Position=Vector2.new(pos.X-size/2,pos.Y-size/2); box.Visible=true
        else box.Visible=false end
    end)
end
local function destroyESP(char:Model)
    if espBoxes[char] then espBoxes[char]:Remove(); espBoxes[char]=nil end
    local id="esp"..char:GetDebugId(); if connections[id] then connections[id]:Disconnect(); connections[id]=nil end
end
local function toggleESP(on)
    toggleStates.ESP=on
    for _,p in ipairs(Players:GetPlayers()) do if p~=LPlr then if on then createESP(p.Character or p.CharacterAdded:Wait()) else destroyESP(p.Character or p.CharacterAdded:Wait()) end end end
end

---------------------------------------------------------------------
-- PLAYER JOIN / LEAVE HANDLERS -------------------------------------
---------------------------------------------------------------------
local function attach(plr:Player)
    if plr==LPlr then return end
    if plr.Character then
        if toggleStates.ESP then createESP(plr.Character) end
        if toggleStates.Hitbox then applyHitbox(plr.Character,true) end
    end
    plr.CharacterAdded:Connect(function(c)
        if toggleStates.ESP then createESP(c) end
        if toggleStates.Hitbox then applyHitbox(c,true) end
    end)
end
for _,p in ipairs(Players:GetPlayers()) do attach(p) end
Players.PlayerAdded:Connect(attach)
Players.PlayerRemoving:Connect(function(p) if p.Character then destroyESP(p.Character); applyHitbox(p.Character,false) end end)

---------------------------------------------------------------------
-- UI TOGGLES -------------------------------------------------------
---------------------------------------------------------------------
newToggle("Bunny Hop", toggleBunny)
newToggle("Speed x1.8", toggleSpeed)
newToggle("Fly (WASD)", toggleFly)
newToggle("Big Hitbox", toggleHitbox)
newToggle("Aim Assist (E)", toggleAim)
newToggle("ESP Box", toggleESP)

---------------------------------------------------------------------
-- CHARACTER REFRESH ------------------------------------------------
---------------------------------------------------------------------
LPlr.CharacterAdded:Connect(function(c)
    Char=c; Hum=c:WaitForChild("Humanoid"); Root=c:WaitForChild("HumanoidRootPart")
    if toggleStates.Hitbox then toggleHitbox(false); toggleHitbox(true) end
end)
