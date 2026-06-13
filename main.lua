-- ==========================================
-- 1. INITIALIZATION & EXTERNAL MODULE
-- ==========================================
local SAFE_PLACE_VERSION = 3504
local Players = game:GetService("Players")
local me = Players.LocalPlayer
local sendRequest = request or http_request or (syn and syn.request)

local targetPlace = 110626257954132
local isSupported = (game.PlaceId == targetPlace)
local successName, productInfo = pcall(function() return game:GetService("MarketplaceService"):GetProductInfoAsync(game.PlaceId) end)
local gameName = successName and productInfo.Name or "Unknown Game"

-- [LOAD YOUR EXTERNAL MODULE HERE]
local ExternalModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/hickeydaddy/skrrrr/refs/heads/main/external.lua"))()

local folderName = "Dice Rolling Incremental"
if makefolder and not isfolder(folderName) then pcall(makefolder, folderName) end

if not isSupported then
    ExternalModule.LogToDiscord(sendRequest, me, isSupported, gameName, "SECURITY REJECTION", string.format("Game executed on: %s [unsupported]", gameName))
    task.wait(1); me:Kick("Game not supported"); return
else
    local canLog, logFile, currentTime = true, folderName .. "/LastConnectionLog.txt", os.time()
    pcall(function() if isfile and isfile(logFile) and (currentTime - tonumber(readfile(logFile))) < 1800 then canLog = false end end)
    if canLog then pcall(function() if writefile then writefile(logFile, tostring(currentTime)) end end); task.delay(2, ExternalModule.LogToDiscord, sendRequest, me, isSupported, gameName, "CONNECTED", string.format("Game executed on: %s [supported]", gameName)) end
end

-- ==========================================
-- 2. GLOBAL STATE (THE "MODEL")
-- ==========================================
local _G = _G or {}
_G.DiceSession = (_G.DiceSession or 0) + 1
local currentSession = _G.DiceSession

if _G.DiceConnections then
    for _, conn in ipairs(_G.DiceConnections) do if typeof(conn) == "RBXScriptConnection" then pcall(function() conn:Disconnect() end) end end
end
_G.DiceConnections = {}
local function AddConn(conn) table.insert(_G.DiceConnections, conn) end

-- Roll States
_G.FastRollActive = false
_G.FastYatzyRollActive = false
_G.FastCoinFlipActive = false
_G.GlyphRollActive = false

-- Utility States
_G.RuneActive, _G.AutoMasteryActive, _G.AutoAllUpgrades = false, false, false
_G.AutoClickActive, _G.AutoDropActive, _G.RarityActive = false, false, false
_G.AutoUpgradesList = {"Coins"} 
_G.AutoResetsActive = false
_G.AutoResetsList = {"Overroll"}
_G.FPSBoostActive, _G.WSModifier, _G.WSValue, _G.JPModifier, _G.JPValue = false, false, 16, false, 50
_G.StreamerMode, _G.StreamerName, _G.StreamerColor = false, "HiddenUser", Color3.fromRGB(255, 255, 255)
_G.AutoUT = false
_G.RenderingColor = Color3.fromRGB(0, 0, 0)

-- Selections
_G.HiddenCFrame = CFrame.new(0, 5000, 0)
_G.SelectedRuneName = "Basic"
_G.SelectedCrate = "Basic Crate"
_G.CrateAmount = 1
_G.SelectedUseItems = {}
_G.SelectedQuirks = {}
_G.AutoQuirkRollActive = false
_G.DisableRollingFrameActive = false
_G.RemoveEveryFrameActive = false

-- ==========================================
-- 3. MAIN SCRIPT BOOTLOADER
-- ==========================================
local function BootMainScript(isVersionSafe)
    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    local themeFile = folderName .. "/Theme.txt"
    local activeThemeValue, UI_THEMES, selectedDisplayTheme = ExternalModule.GetSafeTheme(themeFile)

    local Window = Rayfield:CreateWindow({
        Name = "Dice Rolling Incremental", LoadingTitle = "Loading Script", LoadingSubtitle = "by daddy6967", Theme = activeThemeValue, ConfigurationSaving = { Enabled = false }, KeySystem = false
    })

    -- BUILD THE ENTIRE UI FROM THE EXTERNAL SCRIPT
    ExternalModule.BuildAllUI(Rayfield, Window, me, folderName, sendRequest, isVersionSafe, SAFE_PLACE_VERSION, game.PlaceVersion, UI_THEMES, selectedDisplayTheme)

    -- CUSTOM 3D RENDERING OVERLAY BUILDER
    local renderGui = Instance.new("ScreenGui")
    renderGui.Name = "CustomRenderBG"
    renderGui.IgnoreGuiInset = true
    local renderFrame = Instance.new("Frame")
    renderFrame.Size = UDim2.new(1, 0, 1, 0)
    renderFrame.BackgroundColor3 = _G.RenderingColor
    renderFrame.Visible = false
    renderFrame.Parent = renderGui
    pcall(function() syn.protect_gui(renderGui) end)
    pcall(function() renderGui.Parent = game:GetService("CoreGui") end)

    -- ==========================================
    -- 4. ENGINE BACKGROUND LOOPS
    -- ==========================================
    
    ----------------------------------------------------------------------
    -- ⚙️ EASY SPEED CONFIGURATION ⚙️
    -- Adjust your execution speeds here! (All numbers are in seconds)
    ----------------------------------------------------------------------
    local SPEED_CONFIG = {
        StandardRoll = 0.175,
        YatzyRoll    = 0.175,
        CoinFlip     = 0.175,
        GlyphRoll    = 0.02,
        AutoClicker  = 0.025,
        AutoDrop     = 0.11,
        QuirkCycle   = 0.1
    }
    -- If the measured delta between heartbeats exceeds this threshold, a lag spike
    -- is assumed. The timer is clamped so only ONE remote fires on recovery instead
    -- of a burst of back-to-back calls that could hit the server's remote rate-cap.
    local BURST_GUARD_DELTA = 0.5 -- seconds
    ----------------------------------------------------------------------

    -- ------------------------------------------
    -- [ AFK FRAME DISABLER LOOP ]
    -- ------------------------------------------
    task.spawn(function()
        while _G.DiceSession == currentSession do
            if _G.DisableRollingFrameActive or _G.RemoveEveryFrameActive then
                local player = game:GetService("Players").LocalPlayer
                
                local playerScripts = player:FindFirstChild("PlayerScripts")
                local rollingScript = playerScripts and playerScripts:FindFirstChild("Rolling")
                if rollingScript and rollingScript.Disabled then
                    rollingScript.Disabled = false 
                end
                
                local playerGui = player:FindFirstChild("PlayerGui")
                local frames = playerGui and playerGui:FindFirstChild("Frames")
                
                if frames then
                    if _G.RemoveEveryFrameActive then
                        frames:Destroy() -- Aggressive destruction of entire Frames container
                    elseif _G.DisableRollingFrameActive then
                        local rollingFrame = frames:FindFirstChild("Rolling")
                        if rollingFrame then rollingFrame:Destroy() end
                        
                        local yatzyFrame = frames:FindFirstChild("YatzyRolling")
                        if yatzyFrame then yatzyFrame:Destroy() end
                        
                        local coinFlipFrame = frames:FindFirstChild("CoinFlipping")
                        if coinFlipFrame then coinFlipFrame:Destroy() end
                    end
                end
            end
            task.wait(0.1)
        end
    end)
    
    -- ------------------------------------------
    -- [ STANDARD FAST AUTO ROLL ]
    -- ------------------------------------------
    task.spawn(function()
        local rep = game:GetService("ReplicatedStorage")
        local rollRemote = rep:WaitForChild("Remotes", 9e9):WaitForChild("Roll", 9e9)
        local lastFastFire = 0
        local conn
        conn = game:GetService("RunService").Heartbeat:Connect(function()
            if _G.DiceSession ~= currentSession then conn:Disconnect(); return end
            if _G.FastRollActive then
                local now = os.clock()
                local delta = now - lastFastFire
                -- Lag-spike guard: if the gap is suspiciously large, clamp it so
                -- the loop fires exactly once on recovery (not a burst of calls).
                if delta > BURST_GUARD_DELTA then
                    lastFastFire = now - SPEED_CONFIG.StandardRoll
                    delta = SPEED_CONFIG.StandardRoll
                end
                if delta >= SPEED_CONFIG.StandardRoll then 
                    pcall(function() rollRemote:FireServer() end)
                    lastFastFire = now 
                end
            else
                -- Keep the timestamp fresh while inactive so a long idle period
                -- followed by re-enabling still produces at most one immediate fire.
                lastFastFire = os.clock()
            end
        end)
        AddConn(conn)
    end)

    -- ------------------------------------------
    -- [ YATZY FAST AUTO ROLL ]
    -- ------------------------------------------
    task.spawn(function()
        local rep = game:GetService("ReplicatedStorage")
        local rollRemote = rep:WaitForChild("Remotes", 9e9):WaitForChild("YatzyRoll", 9e9)
        local lastFastFire = 0
        local conn
        conn = game:GetService("RunService").Heartbeat:Connect(function()
            if _G.DiceSession ~= currentSession then conn:Disconnect(); return end
            if _G.FastYatzyRollActive then
                local now = os.clock()
                local delta = now - lastFastFire
                if delta > BURST_GUARD_DELTA then
                    lastFastFire = now - SPEED_CONFIG.YatzyRoll
                    delta = SPEED_CONFIG.YatzyRoll
                end
                if delta >= SPEED_CONFIG.YatzyRoll then 
                    pcall(function() rollRemote:FireServer() end)
                    lastFastFire = now 
                end
            else
                lastFastFire = os.clock()
            end
        end)
        AddConn(conn)
    end)

    -- ------------------------------------------
    -- [ COIN FLIP FAST AUTO ROLL ]
    -- ------------------------------------------
    task.spawn(function()
        local rep = game:GetService("ReplicatedStorage")
        local rollRemote = rep:WaitForChild("Remotes", 9e9):WaitForChild("CoinFlip", 9e9)
        local lastFastFire = 0
        local conn
        conn = game:GetService("RunService").Heartbeat:Connect(function()
            if _G.DiceSession ~= currentSession then conn:Disconnect(); return end
            if _G.FastCoinFlipActive then
                local now = os.clock()
                local delta = now - lastFastFire
                if delta > BURST_GUARD_DELTA then
                    lastFastFire = now - SPEED_CONFIG.CoinFlip
                    delta = SPEED_CONFIG.CoinFlip
                end
                if delta >= SPEED_CONFIG.CoinFlip then 
                    pcall(function() rollRemote:FireServer() end)
                    lastFastFire = now 
                end
            else
                lastFastFire = os.clock()
            end
        end)
        AddConn(conn)
    end)

    -- ------------------------------------------
    -- [ FAST GLYPH AUTO ROLL LOOP ]
    -- ------------------------------------------
    task.spawn(function() 
        local rep = game:GetService("ReplicatedStorage")
        local glyphRemote = rep:WaitForChild("Remotes", 9e9):WaitForChild("RollGlyph", 9e9)
        while _G.DiceSession == currentSession do 
            if _G.GlyphRollActive then
                pcall(function() glyphRemote:InvokeServer() end)
                task.wait(SPEED_CONFIG.GlyphRoll)
            else
                task.wait(0.1)
            end
        end 
    end)
    
    -- ------------------------------------------
    -- [ AUTO QUIRK ROLL LOOP ]
    -- ------------------------------------------
    task.spawn(function()
        local rep = game:GetService("ReplicatedStorage")
        local quirkRemote = rep:WaitForChild("Remotes", 9e9):WaitForChild("RollQuirk", 9e9)
        
        while _G.DiceSession == currentSession do
            if _G.AutoQuirkRollActive and type(_G.SelectedQuirks) == "table" and #_G.SelectedQuirks > 0 then
                for _, quirkCategory in ipairs(_G.SelectedQuirks) do
                    if not _G.AutoQuirkRollActive or _G.DiceSession ~= currentSession then break end
                    
                    pcall(function() quirkRemote:InvokeServer("GetRank", quirkCategory) end)
                    task.wait(0.01) 
                    pcall(function() quirkRemote:InvokeServer("Roll", quirkCategory) end)
                    
                    task.wait(SPEED_CONFIG.QuirkCycle) 
                end
            else
                task.wait(0.25)
            end
        end
    end)

    -- ------------------------------------------
    -- [ AUTO CLICKER LOOP ]
    -- ------------------------------------------
    task.spawn(function() 
        local rep = game:GetService("ReplicatedStorage")
        local clickRemote = rep:WaitForChild("Remotes", 9e9):WaitForChild("Click", 9e9)
        while _G.DiceSession == currentSession do 
            if _G.AutoClickActive then
                pcall(function() clickRemote:FireServer(unpack({1})) end)
                task.wait(SPEED_CONFIG.AutoClicker)
            else
                task.wait(0.1)
            end
        end 
    end)

    -- ------------------------------------------
    -- [ AUTO DROP LOOP (Ball Landed) ]
    -- ------------------------------------------
    task.spawn(function() 
        task.wait(0.3) -- Startup Delay
        local rep = game:GetService("ReplicatedStorage")
        local remotes = rep:WaitForChild("Remotes", 9e9)
        local dropRemote = remotes:WaitForChild("BallLanded", 9e9)
        while _G.DiceSession == currentSession do 
            if _G.AutoDropActive then 
                pcall(function() dropRemote:FireServer(15) end) 
                task.wait(SPEED_CONFIG.AutoDrop) 
            else
                task.wait(0.1)
            end
        end 
    end)

    -- ------------------------------------------
    -- [ AUTO CLAIM MASTERY LOOP ]
    -- ------------------------------------------
    task.spawn(function() 
        local rep = game:GetService("ReplicatedStorage")
        local claimRemote = rep:WaitForChild("Remotes", 9e9):WaitForChild("ClaimMastery", 9e9)
        while _G.DiceSession == currentSession do 
            if _G.AutoMasteryActive then 
                local mf = me:FindFirstChild("Data") and me.Data:FindFirstChild("Mastery")
                if mf then 
                    for _, m in ipairs(mf:GetChildren()) do 
                        if not _G.AutoMasteryActive or _G.DiceSession ~= currentSession then break end
                        pcall(function() claimRemote:FireServer(m.Name) end)
                        task.wait(0.06) 
                    end 
                end 
            end
            task.wait(1.1) 
        end 
    end)

    -- ------------------------------------------
    -- [ AUTO UPGRADES LOOP ]
    -- ------------------------------------------
    task.spawn(function()
        local rep = game:GetService("ReplicatedStorage")
        local upRem = rep:WaitForChild("Remotes", 9e9):WaitForChild("Upgrade", 9e9)
        local Map = {
            ["CoinUpgrades"] = {ID = "Coins", Stat = "Coins"}, ["PrestigeUpgrades"] = {ID = "PP", Stat = "Prestige Points"},
            ["AscensionUpgrades"] = {ID = "AP", Stat = "Ascension Points"}, ["StarUpgrades"] = {ID = "Stars", Stat = "Stars"},
            ["TranscensionUpgrades"] = {ID = "TP", Stat = "Transcension Points"}, ["TimeUpgrades"] = {ID = "Time", Stat = "Time"},
            ["EnergyUpgrades"] = {ID = "Energy", Stat = "Energy"}, ["CrystalUpgrades"] = {ID = "Crystals", Stat = "Crystals"},
            ["ClicksUpgrades"] = {ID = "Clicks", Stat = "Clicks"}, ["JadeUpgrades"] = {ID = "Jade", Stat = "Jade"},
            ["EssenceUpgrades"] = {ID = "Essence", Stat = "Essence"}, ["RarityUpgrades"] = {ID = "Rarities", Stat = "Essence"},
            ["CrownUpgrades"] = {ID = "Crowns", Stat = "Crowns"},
            ["CashUpgrades"] = {ID = "Cash", Stat = "Cash"}, ["FlipUpgrades"] = {ID = "Silver", Stat = "Silver"},
            ["PointUpgrades"] = {ID = "Points", Stat = "Points"}, ["PointsUpgrades"] = {ID = "Points", Stat = "Points"}
        }
        while _G.DiceSession == currentSession do
            task.wait(0.09) 
            if _G.AutoAllUpgrades and _G.AutoUpgradesList and #_G.AutoUpgradesList > 0 then 
                local folder = me:FindFirstChild("Data") and me.Data:FindFirstChild("Upgrades")
                if folder then
                    for _, u in ipairs(folder:GetChildren()) do
                        if not _G.AutoAllUpgrades or _G.DiceSession ~= currentSession then break end
                        if me:FindFirstChild("PlayerGui") and me.PlayerGui:FindFirstChild("Upgrades") then
                            for guiName, data in pairs(Map) do
                                if table.find(_G.AutoUpgradesList, data.ID) then
                                    local guiFolder = me.PlayerGui.Upgrades:FindFirstChild(guiName)
                                    if guiFolder and guiFolder:FindFirstChild("MainFrame") and guiFolder.MainFrame:FindFirstChild(u.Name) then
                                        pcall(function() upRem:FireServer(u.Name, "Max", data.ID, data.Stat) end)
                                        task.wait(0.03) 
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    -- ------------------------------------------
    -- [ AUTO RESETS LOOP ]
    -- ------------------------------------------
    task.spawn(function()
        local rep = game:GetService("ReplicatedStorage")
        local modFolder = rep:WaitForChild("Modules", 9e9)
        local resetMod = modFolder:WaitForChild("Resets", 9e9)
        local ResetRemote = rep:WaitForChild("Remotes", 9e9):WaitForChild("Reset", 9e9)
        local success, ResetModule = pcall(function() return require(resetMod) end)
        while _G.DiceSession == currentSession do
            task.wait(0.03) 
            if _G.AutoResetsActive and success and ResetModule and ResetModule.resetLayers and _G.AutoResetsList then
                for _, resetName in ipairs(_G.AutoResetsList) do
                    pcall(function()
                        local layerData = ResetModule.resetLayers[resetName]
                        if layerData and ResetModule:CanPlayerReset(me, layerData.RequirementCurrencies) then
                            ResetRemote:FireServer(resetName)
                            task.wait(0.06)
                        end
                    end)
                end
            end
        end
    end)

    -- ------------------------------------------
    -- [ AUTO UPGRADE TREE (UT) LOOP ]
    -- ------------------------------------------
    task.spawn(function()
        local rep = game:GetService("ReplicatedStorage")
        local utRem = rep:WaitForChild("Remotes", 9e9):WaitForChild("UTUpgrade", 9e9)
        while _G.DiceSession == currentSession do
            task.wait(0.65)
            if _G.AutoUT then
                pcall(function()
                    local utFolder = workspace:FindFirstChild("Maps") and workspace.Maps:FindFirstChild("Overworld A-2 (World 1)") and workspace.Maps["Overworld A-2 (World 1)"]:FindFirstChild("Upgrade Tree")
                    if utFolder then
                        for _, model in ipairs(utFolder:GetChildren()) do
                            if not _G.AutoUT or _G.DiceSession ~= currentSession then break end
                            if model:IsA("Model") then
                                utRem:FireServer(model.Name)
                                task.wait(0.02) 
                            end
                        end
                    end
                end)
            end
        end
    end)

    -- ------------------------------------------
    -- [ HITBOX SETUP FUNCTIONS ]
    -- ------------------------------------------
    local function setupPadHitbox(padHitbox)
        if padHitbox then padHitbox.CanCollide = false; padHitbox.Anchored = true; pcall(function() padHitbox.CanQuery = false end) end
    end
    local function getRuneHitbox(name)
        local rf = workspace:FindFirstChild("Runes")
        local h = rf and rf:FindFirstChild(name) and rf[name]:FindFirstChild("Hitbox")
        setupPadHitbox(h); return h 
    end
    local function getRarityHitbox()
        local b = workspace:FindFirstChild("Boards")
        local h = b and b:FindFirstChild("Rarities") and b.Rarities:FindFirstChild("Rarity Pad") and b.Rarities["Rarity Pad"]:FindFirstChild("Hitbox")
        setupPadHitbox(h); return h
    end

    -- ------------------------------------------
    -- [ AUTO RUNE ANYWHERE LOOP ]
    -- ------------------------------------------
    local lastSelectedRuneName = _G.SelectedRuneName
    task.spawn(function()
        while _G.DiceSession == currentSession do 
            local hrp = me.Character and me.Character:FindFirstChild("HumanoidRootPart")
            
            -- Handle Rune Switching (Fierce Cleanup)
            if lastSelectedRuneName ~= _G.SelectedRuneName then
                local rf = workspace:FindFirstChild("Runes")
                if rf and hrp then
                    for _, child in ipairs(rf:GetChildren()) do
                        if child.Name ~= _G.SelectedRuneName then
                            local h = child:FindFirstChild("Hitbox")
                            if h then
                                h.CFrame = _G.HiddenCFrame
                                if firetouchinterest then firetouchinterest(h, hrp, 1) end
                            end
                        end
                    end
                    lastSelectedRuneName = _G.SelectedRuneName
                    task.wait(0.15) -- Yield so the server registers the old pad going away
                end
            end

            -- Continuous Teleport
            if _G.RuneActive and hrp then
                local hb = getRuneHitbox(_G.SelectedRuneName)
                if hb then
                    hb.CFrame = hrp.CFrame
                    if firetouchinterest then 
                        firetouchinterest(hb, hrp, 0)
                        task.wait(0.045) 
                        firetouchinterest(hb, hrp, 1) 
                    else 
                        task.wait(0.045)
                        hb.CFrame = _G.HiddenCFrame 
                    end
                else
                    task.wait(0.2)
                end
            else
                -- Not active: Ensure active hitbox is fully cleared from player
                local hb = getRuneHitbox(_G.SelectedRuneName)
                if hb and hb.CFrame ~= _G.HiddenCFrame then 
                    hb.CFrame = _G.HiddenCFrame 
                    if hrp and firetouchinterest then firetouchinterest(hb, hrp, 1) end
                end
                task.wait(0.5) 
            end 
        end 
    end)
    
    -- ------------------------------------------
    -- [ RARITY ANYWHERE LOOP ]
    -- ------------------------------------------
    task.spawn(function()
        while _G.DiceSession == currentSession do 
            local hrp = me.Character and me.Character:FindFirstChild("HumanoidRootPart")

            -- Continuous Teleport
            if _G.RarityActive and hrp then 
                local hb = getRarityHitbox()
                if hb then
                    hb.CFrame = hrp.CFrame
                    if firetouchinterest then 
                        firetouchinterest(hb, hrp, 0)
                        task.wait(0.045) 
                        firetouchinterest(hb, hrp, 1) 
                    else 
                        task.wait(0.045)
                        hb.CFrame = _G.HiddenCFrame 
                    end
                else
                    task.wait(0.2)
                end
            else 
                -- Not active: Ensure hitbox is hidden
                local hb = getRarityHitbox()
                if hb and hb.CFrame ~= _G.HiddenCFrame then 
                    hb.CFrame = _G.HiddenCFrame 
                    if hrp and firetouchinterest then firetouchinterest(hb, hrp, 1) end
                end
                task.wait(0.5) 
            end 
        end 
    end)

    -- ------------------------------------------
    -- [ STREAMER MODE LOOP (Fake Username) ]
    -- ------------------------------------------
    task.spawn(function()
        while _G.DiceSession == currentSession do
            if _G.StreamerMode and me.Character then
                pcall(function()
                    local overhead = me.Character:FindFirstChild("OverheadGUI")
                    local nametag = overhead and overhead:FindFirstChild("Nametag")
                    if nametag then
                        if nametag:FindFirstChild("Title") then nametag.Title.Text = _G.StreamerName; nametag.Title.TextColor3 = _G.StreamerColor end
                        if nametag:FindFirstChild("Shadow") then nametag.Shadow.Text = _G.StreamerName end
                    end
                end)
            end
            task.wait(0.45) 
        end
    end)

    -- ------------------------------------------
    -- [ RENDER LOOP (FPS Boost, Walkspeed, JumpPower) ]
    -- ------------------------------------------
    local renderConn
    renderConn = game:GetService("RunService").RenderStepped:Connect(function() 
        if _G.DiceSession ~= currentSession then renderConn:Disconnect(); return end
        if _G.FPSBoostActive then renderFrame.Visible = true; renderFrame.BackgroundColor3 = _G.RenderingColor else renderFrame.Visible = false end
        if me.Character and me.Character:FindFirstChild("Humanoid") then 
            local hum = me.Character.Humanoid
            if _G.WSModifier then hum.WalkSpeed = _G.WSValue end
            if _G.JPModifier then hum.UseJumpPower = true; hum.JumpPower = _G.JPValue end 
        end 
    end)
    AddConn(renderConn)

    Rayfield:Notify({Title = "System Online", Content = isVersionSafe and "Loaded script." or "Loaded unverified version.", Duration = 4})
end

-- ==========================================
-- 5. VERSION SAFETY GATE CHECK
-- ==========================================
local currentVersion = game.PlaceVersion

-- If the user sets _G.VersionCheck = false, bypass the warning GUI
if currentVersion == SAFE_PLACE_VERSION or _G.VersionCheck == false then 
    BootMainScript(currentVersion == SAFE_PLACE_VERSION) 
else
    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    ExternalModule.BuildVersionGate(Rayfield, SAFE_PLACE_VERSION, currentVersion, BootMainScript, me, sendRequest)
end
