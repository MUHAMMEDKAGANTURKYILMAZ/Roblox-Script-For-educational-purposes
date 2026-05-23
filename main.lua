--====================================================================
-- ADVANCED 3D EVASION SCRIPT (MENZİL 25 - 3D RASTGELE KAÇIŞ)
--====================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local lplayer = Players.LocalPlayer
local setKonumu = nil
local konumGecmisi = {}

-- GÜNCEL METRİK AYARLARI
local MENZIL = 25          -- 25 stud mesafeye bir oyuncu girdiğinde tetiklenir
local KACIS_MESAFESI = 30  -- Her yöne 30 stud uzağa rastgele ışınlanır

-- Karakter boyutu algılayıcı
local function getKarakterBoyut()
    local char = lplayer.Character
    if char and char:FindFirstChild("Humanoid") then
        return char.Humanoid.HipHeight > 0 and char.Humanoid.HipHeight or 2
    end
    return 2
end

-- 3 Boyutlu Tam Rastgele Kaçış Döngüsü
RunService.Heartbeat:Connect(function()
    local char = lplayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    for _, other in pairs(Players:GetPlayers()) do
        if other ~= lplayer and other.Character and other.Character:FindFirstChild("HumanoidRootPart") then
            local oHrp = other.Character.HumanoidRootPart
            local mesafe = (hrp.Position - oHrp.Position).Magnitude
            
            -- Mesafe 25 stud veya daha altındaysa tetiklenir
            if mesafe <= MENZIL then
                -- Küresel (3D) rastgele yön vektörü hesaplama
                local rastgeleX = math.random(-100, 100) / 100
                local rastgeleY = math.random(0, 100) / 100 -- Yere çakılmayı önlemek için yukarı/düz eksen odaklı
                local rastgeleZ = math.random(-100, 100) / 100
                
                local hamYon = Vector3.new(rastgeleX, rastgeleY, rastgeleZ).Unit
                local kacisVektoru = hamYon * KACIS_MESAFESI
                
                -- Yeni hedef 3D koordinatı
                local yeniKonum = hrp.Position + kacisVektoru
                
                -- BOŞLUĞA DÜŞMEYİ ENGELLEYEN GENİŞ GÜVENLİK KUTUSU
                local platform = Instance.new("Part")
                platform.Size = Vector3.new(10, 0.5, 10) -- 10x10 geniş güvenli basma alanı
                platform.Position = yeniKonum - Vector3.new(0, (getKarakterBoyut() + 0.25), 0)
                platform.Anchored = true
                platform.Transparency = 1 -- Tamamen görünmez
                platform.CanCollide = true
                platform.Parent = workspace
                
                -- Karakteri anında 3D koordinata taşı ve tüm fiziksel momentumu sıfırla
                hrp.CFrame = CFrame.new(yeniKonum)
                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                
                -- Platformun güvenli temizliği
                task.spawn(function()
                    task.wait(0.7) -- Havada kalma garantisi süresi
                    platform:Destroy()
                end)
                
                print("[3D-KAÇIŞ] Oyuncu 25 stud sınırına girdi! 30 stud uzağa her yöne rastgele kaçıldı.")
                task.wait(0.3) -- Spam ışınlanma koruma gecikmesi
                break
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
                        akonsona12345678906hChar.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 250, 0)
                    end
                end
            end)
        end
    end
end)

print("25 Stud menzilli, 30 Stud 3D rastgele kaçış kodu aktif.")
