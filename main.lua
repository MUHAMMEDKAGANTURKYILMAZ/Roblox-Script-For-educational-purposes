--====================================================================
-- ULTIMATE COMBAT & AUTOMATION SUITE (E-TAP INTEGRATED GUI)
--====================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

local lplayer = Players.LocalPlayer
local konumGecmisi = {}
local saldiriyor = false

-- OTOMASYON DURUMLARI (GUI'DEN KONTROL EDİLİR)
local KORUMA_AKTIF = true
local HITBOX_AKTIF = true
local WALKFLY_AKTIF = false
local AUTO_ATTACK_AKTIF = false
local AUTO_WALK_AKTIF = false
local AUTO_E_AKTIF = false

-- METRİK AYARLARI
local MENZIL = 25          
local KACIS_MESAFESI = 30  
local HITBOX_BOYUTU = Vector3.new(10, 10, 10)

-- Karakter Boyut Algılayıcı
local function getKarakterBoyut()
    local char = lplayer.Character
    if char and char:FindFirstChild("Humanoid") then
        return char.Humanoid.HipHeight > 0 and char.Humanoid.HipHeight or 2
    end
    return 2
end

-- Sürükleme Fonksiyonu
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
-- Gelişmiş Hile Menüsü Kurulumu (GUI)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UltimateSuiteMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = lplayer:WaitForChild("PlayerGui")

-- Ana Panel Arka Planı (Yeni boyut buton sığması için uyarlandı)
local MainPanel = Instance.new("Frame")
MainPanel.Size = UDim2.new(0, 180, 0, 430)
MainPanel.Position = UDim2.new(0, 20, 0, 80)
MainPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainPanel.BorderSizePixel = 2
MainPanel.BorderColor3 = Color3.fromRGB(180, 30, 30)
MainPanel.Parent = ScreenGui
makeDraggable(MainPanel)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Title.Text = "COMBAT PANEL v5"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 14
Title.Parent = MainPanel

local function createToggleBtn(name, text, posY, defaultState, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 160, 0, 35)
    btn.Position = UDim2.new(0, 10, 0, posY)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BorderSizePixel = 1
    btn.Parent = MainPanel
    
    local state = defaultState
    local function updateVisual()
        if state then
            btn.BackgroundColor3 = Color3.fromRGB(0, 130, 40)
            btn.Text = text .. ": AÇIK"
        else
            btn.BackgroundColor3 = Color3.fromRGB(130, 0, 0)
            btn.Text = text .. ": KAPALI"
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

-- Butonların Menüye Yerleştirilmesi
local BackstabBtn = Instance.new("TextButton")
BackstabBtn.Size = UDim2.new(0, 160, 0, 35)
BackstabBtn.Position = UDim2.new(0, 10, 0, 40)
BackstabBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
BackstabBtn.Text = "GİZLİ ANLIK SALDIRI"
BackstabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
BackstabBtn.Font = Enum.Font.SourceSansBold
BackstabBtn.TextSize = 13
BackstabBtn.Parent = MainPanel

local RewindBtn = Instance.new("TextButton")
RewindBtn.Size = UDim2.new(0, 160, 0, 35)
RewindBtn.Position = UDim2.new(0, 10, 0, 80)
RewindBtn.BackgroundColor3 = Color3.fromRGB(30, 80, 180)
RewindBtn.Text = "10s GERİ IŞINLAN"
RewindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RewindBtn.Font = Enum.Font.SourceSansBold
RewindBtn.TextSize = 13
RewindBtn.Parent = MainPanel

createToggleBtn("Koruma", "25s YATAY KORUMA", 120, KORUMA_AKTIF, function(v) KORUMA_AKTIF = v end)
createToggleBtn("Hitbox", "10x10 HITBOX", 160, HITBOX_AKTIF, function(v) HITBOX_AKTIF = v end)
createToggleBtn("WalkFly", "GİZLİ WALKFLY", 200, WALKFLY_AKTIF, function(v) WALKFLY_AKTIF = v end)
createToggleBtn("AutoAttack", "0.5s OTO VURUŞ", 240, AUTO_ATTACK_AKTIF, function(v) AUTO_ATTACK_AKTIF = v end)
createToggleBtn("AutoWalk", "OTO AKILLI TAKİP", 280, AUTO_WALK_AKTIF, function(v) AUTO_WALK_AKTIF = v end)
createToggleBtn("AutoE", "6s OTO E TUŞU", 320, AUTO_E_AKTIF, function(v) AUTO_E_AKTIF = v end)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 160, 0, 30)
CloseBtn.Position = UDim2.new(0, 10, 0, 390)
CloseBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
CloseBtn.Text = "MENÜYÜ GİZLE / AÇ"
CloseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.TextSize = 12
CloseBtn.Parent = MainPanel

local menuAcik = true
CloseBtn.MouseButton1Click:Connect(function()
    menuAcik = not menuAcik
    MainPanel.Size = menuAcik and UDim2.new(0, 180, 0, 430) or UDim2.new(0, 180, 0, 30)
end)

-- ==========================================
-- FONKSİYONEL MODÜLLER
-- ==========================================

-- 6 Saniyede Bir Otomatik E Tuşu Basma Döngüsü
task.spawn(function()
    while true do
        if AUTO_E_AKTIF then
            -- Sanal olarak klavyeden E tuşuna basılıp bırakılmasını simüle eder
            VirtualUser:TypeKey(Enum.KeyCode.E.Value)
            print("[AUTO-E] E tuşuna basıldı.")
        end
        task.wait(6) -- Tam olarak 6 saniye aralıkla çalışır
    end
end)

-- 10 Saniye Geri Işınlanma Mekanizması
RewindBtn.MouseButton1Click:Connect(function()
    local char = lplayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and #konumGecmisi > 0 then
        hrp.CFrame = konumGecmisi[1]
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        print("[REWIND] 10 saniye önceki konuma dönüldü!")
    end
end)

-- FIFO Konum Kaydedici (Maksimum 10 kayıt)
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

-- WalkFly (Belli Etmeden Havada Yürüme) Modülü
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

-- 0.5 Saniyede Bir Otomatik Vuruş Döngüsü
task.spawn(function()
    while true do
        if AUTO_ATTACK_AKTIF then
            VirtualUser:Button1Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.wait(0.01)
            VirtualUser:Button1Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end
        task.wait(0.5)
    end
end)

-- En Yakın Oyuncuyu Bulma
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

-- Akıllı Kırmızı Nesne Algılayıcı
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

-- Gelişmiş Sabitleyiciler & Hız ve Hitbox Modülü
RunService.RenderStepped:Connect(function()
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
    
    local char = lplayer.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = 50
        humanoid.PlatformStand = WALKFLY_AKTIF and true or false
        if humanoid.Sit then humanoid.Sit = false end
    end
end)

-- GÖRÜNMEZLİK VE KALKAN FONKSİYONU
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

-- ANLIK GİZLİ SALDIRI TETİKLEYİCİSİ
BackstabBtn.MouseButton1Click:Connect(function()
    if saldiriyor then return end
    local char = lplayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local hedef = getEnYakinOyuncu()
    if not hedef then return end

    saldiriyor = true
    local eskiKonum = hrp.CFrame 

    VirtualUser:Button1Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(0.01)
    VirtualUser:Button1Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)

    task.wait(0.19)
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

-- RAYCAST TABANLI DEFANS KORUMASI (Sadece Yatay)
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

print("6s Oto-E Döngülü Hepsi Bir Arada Menü Başarıyla Güncellendi.")
