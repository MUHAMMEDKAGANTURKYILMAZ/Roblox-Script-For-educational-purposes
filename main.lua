--====================================================================
-- ADVANCED COMBAT & MOBILE UI SUITE (BACKSTAB & EVASION TOGGLE)
--====================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

local lplayer = Players.LocalPlayer
local setKonumu = nil
local konumGecmisi = {}

-- GLOBAL AYARLAR
local MENZIL = 25          
local KACIS_MESAFESI = 30  
local kacanKullaniciAktif = true -- Arayüzden kontrol edilebilir kaçış durumu

-- Karakter Boyut Algılayıcı
local function getKarakterBoyut()
    local char = lplayer.Character
    if char and char:FindFirstChild("Humanoid") then
        return char.Humanoid.HipHeight > 0 and char.Humanoid.HipHeight or 2
    end
    return 2
end

-- 4 Saniyede Bir Hız Sabitleme
task.spawn(function()
    while true do
        local char = lplayer.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.WalkSpeed = 50 end
        task.wait(4)
    end
end)

-- Sürükleme Fonksiyonu (Mobil & PC Uyumlu UI Sürükleyici)
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

-- SCREEN GUI KURULUMU
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CombatSuiteGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = lplayer:WaitForChild("PlayerGui")

-- 1. SALDIRI BUTONU (SÜRÜKLEBİLİR)
local AttackBtn = Instance.new("TextButton")
AttackBtn.Size = UDim2.new(0, 110, 0, 50)
AttackBtn.Position = UDim2.new(0, 20, 0, 100)
AttackBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
AttackBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AttackBtn.TextSize = 16
AttackBtn.Font = Enum.Font.SourceSansBold
AttackBtn.Text = "SALDIR (BACK)"
AttackBtn.BorderSizePixel = 2
AttackBtn.Parent = ScreenGui
makeDraggable(AttackBtn)

-- 2. KAÇIŞ OTOMASYON BUTONU (SÜRÜKLEBİLİR)
local ToggleEvasionBtn = Instance.new("TextButton")
ToggleEvasionBtn.Size = UDim2.new(0, 110, 0, 50)
ToggleEvasionBtn.Position = UDim2.new(0, 20, 0, 160)
ToggleEvasionBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 50)
ToggleEvasionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleEvasionBtn.TextSize = 14
ToggleEvasionBtn.Font = Enum.Font.SourceSansBold
ToggleEvasionBtn.Text = "KORUMA: AKTIF"
ToggleEvasionBtn.BorderSizePixel = 2
ToggleEvasionBtn.Parent = ScreenGui
makeDraggable(ToggleEvasionBtn)

-- Koruma Buton Tetikleyicisi
ToggleEvasionBtn.MouseButton1Click:Connect(function()
    kacanKullaniciAktif = not kacanKullaniciAktif
    if kacanKullaniciAktif then
        ToggleEvasionBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 50)
        ToggleEvasionBtn.Text = "KORUMA: AKTIF"
    else
        ToggleEvasionBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        ToggleEvasionBtn.Text = "KORUMA: DEAKTIF"
    end
end)

-- En Yakın Oyuncuyu Bulma Fonksiyonu
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

-- Kalkan / Bloklama Efekti (Hasar Engelleme)
local function setKalkanDurumu(aktif)
    local char = lplayer.Character
    if not char then return end
    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            part.CanCollide = not aktif
            part.Transparency = aktif and 0.5 or 0
        end
    end
end

-- SALDIRI KOMBO MEKANİZMASI (MOUSE1 + ARKAYA SIZMA + GERİ DÖNÜŞ)
local saldiriyor = false
AttackBtn.MouseButton1Click:Connect(function()
    if saldiriyor then return end
    local char = lplayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local hedef = getEnYakinOyuncu()
    if not hedef then print("Yakında saldırılacak oyuncu bulunamadı!") return end

    saldiriyor = true
    local eskiKonum = hrp.CFrame -- Orijinal konumu hafızaya al

    -- 1. Aşama: Ekrana sanal tıklama gönder (Silah/Yumruk tetiklenir)
    VirtualUser:Button1Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(0.01)
    VirtualUser:Button1Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)

    -- 2. Aşama: 0.2 saniye sonra arkaya sızma ve sürekli takip döngüsü
    task.wait(0.19)
    setKalkanDurumu(true) -- Otomatik Kalkan Aktif

    local tBaslangic = tick()
    while tick() - tBaslangic < 0.5 do
        RunService.RenderStepped:Wait()
        local hChar = hedef.Character
        local hHrp = hChar and hChar:FindFirstChild("HumanoidRootPart")
        local gHrp = lplayer.Character and lplayer.Character:FindFirstChild("HumanoidRootPart")
        
        if hHrp and gHrp then
            -- Hedef oyuncunun tam arkasını (0 mesafe) hesapla ve yüzünü ona dön
            local arkaKonum = hHrp.CFrame * CFrame.new(0, 0, 1) 
            gHrp.CFrame = CFrame.new(arkaKonum.Position, hHrp.Position)
            gHrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        else
            break
        end
    end

    -- 3. Aşama: Başlangıç noktasına geri ışınlanma ve kalkanı kapatma
    if lplayer.Character and lplayer.Character:FindFirstChild("HumanoidRootPart") then
        lplayer.Character.HumanoidRootPart.CFrame = eskiKonum
        lplayer.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    end
    setKalkanDurumu(false) -- Kalkan Deaktif
    saldiriyor = false
end)

-- DEFANS: Raycast Tabanlı Yatay Kaçış Döngüsü
RunService.Heartbeat:Connect(function()
    if not kacanKullaniciAktif or saldiriyor then return end
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

-- FIFO Zaman Döngüsü
task.spawn(function()
    while true do
        task.wait(1)
        local char = lplayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            table.insert(konumGecmisi, char.HumanoidRootPart.CFrame)
            if #konumGecmisi > 10 then table.remove(konumGecmisi, 1) end
        end
    end
end)

-- Ölüm ve Geri Sarma Mekanizması
lplayer.CharacterAdded:Connect(function(char)
    local hrp = char:WaitForChild("HumanoidRootPart")
    local humanoid = char:WaitForChild("Humanoid")
    
    humanoid.Died:Connect(function()
        if setKonumu then
            local hedefGecmisKonum = konumGecmisi[1] or hrp.CFrame
            task.spawn(function()
                local yeniChar = lplayer.CharacterAdded:Wait()
                local yeniHrp = yeniChar:WaitForChild("HumanoidRootPart")
                local boyut = getKarakterBoyut()
                
                yeniHrp.CFrame = setKonumu
                task.wait(3)
                yeniHrp.CFrame = hedefGecmisKonum + Vector3.new(0, boyut * 5, 0)
                
                local bv = Instance.new("BodyVelocity")
                bv.Velocity = Vector3.new(0, 0, 0)
                bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bv.Parent = yeniHrp
                task.wait(1)
                bv:Destroy()
            end)
        end
    end)
end)

-- Chat Takipçisi (set komutu)
lplayer.Chatted:Connect(function(msg)
    local char = lplayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if msg:lower() == "set" then
        setKonumu = hrp.CFrame
        print("Işınlanma noktası kaydedildi.")
    end
end)

print("Gelişmiş Mobil UI, Backstab Kombo ve Kalkan Sistemi Yüklendi.")

