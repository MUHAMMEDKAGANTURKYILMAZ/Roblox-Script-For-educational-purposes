--// INSTANT NINJA ANIMATOR (Sıfır Gecikme)
--// Tırmanma, Yüzme, Oturma dahil tüm animasyonlar anında tepki verir.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Tüm Ninja Animasyon ID'leri
local ninjaIDs = {
    Idle = "rbxassetid://656117400",
    Walk = "rbxassetid://656121766",
    Run = "rbxassetid://656118852",
    Jump = "rbxassetid://656107599",
    Fall = "rbxassetid://656115606",
    Climb = "rbxassetid://656114359",
    Swim = "rbxassetid://656121397",
    SwimIdle = "rbxassetid://656122214",
    Sit = "rbxassetid://2506281703" -- Bonus: Karakter oturduğunda Ninja gibi oturur
}

local player = Players.LocalPlayer
local currentConnection

local function setupInstantAnimations(char)
    -- Eski döngüyü temizle
    if currentConnection then
        currentConnection:Disconnect()
    end

    local humanoid = char:WaitForChild("Humanoid")
    local rootPart = char:WaitForChild("HumanoidRootPart")
    local animator = humanoid:WaitForChild("Animator")

    -- 1. ADIM: Roblox'un yavaş geçiş yapan varsayılan sistemini tamamen yok et
    local defaultAnimate = char:WaitForChild("Animate", 3)
    if defaultAnimate then
        defaultAnimate.Disabled = true
    end

    -- 2. ADIM: Karakterde şu an çalan her şeyi anında durdur
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        track:Stop(0)
    end

    -- 3. ADIM: Animasyonları yükle ve döngü (loop) ayarlarını yap
    local tracks = {}
    for name, id in pairs(ninjaIDs) do
        local anim = Instance.new("Animation")
        anim.AnimationId = id
        local track = animator:LoadAnimation(anim)
        
        -- Zıplama ve Düşme hariç her şey sürekli tekrarlanmalıdır
        if name ~= "Jump" and name ~= "Fall" then
            track.Looped = true
        end
        tracks[name] = track
    end

    local currentAnimName = nil

    -- SIFIR GECİKME FONKSİYONU
    local function playAnim(name)
        -- Eğer zaten o animasyondaysak hiçbir şey yapma
        if currentAnimName == name then return end
        
        -- Eski animasyonu 0 saniye fade ile ANINDA durdur
        if currentAnimName and tracks[currentAnimName] then
            tracks[currentAnimName]:Stop(0)
        end
        
        -- Yeni animasyonu 0 saniye fade ile ANINDA başlat
        if tracks[name] then
            tracks[name]:Play(0)
            currentAnimName = name
        end
    end

    -- 4. ADIM: Saniyede 60 kere karakterin ne yaptığını kontrol eden motor
    currentConnection = RunService.RenderStepped:Connect(function()
        if not char or humanoid.Health <= 0 then return end

        local state = humanoid:GetState()
        local velocity = rootPart.AssemblyLinearVelocity
        local flatSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude

        local nextAnim = "Idle"

        -- Karakterin durumuna göre hangi animasyonun çalacağını seçiyoruz
        if state == Enum.HumanoidStateType.Jumping then
            nextAnim = "Jump"
        elseif state == Enum.HumanoidStateType.Freefall then
            nextAnim = "Fall"
        elseif state == Enum.HumanoidStateType.Climbing then
            nextAnim = "Climb"
        elseif state == Enum.HumanoidStateType.Swimming then
            nextAnim = flatSpeed > 1 and "Swim" or "SwimIdle"
        elseif state == Enum.HumanoidStateType.Seated then
            nextAnim = "Sit"
        else
            -- Yerdeyken hıza göre Yürüme veya Koşma
            if flatSpeed > 0.5 then
                if flatSpeed > 18 then -- Hız 18'den fazlaysa kollar arkada koşar
                    nextAnim = "Run"
                else
                    nextAnim = "Walk" -- Normal hızda yürür
                end
            else
                nextAnim = "Idle"
            end
        end

        -- Seçilen animasyonu sıfır gecikme ile ekrana yansıt
        playAnim(nextAnim)
    end)
end

-- Script ilk çalıştığında uygula
if player.Character then
    setupInstantAnimations(player.Character)
end

-- Karakter her öldüğünde/yeniden doğduğunda sistemi tekrar bağla
player.CharacterAdded:Connect(function(char)
    setupInstantAnimations(char)
end)

