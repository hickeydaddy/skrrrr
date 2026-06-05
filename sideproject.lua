-- ========================================================================
-- ALIASES & OPTIMIZATIONS
-- Localizing these global functions makes the script run faster overall.
-- ========================================================================
local t_wait, t_spawn, p_call, t_insert, t_remove = task.wait, task.spawn, pcall, table.insert, table.remove

-- [ ADJUST HERE ] 
-- Initial wait time to let the game load before the script injects.
t_wait(3)

-- ========================================================================
-- MEMORY MANAGEMENT (JANITORS)
-- Handles cleaning up old connections so the script doesn't duplicate if re-executed.
-- ========================================================================
local Janitor = {__index = {}}
function Janitor.new() return setmetatable({_tasks = {}}, Janitor) end
function Janitor.__index:Add(t, m)
    if not t then return t end
    t_insert(self._tasks, {obj=t, method=type(t)=="function" and not m and function(fn) fn() end or (m or "Disconnect")})
    return t
end
function Janitor.__index:Cleanup()
    for i=#self._tasks, 1, -1 do
        local d = self._tasks[i]
        if type(d.method)=="string" and type(d.obj[d.method])=="function" then p_call(d.obj[d.method], d.obj)
        elseif type(d.method)=="function" then p_call(d.method, d.obj) end
        self._tasks[i] = nil
    end
end

if _G.VibeTycoonJanitor then _G.VibeTycoonJanitor:Cleanup() end
local J_Main, J_Purch, J_Rems = Janitor.new(), Janitor.new(), Janitor.new()
_G.VibeTycoonJanitor = J_Main
J_Main:Add(J_Purch, "Cleanup"); J_Main:Add(J_Rems, "Cleanup")

_G.VibeTycoonSession = (_G.VibeTycoonSession or 0) + 1
local cSess = _G.VibeTycoonSession

local HttpS, Plrs, TpS = game:GetService("HttpService"), game:GetService("Players"), game:GetService("TeleportService")
local LP, fName = Plrs.LocalPlayer, "SellLemonsConfigs"
if makefolder and not isfolder(fName) then p_call(makefolder, fName) end

-- ========================================================================
-- TYCOON FINDER (BLANK GUI FIX)
-- Script now waits patiently until you claim a tycoon instead of breaking.
-- ========================================================================
local uTycoon, notifiedWait = nil, false
while _G.VibeTycoonSession == cSess do
    for _, v in ipairs(workspace:GetChildren()) do
        if v:IsA("Folder") and v.Name:match("Tycoon%d") and v:FindFirstChild("Owner") and v.Owner.Value==LP then uTycoon=v; break end
    end
    if uTycoon then break end
    if not notifiedWait then
        p_call(function() game.StarterGui:SetCore("SendNotification", {Title="Vibe Script", Text="Waiting for you to claim a Tycoon...", Duration=5}) end)
        notifiedWait = true
    end
    t_wait(1)
end
if not uTycoon then return end -- Failsafe if session changed

-- ========================================================================
-- BOOTLOADER & UI SETUP
-- ========================================================================
local uiCode, fOk, fErr
fOk, fErr = p_call(function() uiCode = game:HttpGet('https://sirius.menu/rayfield') end)
if not fOk or not uiCode then return warn("⚠️ [Vibe Tycoon]: UI FETCH FAILED\nError: "..tostring(fErr)) end
local rfLoader, lErr = loadstring(uiCode)
if not rfLoader then return warn("⚠️ [Vibe Tycoon]: UI COMPILE FAILED\nError: "..tostring(lErr)) end
local Rayfield = rfLoader()
if not Rayfield then return warn("⚠️ [Vibe Tycoon]: UI INIT FAILED") end

J_Main:Add(Rayfield, "Destroy")
local Window = Rayfield:CreateWindow({Name="Vibe Code Central / Sell Lemons", LoadingTitle="Vibe Codey baby", LoadingSubtitle="Master Edition v4 (Bulletproof)", ConfigurationSaving={Enabled=false}, KeySystem=false})
local MainTab, ConfigTab = Window:CreateTab("Main", 4483362458), Window:CreateTab("Config", 4483362458)

-- ========================================================================
-- STATE & DEFAULT VARIABLES
-- ========================================================================
local AutoBuy, AutoUpgrade, AutoFruit, AutoRebirth, AutoEvolve, AutoAscend, AutoPwr, AutoRejoin = false,false,false,false,false,false,false,false

-- [ ADJUST HERE ] 
-- Anti-stuck default times: 15 mins to hard rejoin, 5 mins for smart stagnation
local RejoinMin, SmartStuck, StuckMin = 15, true, 5
local stats = {buys=0, upgrades=0, fruit=0, rebirths=0, evolves=0, ascends=0}

-- ========================================================================
-- CACHING SYSTEM (Purchases, Upgrades, Remotes)
-- ========================================================================
local CRem = {}

local function UpdRemotes()
    J_Rems:Cleanup(); local rf = uTycoon:FindFirstChild("Remotes")
    CRem = rf and {Rebirth=rf:FindFirstChild("Rebirth"), Evolve=rf:FindFirstChild("Evolve"), Ascend=rf:FindFirstChild("Ascend"), Pwr=rf:FindFirstChild("UpgradePowerLevel"), RebSignal=rf:FindFirstChild("Rebirthed")} or {}
    if not rf then return end
    for ev, k in pairs({Rebirthed="rebirths", Evolved="evolves", Ascended="ascends"}) do
        local r=rf:FindFirstChild(ev); if r and r:IsA("RemoteEvent") then J_Rems:Add(r.OnClientEvent:Connect(function() stats[k]=stats[k]+1 end)) end
    end
end

local aPurch, bSet, uRems, uSet, hkMods = {},{},{},{},{}

local function evalP(m)
    local p = m:FindFirstChild("Purchase")
    -- [ BUG FIX ]: Restored strict exact == true checks so it doesn't accidentally cache false/nil
    if m:GetAttribute("Shown") == true and m:GetAttribute("Purchased") ~= true and p and p:IsA("RemoteFunction") then
        aPurch[m] = p
    else
        aPurch[m] = nil
    end
end

local function hkPMod(m)
    if hkMods[m] then return end; hkMods[m] = true
    J_Purch:Add(function() hkMods[m]=nil; aPurch[m]=nil; bSet[m]=nil end)
    J_Purch:Add(m:GetAttributeChangedSignal("Shown"):Connect(function() evalP(m) end))
    J_Purch:Add(m:GetAttributeChangedSignal("Purchased"):Connect(function() evalP(m) end))
    J_Purch:Add(m.ChildAdded:Connect(function(c) if c.Name=="Purchase" then evalP(m) end end))
    J_Purch:Add(m.ChildRemoved:Connect(function(c) if c.Name=="Purchase" then evalP(m) end end))
    evalP(m)
end

local function scnDesc(d)
    if d:IsA("RemoteFunction") then
        if d.Name=="Upgrade" then uRems[d] = uRems[d] or 1
        elseif d.Name=="Purchase" and d.Parent and d.Parent:IsA("Model") then hkPMod(d.Parent) end
    elseif d:IsA("Model") and d:GetAttribute("Shown")~=nil then hkPMod(d)
    end
end

local function initCache()
    J_Purch:Cleanup(); aPurch, bSet, uRems, uSet, hkMods = {},{},{},{},{}
    local pf = uTycoon:FindFirstChild("Purchases"); if not pf then return end
    for _, d in ipairs(pf:GetDescendants()) do scnDesc(d) end
    J_Purch:Add(pf.DescendantAdded:Connect(scnDesc))
    J_Purch:Add(pf.DescendantRemoving:Connect(function(d)
        if d:IsA("Model") then aPurch[d], bSet[d], hkMods[d] = nil, nil, nil
        elseif d:IsA("RemoteFunction") and d.Name=="Upgrade" then uRems[d], uSet[d] = nil, nil end
    end))
end

J_Main:Add(uTycoon.ChildAdded:Connect(function(c)
    if c.Name=="Purchases" then t_wait(1); initCache()
    elseif c.Name=="Remotes" then t_wait(0.5); UpdRemotes() end
end))
initCache(); UpdRemotes()

-- ========================================================================
-- LEMON TREE CACHE
-- ========================================================================
local aTrees, hTrees = {},{}

local function hkTree(t)
    if aTrees[t] then return end; local j = Janitor.new()
    local tc, detSet, hasDetectors = {}, {}, false

    local function addDet(det)
        if detSet[det] then return end; detSet[det] = true; t_insert(tc, det); hasDetectors = true
    end
    local function remDet(det)
        if not detSet[det] then return end; detSet[det] = nil
        for i = #tc, 1, -1 do if tc[i]==det then t_remove(tc, i); break end end
        hasDetectors = next(detSet) ~= nil
    end

    for _, o in ipairs(t:GetDescendants()) do
        if o:IsA("BasePart") and o.Name=="Fruit" then
            o.CanCollide = false
            local cp = o:FindFirstChild("ClickPart")
            local det = cp and cp:FindFirstChildOfClass("ClickDetector")
            if det and det.MaxActivationDistance > 0 then addDet(det) end
        end
    end

    j:Add(t.DescendantAdded:Connect(function(c)
        if c:IsA("ClickDetector") and c.MaxActivationDistance > 0 and c.Parent and c.Parent.Parent and c.Parent.Parent.Name=="Fruit" then addDet(c)
        elseif c:IsA("BasePart") and c.Name=="Fruit" then c.CanCollide = false end
    end))
    j:Add(t.DescendantRemoving:Connect(function(c) if c:IsA("ClickDetector") then remDet(c) end end))

    aTrees[t] = {tc=tc, hasDetectors=hasDetectors, janitor=j, has=function() return hasDetectors end}
end

for _, d in ipairs(workspace:GetDescendants()) do if d:IsA("Model") and d.Name=="LemonTree" then hkTree(d) end end
J_Main:Add(workspace.DescendantAdded:Connect(function(d) if d:IsA("Model") and d.Name=="LemonTree" then hkTree(d) end end))
J_Main:Add(workspace.DescendantRemoving:Connect(function(d) if aTrees[d] then aTrees[d].janitor:Cleanup(); aTrees[d], hTrees[d] = nil, nil end end))

-- ========================================================================
-- LOOPS & FARMING
-- ========================================================================
local function sLoop(iv, fn) t_spawn(function() while _G.VibeTycoonSession == cSess do t_wait(iv); fn() end end) end

-- [ AUTO BUY LOOP ] 
-- SPEED: 0.04s loop tick
local actBuys = 0
sLoop(0.04, function()
    if not AutoBuy then return end
    -- [ BUG FIX ]: Added strict concurrency limits for Buying to prevent lag/hanging
    if actBuys >= 5 then return end 
    local n = tick()
    for m, r in pairs(aPurch) do
        if not AutoBuy or _G.VibeTycoonSession~=cSess then break end
        if not bSet[m] or n > bSet[m] then
            bSet[m] = n + 15
            actBuys = actBuys + 1
            t_spawn(function()
                if r.Parent then
                    local ok, res = p_call(function() return r:InvokeServer() end)
                    if ok and res ~= false then stats.buys = stats.buys + 1 end
                end
                -- [ ADJUST HERE ] bSet[m] = tick() + 1.5 -> Wait 1.5s before buying same item again
                bSet[m] = tick() + 1.5
                actBuys = math.max(0, actBuys - 1)
            end)
        end
    end
end)

-- [ AUTO UPGRADE LOOP ] 
-- SPEED: 0.1s loop tick
local actUpds = 0
sLoop(0.1, function()
    if not AutoUpgrade then return end
    if actUpds >= 5 then return end
    local n = tick()
    for r, cl in pairs(uRems) do
        if not AutoUpgrade or _G.VibeTycoonSession~=cSess then break end
        if not r.Parent then uRems[r], uSet[r] = nil, nil
        elseif actUpds < 5 and (not uSet[r] or n > uSet[r]) then
            uSet[r], actUpds = n + 30, actUpds + 1
            t_spawn(function()
                local l = cl
                p_call(function()
                    local b = 0
                    while l <= 100 do
                        if not AutoUpgrade or _G.VibeTycoonSession~=cSess or not r.Parent then break end
                        local ok, res = p_call(function() return r:InvokeServer(l) end)
                        if not ok or res == false then break end
                        l, stats.upgrades, b = l+1, stats.upgrades+1, b+1
                        if b % 2 == 0 then t_wait(0.01) end
                        uSet[r] = tick() + 30
                    end
                end)
                uRems[r], uSet[r], actUpds = l, nil, math.max(0, actUpds - 1)
            end)
        end
    end
end)

-- [ AUTO FRUIT LOOP ] 
-- SPEED: 0.25s loop tick
sLoop(0.25, function()
    if not AutoFruit then return end
    local n = tick()
    for t, d in pairs(aTrees) do
        if not AutoFruit or _G.VibeTycoonSession~=cSess then break end
        if not t.Parent then d.janitor:Cleanup(); aTrees[t], hTrees[t] = nil, nil; continue end
        if (hTrees[t] and n <= hTrees[t]) or not d.has() then continue end
        hTrees[t] = n + 15
        local tc = d.tc
        t_spawn(function()
            p_call(function()
                local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                local pv = t:GetPivot()
                if (hrp.Position - pv.Position).Magnitude > 15 then
                    hrp.CFrame = pv + Vector3.new(0, 5, 0); t_wait(0.25)
                end
                for _, det in ipairs(tc) do
                    if det.Parent then if p_call(fireclickdetector, det) then stats.fruit = stats.fruit + 1 end; t_wait(0.05) end
                end
            end)
            hTrees[t] = tick() + 1
        end)
    end
end)

-- [ SINGLE-LINE LOOPS ]
sLoop(0.25, function() if AutoPwr and CRem.Pwr and CRem.Pwr.Parent then p_call(CRem.Pwr.InvokeServer, CRem.Pwr) end end)
sLoop(5,    function() if AutoEvolve and CRem.Evolve and CRem.Evolve.Parent then p_call(CRem.Evolve.InvokeServer, CRem.Evolve) end end)
sLoop(1,    function() if AutoAscend and CRem.Ascend and CRem.Ascend.Parent then p_call(CRem.Ascend.InvokeServer, CRem.Ascend) end end)

-- [ AUTO REBIRTH LOOP ] SPEED: 0.5s
local RMult, RCd, rBusyTick = 2.0, 5, nil

local NUMS = {k=1e3,m=1e6,b=1e9,t=1e12,qd=1e15,qn=1e18,sx=1e21,sp=1e24,thousand=1e3,million=1e6,billion=1e9,trillion=1e12,quadrillion=1e15,quintillion=1e18,sextillion=1e21,septillion=1e24,octillion=1e27,nonillion=1e30,decillion=1e33,undecillion=1e36,duodecillion=1e39}
local function pNum(s)
    if not s then return nil end
    s = tostring(s):gsub(",",""):lower(); local n = tonumber(s:match("[%d%.]+"))
    if not n then return nil end; local w = s:match("[%d%.%s]+([a-z]+)")
    return w and NUMS[w] and n * NUMS[w] or n
end

local rBdy
sLoop(0.5, function()
    if not AutoRebirth or (rBusyTick and tick()-rBusyTick <= 30) or not CRem.Rebirth then return end
    if rBdy and not rBdy.Parent then rBdy = nil end
    if not rBdy then rBdy = LP:FindFirstChild("PlayerGui") and LP.PlayerGui:FindFirstChild("Rebirth") and LP.PlayerGui.Rebirth:FindFirstChild("InvestorsMenu") and LP.PlayerGui.Rebirth.InvestorsMenu:FindFirstChild("Body") end
    local a, p = rBdy and rBdy:FindFirstChild("Amount"), rBdy and rBdy:FindFirstChild("Potential")
    local cur, pot = a and a:FindFirstChild("Quantity") and pNum(a.Quantity.Text) or 0, p and p:FindFirstChild("Quantity") and pNum(p.Quantity.Text) or 0
    if pot and pot >= 1 and pot >= cur * RMult then
        rBusyTick = tick()
        p_call(function()
            local done, sig, c = false, CRem.RebSignal
            if sig and sig.Parent then c = sig.OnClientEvent:Connect(function() done = true end) end
            p_call(function()
                p_call(CRem.Rebirth.InvokeServer, CRem.Rebirth)
                local el = 0
                while not done and el < 8 do t_wait(0.1); el = el + 0.1 end
            end)
            if c then c:Disconnect() end; t_wait(RCd)
        end)
        initCache(); rBusyTick = nil
    end
end)

-- ========================================================================
-- UTILS & ANTI-STUCK
-- ========================================================================
local function exRej()
    Rayfield:Notify({Title="System", Content="Executing Auto-Rejoin...", Duration=5}); t_wait(1)
    p_call(function()
        local ok = p_call(function() if #Plrs:GetPlayers() <= 1 then TpS:Teleport(game.PlaceId, LP) else TpS:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end end)
        if not ok then LP:Kick("\nRejoining...") end
    end)
end

t_spawn(function()
    local sT, lTot, sTks = tick(), 0, 0
    while _G.VibeTycoonSession == cSess do
        t_wait(10)
        if AutoRejoin then if (tick() - sT) / 60 >= RejoinMin then exRej(); sT = tick() end else sT = tick() end
        local cT = (AutoBuy and stats.buys or 0) + (AutoUpgrade and stats.upgrades or 0) + (AutoFruit and stats.fruit or 0)
        if AutoRejoin and SmartStuck and (AutoBuy or AutoUpgrade or AutoFruit) then
            if cT == lTot then
                sTks = sTks + 1; if sTks >= StuckMin * 6 then Rayfield:Notify({Title="Anti-Stuck", Content="Stagnation! Forcing Rejoin.", Duration=3}); exRej() end
            else sTks = 0 end
        else sTks = 0 end
        lTot = cT
    end
end)

local function tch(hrp, p) p_call(firetouchinterest, hrp, p, 0); p_call(firetouchinterest, hrp, p, 1) end

-- ========================================================================
-- UI SETUP & BINDS
-- ========================================================================
MainTab:CreateSection("Auto Farming")
local TAB = MainTab:CreateToggle({Name="Auto Buy",     CurrentValue=false, Callback=function(v) AutoBuy=v end})
local TAU = MainTab:CreateToggle({Name="Auto Upgrade", CurrentValue=false, Callback=function(v) AutoUpgrade=v end})
local TAF = MainTab:CreateToggle({Name="Auto Fruit",   CurrentValue=false, Callback=function(v) AutoFruit=v end})
MainTab:CreateSection("Progression")
local TAR = MainTab:CreateToggle({Name="Auto Rebirth",  CurrentValue=false, Callback=function(v) AutoRebirth=v end})
local IRM = MainTab:CreateInput({Name="Rebirth Requirement Multiplier", PlaceholderText="Default: 2",  RemoveTextAfterFocusLost=false, Callback=function(t) local v=tonumber(t); if v then RMult=v end end})
local IRC = MainTab:CreateInput({Name="Min Seconds Before Rebirthing",  PlaceholderText="Default: 5",  RemoveTextAfterFocusLost=false, Callback=function(t) local v=tonumber(t); if v then RCd=v end end})
local TAE = MainTab:CreateToggle({Name="Auto Evolve (x10 income)", CurrentValue=false, Callback=function(v) AutoEvolve=v end})
local TAA = MainTab:CreateToggle({Name="Auto Ascend",       CurrentValue=false, Callback=function(v) AutoAscend=v end})
local TAP = MainTab:CreateToggle({Name="Auto Power Level",  CurrentValue=false, Callback=function(v) AutoPwr=v end})
MainTab:CreateSection("Anti-Stuck & Utilities")
local TRJ = MainTab:CreateToggle({Name="Auto Rejoin",                  CurrentValue=false, Callback=function(v) AutoRejoin=v end})
local TSS = MainTab:CreateToggle({Name="Smart Stagnation Detection",   CurrentValue=true,  Callback=function(v) SmartStuck=v end})
local IST = MainTab:CreateInput({Name="Smart Stagnation Timer (Mins)", PlaceholderText="Default: 5",  RemoveTextAfterFocusLost=false, Callback=function(t) local v=tonumber(t); if v then StuckMin=v end end})
local IRT = MainTab:CreateInput({Name="Hard Rejoin Timer (Mins)",      PlaceholderText="Default: 15", RemoveTextAfterFocusLost=false, Callback=function(t) local v=tonumber(t); if v then RejoinMin=v end end})

MainTab:CreateButton({Name="Pull All Levers (sewer)", Callback=function()
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local s, p = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Sewer"), 0
    for _, o in ipairs((s or workspace):GetDescendants()) do if o:IsA("BasePart") and o.Name:lower():match("lever") then tch(hrp, o); p=p+1 end end
    if s then for _, o in ipairs(s:GetDescendants()) do if o:IsA("BasePart") and (o.Name=="VineKey" or o.Name=="UFOKey") then tch(hrp, o) end end end
    Rayfield:Notify({Title="Levers", Content=p>0 and ("Pulled "..p.." lever(s)") or "No levers found", Duration=4})
end})

MainTab:CreateButton({Name="Vine Harvest", Callback=function()
    Rayfield:Notify({Title="Vine Harvest", Content="Running...", Duration=2})
    t_spawn(function()
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        local s = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Sewer"); if not s then return end
        for _, o in ipairs(s:GetDescendants()) do if o:IsA("BasePart") and o.Name:lower():match("lever") then tch(hrp, o) end end
        for _, fn in ipairs({"CashVine", "SewerAlien"}) do local f=s:FindFirstChild(fn); if f then for _, o in ipairs(f:GetDescendants()) do if o:IsA("BasePart") and (o.Name=="VineKey" or o.Name=="UFOKey") then tch(hrp, o) end end end end
        t_wait(0.3); local cv = s:FindFirstChild("CashVine"); if cv and cv:FindFirstChild("VineDoor") then for _, o in ipairs(cv.VineDoor:GetDescendants()) do if o:IsA("BasePart") then tch(hrp, o) end end end
        t_wait(0.3); if cv and cv:FindFirstChild("CashVine") then p_call(function() hrp.CFrame=cv.CashVine:GetPivot()+Vector3.new(0,3,0) end); t_wait(0.2); for _, o in ipairs(cv.CashVine:GetDescendants()) do if o:IsA("BasePart") then tch(hrp, o) end end end
        Rayfield:Notify({Title="Vine Harvest", Content="Done!", Duration=5})
    end)
end})

MainTab:CreateButton({Name="Teleport to Sewer Alien", Callback=function()
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if hrp then p_call(function() hrp.CFrame=CFrame.new(-42,-41,180) end); Rayfield:Notify({Title="Teleport", Content="Teleported to UFO", Duration=3}) end
end})

MainTab:CreateButton({Name="Destroy GUI", Callback=function() J_Main:Cleanup(); aPurch, uRems, aTrees, bSet, uSet, hTrees, hkMods = {},{},{},{},{},{},{}; Rayfield:Destroy() end})

-- ========================================================================
-- CONFIGURATION SYSTEM
-- ========================================================================
local tCfg, sCfg = "Config", "Config"
ConfigTab:CreateSection("Configuration Profiles")
ConfigTab:CreateInput({Name="Config name", PlaceholderText="Enter profile name...", RemoveTextAfterFocusLost=false, Callback=function(t) if t and t~="" then tCfg=t end end})
local CDrp = ConfigTab:CreateDropdown({Name="Config list", Options={"Config"}, CurrentOption={"Config"}, MultipleOptions=false, Callback=function(o) if o and o[1] then sCfg=o[1] end end})
local function refL() local p={}; p_call(function() if listfiles then for _,f in pairs(listfiles(fName)) do local n=f:match("([^/\\]+)%.json$"); if n then t_insert(p,n) end end end end); if #p==0 then t_insert(p,"Config") end; CDrp:Refresh(p,true) end
local function sC(n) if writefile then p_call(function() writefile(fName.."/"..n..".json", HttpS:JSONEncode({AB=AutoBuy,AU=AutoUpgrade,AF=AutoFruit,AR=AutoRebirth,RM=RMult,RCd=RCd,AE=AutoEvolve,AA=AutoAscend,AP=AutoPwr,ARJ=AutoRejoin,RJM=RejoinMin,SS=SmartStuck,SM=StuckMin})) end) end end
local function lC(n) if readfile and isfile then p_call(function() local pt=fName.."/"..n..".json"; if not isfile(pt) then return end; local d=HttpS:JSONDecode(readfile(pt)); local function a(t,k) if d[k]~=nil then t:Set(d[k]) end end; a(TAB,"AB"); a(TAU,"AU"); a(TAF,"AF"); a(TAR,"AR"); a(TAE,"AE"); a(TAA,"AA"); a(TAP,"AP"); a(TRJ,"ARJ"); a(TSS,"SS"); if d.RM~=nil then IRM:Set(tostring(d.RM)); RMult=d.RM end; if d.RCd~=nil then IRC:Set(tostring(d.RCd)); RCd=d.RCd end; if d.RJM~=nil then IRT:Set(tostring(d.RJM)); RejoinMin=d.RJM end; if d.SM~=nil then IST:Set(tostring(d.SM)); StuckMin=d.SM end end) end end
local function aC() return (sCfg~="Config") and sCfg or tCfg end
ConfigTab:CreateButton({Name="Create config",   Callback=function() sC(tCfg); t_wait(0.2); refL(); Rayfield:Notify({Title="Config", Content="Created: "..tCfg, Duration=2}) end})
ConfigTab:CreateButton({Name="Load config",     Callback=function() local t=aC(); lC(t); Rayfield:Notify({Title="Config", Content="Loaded: "..t, Duration=2}) end})
ConfigTab:CreateButton({Name="Overwrite config",Callback=function() local t=aC(); sC(t); Rayfield:Notify({Title="Config", Content="Overwrote: "..t, Duration=2}) end})
ConfigTab:CreateButton({Name="Refresh list",    Callback=function() refL(); Rayfield:Notify({Title="Config", Content="List refreshed.", Duration=1}) end})
local aLbl = ConfigTab:CreateParagraph({Title="Set as autoload", Content="Current autoload: none"})
ConfigTab:CreateButton({Name="Set as autoload", Callback=function() local t=aC(); p_call(function() if writefile then writefile(fName.."/Autoload.txt", t); aLbl:Set({Title="Set as autoload", Content="Current autoload: "..t}); Rayfield:Notify({Title="Config", Content=t.." set to Autoload.", Duration=2}) end end) end})
t_spawn(function() t_wait(1.5); refL(); p_call(function() if isfile and isfile(fName.."/Autoload.txt") then local a=readfile(fName.."/Autoload.txt"); if a and a~="" then aLbl:Set({Title="Set as autoload", Content="Current autoload: "..a}); lC(a) end end end) end)

Rayfield:Notify({Title="Loaded", Content="Master Edition v4 Loaded", Duration=5})
