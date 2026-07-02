local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Player = Players.LocalPlayer
local Backpack = Player:WaitForChild("Backpack")

local success, objects = pcall(function()
    return game:GetObjects("rbxassetid://125013769")
end)

if not success or not objects or not objects[1] then
    warn("Kılıç yüklenemedi! Roblox API'si engellemiş olabilir.")
    return
end

local Tool = objects[1]


for _, child in pairs(Tool:GetChildren()) do
    if child:IsA("Script") or child:IsA("LocalScript") then
        child:Destroy()
    end
end

Tool.Parent = Backpack
local Handle = Tool:WaitForChild("Handle")

local Grips = {
    Up = CFrame.new(0, 0, -1.5, 0, 0, 1, 1, 0, 0, 0, 1, 0),
    Out = CFrame.new(0, 0, -1.5, 0, -1, 0, -1, 0, 0, 0, 0, -1),
}

local DamageValues = { BaseDamage = 5, SlashDamage = 10, LungeDamage = 30 }
local Damage = DamageValues.BaseDamage
local LastAttack = 0
local ToolEquipped = false
Tool.Enabled = true

local Sounds = {
    Slash = Handle:FindFirstChild("Slash"),
    Lunge = Handle:FindFirstChild("Lunge"),
    Unsheath = Handle:FindFirstChild("Unsheath")
}

function SwordUp() Tool.Grip = Grips.Up end
function SwordOut() Tool.Grip = Grips.Out end

function Attack()
    Damage = DamageValues.SlashDamage
    if Sounds.Slash then Sounds.Slash:Play() end
    
    local Anim = Instance.new("StringValue")
    Anim.Name = "toolanim"
    Anim.Value = "Slash"
    Anim.Parent = Tool
end

function Lunge()
    Damage = DamageValues.LungeDamage
    if Sounds.Lunge then Sounds.Lunge:Play() end
    
    local Anim = Instance.new("StringValue")
    Anim.Name = "toolanim"
    Anim.Value = "Lunge"
    Anim.Parent = Tool
    
    local Character = Player.Character
    local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
    
    
    if RootPart then
        local Force = Instance.new("BodyVelocity")
        Force.velocity = Vector3.new(0, 10, 0) + (RootPart.CFrame.lookVector * 60)
        Force.maxForce = Vector3.new(4000, 4000, 4000)
        Force.Parent = RootPart
        Debris:AddItem(Force, 0.5)
    end
    
    task.wait(0.25)
    SwordOut()
    task.wait(0.25)
    SwordUp()
end


Tool.Activated:Connect(function()
    if not Tool.Enabled or not ToolEquipped then return end
    Tool.Enabled = false
    
    local currentTick = tick()
    
    if (currentTick - LastAttack) < 0.2 then
        Lunge()
    else
        Attack()
    end
    
    Damage = DamageValues.BaseDamage
    LastAttack = currentTick
    Tool.Enabled = true
end)

Tool.Equipped:Connect(function()
    ToolEquipped = true
    if Sounds.Unsheath then Sounds.Unsheath:Play() end
end)

Tool.Unequipped:Connect(function()
    ToolEquipped = false
end)

Handle.Touched:Connect(function(Hit)
    if not Hit or not Hit.Parent then return end
    local targetHumanoid = Hit.Parent:FindFirstChild("Humanoid")
    local myHumanoid = Player.Character and Player.Character:FindFirstChild("Humanoid")
    
    
    if targetHumanoid and targetHumanoid ~= myHumanoid then
        targetHumanoid:TakeDamage(Damage)
    end
end)


SwordUp()

