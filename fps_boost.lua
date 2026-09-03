-- ==============================================
-- SCRIPT FPS BOOST - Optimalisasi Performa Roblox
-- ==============================================

-- Ambil semua service yang dibutuhkan
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserSettings = UserSettings()
local LocalPlayer = Players.LocalPlayer

-- ==============================================
-- 1. TURUNKAN KUALITAS GRAFIS
-- ==============================================

-- Set kualitas grafis ke level terendah (Level 1)
pcall(function()
    UserSettings.GameSettings.GraphicsQualityLevel = Enum.QualityLevel.Level1
end)

-- ==============================================
-- 2. MATIKAN EFEK VISUAL
-- ==============================================

-- Matikan bayangan
Lighting.GlobalShadows = false
Lighting.FogEnd = 1
Lighting.FogStart = 1
Lighting.Brightness = 1

-- Turunkan kualitas air
pcall(function()
    Workspace.Terrain.WaterWaveSize = 0
    Workspace.Terrain.WaterWaveSpeed = 0
end)

-- ==============================================
-- 3. HAPUS PARTIKEL & EFEK YANG TIDAK PERLU
-- ==============================================

local function removeParticles()
    for _, obj in pairs(Workspace:GetDescendants()) do
        pcall(function()
            if obj:IsA("ParticleEmitter") or 
               obj:IsA("Trail") or 
               obj:IsA("Smoke") or 
               obj:IsA("Fire") or 
               obj:IsA("Sparkles") or
               obj:IsA("BloomEffect") or
               obj:IsA("BlurEffect") or
               obj:IsA("SunRaysEffect") or
               obj:IsA("ColorCorrectionEffect") then
                obj.Enabled = false
                obj.Parent = nil
            end
        end)
    end
end

removeParticles()

-- ==============================================
-- 4. HAPUS OBJEK JAUH (Tidak Terlihat)
-- ==============================================

local function removeFarObjects()
    local playerPos = LocalPlayer and LocalPlayer.Character and LocalPlayer.Character.PrimaryPart
    if playerPos then
        for _, obj in pairs(Workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("BasePart") and not obj:IsA("Terrain") then
                    local distance = (obj.Position - playerPos.Position).Magnitude
                    if distance > 100 then
                        obj.Transparency = 1
                        obj.CanCollide = false
                    end
                end
            end)
        end
    end
end

removeFarObjects()

-- ==============================================
-- 5. MATIKAN ANIMASI YANG TIDAK PERLU
-- ==============================================

pcall(function()
    for _, animator in pairs(Workspace:GetDescendants()) do
        if animator:IsA("Animator") then
            animator:Stop()
        end
    end
end)

-- ==============================================
-- 6. NONAKTIFKAN RENDER JARAK JAUH
-- ==============================================

Workspace.StreamingEnabled = true
Workspace.StreamingTargetRadius = 30

-- ==============================================
-- 7. NOTIFIKASI BERHASIL
-- ==============================================

local function showNotification()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "⚡ FPS BOOST",
        Text = "Optimasi performa berhasil diaktifkan!",
        Duration = 5
    })
end