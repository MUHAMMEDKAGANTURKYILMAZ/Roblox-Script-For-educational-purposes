--====================================================================
-- DELTA MOBILE COMPATIBLE ULTIMATE SUITE (FIXED v6)
--====================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local lplayer = Players.LocalPlayer
local konumGecmisi = {}
local saldiriyor = false

-- OTOMASYON DURUMLARI (AÇIK/KAPALI)
local KORUMA_AKTIF = true
local HITBOX_AKTIF = true
local WALKFLY_AKTIF = false
local AUTO_ATTACK_AKTIF = false
local AUTO_WALK_AKTIF = false
local AUTO_E_AKTIF = false

-- METRİKLER
local MENZIL = 25          
local KACIS_MESAFESI = 30  
local HITBOX_BOYUTU = Vector3.new(10, 10, 10)

-- Mobil Karakter Boyut Hesaplayıcı
local function getKarakterBoyut()
    local char = lplayer.Character
    if char and char:FindFirstChild("Humanoid") then
        return char.Humanoid.HipHeight > 0 and char.Humanoid.HipHeight or 2
    end
    return 2
end

-- %100 Mobil Touch Sürükleme Fonksiyonu
local function makeDraggable(guiObject)
    local dragging, dragInput, dragStart, startPos
    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiObject.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    guiObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            guiObject.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- ==========================================
-- MOBIL UYUMLU Gelişmiş Hile Menüsü (GUI)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DeltaFixedMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = lplayer:WaitForChild("PlayerGui")

-- Ana Panel (Genişlik ve Yükseklik Mobile Göre Optimize Edildi)
local MainPanel = Instance.new("Frame")
MainPanel.Size = UDim2.new(0, 260, 0, 240)
MainPanel.Position = UDim2.new(0.1, 0, 0.2, 0)
MainPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainPanel.BorderSizePixel = 2
MainPanel.BorderColor3 = Color3.fromRGB(180, 30, 30)
MainPanel.Parent = ScreenGui
makeDraggable(MainPanel)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Title.Text = "DELTA FIXED PANEL v6"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 14
Title.Parent = MainPanel

-- Butonları İçine Alan Gövde (Gizleme İşlemi İçin)
local ButtonContainer = Instance.new("Frame")
ButtonContainer.Size = UDim2.new(1, 0, 1, -30)
ButtonContainer.Position = UDim2.new(0, 0, 0, 30)
ButtonContainer.BackgroundTransparency = 1
ButtonContainer.Parent = MainPanel

-- Yan Yana Buton Düzeni İçin Grid Yapısı
local UIGridLayout = Instance.new("UIGridLayout")
UIGridLayout.CellSize = UDim2.new(0, 115, 0, 35)
UIGridLayout.CellPadding = UDim2.new(0, 10, 0, 8)
UIGridLayout.StartCorner = Enum.UIStartCorner.TopLeft
UIGridLayout.FillDirection = Enum.UIFillDirection.Horizontal
UIGridLayout.Parent = ButtonContainer
UIGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- Buton Oluşturucu Fonksiyon
local function createToggleBtn(text, defaultState, callback)
    local btn = Instance.new("TextButton")
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 12
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BorderSizePixel = 1
    btn.Parent = ButtonContainer
    
    local state = defaultState
    local function updateVisual()
        if state then
            btn.BackgroundColor3 = Color3.fromRGB(0, 120, 35)
            btn.Text = text .. "\n[AÇIK]"
        else
            btn.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
            btn.Text = text .. "\n[KAPALI]"
        end
    end
    updateVisual()
    
    btn.MouseButton1Click:Connect(function()
        state = not state
        updateVisual()
        callback(state)
    end)
    return btn
end

-- Aksiyon Butonları (Grid İçinde Otomatik Hizalanır)
local BackstabBtn = Instance.new("TextButton")
BackstabBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
BackstabBtn.Text = "ANLIK\nSALDIRI"
BackstabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
BackstabBtn.Font = Enum.Font.SourceSansBold
BackstabBtn.TextSize = 12
BackstabBtn.Parent = ButtonContainer

local RewindBtn = Instance.new("TextButton")
RewindBtn.BackgroundColor3 = Color3.fromRGB(30, 80, 180)
RewindBtn.Text = "10s GERİ\nIŞINLAN"
RewindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RewindBtn.Font = Enum.Font.SourceSansBold
RewindBtn.TextSize = 12
RewindBtn.Parent = ButtonContainer

createToggleBtn("YATAY KORUMA", KORUMA_AKTIF, function(v) KORUMA_AKTIF = v end)
createToggleBtn("10x10 HITBOX", HITBOX_AKTIF, function(v) HITBOX_AKTIF = v end)
createToggleBtn("GİZLİ WALKFLY", WALKFLY_AKTIF, function(v) WALKFLY_AKTIF = v end)
createToggleBtn("0.5s OTO VURUŞ", AUTO_ATTACK_AKTIF, function(v) AUTO_ATTACK_AKTIF = v end)
createToggleBtn("AKILLI TAKİP", AUTO_WALK_AKTIF, function(v) AUTO_WALK_AKTIF = v end)
createToggleBtn("6s OTO E TUŞU", AUTO_E_AKTIF, function(v) AUTO_E_AKTIF = v end)

-- KESİN ÇALIŞAN GİZLE/AÇ BUTONU (Başlığın Sağ Üst Köşesinde)
local ToggleMenuBtn = Instance.new("TextButton")
ToggleMenuBtn.Size = UDim2.new(0, 60, 0, 24)
ToggleMenuBtn.Position = UDim2.new(1, -65, 0, 3)
ToggleMenuBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
ToggleMenuBtn.Text = "GİZLE"
ToggleMenuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleMenuBtn.Font = Enum.Font.SourceSansBold
ToggleMenuBtn.TextSize = 11
ToggleMenuBtn.Parent = MainPanel

local menuAcik = true
ToggleMenuBtn.MouseButton1Click:Connect(function()
    menuAcik = not menuAcik
    if menuAcik then
        ButtonContainer.Visible = true
        MainPanel.Size = UDim2.new(0, 260, 0, 240)
        ToggleMenuBtn.Text = "GİZLE"
    else
        ButtonContainer.Visible = false
        MainPanel.Size = UDim2.new(0, 260, 0, 30)
        ToggleMenuBtn.Text = "GÖSTER"
    end
end)

-- ==========================================
-- GÜVENİLİR MOBİL MODÜL SİSTEMLERİ
-- ==========================================

-- Mobil Uyumlu Sanal Tıklama Fonksiyonu (Tool'ları Tetikler)
local function mobileClick()
    local char = lplayer.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if tool then
        tool:Activate() -- Ekrana tıklamak yerine doğrudan elindeki silahı sunucu seviyesinde tetikler (Kesin Çözüm)
    end
end

-- 6 Saniyede Bir Otomatik E Tuşu Modülü
task.spawn(function()
    while true do
        if AUTO_E_AKTIF then
            -- ProximityPrompt'ları doğrudan kod üzerinden tetikler (Tuşa basma taklidinden çok daha hızlı ve kesindir)
            for _, prompt in pairs(workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") and lplayer:DistanceFromCharacter(prompt.Parent.Position) <= prompt.MaxActivationDistance then
                    prompt:InputHoldBegin()
                    task.wait(0.1)
                    prompt:InputHoldEnd()
                end
            end
        end
        task.wait(6)
    end
end)

-- 10 Saniye Geri Işınlanma Modülü
RewindBtn.MouseButton1Click:Connect(function()
    local char = lplayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and #konumGecmisi > 0 then
        hrp.CFrame = konumGecmisi[1]
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    end
end)

-- Konum Kaydedici Hafıza Döngüsü (FIFO)
task.spawn(function()
    while true do
        task.wait(1)
        local char = lplayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") and not saldiriyor then
            table.insert(konumGecmisi, char.HumanoidRootPart.CFrame)
            if #konumGecmisi > 10 then table.remove(konumGecmisi, 1) end
        end
    end
end)

-- Mobil Gizli WalkFly Modülü
RunService.Heartbeat:Connect(function()
    local char = lplayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    
    if hrp and humanoid then
        if WALKFLY_AKTIF then
            humanoid.PlatformStand = true
            local bv = hrp:FindFirstChild("WalkFlyBV") or Instance.new("BodyVelocity")
            bv.Name = "WalkFlyBV"
            bv.MaxForce = Vector3.new(0, math.huge, 0)
            bv.Velocity = Vector3.new(0, 0, 0)
            bv.Parent = hrp
        else
            if hrp:FindFirstChild("WalkFlyBV") then hrp.WalkFlyBV:Destroy() end
        end
    end
end)

-- 0.5 Saniyede Bir Otomatik Vuruş
task.spawn(function()
    while true do
        if AUTO_ATTACK_AKTIF then
            mobileClick()
        end
        task.wait(0.5)
    end
end)

-- En Yakın Oyuncuyu Bulucu
local function getEnYakinOyuncu()
    local enYakin = nil
    local enKisaMesafe = math.huge
    local char = lplayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= lplayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local mesafe = (hrp.Position - player.Character.HumanoidRootPart.Position).Magnitude
            if mesafe < enKisaMesafe then
                enKisaMesafe = mesafe
                enYakin = player
            end
        end
    end
    return enYakin
end

-- Akıllı Kırmızı Nesne Bulucu
local function getKirmiziNesne()
    local char = lplayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.CanCollide and (obj.Color == Color3.fromRGB(255, 0, 0) or obj:FindFirstChildOfClass("ProximityPrompt")) then
            local mesafe = (hrp.Position - obj.Position).Magnitude
            if mesafe <= 50 then
                return obj
            end
        end
    end
    return nil
end

-- OTO AKILLI TAKİP DÖNGÜSÜ
RunService.Heartbeat:Connect(function()
    if not AUTO_WALK_AKTIF or saldiriyor then return end
    local char = lplayer.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local hedefNesne = getKirmiziNesne()
    if hedefNesne then
        humanoid:MoveTo(hedefNesne.Position)
    else
        local hedefOyuncu = getEnYakinOyuncu()
        if hedefOyuncu and hedefOyuncu.Character and hedefOyuncu.Character:FindFirstChild("HumanoidRootPart") then
            humanoid:MoveTo(hedefOyuncu.Character.HumanoidRootPart.Position)
        end
    end
end)

-- Hitbox Genişletici, Hız Sabitleyici ve Anti-Knockback (Tam Kilit)
RunService.RenderStepped:Connect(function()
    -- Hitbox Kontrolü
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= lplayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local root = player.Character.HumanoidRootPart
            if HITBOX_AKTIF then
                root.Size = HITBOX_BOYUTU
                root.Transparency = 0.7
                root.Color = Color3.fromRGB(255, 0, 0)
                root.CanCollide = false
            else
                root.Size = Vector3.new(2, 2, 1)
                root.Transparency = 0
            end
        end
    end
    
    -- Anti Ragdoll & Hız Kilit
    local char = lplayer.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = 50
        humanoid.PlatformStand = WALKFLY_AKTIF and true or false
        if humanoid.Sit then humanoid.Sit = false end
    end
end)

-- GÖRÜNMEZLİK FONKSİYONU
local function setKalkanVeGorunmezlik(aktif)
    local char = lplayer.Character
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Decal") then
            part.CanCollide = not aktif
            if part:IsA("BasePart") then part.Transparency = aktif and 1 or 0
            elseif part:IsA("Decal") then part.Transparency = aktif and 1 or 0 end
        end
    end
end

-- MOBIL KESIN ÇALIŞAN BACKSTAB SALDIRISI
BackstabBtn.MouseButton1Click:Connect(function()
    if saldiriyor then return end
    local char = lplayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local hedef = getEnYakinOyuncu()
    if not hedef then return end

    saldiriyor = true
    local eskiKonum = hrp.CFrame 

    mobileClick()

    task.wait(0.15)
    setKalkanVeGorunmezlik(true)

    local tBaslangic = tick()
    while tick() - tBaslangic < 0.5 do
        RunService.RenderStepped:Wait()
        local hChar = hedef.Character
        local hHrp = hChar and hChar:FindFirstChild("HumanoidRootPart")
        local gHrp = lplayer.Character and lplayer.Character:FindFirstChild("HumanoidRootPart")
        
        if hHrp and gHrp then
            local arkaKonum = hHrp.CFrame * CFrame.new(0, 0, 1) 
            gHrp.CFrame = CFrame.new(arkaKonum.Position, hHrp.Position)
            gHrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        else break end
    end

    if lplayer.Character and lplayer.Character:FindFirstChild("HumanoidRootPart") then
        lplayer.Character.HumanoidRootPart.CFrame = eskiKonum
        lplayer.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    end
    setKalkanVeGorunmezlik(false)
    saldiriyor = false
end)

-- DEFANS: Raycast Tabanlı Kaçış (Yatay Zemin Kontrollü)
RunService.Heartbeat:Connect(function()
    if not KORUMA_AKTIF or saldiriyor then return end
    local char = lplayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    for _, other in pairs(Players:GetPlayers()) do
        if other ~= lplayer and other.Character and other.Character:FindFirstChild("HumanoidRootPart") then
            local oHrp = other.Character.HumanoidRootPart
            local mesafe = (hrp.Position - oHrp.Position).Magnitude
            
            if mesafe <= MENZIL then
                local bulunanGuvliKonum = nil
                for i = 1, 5 do
                    local rastgeleAci = math.rad(math.random(0, 360))
                    local yatayYon = Vector3.new(math.cos(rastgeleAci), 0, math.sin(rastgeleAci))
                    local hedefPozisyon = hrp.Position + (yatayYon * KACIS_MESAFESI)
                    
                    local raycastParams = RaycastParams.new()
                    raycastParams.FilterDescendantsInstances = {char, other.Character}
                    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                    
                    local rayOrigin = hedefPozisyon + Vector3.new(0, 10, 0)
                    local rayDirection = Vector3.new(0, -40, 0)
                    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
                    
                    if raycastResult then
                        bulunanGuvliKonum = raycastResult.Position + Vector3.new(0, getKarakterBoyut(), 0)
                        break
                    end
                end
                
                if bulunanGuvliKonum then
                    hrp.CFrame = CFrame.new(bulunanGuvliKonum)
                    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    task.wait(0.3)
                    break
                end
            end
        end
    end
end)

print("Delta Mobile %100 Uyumlu Panel Yuklendi.")
