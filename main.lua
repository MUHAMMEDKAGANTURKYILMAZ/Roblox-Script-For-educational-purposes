--====================================================================
-- ADVANCED EXPLOIT TEST SUITE (STRESS TEST v4)
--====================================================================
-- Bu script tamamen laboratuvar ortamında sunucu korumalarını (Server Anti-Cheat)
-- test etmek amacıyla istemci tarafında (Executor) çalıştırılmak üzere yazılmıştır.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local lplayer = Players.LocalPlayer
if not lplayer then return end

--====================================================================
-- 1. KATMAN: CORE METATABLE HOOKING & API MASKELEME
--====================================================================
local rawmt = getrawmetatable(game)
local oldNamecall = rawmt.__namecall
local oldIndex = rawmt.__index
setreadonly(rawmt, false)

rawmt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    -- Anti-Kick: İstemci tabanlı yerel Kick çağrılarını yutar
    if method == "Kick" or method == "kick" then
        print("[TEST-BYPASS] Yerel Kick çağrısı engellendi.")
        return nil
    end
    
    -- Network Filter: Raporlama ve tespit içeren Remote sinyallerini bloke eder
    if method == "FireServer" or method == "InvokeServer" then
        local rName = string.lower(self.Name)
        if string.find(rName, "cheat") or string.find(rName, "ban") or string.find(rName, "kick") or string.find(rName, "detect") then
            print("[TEST-BYPASS] Tespit sinyali engellendi: " .. self.Name)
            return nil
        end
    end
    return oldNamecall(self, unpack(args))
end)

rawmt.__index = newcclosure(function(self, key)
    -- Memory Spoofing: Koruma scriptleri hız değerini sorguladığında yalan söyler
    if self:IsA("Humanoid") and not checkcaller() then
        if key == "WalkSpeed" then return 16
        elseif key == "JumpPower" or key == "JumpHeight" then return 50 end
    end
    return oldIndex(self, key)
end)
setreadonly(rawmt, true)

--====================================================================
-- 2. KATMAN: DOYSA SİSTEMİ İLE KALICI SPAWN (GİRİŞ-ÇIKIŞ HAFIZASI)
--====================================================================
local spawnFile = "KalıcıKonum_Veritabani.txt"
local baslangicCFrame = nil

if isfile and writefile and readfile then
    if not isfile(spawnFile) then
        local char = lplayer.Character or lplayer.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")
        writefile(spawnFile, HttpService:JSONEncode({hrp.CFrame.X, hrp.CFrame.Y, hrp.CFrame.Z}))
        baslangicCFrame = hrp.CFrame
        print("[DATABASE] İlk giriş konumu kalıcı olarak dosyaya yazıldı.")
    else
        local veri = HttpService:JSONDecode(readfile(spawnFile))
        baslangicCFrame = CFrame.new(veri[1], veri[2], veri[3])
        print("[DATABASE] Kalıcı spawn konumu başarıyla yüklendi.")
    end
end

-- Dinamik boyut algılayıcı
local function getKarakterBoyut()
    local char = lplayer.Character
    if char and char:FindFirstChild("Humanoid") then
        return char.Humanoid.HipHeight > 0 and char.Humanoid.HipHeight or 2
    end
    return 2
end

--====================================================================
-- 3. KATMAN: AKILLI ÇEVRE VE MESAFE KORUMASI (RAYCAST DUVARI)
--====================================================================
local flyModu = false
local ucmaHizi = 85
local sonZiplama = 0
local ziplamaSayisi = 0
local setKonumu = nil
local konumGecmisi = {}

local function cevreKorumasıGuncelle(hrp, boyut)
    local tehlikeVar = false
    for _, other in pairs(Players:GetPlayers()) do
        if other ~= lplayer and other.Character and other.Character:FindFirstChild("HumanoidRootPart") then
            local oHrp = other.Character.HumanoidRootPart
            local mesafe = (hrp.Position - oHrp.Position).Magnitude
            
            -- Karakterin 1.5 katı mesafeye düşman yaklaşırsa
            if mesafe <= (boyut * 1.5) then
                tehlikeVar = true
                
                -- Karakterin boyutunun 2 katı uzaklıkta zemin araması (Raycast)
                local raycastParams = RaycastParams.new()
                raycastParams.FilterDescendantsInstances = {lplayer.Character, other.Character}
                raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                
                local sapmaYonu = hrp.CFrame.LookVector * (boyut * 2)
                local zeminKontrol = workspace:Raycast(hrp.Position + sapmaYonu + Vector3.new(0, 5, 0), Vector3.new(0, -25, 0), raycastParams)
                
                if zeminKontrol then
                    hrp.CFrame = CFrame.new(zeminKontrol.Position + Vector3.new(0, 3, 0))
                else
                    -- Güvenli zemin yoksa havaya ışınla ve asılı bırak
                    hrp.CFrame = hrp.CFrame + Vector3.new(0, boyut * 5, 0)
                    
                    local kilit = hrp:FindFirstChild("HavaKilidi") or Instance.new("BodyVelocity")
                    kilit.Name = "HavaKilidi"
                    kilit.Velocity = Vector3.new(0, 0, 0)
                    kilit.MaxForce = Vector3.new(0, math.huge, 0)
                    kilit.Parent = hrp
                end
                break
            end
        end
    end
    if not tehlikeVar and hrp:FindFirstChild("HavaKilidi") and not flyModu then
        hrp.HavaKilidi:Destroy()
    end
end

--====================================================================
-- 4. KATMAN: FIFO REWIND & DİNAMİK ÖLÜM MEKANİZMASI
--====================================================================
lplayer.CharacterAdded:Connect(function(char)
    local hrp = char:WaitForChild("HumanoidRootPart")
    task.wait(0.1)
    if baslangicCFrame then hrp.CFrame = baslangicCFrame end
    
    local humanoid = char:WaitForChild("Humanoid")
    humanoid.Died:Connect(function()
        if setKonumu then
            -- Ölmeden önceki 10. saniyedeki konumu dizinden çek
            local hedefGecmisKonum = konumGecmisi[1] or hrp.CFrame
            
            task.spawn(function()
                local yeniChar = lplayer.CharacterAdded:Wait()
                local yeniHrp = yeniChar:WaitForChild("HumanoidRootPart")
                local boyut = getKarakterBoyut()
                
                -- Adım 1: Düz "set" konumuna anında ışınlanma
                yeniHrp.CFrame = setKonumu
                task.wait(3)
                
                -- Adım 2: 10 saniye önceki konumun 5 katı yukarısı
                yeniHrp.CFrame = hedefGecmisKonum + Vector3.new(0, boyut * 5, 0)
                
                -- Adım 3: 1 saniye havada asılı kalma (LinearVelocity)
                local lv = Instance.new("LinearVelocity")
                local att = Instance.new("Attachment")
                att.Parent = yeniHrp
                lv.Attachment0 = att
                lv.VectorVelocity = Vector3.new(0, 0, 0)
                lv.MaxForce = math.huge
                lv.Parent = yeniHrp
                
                task.wait(1)
                lv:Destroy()
                att:Destroy()
            end)
        end
    end)
end)

-- FIFO Saat Mekanizması (10 Saniyelik Hafıza)
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

--====================================================================
-- 5. KATMAN: ZIPLAMA TETİKLEYİCİLİ FLY & SÜREKLİ HIZ
--====================================================================
UserInputService.JumpRequest:Connect(function()
    local suAn = tick()
    if suAn - sonZiplama < 0.35 then
        ziplamaSayisi = ziplamaSayisi + 1
    else
        ziplamaSayisi = 1
    end
    sonZiplama = suAn

    if ziplamaSayisi >= 3 then
        flyModu = not flyModu
        ziplamaSayisi = 0
    end
end)

RunService.Heartbeat:Connect(function()
    local char = lplayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then return end
    
    local hrp = char.HumanoidRootPart
    local humanoid = char.Humanoid
    local boyut = getKarakterBoyut()
    
    -- Hız her karede zorla 50'ye setlenir
    humanoid.WalkSpeed = 50
    
    cevreKorumasıGuncelle(hrp, boyut)
    
    -- Delta Tarzı Fly Kontrolü
    if flyModu then
        humanoid.PlatformStand = true
        local bv = hrp:FindFirstChild("FlyMotoru") or Instance.new("BodyVelocity")
        bv.Name = "FlyMotoru"
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        
        local cam = workspace.CurrentCamera
        local yon = Vector3.new(0,0,0)
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then yon = yon + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then yon = yon - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then yon = yon - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then yon = yon + cam.CFrame.RightVector end
        
        bv.Velocity = yon * ucmaHizi
        bv.Parent = hrp
    else
        humanoid.PlatformStand = false
        if hrp:FindFirstChild("FlyMotoru") then hrp.FlyMotoru:Destroy() end
    end
end)

--====================================================================
-- 6. KATMAN: SOHBET TABANLI HEDEF PENETRASYONU VE ETKİLEŞİM
--====================================================================
lplayer.Chatted:Connect(function(msg)
    local char = lplayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    
    if msg:lower() == "set" then
        setKonumu = hrp.CFrame
        print("[SYS] Geri dönüş koordinatları güncellendi.")
    end
    
    -- Oyuncu İçine Sızma ve Kasırga Fırlatması
    for _, hedef in pairs(Players:GetPlayers()) do
        if hedef ~= lplayer and hedef.Name:lower() == msg:lower() then
            task.spawn(function()
                local tBaslangic = tick()
                print("[ATTACK] Hedef kilitlendi: " .. hedef.Name)
                
                while tick() - tBaslangic < 1 do
                    RunService.RenderStepped:Wait()
                    local hChar = hedef.Character
                    if hChar and hChar:FindFirstChild("HumanoidRootPart") then
                        -- İç içe geçme ve eksenel rotasyon manipülasyonu
                        hrp.CFrame = hChar.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(1440 * tick()), 0)
                        
                        -- Ağ momentumu (AssemblyLinearVelocity) manipülasyon denemesi
                        hChar.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(math.random(-50,50), 350, math.random(-50,50))
                    end
                end
            end)
        end
    end
end)

print("[SUITE] Tüm test modülleri başarıyla birleştirildi. Kontroller aktif.")
