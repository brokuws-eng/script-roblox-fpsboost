-- ================================================================
-- ROBBLOX OPTIMIZER (FPS BOOST)
-- ================================================================

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

-- 1. Menurunkan kualitas pencahayaan
Lighting.GlobalShadows = false
Lighting.FogEnd = 500
Lighting.ExposureCompensation = -3.0

-- 2. Matikan semua partikel dan efek visual yang berat
for _, descendant in ipairs(Workspace:GetDescendants()) do
    if descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") or descendant:IsA("Fire") or descendant:IsA("Smoke") or descendant:IsA("Sparkles") then
        descendant.Enabled = false
    end
    
    if descendant:IsA("BasePart") then
        descendant.CastShadow = false
        descendant.Material = Enum.Material.SmoothPlastic
    end
    
    if descendant:IsA("Decal") or descendant:IsA("Texture") then
        pcall(function() descendant:Destroy() end)
    end
end

-- 3. Matikan semua suara yang tidak perlu
for _, sound in ipairs(Workspace:GetDescendants()) do
    if sound:IsA("Sound") then
        pcall(function() sound:Destroy() end)
    end
end

-- 4. Menghapus semua GUI yang tidak perlu
for _, gui in ipairs(game:GetService("CoreGui"):GetChildren()) do
    if gui.Name ~= "RobloxOptimizer" and gui.Name ~= "Delta" and gui.Name ~= "DeltaHub" then
        pcall(function() gui:Destroy() end)
    end
end

-- 5. Menghapus semua ProximityPrompt yang tidak perlu
for _, prompt in ipairs(Workspace:GetDescendants()) do
    if prompt:IsA("ProximityPrompt") then
        pcall(function() prompt:Destroy() end)
    end
end

-- ================================================================
-- PRINT STATUS
-- ================================================================
print("✅ RobloxOptimizer berhasil dijalankan!")
