-- ================================================================
-- GOLLHUB V1 - FPS BOOST ONLY (NO GUI)
-- ================================================================

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

-- ================================================================
-- FUNGSI FPS BOOST
-- ================================================================

-- 1. Turunkan kualitas cahaya & matikan bayangan
Lighting.GlobalShadows = false
Lighting.FogEnd = 800
Lighting.ExposureCompensation = -0.5

-- 2. Matikan semua partikel, efek, dan tekstur yang berat
task.spawn(function()
    while true do
        -- Matikan semua partikel di workspace
        for _, descendant in ipairs(Workspace:GetDescendants()) do
            if descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") or descendant:IsA("Fire") or descendant:IsA("Smoke") or descendant:IsA("Sparkles") then
                descendant.Enabled = false
            end
            
            -- Matikan bayangan pada part
            if descendant:IsA("BasePart") then
                descendant.CastShadow = false
                descendant.Material = Enum.Material.SmoothPlastic
            end
            
            -- Hapus tekstur dan decal yang berat
            if descendant:IsA("Decal") or descendant:IsA("Texture") then
                pcall(function() descendant:Destroy() end)
            end
        end
        
        -- Matikan semua GUI yang tidak perlu di CoreGui
        for _, gui in ipairs(CoreGui:GetChildren()) do
            if gui.Name ~= "GollHub" then
                pcall(function() gui:Destroy() end)
            end
        end
        
        task.wait(5) -- Ulangi setiap 5 detik
    end
end)

-- 3. Matikan semua animasi dan suara yang tidak perlu
task.spawn(function()
    while true do
        for _, sound in ipairs(Workspace:GetDescendants()) do
            if sound:IsA("Sound") then
                pcall(function() sound:Destroy() end)
            end
        end
        task.wait(10)
    end
end)

-- ================================================================
-- PRINT STATUS
-- ================================================================
