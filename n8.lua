local g = game
local p = g:GetService("Players")
local tw = g:GetService("TweenService")
local l = p.LocalPlayer
local c = workspace.CurrentCamera

local function giveDashOnly()
    local bp = l:WaitForChild("Backpack")
    
    
    if bp:FindFirstChild("Dash") then return end
    
    local dashTool = Instance.new("Tool")
    dashTool.Name = "Dash"
    dashTool.RequiresHandle = false
    dashTool.ToolTip = "Basılı Tut ve Bırak"
    
    local isCharging = false
    local chargeStartTime = 0
    local maxChargeTime = 1.0
    
    dashTool.Activated:Connect(function()
        if isCharging then return end
        isCharging = true
        chargeStartTime = tick()
        tw:Create(c, TweenInfo.new(maxChargeTime, Enum.EasingStyle.Linear), {FieldOfView = c.FieldOfView - 10}):Play()
    end)
    
    dashTool.Deactivated:Connect(function()
        if not isCharging then return end
        isCharging = false
        
        local char = l.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local hrp = char.HumanoidRootPart
        
        local holdTime = math.clamp(tick() - chargeStartTime, 0, maxChargeTime)
        local dashDist = 20 + (holdTime * 80)
        
        
        tw:Create(c, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {FieldOfView = 70 + 30}):Play()
        
        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = {char}
        rayParams.FilterType = Enum.RaycastFilterType.Blacklist
        
        local lookDir = hrp.CFrame.LookVector
        local result = workspace:Raycast(hrp.Position, lookDir * dashDist, rayParams)
        
        local endPos = result and (result.Position - (lookDir * 2)) or (hrp.Position + (lookDir * dashDist))
        
        
        local streak = Instance.new("Part")
        streak.Anchored = true
        streak.CanCollide = false
        streak.Material = Enum.Material.Neon
        streak.Color = Color3.fromRGB(255, 30, 30)
        streak.Size = Vector3.new(2, 2, (endPos - hrp.Position).Magnitude)
        streak.CFrame = CFrame.lookAt(hrp.Position, endPos) * CFrame.new(0, 0, -(endPos - hrp.Position).Magnitude / 2)
        streak.Parent = workspace
        
        tw:Create(hrp, TweenInfo.new(0.15, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {CFrame = CFrame.new(endPos) * CFrame.Angles(hrp.CFrame:ToEulerAnglesXYZ())}):Play()
        tw:Create(streak, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1}):Play()
        g:GetService("Debris"):AddItem(streak, 0.5)
        
        task.wait(0.15)
        tw:Create(c, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {FieldOfView = 70}):Play()
    end)
    
    
    local existingItems = bp:GetChildren()
    for _, item in ipairs(existingItems) do item.Parent = nil end
    
    
    local filler = Instance.new("Folder") 
    filler.Name = "Filler"
    filler.Parent = bp
    
    dashTool.Parent = bp
    
    for _, item in ipairs(existingItems) do item.Parent = bp end
end

giveDashOnly()
l.CharacterAdded:Connect(function()
    task.wait(0.5)
    giveDashOnly()
end)

