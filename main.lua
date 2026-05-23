--====================================================================
-- DELTA SLAP BATTLES v6.3 - Anti Slap + Auto Walk + Auto Slap
--====================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local lplayer = Players.LocalPlayer
local karakter = lplayer.Character or lplayer.CharacterAdded:Wait()

local saldiriyor = false

-- AYARLAR
local REACH_AKTIF = true
local AUTO_SLAP_AKTIF = true
local AUTO_WALK_AKTIF = true
local ANTI_SLAP_AKTIF = true

local SLAP_HIZ = 0.12        -- Ne kadar hızlı vuracak (çok düşük yapma, kick yersin)
local WALK_MENZIL = 100

-- =================== GUI ===================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = lplayer:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 260, 0, 240)
Main.Position = UDim2.new(0.1, 0, 0.2, 0)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
Main.BorderColor3 = Color3.fromRGB(255, 50, 50)
Main.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,0,0,35)
Title.BackgroundColor3 = Color3.fromRGB(30,30,30)
Title.Text = "DELTA SLAP v6.3"
Title.TextColor3 = Color3.fromRGB(255, 70, 70)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.Parent = Main

local Container = Instance.new("Frame")
Container.Size = UDim2.new(1,-20,1,-50)
Container.Position = UDim2.new(0,10,0,40)
Container.BackgroundTransparency = 1
Container.Parent = Main

local Grid = Instance.new("UIGridLayout")
Grid.CellSize = UDim2.new(0, 115, 0, 45)
Grid.CellPadding = UDim2.new(0, 8, 0, 8)
Grid.Parent = Container

local function ToggleBtn(text, default, callback)
    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = default and Color3.fromRGB(0, 170, 80) or Color3.fromRGB(170, 0, 0)
    btn.Text = text .. "\n[" .. (default and "AÇIK" or "KAPALI") .. "]"
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 13
    btn.Parent = Container
    
    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(0,170,80) or Color3.fromRGB(170,0,0)
        btn.Text = text .. "\n[" .. (state and "AÇIK" or "KAPALI") .. "]"
        callback(state)
    end)
    return btn
end

ToggleBtn("Reach", REACH_AKTIF, function(v) REACH_AKTIF = v end)
ToggleBtn("Sürekli Vur", AUTO_SLAP_AKTIF, function(v) AUTO_SLAP_AKTIF = v end)
ToggleBtn("Düşmana Yürü", AUTO_WALK_AKTIF, function(v) AUTO_WALK_AKTIF = v end)
ToggleBtn("Anti Slap", ANTI_SLAP_AKTIF, function(v) ANTI_SLAP_AKTIF = v end)

-- =================== FONKSİYONLAR ===================

-- En yakın oyuncuyu bul
local function getEnYakin()
    local enYakin = nil
    local enKisa = math.huge
    local hrp = karakter:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lplayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (hrp.Position - p.Character.HumanoidRootPart.Position).Magnitude
            if dist < enKisa and dist < WALK_MENZIL then
                enKisa = dist
                enYakin = p
            end
        end
    end
    return enYakin
end

-- Reach
RunService.Heartbeat:Connect(function()
    if REACH_AKTIF and karakter:FindFirstChild("HumanoidRootPart") then
        local root = karakter.HumanoidRootPart
        root.Size = Vector3.new(25, 25, 25)
        root.Transparency = 0.75
        root.Color = Color3.fromRGB(255, 0, 0)
        root.CanCollide = false
    end
end)

-- Sürekli Vur (Auto Slap)
task.spawn(function()
    while true do
        if AUTO_SLAP_AKTIF then
            local tool = karakter:FindFirstChildOfClass("Tool")
            if tool then
                tool:Activate()
            end
        end
        task.wait(SLAP_HIZ)
    end
end)

-- Düşmana Otomatik Yürüme
RunService.Heartbeat:Connect(function()
    if not AUTO_WALK_AKTIF then return end
    local humanoid = karakter:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local hedef = getEnYakin()
    if hedef and hedef.Character and hedef.Character:FindFirstChild("HumanoidRootPart") then
        humanoid:MoveTo(hedef.Character.HumanoidRootPart.Position)
    end
end)

-- Anti Slap (Basit Koruma)
RunService.Heartbeat:Connect(function()
    if not ANTI_SLAP_AKTIF then return end
    local hrp = karakter:FindFirstChild("HumanoidRootPart")
    local hum = karakter:FindFirstChildOfClass("Humanoid")
    
    if hrp and hum then
        -- Anti ragdoll ve knockback koruması
        hum.PlatformStand = false
        if hum.Sit then hum.Sit = false end
        
        -- Yüksek hız kilidi
        hum.WalkSpeed = 22
    end
end)

print("Delta Slap Battles v6.3 Yüklendi ✅")
print("Anti Slap + Auto Walk + Auto Slap aktif!")

-- Karakter yenilenirse yeniden ata
lplayer.CharacterAdded:Connect(function(newChar)
    karakter = newChar
    task.wait(1)
end)
