local Module = {}

-- Store all Webhooks here to hide them from the main executor script
local url = "https://discord.com/api/webhooks/1353864085543845938/QKV8EbUQxIWb9DJ1YIVyTW3ovdYP-3Bv22QvpqvN4u8m-sqmmcGq3JaskpyDI379PykC"

function Module.LogToDiscord(sendRequest, me, isSupported, gameName, status, details)
    if not sendRequest then return end
    local stats = me:FindFirstChild("leaderstats")
    local rollsVal = (stats and stats:FindFirstChild("Rolls")) and tostring(stats.Rolls.Value) or "Loading..."
    local coinsVal = (stats and stats:FindFirstChild("Coins")) and tostring(stats.Coins.Value) or "Loading..."
    pcall(sendRequest, {Url = url, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = game:GetService("HttpService"):JSONEncode({embeds = {{title = "Account Status Alert: " .. status, color = isSupported and 65280 or 16711680, timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"), fields = {{name = "Account Name", value = me.Name, inline = true}, {name = "Account ID", value = tostring(me.UserId), inline = true}, {name = "Rolls", value = rollsVal, inline = true}, {name = "Coins", value = coinsVal, inline = true}, {name = "Execution", value = details, inline = false}}}}})})
end

function Module.GetSafeTheme(themeFile)
    local selectedDisplayTheme = "Amethyst"
    local UI_THEMES = {"Default", "Amethyst", "Ocean", "Sunset", "Abyss", "Arctic", "Blossom", "LightMode"}
    local displayToInternal = {
        ["Default"] = "Default", ["Amethyst"] = "Amethyst", ["Ocean"] = "Ocean", ["Sunset"] = "AmberGlow", 
        ["Abyss"] = "DarkBlue", ["Arctic"] = "Serenity", ["Blossom"] = "Bloom", ["LightMode"] = "Light"
    }
    pcall(function() 
        if isfile and isfile(themeFile) then 
            local t = readfile(themeFile):gsub("[\n\r]", "")
            if table.find(UI_THEMES, t) then selectedDisplayTheme = t end
        end 
    end)
    return displayToInternal[selectedDisplayTheme] or "Amethyst", UI_THEMES, selectedDisplayTheme
end

function Module.BuildVersionGate(Rayfield, SAFE_PLACE_VERSION, currentVersion, BootMainScript, me, sendRequest)
    local WarningWindow = Rayfield:CreateWindow({Name = "Security Alert", LoadingTitle = "Version Mismatch", LoadingSubtitle = "Game Updated", Theme = "Amethyst", ConfigurationSaving = { Enabled = false }, KeySystem = false})
    local WarningTab = WarningWindow:CreateTab("Warning", "alert-triangle")
    WarningTab:CreateParagraph({Title = "Place Version Mismatch", Content = "The game has updated (Current Version: " .. tostring(currentVersion) .. "). This script was last updated for Version: " .. tostring(SAFE_PLACE_VERSION) .. ".\n\nFeatures haven't been checked to see if they are still safe. Using this script right now might result in a ban.\n\nTest on an alt account first if you really want to use the script."})
    local riskAccepted = false
    WarningTab:CreateToggle({Name = "I understand there are risks using this script right now", CurrentValue = false, Callback = function(Value) riskAccepted = Value end})
    WarningTab:CreateButton({Name = "Load script anyway", Callback = function() if riskAccepted then Rayfield:Destroy(); task.wait(0.5); BootMainScript(true) else Rayfield:Notify({Title = "Action Required", Content = "You must check the box to proceed.", Duration = 3}) end end})
    WarningTab:CreateButton({Name = "Unload script, wait for update", Callback = function() Rayfield:Destroy() end})
end

function Module.BuildAllUI(Rayfield, Window, me, folderName, sendRequest, isVersionSafe, SAFE_PLACE_VERSION, currentVersion, UI_THEMES, selectedDisplayTheme)
    local AboutTab = Window:CreateTab("About", "info") 
    local MainTab = Window:CreateTab("Main", "home")
    local MiscTab = Window:CreateTab("Misc", "settings")
    local ConfigTab = Window:CreateTab("Config", "file-text")

    -- [ABOUT TAB]
    AboutTab:CreateSection("Script Information")
    AboutTab:CreateParagraph({Title = "Status", Content = isVersionSafe and "Game version matched (" .. tostring(SAFE_PLACE_VERSION) .. ")! Script is safe to use and everything is working fine!" or "⚠️ Warning: Running on an unverified game version (" .. tostring(currentVersion) .. "). Script was last updated for version " .. tostring(SAFE_PLACE_VERSION) .. ". Use at your risk!"})
    
    AboutTab:CreateSection("Safety Guidelines")
    AboutTab:CreateParagraph({Title = "⚠️ Private Server Recommended", Content = "Please use this script in a private server only. Make sure your private server only has you or a very trusted friend in it. Do not put random people in your server to avoid being reported/ being tracked by developers."})
    
    AboutTab:CreateSection("Update Logs")
    AboutTab:CreateParagraph({Title = "<font size=\"16\"><b>[*] Update: 6/15/2026 (Anti-Lag Nuke)</b></font>", Content = "• Completely rebuilt the AFK Frame Disabler. It now severs network event connections and aggressively disables native game scripts to drastically reduce RAM/CPU leaks from fast-rolling."})
    AboutTab:CreateParagraph({Title = "<font size=\"16\"><b>[*] Update: 6/13/2026 (Hotfix)</b></font>", Content = "• Fixed Crate Opener Configuration bug. Crate Type, Amount, and Delay now properly save/load.\n• Added Map Pre-loading sequence to ensure UT/Rune features work instantly."})
    AboutTab:CreateParagraph({Title = "<font size=\"16\"><b>[*] Update: 6/13/2026</b></font>", Content = "• Overhauled Auto Quirk Loop to stay on a single category and aggressively spam rolls before switching.\n• Converted Crate Opener into a Loop Toggle with an adjustable delay input.\n• Added Auto Drop (Ball Landed) feature.\n• Fixed Auto Upgrades to dynamically read from the game's new Upgrades module."})
    AboutTab:CreateParagraph({Title = "<font size=\"16\"><b>[*] Update: 6/11/2026</b></font>", Content = "• Removed Global Throttle so individual remotes can fire at maximum independent speeds.\n• Grouped all execution speeds into a single, easy-to-edit SPEED_CONFIG table."})

    -- [MAIN TAB]
    MainTab:CreateSection("Exploits")
    local unlockBtn
    local hasUnlocked = false
    unlockBtn = MainTab:CreateButton({
        Name = "Unlock Every Features ingame",
        Callback = function()
            if hasUnlocked then Rayfield:Notify({Title = "Notice", Content = "Features already unlocked this session.", Duration = 2}); return end
            hasUnlocked = true
            pcall(function()
                local unlocks = me:FindFirstChild("Data") and me.Data:FindFirstChild("Unlocks")
                if unlocks then
                    for _, child in ipairs(unlocks:GetChildren()) do if child:IsA("ValueBase") then child.Value = 1 end end
                    Rayfield:Notify({Title = "Success", Content = "All features successfully unlocked! (One-Time Use)", Duration = 3})
                    if unlockBtn then unlockBtn:Set("All Features Unlocked ✓") end
                end
            end)
        end
    })
    
    MainTab:CreateParagraph({Title = "⚠️ FPS Booster Note", Content = "Restart Required: You might need to rejoin after enabling/disabling the Frame Disablers for them to work properly. Save this in your autoload!"})
    local Toggle_RollingFrame = MainTab:CreateToggle({Name = "Disable ALL Rolling Frames (Boost FPS by A LOT)", CurrentValue = false, Callback = function(V) _G.DisableRollingFrameActive = V end})
    local Toggle_RemoveFrames = MainTab:CreateToggle({Name = "Remove every frame (For AFK users)", CurrentValue = false, Callback = function(V) _G.RemoveEveryFrameActive = V end})

    MainTab:CreateSection("Item Utilities")
    local crateList = {}
    local useItemList = {}
    pcall(function()
        local itemsFolder = me:FindFirstChild("Data") and me.Data:FindFirstChild("Items")
        if itemsFolder then
            for _, item in ipairs(itemsFolder:GetChildren()) do
                local name = item.Name
                if string.match(name, "Crate") then 
                    table.insert(crateList, name) 
                elseif not string.match(name, "Chest") and not string.match(name, "Quest Reroll") then
                    table.insert(useItemList, name)
                end
            end
        end
    end)
    if #crateList == 0 then table.insert(crateList, "Basic Crate") end
    if #useItemList == 0 then table.insert(useItemList, "None") end
    
    _G.SelectedCrate = crateList[1]
    _G.CrateDelay = 0.01
    _G.AutoCrateAmount = 100
    _G.SelectedUseItems = {useItemList[1]}
    
    local Dropdown_Crates = MainTab:CreateDropdown({Name = "Select Crate Type", Options = crateList, CurrentOption = {crateList[1]}, MultipleOptions = false, Callback = function(O) if O and O[1] then _G.SelectedCrate = O[1] end end})
    local Input_CrateAmount = MainTab:CreateInput({Name = "Auto Crate Amount", PlaceholderText = "Amount per tick (Default 100)", RemoveTextAfterFocusLost = false, Callback = function(T) local num = tonumber(T); if num and num > 0 then _G.AutoCrateAmount = math.floor(num) end end})
    local Input_CrateDelay = MainTab:CreateInput({Name = "Auto Crate Delay (Seconds)", PlaceholderText = "Min: 0.01", RemoveTextAfterFocusLost = false, Callback = function(T) local num = tonumber(T); if num and num >= 0.01 then _G.CrateDelay = num end end})
    local Toggle_AutoCrate = MainTab:CreateToggle({Name = "Auto Open Crate", CurrentValue = false, Callback = function(V) _G.AutoCrateActive = V end})
    
    local Dropdown_UseItems = MainTab:CreateDropdown({Name = "Select Item(s) to Use Max", Options = useItemList, CurrentOption = _G.SelectedUseItems, MultipleOptions = true, Callback = function(O) _G.SelectedUseItems = O end})
    MainTab:CreateButton({Name = "Use Max Selected Item(s)", Callback = function()
        if _G.SelectedUseItems and #_G.SelectedUseItems > 0 and _G.SelectedUseItems[1] ~= "None" then
            task.spawn(function()
                for _, itemName in ipairs(_G.SelectedUseItems) do
                    if itemName ~= "None" then
                        pcall(function()
                            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("UseItem"):FireServer(itemName, true)
                        end)
                        task.wait(0.15) -- Cooldown so it doesn't look suspicious
                    end
                end
                Rayfield:Notify({Title = "Items Used", Content = "Successfully used max for selected items.", Duration = 3})
            end)
        else 
            Rayfield:Notify({Title = "Error", Content = "No valid items selected.", Duration = 3}) 
        end
    end})

    MainTab:CreateSection("Quirk Utilities")
    local quirkList = {}
    pcall(function()
        local quirksFolder = me:FindFirstChild("Data") and me.Data:FindFirstChild("Quirks")
        if quirksFolder then
            for _, q in ipairs(quirksFolder:GetChildren()) do
                table.insert(quirkList, q.Name)
            end
        end
    end)
    if #quirkList == 0 then table.insert(quirkList, "Rarities") end
    
    _G.SelectedQuirks = {}
    local Dropdown_Quirks = MainTab:CreateDropdown({Name = "Choose Quirk(s) to auto roll", Options = quirkList, CurrentOption = _G.SelectedQuirks, MultipleOptions = true, Callback = function(O) _G.SelectedQuirks = O end})
    local Toggle_AutoQuirk = MainTab:CreateToggle({Name = "Auto Roll Quirk(s)", CurrentValue = false, Callback = function(V) _G.AutoQuirkRollActive = V end})

    MainTab:CreateSection("Automation")
    local Toggle_AutoClick = MainTab:CreateToggle({Name = "Auto Click (for Clicks currency)", CurrentValue = false, Callback = function(V) _G.AutoClickActive = V end})
    local Toggle_AutoDrop = MainTab:CreateToggle({Name = "Auto Drop (Ball Landed)", CurrentValue = false, Callback = function(V) _G.AutoDropActive = V end})
    local Toggle_Glyph = MainTab:CreateToggle({Name = "Fast Glyph Auto Roll", CurrentValue = false, Callback = function(V) _G.GlyphRollActive = V end})
    
    -- ALL ROLLS
    local Toggle_FastRoll = MainTab:CreateToggle({Name = "Fast Auto Roll", CurrentValue = false, Callback = function(V) _G.FastRollActive = V end})
    local Toggle_FastYatzy = MainTab:CreateToggle({Name = "Fast Yatzy Auto Roll", CurrentValue = false, Callback = function(V) _G.FastYatzyRollActive = V end})
    local Toggle_FastCoinFlip = MainTab:CreateToggle({Name = "Fast Auto Coin Flip", CurrentValue = false, Callback = function(V) _G.FastCoinFlipActive = V end})

    MainTab:CreateSection("Resets")
    local Toggle_Resets = MainTab:CreateToggle({Name = "Enable Auto Resets", CurrentValue = false, Callback = function(V) _G.AutoResetsActive = V end})
    local Dropdown_Resets = MainTab:CreateDropdown({Name = "Select Resets to Auto", Options = {"Overroll", "Rebirth", "Tiers"}, CurrentOption = {"Overroll"}, MultipleOptions = true, Callback = function(O) _G.AutoResetsList = O end})

    MainTab:CreateSection("Upgrades & Achievements")
    local Toggle_AllUpgrades = MainTab:CreateToggle({Name = "Enable Auto Upgrades", CurrentValue = false, Callback = function(V) _G.AutoAllUpgrades = V end})
    local Dropdown_Upgrades = MainTab:CreateDropdown({Name = "Select Currencies to Auto-Upgrade", Options = {"Coins", "PP", "AP", "Stars", "TP", "Time", "Energy", "Crystals", "Clicks", "Jade", "Essence", "Rarities", "Crowns", "Cash", "Silver", "Points", "SP"}, CurrentOption = {"Coins"}, MultipleOptions = true, Callback = function(O) _G.AutoUpgradesList = O end})
    local Toggle_UT = MainTab:CreateToggle({Name = "Auto Upgrade Tree", CurrentValue = false, Callback = function(V) _G.AutoUT = V end})
    local Toggle_Mastery = MainTab:CreateToggle({Name = "Auto Claim Mastery", CurrentValue = false, Callback = function(V) _G.AutoMasteryActive = V end})

    MainTab:CreateSection("Pad & Rune Utilities")
    local runesFolder = workspace:FindFirstChild("Runes")
    local dynamicRuneList = {}
    if runesFolder then for _, child in ipairs(runesFolder:GetChildren()) do table.insert(dynamicRuneList, child.Name) end end
    if #dynamicRuneList == 0 then table.insert(dynamicRuneList, "Basic") end 
    _G.SelectedRuneName = dynamicRuneList[1]
    
    local Dropdown_Rune = MainTab:CreateDropdown({Name = "Select Rune Type", Options = dynamicRuneList, CurrentOption = {dynamicRuneList[1]}, MultipleOptions = false, Callback = function(O) if O and O[1] then _G.SelectedRuneName = O[1] end end})
    local Toggle_Rune = MainTab:CreateToggle({Name = "Auto Rune Anywhere", CurrentValue = false, Callback = function(V) _G.RuneActive = V end})
    local Toggle_Rarity = MainTab:CreateToggle({Name = "Rarity Anywhere", CurrentValue = false, Callback = function(V) _G.RarityActive = V end})

    -- [MISC TAB]
    MiscTab:CreateSection("Streamer Mode")
    MiscTab:CreateParagraph({Title = "Visual Only!", Content = "This only changes your name on YOUR screen. Other players will still see your real username. This is meant for showcasing the script or flexing on Discord without being recognized."})
    MiscTab:CreateInput({Name = "Fake Username", PlaceholderText = "Type desired name...", RemoveTextAfterFocusLost = false, Callback = function(T) if T ~= "" then _G.StreamerName = T end end})
    MiscTab:CreateColorPicker({Name = "Fake Username Color", Color = Color3.fromRGB(255, 255, 255), Flag = "StreamerColor", Callback = function(V) _G.StreamerColor = V end})
    local Toggle_Streamer = MiscTab:CreateToggle({Name = "Enable Streamer Mode", CurrentValue = false, Callback = function(V) _G.StreamerMode = V; if not V and me.Character then pcall(function() local nametag = me.Character:FindFirstChild("OverheadGUI") and me.Character.OverheadGUI:FindFirstChild("Nametag"); if nametag then if nametag:FindFirstChild("Title") then nametag.Title.Text = me.DisplayName; nametag.Title.TextColor3 = Color3.fromRGB(255,255,255) end; if nametag:FindFirstChild("Shadow") then nametag.Shadow.Text = me.DisplayName end end end) end end})

    MiscTab:CreateSection("System")
    local Toggle_FPS = MiscTab:CreateToggle({Name = "Disable 3dRendering (FPS Boost)", CurrentValue = false, Callback = function(V) _G.FPSBoostActive = V; pcall(function() game:GetService("RunService"):Set3dRenderingEnabled(not V) end) end})
    MiscTab:CreateColorPicker({Name = "3D Rendering BG Color", Color = Color3.fromRGB(0,0,0), Callback = function(V) _G.RenderingColor = V end})

    MiscTab:CreateSection("Player Modifiers")
    local Toggle_Walkspeed = MiscTab:CreateToggle({Name = "Enable Walkspeed", CurrentValue = false, Callback = function(V) _G.WSModifier = V end})
    local Slider_Walkspeed = MiscTab:CreateSlider({Name = "Walkspeed", Range = {16, 250}, Increment = 1, CurrentValue = 16, Flag = "Slider_WS", Callback = function(V) _G.WSValue = V end})
    local Toggle_JumpPower = MiscTab:CreateToggle({Name = "Enable JumpPower", CurrentValue = false, Callback = function(V) _G.JPModifier = V end})
    local Slider_JumpPower = MiscTab:CreateSlider({Name = "JumpPower", Range = {50, 300}, Increment = 1, CurrentValue = 50, Flag = "Slider_JP", Callback = function(V) _G.JPValue = V end})

    -- [CONFIG TAB]
    local themeFile = folderName .. "/Theme.txt"
    ConfigTab:CreateSection("Appearance Customization")
    ConfigTab:CreateDropdown({
        Name = "Select UI Theme", Options = UI_THEMES, CurrentOption = {selectedDisplayTheme}, MultipleOptions = false,
        Callback = function(O) 
            if O and O[1] then 
                pcall(function() if writefile then writefile(themeFile, O[1]) end end)
                if O[1] ~= selectedDisplayTheme then Rayfield:Notify({Title = "Theme Saved", Content = "Please re-execute the script to apply.", Duration = 4}) end
            end
        end
    })

    ConfigTab:CreateSection("Configuration Profiles")
    local typedConfigName, selectedConfigProfile = "Config", "Config"
    ConfigTab:CreateInput({Name = "Config name", PlaceholderText = "Enter profile name...", RemoveTextAfterFocusLost = false, Callback = function(T) if T and T ~= "" then typedConfigName = T end end})
    local configListDropdown = ConfigTab:CreateDropdown({Name = "Config list", Options = {"Config"}, CurrentOption = {"Config"}, MultipleOptions = false, Callback = function(O) if O and O[1] then selectedConfigProfile = O[1] end end})
    local function refreshList() local p = {}; pcall(function() if listfiles then for _, f in pairs(listfiles("Dice Rolling Incremental")) do local n = f:match("([^/\\]+)%.json$"); if n then table.insert(p, n) end end end end); if #p == 0 then table.insert(p, "Config") end; configListDropdown:Refresh(p, true) end
    
    local function saveUniversal(n) if not writefile then return end; pcall(function() local d = {FastRoll=_G.FastRollActive, FastYatzy=_G.FastYatzyRollActive, FastCoinFlip=_G.FastCoinFlipActive, AutoClick=_G.AutoClickActive, AutoDrop=_G.AutoDropActive, AutoCrate=_G.AutoCrateActive, AutoCrateAmount=_G.AutoCrateAmount, CrateDelay=_G.CrateDelay, SelectedCrate=_G.SelectedCrate, Glyph=_G.GlyphRollActive, AutoMastery=_G.AutoMasteryActive, Rune=_G.RuneActive, Rarity=_G.RarityActive, RuneType=_G.SelectedRuneName, UseItemsList=_G.SelectedUseItems, SelectedQuirks=_G.SelectedQuirks, AutoQuirk=_G.AutoQuirkRollActive, RollingFrame=_G.DisableRollingFrameActive, RemoveFrames=_G.RemoveEveryFrameActive, WSMod=_G.WSModifier, WSVal=_G.WSValue, JPMod=_G.JPModifier, JPVal=_G.JPValue, FPS=_G.FPSBoostActive, StreamerMode=_G.StreamerMode, AutoAllUpgrades=_G.AutoAllUpgrades, AutoResets=_G.AutoResetsActive, ResetsList=_G.AutoResetsList, AutoUT=_G.AutoUT, AutoUpgrades=_G.AutoUpgradesList, BgR=_G.RenderingColor.R, BgG=_G.RenderingColor.G, BgB=_G.RenderingColor.B}; writefile("Dice Rolling Incremental/" .. n .. ".json", game:GetService("HttpService"):JSONEncode(d)) end) end
    local function loadUniversal(n) if not readfile or not isfile then return end; pcall(function() local p = "Dice Rolling Incremental/" .. n .. ".json"; if isfile(p) then local d = game:GetService("HttpService"):JSONDecode(readfile(p)); if d.FastRoll ~= nil then _G.FastRollActive = d.FastRoll; Toggle_FastRoll:Set(d.FastRoll) end; if d.FastYatzy ~= nil then _G.FastYatzyRollActive = d.FastYatzy; Toggle_FastYatzy:Set(d.FastYatzy) end; if d.FastCoinFlip ~= nil then _G.FastCoinFlipActive = d.FastCoinFlip; Toggle_FastCoinFlip:Set(d.FastCoinFlip) end; if d.AutoClick ~= nil then _G.AutoClickActive = d.AutoClick; Toggle_AutoClick:Set(d.AutoClick) end; if d.AutoDrop ~= nil then _G.AutoDropActive = d.AutoDrop; Toggle_AutoDrop:Set(d.AutoDrop) end; if d.AutoCrate ~= nil then _G.AutoCrateActive = d.AutoCrate; Toggle_AutoCrate:Set(d.AutoCrate) end; if d.AutoCrateAmount ~= nil then _G.AutoCrateAmount = d.AutoCrateAmount; pcall(function() Input_CrateAmount:Set(tostring(d.AutoCrateAmount)) end) end; if d.CrateDelay ~= nil then _G.CrateDelay = d.CrateDelay; pcall(function() Input_CrateDelay:Set(tostring(d.CrateDelay)) end) end; if d.SelectedCrate ~= nil then _G.SelectedCrate = d.SelectedCrate; pcall(function() Dropdown_Crates:Set({d.SelectedCrate}) end) end; if d.Glyph ~= nil then _G.GlyphRollActive = d.Glyph; Toggle_Glyph:Set(d.Glyph) end; if d.AutoMastery ~= nil then _G.AutoMasteryActive = d.AutoMastery; Toggle_Mastery:Set(d.AutoMastery) end; if d.Rune ~= nil then _G.RuneActive = d.Rune; Toggle_Rune:Set(d.Rune) end; if d.Rarity ~= nil then _G.RarityActive = d.Rarity; Toggle_Rarity:Set(d.Rarity) end; if d.RuneType ~= nil then _G.SelectedRuneName = d.RuneType; Dropdown_Rune:Set({d.RuneType}) end; if d.UseItemsList ~= nil then _G.SelectedUseItems = d.UseItemsList; Dropdown_UseItems:Set(d.UseItemsList) end; if d.SelectedQuirks ~= nil then _G.SelectedQuirks = d.SelectedQuirks; Dropdown_Quirks:Set(d.SelectedQuirks) end; if d.AutoQuirk ~= nil then _G.AutoQuirkRollActive = d.AutoQuirk; Toggle_AutoQuirk:Set(d.AutoQuirk) end; if d.RollingFrame ~= nil then _G.DisableRollingFrameActive = d.RollingFrame; Toggle_RollingFrame:Set(d.RollingFrame) end; if d.RemoveFrames ~= nil then _G.RemoveEveryFrameActive = d.RemoveFrames; Toggle_RemoveFrames:Set(d.RemoveFrames) end; if d.WSMod ~= nil then _G.WSModifier = d.WSMod; Toggle_Walkspeed:Set(d.WSMod) end; if d.WSVal ~= nil then _G.WSValue = d.WSVal; Slider_Walkspeed:Set(d.WSVal) end; if d.JPMod ~= nil then _G.JPModifier = d.JPMod; Toggle_JumpPower:Set(d.JPMod) end; if d.JPVal ~= nil then _G.JPValue = d.JPVal; Slider_JumpPower:Set(d.JPVal) end; if d.StreamerMode ~= nil then _G.StreamerMode = d.StreamerMode; Toggle_Streamer:Set(d.StreamerMode) end; if d.AutoAllUpgrades ~= nil then _G.AutoAllUpgrades = d.AutoAllUpgrades; Toggle_AllUpgrades:Set(d.AutoAllUpgrades) end; if d.FPS ~= nil then _G.FPSBoostActive = d.FPS; Toggle_FPS:Set(d.FPS); pcall(function() game:GetService("RunService"):Set3dRenderingEnabled(not d.FPS) end) end; if d.AutoResets ~= nil then _G.AutoResetsActive = d.AutoResets; Toggle_Resets:Set(d.AutoResets) end; if d.ResetsList ~= nil then _G.AutoResetsList = d.ResetsList; Dropdown_Resets:Set(d.ResetsList) end; if d.AutoUT ~= nil then _G.AutoUT = d.AutoUT; Toggle_UT:Set(d.AutoUT) end; if d.AutoUpgrades ~= nil then _G.AutoUpgradesList = d.AutoUpgrades; Dropdown_Upgrades:Set(d.AutoUpgrades) end; if d.BgR ~= nil and d.BgG ~= nil and d.BgB ~= nil then _G.RenderingColor = Color3.new(d.BgR, d.BgG, d.BgB) end end end) end
    
    ConfigTab:CreateButton({Name = "Create config", Callback = function() if typedConfigName ~= "" then saveUniversal(typedConfigName); task.wait(0.2); refreshList(); Rayfield:Notify({Title = "Config", Content = "Created: " .. typedConfigName, Duration = 2}) end end})
    ConfigTab:CreateButton({Name = "Load config", Callback = function() local t = (selectedConfigProfile ~= "Config") and selectedConfigProfile or typedConfigName; loadUniversal(t); Rayfield:Notify({Title = "Config", Content = "Loaded: " .. t, Duration = 2}) end})
    ConfigTab:CreateButton({Name = "Overwrite config", Callback = function() local t = (selectedConfigProfile ~= "Config") and selectedConfigProfile or typedConfigName; saveUniversal(t); Rayfield:Notify({Title = "Config", Content = "Overwrote: " .. t, Duration = 2}) end})
    ConfigTab:CreateButton({Name = "Refresh list", Callback = function() refreshList(); Rayfield:Notify({Title = "Config", Content = "List refreshed.", Duration = 1}) end})
    local autoloadLabel = ConfigTab:CreateParagraph({Title = "Set as autoload", Content = "Current autoload: none"})
    ConfigTab:CreateButton({Name = "Set as autoload", Callback = function() local t = (selectedConfigProfile ~= "Config") and selectedConfigProfile or typedConfigName; pcall(function() if writefile then writefile("Dice Rolling Incremental/Autoload.txt", t); autoloadLabel:Set({Title = "Set as autoload", Content = "Current autoload: " .. t}); Rayfield:Notify({Title = "Config", Content = t .. " set to Autoload.", Duration = 2}) end end) end})
    task.spawn(function() task.wait(1.5); refreshList(); pcall(function() if isfile and isfile("Dice Rolling Incremental/Autoload.txt") then local a = readfile("Dice Rolling Incremental/Autoload.txt"); if a and a ~= "" then autoloadLabel:Set({Title = "Set as autoload", Content = "Current autoload: " .. a}); loadUniversal(a) end end end) end)
end

return Module
