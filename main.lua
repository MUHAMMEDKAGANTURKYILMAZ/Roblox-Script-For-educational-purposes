--====================================================================
-- HORIZONTAL 2D EVASION & RAYCAST SAFE GUARD (MENZİL 25 - HIZ SAYAÇLI)
--====================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local lplayer = Players.LocalPlayer
local setKonumu = nil
local konumGecmisi = {}

-- GÜVENLİK VE METRİK AYARLARI
local MENZIL = 25          -- 25 stud mesafeye bir oyuncu girdiğinde tetiklenir
local KACIS_MESAFESI = 30  -- Yatay düzlemde kaç stud uzağa kaçılacağı

-- Karakter boyutu algılayıcı
local function getKarakterBoyut()
    local char = lplayer.Character
    if char and char:FindFirstChild("Humanoid") then
        return char.Humanoid.HipHeight > 0 and char.Humanoid.HipHeight or 2
    end
    return 2
end

-- 4 Saniyede Bir Hızı 50 Yapma Döngüsü
task.spawn(function()
    while true do
        local char = lplayer.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 50
        end
        task.wait(4) -- Her 4 saniyede bir tetiklenir
    end
end)

-- Yatay Düzlemde Kaçış ve Kesin Zemin Kontrol Döngüsü
RunService.Heartbeat:Connect(function()
    local char = lplayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    for _, other in pairs(Players:GetPlayers()) do
        if other ~= lplayer and other.Character and other.Character:FindFirstChild("HumanoidRootPart") then
            local oHrp = other.Character.HumanoidRootPart
            local mesafe = (hrp.Position - oHrp.Position).Magnitude
            
            -- Belirlenen menzile girildiğinde tetiklenir
            if mesafe <= MENZIL then
                local bulunanGuvliKonum = nil
                
                -- Güvenli zemin bulana kadar maksimum 5 deneme yapar (Sonsuz döngü kilidini önler)
                for i = 1, 5 do
                    -- Sadece X ve Z eksenlerinde (Yatay) 360 derece rastgele yön
                    local rastgeleAci = math.rad(math.random(0, 360))
                    local yatayYon = Vector3.new(math.cos(rastgeleAci), 0, math.sin(rastgeleAci))
                    local hedefPozisyon = hrp.Position + (yatayYon * KACIS_MESAFESI)
                    
                    -- RAYCAST ILE BOŞLUK KONTROLÜ
                    -- Hedeflenen noktanın 10 stud yukarısından aşağıya doğru 40 stud boyunca zemin arar
                    local raycastParams = RaycastParams.new()
                    raycastParams.FilterDescendantsInstances = {char, other.Character}
                    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                    
                    local rayOrigin = hedefPozisyon + Vector3.new(0, 10, 0)
                    local rayDirection = Vector3.new(0, -40, 0)
                    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
                    
                    -- Eğer altında basabileceği katı bir zemin (Part/Terrain) bulunduysa koordinatı onaylar
                    if raycastResult then
                        bulunanGuvliKonum = raycastResult.Position + Vector3.new(0, getKarakterBoyut(), 0)
                        break
                    end
                end
                
                -- Eğer güvenli zemin doğrulandıysa ışınlanmayı gerçekleştirir
                if bulunanGuvliKonum then
                    hrp.CFrame = CFrame.new(bulunanGuvliKonum)
                    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    print("[GÜVENLİK] Doğrulanmış katı zemine yatay ışınlanma yapıldı. Boşluk engellendi.")
                    task.wait(0.3) -- Ardışık tetiklenme engelleme süresi
                    break
                end
            end
        end
    end
end)

-- FIFO Zaman Döngüsü (Son 10 saniyenin konum kaydı)
task.spawn(function()
    while true do
        task.wait(1)
        local char = lplayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            table.insert(konumGecmisi, char.HumanoidRootPart.CFrame)
            if #konumGecmisi > 10 then 
                table.remove(konumGecmisi, 1) 
            end
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
                
                -- 1. Aşama: SET konumuna ışınlanma
                yeniHrp.CFrame = setKonumu
                task.wait(3)
                
                -- 2. Aşama: 10 saniye önceki konumun 5 katı yukarısı
                yeniHrp.CFrame = hedefGecmisKonum + Vector3.new(0, boyut * 5, 0)
                
                -- 3. Aşama: 1 saniye havada asılı tutma
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

-- Sohbet Takipçisi (Set ve Oyuncu Fırlatma)
lplayer.Chatted:Connect(function(msg)
    local char = lplayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    if msg:lower() == "set" then
        setKonumu = hrp.CFrame
        print("Işınlanma noktası başarıyla kaydedildi.")
    end
    
    -- Oyuncu içine sızma ve fırlatma döngüsü
    for _, hedef in pairs(Players:GetPlayers()) do
        if hedef ~= lplayer and hedef.Name:lower() == msg:lower() then
            task.spawn(function()
                local tBaslangic = tick()
                while tick() - tBaslangic < 1 do
                    RunService.RenderStepped:Wait()
                    local hChar = hedef.Character
                    if hChar and hChar:FindFirstChild("HumanoidRootPart") then
                        hrp.CFrame = hChar.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(720 * tick()), 0)
                        hChar.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 250, 0)
                    end
                end
            end)
        end
    end
end)

print("Yatay kaçış, Raycast zemin koruması ve 4s hız döngüsü aktif.")
