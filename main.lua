--====================================================================
-- DELTA SLAP BATTLES v6.6 - Büyük Görünmez Zemin + Düzeltmeler
--====================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local lplayer = Players.LocalPlayer
local karakter = lplayer.Character or lplayer.CharacterAdded:Wait()

-- AYARLAR
local AUTO_SLAP_AKTIF = true
local AUTO_WALK_AKTIF = true
local ANTI_SLAP_AKTIF = true
local ANTI_VOID_PLATFORM = true   -- Yeni Büyük Görünmez Zemin
local TELEPORT_TO_PLAYER = true

local SLAP_HIZ = 0.14
local TELEPORT_MENZIL = 100
local TELEPORT_YAKINLIK = 25

-- =================== GUI ===================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = lplayer:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 270, 0, 270)
Main.Position = UDim2.new(0.08, 0, 0.15, 0)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Main.BorderColor3 = Color3.fromRGB(220, 50, 50)
Main.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,0,0,35)
Title.BackgroundColor3 = Color3.fromRGB(35,35,35)
Title.Text = "DELTA SLAP v6.6"
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

ToggleButton("Sürekli Vur", AUTO_SLAP_AKTIF, function(v) AUTO_SLAP_AKTIF = v end)
ToggleButton("Düşmana Yürü", AUTO_WALK_AKTIF, function(v) AUTO_WALK_AKTIF = v end)
ToggleButton("Anti Slap", ANTI_SLAP_AKTIF, function(v) ANTI_SLAP_AKTIF = v end)
ToggleButton("Büyük Zemin (Anti Void)", ANTI_VOID_PLATFORM, function(v) ANTI_VOID_PLATFORM = v end)
ToggleButton("Oyuncuya Işınlan", TELEPORT_TO_PLAYER, function(v) TELEPORT_TO_PLAYER = v end)

-- Gizle/Göster
local acik = true
ToggleBtn.MouseButton1Click:Connect(function()
    acik = not acik
    Container.Visible = acik
    Main.Size = acik and UDim2.new(0,270,0,270) or UDim2.new(0,270,0,40)
    ToggleBtn.Text = acik and "GİZLE" or "GÖSTER"
end)

-- =================== BÜYÜK GÖRÜNMEZ ZEMİN ===================
local voidPlatform = nil

local function CreateAntiVoidPlatform()
    if voidPlatform then voidPlatform:Destroy() end
    
    voidPlatform = Instance.new("Part")
    voidPlatform.Name = "DeltaAntiVoid"
    voidPlatform.Size = Vector3.new(6000, 1, 6000)  -- Çok büyük
    voidPlatform.Transparency = 1
    voidPlatform.Anchored = true
    voidPlatform.CanCollide = true
    voidPlatform.Material = Enum.Material.ForceField
    voidPlatform.Color = Color3.fromRGB(0,0,0)
    voidPlatform.Parent = workspace
end

-- =================== ANA DÖNGÜ ===================

-- Reach (Tamamen Kaldırıldı - Hiçbir şey değiştirmiyoruz)
-- Sadece normal boyutta kalacak

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

-- Ana Döngü (Yerde Tutma + Işınlanma + Zemin)
RunService.Heartbeat:Connect(function()
    local root = karakter:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Büyük Görünmez Zemin
    if ANTI_VOID_PLATFORM then
        if not voidPlatform then CreateAntiVoidPlatform() end
        voidPlatform.CFrame = CFrame.new(root.Position.X, root.Position.Y - 4, root.Position.Z)
    elseif voidPlatform then
        voidPlatform:Destroy()
        voidPlatform = nil
    end

    -- Sürekli Yerde Tutma
    if root.Position.Y < 10 then
        root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X * 0.4, 10, root.AssemblyLinearVelocity.Z * 0.4)
    end

    -- Oyuncuya Işınlanma
    if TELEPORT_TO_PLAYER then
        local hedef = getEnYakin()
        if hedef then
            local hedefPoz = hedef.Position
            local direction = (hedefPoz - root.Position).Unit
            local yeniPoz = hedefPoz - direction * TELEPORT_YAKINLIK
            root.CFrame = CFrame.new(yeniPoz.X, math.max(yeniPoz.Y + 5, 15), yeniPoz.Z)
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
        root.AssemblyLinearVelocity = root.AssemblyLinearVelocity * 0.4
    end
end)

-- Karakter Yenileme
lplayer.CharacterAdded:Connect(function(newChar)
    karakter = newChar
    task.wait(1)
end)

print("Delta Slap Battles v6.6 Yüklendi")
print("Hitbox tamamen kaldırıldı + Ayak altında devasa görünmez zemin eklendi ✅")
