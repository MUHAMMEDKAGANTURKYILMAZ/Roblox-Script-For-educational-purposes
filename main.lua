--====================================================================
-- DELTA SLAP BATTLES v6.5 - Anti Void + Teleport + Ground Lock
--====================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local lplayer = Players.LocalPlayer
local karakter = lplayer.Character or lplayer.CharacterAdded:Wait()

-- AYARLAR
local AUTO_SLAP_AKTIF = true
local AUTO_WALK_AKTIF = true
local ANTI_SLAP_AKTIF = true
local ANTI_VOID_AKTIF = true
local TELEPORT_TO_PLAYER = true
local REACH_AKTIF = true

local SLAP_HIZ = 0.13
local TELEPORT_MENZIL = 100   -- 100 study içindeyse ışınlan
local TELEPORT_YAKINLIK = 25  -- Oyuncunun 25 study yanına

-- =================== GUI ===================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = lplayer:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 270, 0, 260)
Main.Position = UDim2.new(0.08, 0, 0.15, 0)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Main.BorderColor3 = Color3.fromRGB(220, 50, 50)
Main.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,0,0,35)
Title.BackgroundColor3 = Color3.fromRGB(35,35,35)
Title.Text = "DELTA SLAP v6.5"
Title.TextColor3 = Color3.fromRGB(255, 60, 60)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.Parent = Main

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 75, 0, 28)
ToggleBtn.Position = UDim2.new(1, -80, 0, 4)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
ToggleBtn.Text = "GİZLE"
ToggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.TextSize = 13
ToggleBtn.Parent = Main

local Container = Instance.new("Frame")
Container.Size = UDim2.new(1,-20,1,-55)
Container.Position = UDim2.new(0,10,0,40)
Container.BackgroundTransparency = 1
Container.Parent = Main

local Grid = Instance.new("UIGridLayout")
Grid.CellSize = UDim2.new(0, 118, 0, 45)
Grid.CellPadding = UDim2.new(0, 8, 0, 8)
Grid.Parent = Container

local function ToggleButton(text, default, callback)
    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = default and Color3.fromRGB(0, 165, 80) or Color3.fromRGB(165, 0, 0)
    btn.Text = text .. "\n[" .. (default and "AÇIK" or "KAPALI") .. "]"
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 13
    btn.Parent = Container
    
    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(0,165,80) or Color3.fromRGB(165,0,0)
        btn.Text = text .. "\n[" .. (state and "AÇIK" or "KAPALI") .. "]"
        callback(state)
    end)
    return btn
end

ToggleButton("Reach", REACH_AKTIF, function(v) REACH_AKTIF = v end)
ToggleButton("Sürekli Vur", AUTO_SLAP_AKTIF, function(v) AUTO_SLAP_AKTIF = v end)
ToggleButton("Düşmana Yürü", AUTO_WALK_AKTIF, function(v) AUTO_WALK_AKTIF = v end)
ToggleButton("Anti Slap", ANTI_SLAP_AKTIF, function(v) ANTI_SLAP_AKTIF = v end)
ToggleButton("Anti Void", ANTI_VOID_AKTIF, function(v) ANTI_VOID_AKTIF = v end)
ToggleButton("Oyuncuya Işınlan", TELEPORT_TO_PLAYER, function(v) TELEPORT_TO_PLAYER = v end)

-- Gizle/Göster
local acik = true
ToggleBtn.MouseButton1Click:Connect(function()
    acik = not acik
    Container.Visible = acik
    Main.Size = acik and UDim2.new(0,270,0,260) or UDim2.new(0,270,0,40)
    ToggleBtn.Text = acik and "GİZLE" or "GÖSTER"
end)

-- =================== SİSTEMLER ===================

-- Reach (Görünmez)
RunService.Heartbeat:Connect(function()
    if REACH_AKTIF and karakter:FindFirstChild("HumanoidRootPart") then
        local root = karakter.HumanoidRootPart
        root.Size = Vector3.new(20, 10, 20)
        root.Transparency = 1        -- Kırmızı kaldırıldı
        root.CanCollide = false
    end
end)

-- Sürekli Vur
task.spawn(function()
    while true do
        if AUTO_SLAP_AKTIF then
            local tool = karakter:FindFirstChildOfClass("Tool")
            if tool then tool:Activate() end
        end
        task.wait(SLAP_HIZ)
    end
end)

-- En Yakın Oyuncu
local function getEnYakin()
    local enYakin = nil
    local enKisa = math.huge
    local myRoot = karakter:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lplayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (myRoot.Position - p.Character.HumanoidRootPart.Position).Magnitude
            if dist < enKisa and dist <= TELEPORT_MENZIL then
                enKisa = dist
                enYakin = p.Character.HumanoidRootPart
            end
        end
    end
    return enYakin
end

-- Oyuncuya Işınlanma + Yerde Tutma
RunService.Heartbeat:Connect(function()
    local root = karakter:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Sürekli Yerde Tutma (Y = 0 civarı)
    if root.Position.Y < 5 then
        root.CFrame = root.CFrame * CFrame.new(0, 8, 0)
        root.AssemblyLinearVelocity = Vector3.new(0, 5, 0)
    end

    -- En Yakına Işınlan (100 study içinde)
    if TELEPORT_TO_PLAYER then
        local hedef = getEnYakin()
        if hedef then
            local hedefPoz = hedef.Position
            local yeniPoz = hedefPoz + (hedefPoz - root.Position).Unit * TELEPORT_YAKINLIK
            root.CFrame = CFrame.new(yeniPoz.X, math.max(yeniPoz.Y, 10), yeniPoz.Z)
        end
    end
end)

-- Anti Slap
RunService.Heartbeat:Connect(function()
    if not ANTI_SLAP_AKTIF then return end
    local hum = karakter:FindFirstChildOfClass("Humanoid")
    local root = karakter:FindFirstChild("HumanoidRootPart")
    if hum and root then
        hum.PlatformStand = false
        hum.WalkSpeed = 20
        root.AssemblyLinearVelocity = root.AssemblyLinearVelocity * 0.35
    end
end)

-- Anti Void (Gelişmiş)
RunService.Heartbeat:Connect(function()
    if not ANTI_VOID_AKTIF then return end
    local root = karakter:FindFirstChild("HumanoidRootPart")
    if root and root.Position.Y < -30 then
        root.CFrame = CFrame.new(root.Position.X, 80, root.Position.Z)
        root.AssemblyLinearVelocity = Vector3.new(0, 20, 0)
    end
end)

-- Karakter Yenileme
lplayer.CharacterAdded:Connect(function(newChar)
    karakter = newChar
    task.wait(1)
end)

print("Delta Slap Battles v6.5 Yüklendi ✅")
print("Kırmızı hitbox kaldırıldı + Yer kilidi + Işınlanma eklendi")
