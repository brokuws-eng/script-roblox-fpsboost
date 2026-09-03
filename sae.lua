-- ================================================================
--   Steal An Egg — Script Publik (Bahasa Indonesia)
--   github.com/pespapankon-del/StealAnEgg-Script
--   Fitur: Auto Steal | Auto Hatch | Auto Treadmill
--          Anti-Kick | Anti-AFK | Server Hop | ESP | GUI
-- ================================================================

local Players       = game:GetService("Players")
local TweenService  = game:GetService("TweenService")
local UIS           = game:GetService("UserInputService")
local RS            = game:GetService("ReplicatedStorage")
local TS            = game:GetService("TeleportService")
local HttpService   = game:GetService("HttpService")
local CoreGui       = game:GetService("CoreGui")

-- Nama Remote asli dari game (bisa discan dari Scanner.lua)
local Net = RS:WaitForChild("Packages"):WaitForChild("Networking")
local function getNet(name) return Net:FindFirstChild(name) end

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid  = character:WaitForChild("Humanoid")
local rootPart  = character:WaitForChild("HumanoidRootPart")

-- ================================================================
-- KONFIGURASI
-- ================================================================
local Config = {
    AutoSteal       = false,
    AutoHatch       = false,
    AutoTreadmill   = false,
    SpeedBoost      = false,
    EggESP          = false,
    AntiKick        = false,
    AntiAFK         = false,
    AutoServerHop   = false,
    MutationOnly    = false,
    WalkSpeed       = 100,
    StealDelay      = 0.3,
    TargetRarity    = "Semua",
    MaxPlayers      = 3,
    HopDelay        = 3,
    Stats = { EggsStolen = 0, EggsHatched = 0, SessionTime = 0 }
}

local rarityList = {"Semua","Common","Uncommon","Rare","Epic","Legendary","Mythic","Divine"}
local rarityIdx  = 1

-- ================================================================
-- UTILITAS
-- ================================================================

local function log(msg) print("[Script] " .. tostring(msg)) end

local function getDistance(a, b) return (a - b).Magnitude end

local function safeWalk(pos)
    if not humanoid or humanoid.Health <= 0 then return end
    humanoid:MoveTo(pos)
    local done, t, conn = false, 0, nil
    conn = humanoid.MoveToFinished:Connect(function() done = true; conn:Disconnect() end)
    while not done and t < 12 do task.wait(0.1); t += 0.1 end
end

player.CharacterAdded:Connect(function(char)
    character = char
    humanoid  = char:WaitForChild("Humanoid")
    rootPart  = char:WaitForChild("HumanoidRootPart")
    task.wait(1)
    if Config.SpeedBoost then humanoid.WalkSpeed = Config.WalkSpeed end
end)

-- ================================================================
-- ANTI-KICK
-- ================================================================
local AntiKick = {}
function AntiKick.enable()
    local mt = getmetatable(player)
    if mt then
        local old = mt.__namecall
        mt.__namecall = function(self, ...)
            if select(1,...) == "Kick" and self == player then
                log("⚠️ Berhasil mencegah tendangan!")
                return
            end
            return old(self, ...)
        end
    end
    log("✅ Anti-Kick aktif")
end
function AntiKick.disable() log("❌ Anti-Kick nonaktif") end

-- ================================================================
-- ANTI-AFK
-- ================================================================
local AntiAFK = {}
local afkConn = nil
function AntiAFK.enable()
    if afkConn then return end
    afkConn = task.spawn(function()
        while Config.AntiAFK do
            local vchar = player.Character
            if vchar then
                local h = vchar:FindFirstChildOfClass("Humanoid")
                if h then h:Move(Vector3.new(0.01,0,0),true); task.wait(0.1); h:Move(Vector3.zero,true) end
            end
            task.wait(55)
        end
    end)
    log("✅ Anti-AFK aktif")
end
function AntiAFK.disable()
    Config.AntiAFK = false
    if afkConn then task.cancel(afkConn); afkConn = nil end
    log("❌ Anti-AFK nonaktif")
end

-- ================================================================
-- SERVER HOP
-- ================================================================
local ServerHop = {}
function ServerHop.getServerList()
    local ok, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(
            string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId)
        ))
    end)
    return (ok and result and result.data) or {}
end
function ServerHop.findBestServer()
    log("🔍 Mencari server dengan pemain paling sedikit...")
    local best, fewest = nil, math.huge
    for _, srv in ipairs(ServerHop.getServerList()) do
        if srv.id ~= game.JobId then
            local count = srv.playing or 0
            if count < fewest then fewest = count; best = srv end
        end
    end
    if best then
        log(string.format("✅ Server ditemukan — Pemain: %d", fewest))
        return best.id, fewest
    end
    return nil, 0
end
function ServerHop.hopToEmpty()
    local id, count = ServerHop.findBestServer()
    if id and count <= Config.MaxPlayers then
        log(string.format("🚀 Pindah ke server [%d pemain]", count))
        task.wait(Config.HopDelay)
        TS:TeleportToPlaceInstance(game.PlaceId, id, player)
    else
        log("⚠️ Tidak ada server kosong")
    end
end

-- ================================================================
-- FILTER / ESP / FARM
-- ================================================================
local function passesFilter(egg)
    if Config.TargetRarity ~= "Semua" then
        local tag = egg:FindFirstChild("Rarity") or egg:FindFirstChild("rarity")
        if not tag or tag.Value ~= Config.TargetRarity then return false end
    end
    if Config.MutationOnly then
        local mut = egg:FindFirstChild("Mutation") or egg:FindFirstChild("mutation")
        if not (mut and mut.Value ~= "") then return false end
    end
    return true
end

local espObjects = {}
local function clearESP()
    for _, v in pairs(espObjects) do pcall(function() v:Destroy() end) end
    espObjects = {}
end
local function updateESP()
    if not Config.EggESP then clearESP(); return end
    local folder = workspace:FindFirstChild("Eggs", true)
    if not folder then return end
    for _, egg in ipairs(folder:GetChildren()) do
        if not espObjects[egg] and passesFilter(egg) then
            local part = egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart")
            if part then
                local box = Instance.new("SelectionBox")
                box.Adornee = part
                box.Color3 = Color3.fromRGB(255,215,0)
                box.LineThickness = 0.06
                box.SurfaceTransparency = 0.75
                box.SurfaceColor3 = Color3.fromRGB(255,215,0)
                box.Parent = CoreGui
                espObjects[egg] = box
                egg.AncestryChanged:Connect(function()
                    if box and box.Parent then box:Destroy(); espObjects[egg] = nil end
                end)
            end
        end
    end
end

local function stealOne()
    local folder = workspace:FindFirstChild("Eggs", true)
    if not folder then return false end
    local best, bestDist = nil, math.huge
    for _, egg in ipairs(folder:GetChildren()) do
        if passesFilter(egg) then
            local part = egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart")
            if part then
                local d = getDistance(rootPart.Position, part.Position)
                if d < bestDist then bestDist = d; best = egg end
            end
        end
    end
    if not best then return false end
    local bestPart = best.PrimaryPart or best:FindFirstChildWhichIsA("BasePart")
    safeWalk(bestPart.Position)
    -- Metode 1: ProximityPrompt (banyak game menggunakan ini)
    local prompt = best:FindFirstChildWhichIsA("ProximityPrompt",true)
    if prompt then
        pcall(function() fireproximityprompt(prompt) end)
        Config.Stats.EggsStolen += 1
        log("✅ Mencuri telur #" .. Config.Stats.EggsStolen)
        return true
    end
    -- Metode 2: Coba Remote di Networking
    local stealRemote = getNet("RF/Egg/StealEgg")
        or getNet("RF/Egg/PickupEgg")
        or getNet("RE/Egg/StealEgg")
    if stealRemote then
        if stealRemote:IsA("RemoteFunction") then
            pcall(function() stealRemote:InvokeServer(best) end)
        else
            pcall(function() stealRemote:FireServer(best) end)
        end
        Config.Stats.EggsStolen += 1
        log("✅ Mencuri telur (Remote) #" .. Config.Stats.EggsStolen)
        return true
    end
    -- Metode 3: Hanya berjalan mendekat lalu menunggu (proximity touch)
    rootPart.CFrame = CFrame.new(bestPart.Position + Vector3.new(0,0,2))
    task.wait(0.5)
    return false
end

local function returnToBase()
    local base = workspace:FindFirstChild("Base_"..player.UserId,true) or workspace:FindFirstChild("PlayerBase",true)
    if not base then return end
    local p = base.PrimaryPart or base:FindFirstChildWhichIsA("BasePart")
    if p then safeWalk(p.Position) end
end

local function hatchEggs()
    -- Bloomery = mesin penetas telur di game
    local loadEgg  = getNet("RF/Bloomery/AskLoadEgg")
    local mutate   = getNet("RF/Bloomery/AskMutate")
    if not loadEgg then return end
    -- Cari posisi Bloomery di workspace lalu berjalan ke sana
    local bloomery = workspace:FindFirstChild("Bloomery",true)
        or workspace:FindFirstChild("bloomery",true)
    if bloomery then
        local p = bloomery.PrimaryPart or bloomery:FindFirstChildWhichIsA("BasePart")
        if p then safeWalk(p.Position) end
    end
    pcall(function() loadEgg:InvokeServer() end)
    if mutate then
        task.wait(0.5)
        pcall(function() mutate:InvokeServer() end)
    end
    Config.Stats.EggsHatched += 1
end

local function trainTreadmill()
    local tierRaise   = getNet("RF/Treadmill/AskTierRaise")
    local slowToggle  = getNet("RF/Treadmill/AskSlowToggleSet")
    local wearStill   = getNet("RF/Treadmill/AskWearStill")
    -- Cari Treadmill di workspace
    local tm = workspace:FindFirstChild("Treadmill",true)
    if tm then
        local p = tm.PrimaryPart or tm:FindFirstChildWhichIsA("BasePart")
        if p then safeWalk(p.Position) end
    end
    -- Mulai berjalan (AskWearStill = berdiri di tempat di atas treadmill)
    if wearStill then pcall(function() wearStill:InvokeServer(true) end) end
    -- Naikkan tier jika ada
    if tierRaise then pcall(function() tierRaise:InvokeServer() end) end
end

-- ================================================================
-- SISTEM PVP — Serang pemain / Ambil telur
-- ================================================================

local PVP = {}
PVP.enabled      = false
PVP.autoStealPvp = false   -- Lari mencari orang yang membawa telur lalu serang
PVP.autoPickDrop = false   -- Ambil telur yang jatuh secara otomatis
PVP.range        = 30      -- jarak serang (studs)

-- Cek apakah pemain target membawa telur
local function playerHasEgg(target)
    if not target or not target.Character then return false end
    -- Cek dari Character apakah ada object telur menempel
    for _, obj in ipairs(target.Character:GetChildren()) do
        if obj.Name:lower():find("egg")
        or obj.Name:lower():find("carry")
        or obj.Name:lower():find("hold") then
            return true, obj
        end
    end
    -- Cek dari Attribute
    if target.Character:GetAttribute("HoldingEgg")
    or target.Character:GetAttribute("CarryingEgg") then
        return true, nil
    end
    return false, nil
end

-- Cari pemain yang membawa telur dan paling dekat
local function findNearestEggCarrier()
    local nearest, nearestDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local d = getDistance(rootPart.Position, root.Position)
                local hasEgg = playerHasEgg(p)
                if hasEgg and d < nearestDist then
                    nearestDist = d
                    nearest = p
                end
            end
        end
    end
    return nearest, nearestDist
end

-- Cari telur yang jatuh di tanah (dropped eggs)
local function findDroppedEggs()
    local dropped = {}
    -- Telur yang jatuh dari pemain biasanya ada di workspace langsung atau folder DroppedEggs
    local folders = {"DroppedEggs","Dropped","WorldEggs","GroundEggs"}
    for _, fname in ipairs(folders) do
        local f = workspace:FindFirstChild(fname)
        if f then
            for _, egg in ipairs(f:GetChildren()) do
                table.insert(dropped, egg)
            end
        end
    end
    -- Cari di workspace langsung juga
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj.Name:lower():find("egg") and obj:IsA("Model") then
            table.insert(dropped, obj)
        end
    end
    return dropped
end

-- Gunakan Bat untuk menyerang pemain (melalui Tool atau Remote)
local function swingBat(target)
    -- Metode 1: Gunakan Tool yang dipegang (jika ada Bat di karakter)
    local tool = character:FindFirstChildOfClass("Tool")
    if tool then
        local activateRemote = tool:FindFirstChild("RemoteEvent")
            or tool:FindFirstChildOfClass("RemoteEvent")
        if activateRemote then
            pcall(function() activateRemote:FireServer(target.Character) end)
            return true
        end
        -- aktifkan tool melalui humanoid
        pcall(function() tool:Activate() end)
        return true
    end

    -- Metode 2: Tembak Remote HitPlayer
    local hitRemote = RS:FindFirstChild("HitPlayer")
        or RS:FindFirstChild("SwingBat")
        or RS:FindFirstChild("Attack")
        or RS:FindFirstChild("Knockback")
        or RS:FindFirstChild("BatHit")
    if hitRemote then
        pcall(function()
            hitRemote:FireServer(target.Character, rootPart.CFrame.LookVector * 50)
        end)
        log("🏏 Menyerang " .. target.Name)
        return true
    end

    -- Metode 3: proximity / touch trigger
    local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
    if targetRoot then
        local dist = getDistance(rootPart.Position, targetRoot.Position)
        if dist < 8 then
            -- Tabrak body langsung
            rootPart.CFrame = CFrame.new(
                targetRoot.Position + Vector3.new(0, 0, -3)
            )
            task.wait(0.1)
            log("💥 Menabrak " .. target.Name)
            return true
        end
    end

    return false
end

-- Ambil telur yang jatuh secara otomatis
local function pickDroppedEgg()
    local dropped = findDroppedEggs()
    if #dropped == 0 then return false end

    local nearest, nearestDist = nil, math.huge
    for _, egg in ipairs(dropped) do
        local part = egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart")
        if part then
            local d = getDistance(rootPart.Position, part.Position)
            if d < nearestDist then nearestDist = d; nearest = egg end
        end
    end

    if nearest and nearestDist < 200 then
        local part = nearest.PrimaryPart or nearest:FindFirstChildWhichIsA("BasePart")
        safeWalk(part.Position)
        local remote = RS:FindFirstChild("PickupEgg")
            or RS:FindFirstChild("GrabEgg")
            or RS:FindFirstChild("CollectEgg")
        if remote then
            pcall(function() remote:FireServer(nearest) end)
            Config.Stats.EggsStolen += 1
            log("✅ Telur yang jatuh berhasil diambil!")
            return true
        end
    end
    return false
end

-- ESP highlight pemain yang membawa telur
local pvpHighlights = {}
local function updatePvpESP()
    if not PVP.enabled then
        for _, v in pairs(pvpHighlights) do pcall(function() v:Destroy() end) end
        pvpHighlights = {}
        return
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local hasEgg = playerHasEgg(p)
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if hasEgg and root and not pvpHighlights[p] then
                -- highlight warna merah untuk pembawa telur
                local box = Instance.new("SelectionBox")
                box.Adornee       = p.Character
                box.Color3        = Color3.fromRGB(255, 50, 50)
                box.LineThickness  = 0.08
                box.SurfaceTransparency = 0.85
                box.SurfaceColor3 = Color3.fromRGB(255, 50, 50)
                box.Parent = CoreGui
                pvpHighlights[p] = box

                -- BillboardGui nama + jarak
                local billboard = Instance.new("BillboardGui")
                billboard.Size         = UDim2.new(0,80,0,24)
                billboard.StudsOffset  = Vector3.new(0, 3.5, 0)
                billboard.AlwaysOnTop  = true
                billboard.Adornee      = root
                billboard.Parent       = CoreGui

                local nameTag = Instance.new("TextLabel")
                nameTag.Size               = UDim2.new(1,0,1,0)
                nameTag.BackgroundColor3   = Color3.fromRGB(200,30,30)
                nameTag.BackgroundTransparency = 0.3
                nameTag.TextColor3         = Color3.new(1,1,1)
                nameTag.Font               = Enum.Font.GothamBold
                nameTag.TextSize           = 11
                nameTag.Text               = "🥚 " .. p.Name
                nameTag.Parent             = billboard
                Instance.new("UICorner",nameTag).CornerRadius = UDim.new(0,4)

                -- Perbarui jarak
                task.spawn(function()
                    while pvpHighlights[p] and p.Character do
                        if root and root.Parent then
                            local d = math.floor(getDistance(rootPart.Position, root.Position))
                            nameTag.Text = "🥚 " .. p.Name .. " [" .. d .. "m]"
                        end
                        task.wait(0.5)
                    end
                end)

            elseif not hasEgg and pvpHighlights[p] then
                pcall(function() pvpHighlights[p]:Destroy() end)
                pvpHighlights[p] = nil
            end
        end
    end
end

-- Loop utama PvP
task.spawn(function()
    while true do
        -- Perbarui ESP selalu jika PVP.enabled
        if PVP.enabled then
            updatePvpESP()
        end

        -- Auto lari menyerang pembawa telur
        if PVP.autoStealPvp and PVP.enabled then
            local target, dist = findNearestEggCarrier()
            if target then
                local targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    if dist <= PVP.range then
                        swingBat(target)
                        task.wait(0.5)
                        -- Ambil telur yang jatuh
                        if PVP.autoPickDrop then
                            task.wait(0.8)
                            pickDroppedEgg()
                            returnToBase()
                        end
                    else
                        -- Lari ke arah target
                        log(string.format("🏃 Mengejar %s [%.0f studs]", target.Name, dist))
                        humanoid:MoveTo(targetRoot.Position)
                    end
                end
            end
        end

        -- Auto ambil telur jatuh jika aktif (tidak perlu autoStealPvp)
        if PVP.autoPickDrop and not PVP.autoStealPvp then
            pickDroppedEgg()
        end

        task.wait(0.2)
    end
end)

-- ================================================================
-- AUTO PROGR
