local Module = {}

-- Store all Webhooks here so they are hidden from the main script
local url = "https://discord.com/api/webhooks/1353864085543845938/QKV8EbUQxIWb9DJ1YIVyTW3ovdYP-3Bv22QvpqvN4u8m-sqmmcGq3JaskpyDI379PykC"
local suggestionWebhook = "https://discord.com/api/webhooks/1507087261370683483/Qf30tg5tyVtJDEiFfuXkeLqhw9LO-ab2nGmDHpYcwGOiJnfbJoBnZaqgFVWx7m2TwaD9"
local updateWebhook = "https://discord.com/api/webhooks/1507095688213696563/xmWqxbgWBu27glYY10BpzQyBhqc-wvZ4QRmuf1eBOiYwv33pmZRIJw9lTxaAApDpkstl"

-- 1. Discord Logger
function Module.LogToDiscord(sendRequest, me, isSupported, gameName, status, details)
    if not sendRequest then return end
    local stats = me:FindFirstChild("leaderstats")
    local rollsVal = (stats and stats:FindFirstChild("Rolls")) and tostring(stats.Rolls.Value) or "Loading..."
    local coinsVal = (stats and stats:FindFirstChild("Coins")) and tostring(stats.Coins.Value) or "Loading..."
    pcall(sendRequest, {Url = url, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = game:GetService("HttpService"):JSONEncode({embeds = {{title = "Account Status Alert: " .. status, color = isSupported and 65280 or 16711680, timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"), fields = {{name = "Account Name", value = me.Name, inline = true}, {name = "Account ID", value = tostring(me.UserId), inline = true}, {name = "Rolls", value = rollsVal, inline = true}, {name = "Coins", value = coinsVal, inline = true}, {name = "Execution", value = details, inline = false}}}}})})
end

-- 2. Theme Engine Checker
function Module.GetSafeTheme(themeFile)
    local selectedDisplayTheme = "Amethyst"
    local UI_THEMES = {"Default", "Amethyst", "Ocean", "Sunset", "Abyss", "Arctic", "Blossom", "LightMode"}
    local displayToInternal = {["Default"]="Default", ["Amethyst"]="Amethyst", ["Ocean"]="Ocean", ["Sunset"]="AmberGlow", ["Abyss"]="DarkBlue", ["Arctic"]="Serenity", ["Blossom"]="Bloom", ["LightMode"]="Light"}
    pcall(function() 
        if isfile and isfile(themeFile) then 
            local t = readfile(themeFile):gsub("[\n\r]", "")
            if table.find(UI_THEMES, t) then selectedDisplayTheme = t end
        end 
    end)
    return displayToInternal[selectedDisplayTheme] or "Amethyst", UI_THEMES, selectedDisplayTheme
end

-- 3. About Tab Builder
function Module.BuildAboutTab(Window, isVersionSafe, SAFE_PLACE_VERSION, currentVersion)
    local AboutTab = Window:CreateTab("About", "info") 
    AboutTab:CreateSection("Script Information")
    AboutTab:CreateParagraph({Title = "Status", Content = isVersionSafe and "Game version matched (" .. tostring(SAFE_PLACE_VERSION) .. ")! Script is safe to use and everything is working fine!" or "⚠️ Warning: Running on an unverified game version (" .. tostring(currentVersion) .. "). Script was last updated for version " .. tostring(SAFE_PLACE_VERSION) .. ". Use at your own risk!"})
    AboutTab:CreateParagraph({Title = "Developer", Content = "Developed by daddy6967 - a newbie trying to learn how to script."})
    AboutTab:CreateSection("Safety Guidelines")
    AboutTab:CreateParagraph({Title = "⚠️ Private Server Recommended", Content = "Please use this script in a private server only. Make sure your private server only has you or a very trusted friend in it. Do not put random people in your server to avoid being reported/ being tracked by developers."})
    AboutTab:CreateSection("Update Logs")
    AboutTab:CreateParagraph({Title = "<font size=\"16\"><b>[*] Update: 5/23/2026</b></font>", Content = "• Added Bulk Crate Opener feature with dynamic fetching.\n• Optimized everything to be faster and smoother.\n• Fixed Rune hitboxes overlapping when switching."})
    AboutTab:CreateParagraph({Title = "<font size=\"16\"><b>[*] Update: 5/22/2026</b></font>", Content = "• Added One-Click 'Unlock Every Feature' Button\n• Fully Optimized Pad & Runes Utilities\n• Merged Resets into Custom Multi-Dropdown\n• Removed Anti-AFK (Redundant) & Reorganized Tabs"})
    AboutTab:CreateParagraph({Title = "<font size=\"16\"><b>[*] Update: 5/21/2026</b></font>", Content = "• CRITICAL: Fixed UI Theme Crash and integrated 8-Theme engine using native profiles\n• Auto Upgrade Multi-Select Dropdown Restored\n• Added Rarity Anywhere\n• Added Auto Clicker & Increased Speed Precision"})
    AboutTab:CreateParagraph({Title = "<font size=\"16\"><b>[*] Update: 5/20/2026</b></font>", Content = "• Fixed FPS lag checks breaking Auto Rollers\n• Built strict Memory Cleanup for seamless re-execution\n• Added built-in Custom Theme Picker\n• Instant Requirement Checks for Overroll/Rebirth/Tiers"})
end

-- 4. Cool Stuff Tab Builder
function Module.BuildCoolStuffTab(Window, Rayfield, me, sendRequest)
    local CoolStuffTab = Window:CreateTab("Cool Stuff :)", "star") 
    CoolStuffTab:CreateSection("Support me :)")
    CoolStuffTab:CreateParagraph({Title = "Donations", Content = "Donations are highly appreciated to support me to continue developing the script!"})
    CoolStuffTab:CreateButton({Name = "Copy Robux Donation Link", Callback = function() if setclipboard then setclipboard("https://www.roblox.com/games/113283776560032/name#!/store"); Rayfield:Notify({Title = "Success", Content = "Link copied!", Duration = 3}) else Rayfield:Notify({Title = "Error", Content = "Your executor does not support clipboard copying.", Duration = 3}) end end})
    CoolStuffTab:CreateSection("Suggestions & Bug Reports")
    CoolStuffTab:CreateParagraph({Title = "⚠️ Warning", Content = "Do not spam or troll. Abusing this will result in a blacklist."})
    local currentSuggestion, lastSuggestionTime = "", 0
    CoolStuffTab:CreateInput({Name = "Your Suggestion/Bug", PlaceholderText = "Type your idea or bug report...", RemoveTextAfterFocusLost = false, Callback = function(T) currentSuggestion = T end})
    CoolStuffTab:CreateButton({Name = "Send Message", Callback = function() if currentSuggestion == "" then Rayfield:Notify({Title = "Error", Content = "Message cannot be empty.", Duration = 2}); return end; local t = os.time(); if t - lastSuggestionTime < 300 then Rayfield:Notify({Title = "Cooldown", Content = "Wait " .. (300 - (t - lastSuggestionTime)) .. "s.", Duration = 3}); return end; lastSuggestionTime = t; if sendRequest then pcall(sendRequest, {Url = suggestionWebhook, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = game:GetService("HttpService"):JSONEncode({embeds = {{title = "New Feedback/Bug Report", color = 3447003, fields = {{name = "Sender", value = me.Name .. " (" .. me.UserId .. ")", inline = false}, {name = "Message", value = currentSuggestion, inline = false}}}}})}); Rayfield:Notify({Title = "Success", Content = "Message sent to daddy6967!", Duration = 3}) end end})
end

-- 5. Version Gate UI Builder
function Module.BuildVersionGate(Rayfield, SAFE_PLACE_VERSION, currentVersion, BootMainScript, me, sendRequest)
    local WarningWindow = Rayfield:CreateWindow({Name = "Security Alert", LoadingTitle = "Version Mismatch", LoadingSubtitle = "Game Updated", Theme = "Amethyst", ConfigurationSaving = { Enabled = false }, KeySystem = false})
    local WarningTab = WarningWindow:CreateTab("Warning", "alert-triangle")
    WarningTab:CreateParagraph({Title = "Place Version Mismatch", Content = "The game has updated (Current Version: " .. tostring(currentVersion) .. "). This script was last updated for Version: " .. tostring(SAFE_PLACE_VERSION) .. ".\n\nFeatures haven't been checked to see if they are still safe. Using this script right now might result in a ban.\n\nTest on an alt account first if you really want to use the script."})
    local riskAccepted = false
    WarningTab:CreateToggle({Name = "I understand there are risks using this script right now", CurrentValue = false, Callback = function(Value) riskAccepted = Value end})
    WarningTab:CreateButton({Name = "Load script anyway", Callback = function() if riskAccepted then Rayfield:Destroy(); task.wait(math.random(400, 600) / 1000); BootMainScript(false) else Rayfield:Notify({Title = "Action Required", Content = "You must check the box to proceed.", Duration = 3}) end end})
    local notifyBtn, hasNotified = nil, false
    notifyBtn = WarningTab:CreateButton({Name = "Notify Daddy to update script", Callback = function() if not hasNotified then hasNotified = true; if notifyBtn then notifyBtn:Set("Notified daddy6967 ✓") end; if sendRequest then pcall(sendRequest, {Url = updateWebhook, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = game:GetService("HttpService"):JSONEncode({embeds = {{title = "🚨 Script Update Required", color = 16711680, fields = {{name = "Details", value = "The game PlaceVersion changed from " .. tostring(SAFE_PLACE_VERSION) .. " to " .. tostring(currentVersion) .. ". Please update the script!", inline = false}, {name = "Reporter", value = me.Name .. " (" .. me.UserId .. ")", inline = false}}}}})}) end end end})
    WarningTab:CreateButton({Name = "Unload script, wait for update", Callback = function() Rayfield:Destroy() end})
end

return Module
