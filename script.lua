-- ================================================================
-- GOLLHUB FPS BOOST (STATIS - TANPA LOOP AGRESIF)
-- ================================================================

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

-- 1. MENGHILANGKAN STUD (SMOOTH PLASTIC)
for _, part in ipairs(Workspace:GetDescendants()) do
    if part:IsA("BasePart") then
        part.Material = Enum.Material.SmoothPlastic
        part.TopSurface = Enum.SurfaceType.Smooth
        part.BottomSurface = Enum.SurfaceType.Smooth
        part.LeftSurface = Enum.SurfaceType.Smooth
        part.RightSurface = Enum.SurfaceType.Smooth
        part.FrontSurface = Enum.SurfaceType.Smooth
        part.BackSurface = Enum.SurfaceType.Smooth
    end
end

-- 2. MENGHILANGKAN TEMBOK
for _, obj in ipairs(Workspace:GetDescendants()) do
    if obj:IsA("BasePart") and obj.Size.Y > 10 and obj.Transparency == 0 then
        pcall(function() obj:Destroy() end)
    end
end

-- 3. MENURUNKAN KUALITAS CAHAYA & BAYANGAN
Lighting.GlobalShadows = false
Lighting.FogEnd = 1000
Lighting.ExposureCompensation = -1.0

-- 4. MENGHAPUS PARTIKEL, TEKSTUR, DAN SUARA (SATU KALI SAJA)
for _, descendant in ipairs(Workspace:GetDescendants()) do
    if descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") or descendant:IsA("Fire") or descendant:IsA("Smoke") or descendant:IsA("Sparkles") then
        descendant.Enabled = false
    end
    
    if descendant:IsA("Decal") or descendant:IsA("Texture") then
        pcall(function() descendant:Destroy() end)
    end
end

for _, sound in ipairs(Workspace:GetDescendants()) do
    if sound:IsA("Sound") then
        pcall(function() sound:Destroy() end)
    end
end

-- 5. MENGHAPUS GUI YANG TIDAK PERLU (SATU KALI SAJA)
for _, gui in ipairs(CoreGui:GetChildren()) do
    if gui.Name ~= "GollHub" and gui.Name ~= "Delta" and gui.Name ~= "DeltaHub" and gui.Name ~= "DeltaMain" then
        pcall(function() gui:Destroy() end)
    end
end
