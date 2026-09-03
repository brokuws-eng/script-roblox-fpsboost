-- ================================================================
-- SCRIPT STEAL AN EGG (BERDASARKAN KONFIGURASI)
-- ================================================================

local Players       = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService    = game:GetService("RunService")
local TweenService  = game:GetService("TweenService")
local Workspace     = game:GetService("Workspace")

-- Player & Character
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- ================================================================
-- KONFIGURASI (DARI TABEL SEBELUMNYA)
-- ================================================================
local Config = {
    ["Eggs/Auto Steal/Toggle/Auto Steal"] = true,
    ["Eggs/Auto Steal/Dropdown/Rarity"] = {"Divine", "Eternal", "Secret"},
    ["Eggs/Auto Steal/Slider/Tween Speed"] = 500,
    ["Eggs/Auto Steal/Toggle/Treadmill when no eggs"] = true,
    ["Eggs/Lifecycle/Toggle/Auto Place Eggs"] = true,
    ["Eggs/Lifecycle/Toggle/Auto Hatch Ready"] = true,
    ["Eggs/Server Hop/Toggle/Auto Hop when Empty"] = false,
    ["Pets/Pets/Toggle/Auto Sell Pets"] = true,
    ["Pets/Pets/Dropdown/Sell Rarities"] = {"Cosmic", "Mythic", "Legendary", "Epic", "Rare", "Uncommon", "Common"},
    ["ESP/ESP/Toggle/Egg ESP"] = false,
    ["ESP/Performance/Toggle/Boost FPS"] = true,
    ["ESP/Movement/Slider/WalkSpeed"] = 16,
    ["Upgrade/Trails/Toggle/Auto Buy Cash Trails"] = true,
    ["Upgrade/Training/Toggle/Auto Treadmill Upgrade"] = true,
}

-- ================================================================
-- UTILITAS (FUNGSI DASAR)
-- ================================================================

-- Fungsi untuk berjalan ke suatu posisi
local function safeWalk(targetPos)
    if not humanoid or humanoid.Health <= 0 then return end
    humanoid:MoveTo(targetPos)
    
    local reached = false
    local connection = humanoid.MoveToFinished:Connect(function()
        reached = true
    end)
    
    -- Tunggu sampai sampai atau timeout 10 detik
    local start = os.clock()
    while not reached and (os.clock() - start) < 10 do
        task.wait(0.1)
    end
    
    connection:Disconnect()
end

-- Fungsi untuk mencari telur di Workspace
local function findEggs()
    -- Cari folder telur (nama folder bisa berbeda-beda, cek pakai Dex)
    local eggFolder = Workspace:FindFirstChild("Eggs") 
        or Workspace:FindFirstChild("EggFolder")
        or Workspace:FindFirstChild("WorldEggs")
    
    if not eggFolder then return {} end
    
    local eggs = {}
    for _, egg in ipairs(eggFolder:GetChildren()) do
        table.insert(eggs, egg)
    end
    return eggs
end

-- Fungsi untuk mengecek apakah telur lolos filter rarity
local function passesFilter(egg)
    local targetRarities = Config["Eggs/Auto Steal/Dropdown/Rarity"]
    if #targetRarities == 0 then return true end -- Jika kosong, ambil semua
    
    local rarityTag = egg:FindFirstChild("Rarity") or egg:FindFirstChild("rarity")
    if rarityTag and rarityTag.Value then
        for _, rarity in ipairs(targetRarities) do
            if rarityTag.Value == rarity then
                return true
            end
        end
    end
    return false
end

-- ================================================================
-- FITUR 1: AUTO STEAL (MENCURI TELUR OTOMATIS)
-- ================================================================
local function autoSteal()
    if not Config["Eggs/Auto Steal/Toggle/Auto Steal"] then return end
    
    local eggs = findEggs()
    if #eggs == 0 then 
        -- Jika tidak ada telur, jalankan treadmill jika diaktifkan
        if Config["Eggs/Auto Steal/Toggle/Treadmill when no eggs"] then
            -- (Logika treadmill bisa kamu tambahkan di sini)
        end
        return 
    end
    
    local bestEgg, bestDist = nil, math.huge
    for _, egg in ipairs(eggs) do
        if passesFilter(egg) then
            local eggPart = egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart")
            if eggPart then
                local dist = (rootPart.Position - eggPart.Position).Magnitude
                if dist < bestDist then
                    bestDist = dist
                    bestEgg = egg
                end
            end
        end
    end
    
    if bestEgg then
        local eggPart = bestEgg.PrimaryPart or bestEgg:FindFirstChildWhichIsA("BasePart")
        if eggPart then
            -- Berjalan ke telur
            safeWalk(eggPart.Position)
            
            -- Coba panggil ProximityPrompt (jika ada)
            local prompt = bestEgg:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                pcall(function() fireproximityprompt(prompt) end)
            else
                -- Coba panggil RemoteEvent (cek nama remote pakai Remote Spy)
                local stealRemote = ReplicatedStorage:FindFirstChild("StealEgg") 
                    or ReplicatedStorage:FindFirstChild("PickupEgg")
                if stealRemote then
                    pcall(function() stealRemote:FireServer(bestEgg) end)
                end
            end
        end
    end
end

-- ================================================================
-- FITUR 2: AUTO SELL PETS
-- ================================================================
local function autoSellPets()
    if not Config["Pets/Pets/Toggle/Auto Sell Pets"] then return end
    
    -- Cari remote untuk menjual pets
    local sellRemote = ReplicatedStorage:FindFirstChild("SellPets")
        or ReplicatedStorage:FindFirstChild("SellAllPets")
    
    if sellRemote then
        pcall(function() sellRemote:FireServer() end)
    end
end

-- ================================================================
-- FITUR 3: AUTO BUY TRAILS
-- ================================================================
local function autoBuyTrails()
    if not Config["Upgrade/Trails/Toggle/Auto Buy Cash Trails"] then return end
    
    local buyRemote = ReplicatedStorage:FindFirstChild("BuyTrail")
        or ReplicatedStorage:FindFirstChild("PurchaseTrail")
    
    if buyRemote then
        pcall(function() buyRemote:FireServer() end)
    end
end

-- ================================================================
-- FITUR 4: AUTO TREADMILL UPGRADE
-- ================================================================
local function autoTreadmillUpgrade()
    if not Config["Upgrade/Training/Toggle/Auto Treadmill Upgrade"] then return end
    
    local tierRemote = ReplicatedStorage:FindFirstChild("TreadmillTier")
        or ReplicatedStorage:FindFirstChild("UpgradeTreadmill")
    
    if tierRemote then
        pcall(function() tierRemote:FireServer() end)
    end
end

-- ================================================================
-- FITUR 5: ESP (MELIHAT TELUR MENEMBUS DINDING)
-- ================================================================
local espObjects = {}
local function updateESP()
    if not Config["ESP/ESP/Toggle/Egg ESP"] then
        -- Hapus semua ESP jika dimatikan
        for _, obj in pairs(espObjects) do
            pcall(function() obj:Destroy() end)
        end
        espObjects = {}
        return
    end
    
    local eggs = findEggs()
    for _, egg in ipairs(eggs) do
        if not espObjects[egg] then
            local eggPart = egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart")
            if eggPart then
                local box = Instance.new("SelectionBox")
                box.Adornee = eggPart
                box.Color3 = Color3.fromRGB(255, 215, 0)
                box.LineThickness = 0.05
                box.SurfaceTransparency = 0.75
                box.SurfaceColor3 = Color3.fromRGB(255, 215, 0)
                box.Parent = game:GetService("CoreGui")
                espObjects[egg] = box
            end
        end
    end
end

-- ================================================================
-- FITUR 6: FPS BOOST (OPTIMASI)
-- ================================================================
local function boostFPS()
    if not Config["ESP/Performance/Toggle/Boost FPS"] then return end
    
    -- Matikan efek visual yang berat
    for _, descendant in ipairs(Workspace:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Material = Enum.Material.SmoothPlastic -- Ganti material ke plastik halus
        elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
            pcall(function() descendant:Destroy() end) -- Hapus tekstur
        end
    end
    
    -- Matikan bayangan dan partikel
    local lighting = game:GetService("Lighting")
    lighting.GlobalShadows = false
    lighting.FogEnd = 1000 -- Kurangi jarak pandang
end

-- ================================================================
-- LOOP UTAMA (MENJALANKAN SEMUA FITUR)
-- ================================================================
task.spawn(function()
    -- Jalankan FPS Boost sekali di awal
    boostFPS()
    
    while true do
        -- Jalankan Auto Steal
        autoSteal()
        
        -- Jalankan Auto Sell (setiap 10 detik)
        task.wait(10)
        autoSellPets()
        
        -- Jalankan Auto Buy Trails (setiap 30 detik)
        task.wait(30)
        autoBuyTrails()
        
        -- Jalankan Auto Treadmill Upgrade (setiap 60 detik)
        task.wait(60)
        autoTreadmillUpgrade()
        
        -- Update ESP
        updateESP()
        
        task.wait(0.1)
    end
end)

-- ================================================================
-- HANDLE KARAKTER RESPAWN
-- ================================================================
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    rootPart = newChar:WaitForChild("HumanoidRootPart")
end)