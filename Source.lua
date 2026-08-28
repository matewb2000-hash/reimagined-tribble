-- TIFR AutoFarm + Troll Unlocker GUI
-- Executor: Synapse X / KRNL / Fluxus

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local lp = Players.LocalPlayer
local mouse = lp:GetMouse()

-- ============================================================
-- CORE STATE
-- ============================================================
local State = {
    AutoFarm     = false,
    AutoBoss     = false,
    AutoCollect  = false,
    SelectedTroll = nil,
    FarmDelay    = 0.1,
    WalkSpeed    = 16,
    JumpPower    = 50,
    Noclip       = false,
    InfHealth    = false,
}

-- ============================================================
-- TROLL LIST (ALL — including locked/badge/event/secret)
-- ============================================================
local TrollList = {
    -- Starter
    "Trollface", "Troll",
    -- Normal
    "Trollge", "LowQuality", "DemoTroll", "Imposter", "Sonic",
    "Shaggy", "Goofy", "Sanic", "Kermit", "TrollgeV2",
    "ElTrollio", "NegaTroll", "VoidTroll", "InfiniteTroll",
    -- Badge
    "DemoKnight", "UltraTrollge", "MegaTrollge", "GigaTrollge",
    "TeraTrollge", "OmegaTrollge", "AbsoluteTrollge",
    -- Event / Secret / Locked
    "TurboTrollge", "ShadowTrollge", "BloodTrollge", "VoidKnight",
    "CrimsonTroll", "GlitchTroll", "CorruptTrollge", "TrueOmega",
    "HyperTrollge", "NullTroll", "EternalTrollge", "DarkMatterTroll",
    "PhantomTroll", "ChaosTrollge", "DivineTrollge", "LiminalTroll",
    "SecretTroll_01", "SecretTroll_02", "DevTrollge",
}

-- ============================================================
-- GUI BUILDER
-- ============================================================
local function makeTween(obj, props, t)
    TweenService:Create(obj, TweenInfo.new(t or 0.2), props):Play()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TIFR_Onyx"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = (function()
    local ok, gc = pcall(function() return gethui() end)
    return ok and gc or lp.PlayerGui
end)()

-- Main Frame
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 480, 0, 560)
Main.Position = UDim2.new(0.5, -240, 0.5, -280)
Main.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = ScreenGui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

-- Accent bar
local Accent = Instance.new("Frame")
Accent.Size = UDim2.new(1, 0, 0, 3)
Accent.BackgroundColor3 = Color3.fromRGB(180, 0, 255)
Accent.BorderSizePixel = 0
Accent.Parent = Main

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.Position = UDim2.new(0, 0, 0, 3)
TitleBar.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚡ TIFR Onyx v67"
Title.TextColor3 = Color3.fromRGB(200, 100, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- Minimize button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -40, 0, 5)
MinBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
MinBtn.Text = "−"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 16
MinBtn.BorderSizePixel = 0
MinBtn.Parent = TitleBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

-- Drag
local dragging, dragStart, startPos
TitleBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = i.Position
        startPos = Main.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = i.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- Tab bar
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, 0, 0, 36)
TabBar.Position = UDim2.new(0, 0, 0, 43)
TabBar.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
TabBar.BorderSizePixel = 0
TabBar.Parent = Main
Instance.new("UIListLayout", TabBar).FillDirection = Enum.FillDirection.Horizontal

-- Content area
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, 0, 1, -82)
Content.Position = UDim2.new(0, 0, 0, 82)
Content.BackgroundTransparency = 1
Content.Parent = Main

-- ============================================================
-- TAB SYSTEM
-- ============================================================
local tabs = {}
local tabFrames = {}
local activeTab = nil

local function switchTab(name)
    for n, f in pairs(tabFrames) do
        f.Visible = (n == name)
    end
    for n, b in pairs(tabs) do
        b.BackgroundColor3 = (n == name)
            and Color3.fromRGB(180, 0, 255)
            or  Color3.fromRGB(25, 25, 35)
    end
    activeTab = name
end

local function makeTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.25, 0, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(200, 200, 210)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 12
    btn.Parent = TabBar

    local frame = Instance.new("ScrollingFrame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.ScrollBarThickness = 4
    frame.ScrollBarImageColor3 = Color3.fromRGB(180, 0, 255)
    frame.Visible = false
    frame.Parent = Content

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.Parent = frame
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.PaddingTop = UDim.new(0, 10)
    padding.Parent = frame

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        frame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)

    tabs[name] = btn
    tabFrames[name] = frame

    btn.MouseButton1Click:Connect(function() switchTab(name) end)
    return frame
end

-- ============================================================
-- UI HELPERS
-- ============================================================
local function makeLabel(parent, text, order)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 20)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(160, 100, 255)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 13
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.LayoutOrder = order or 0
    l.Parent = parent
end

local function makeToggle(parent, text, stateKey, order, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 34)
    row.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    row.BorderSizePixel = 0
    row.LayoutOrder = order or 0
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(220, 220, 230)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 44, 0, 22)
    toggle.Position = UDim2.new(1, -54, 0.5, -11)
    toggle.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    toggle.Text = ""
    toggle.BorderSizePixel = 0
    toggle.Parent = row
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = UDim2.new(0, 2, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(150, 150, 160)
    knob.BorderSizePixel = 0
    knob.Parent = toggle
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local function refresh()
        local on = State[stateKey]
        makeTween(toggle, {BackgroundColor3 = on
            and Color3.fromRGB(180, 0, 255)
            or  Color3.fromRGB(50, 50, 65)})
        makeTween(knob, {
            Position = on
                and UDim2.new(1, -20, 0.5, -9)
                or  UDim2.new(0, 2, 0.5, -9),
            BackgroundColor3 = on
                and Color3.fromRGB(255, 255, 255)
                or  Color3.fromRGB(150, 150, 160)
        })
    end
    refresh()

    toggle.MouseButton1Click:Connect(function()
        State[stateKey] = not State[stateKey]
        refresh()
        if callback then callback(State[stateKey]) end
    end)
end

local function makeButton(parent, text, order, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = Color3.fromRGB(140, 0, 220)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.LayoutOrder = order or 0
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(callback)

    btn.MouseEnter:Connect(function()
        makeTween(btn, {BackgroundColor3 = Color3.fromRGB(180, 0, 255)})
    end)
    btn.MouseLeave:Connect(function()
        makeTween(btn, {BackgroundColor3 = Color3.fromRGB(140, 0, 220)})
    end)
end

local function makeSlider(parent, text, stateKey, min, max, order)
    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(1, 0, 0, 52)
    wrap.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    wrap.BorderSizePixel = 0
    wrap.LayoutOrder = order or 0
    wrap.Parent = parent
    Instance.new("UICorner", wrap).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 0, 22)
    lbl.Position = UDim2.new(0, 10, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = text .. ": " .. tostring(State[stateKey])
    lbl.TextColor3 = Color3.fromRGB(200, 200, 210)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = wrap

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -20, 0, 6)
    track.Position = UDim2.new(0, 10, 0, 34)
    track.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    track.BorderSizePixel = 0
    track.Parent = wrap
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((State[stateKey] - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(180, 0, 255)
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local draggingSlider = false
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = true
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = false
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if draggingSlider and i.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = math.clamp(
                (i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + (max - min) * rel)
            State[stateKey] = val
            fill.Size = UDim2.new(rel, 0, 1, 0)
            lbl.Text = text .. ": " .. tostring(val)
        end
    end)
end

-- ============================================================
-- TROLL SELECTOR (scrollable list with equip button)
-- ============================================================
local function makeTrollSelector(parent)
    makeLabel(parent, "🧬 Select Troll (All — including locked)", 0)

    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, 0, 0, 30)
    searchBox.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    searchBox.BorderSizePixel = 0
    searchBox.PlaceholderText = "Search troll..."
    searchBox.Text = ""
    searchBox.TextColor3 = Color3.fromRGB(220, 220, 230)
    searchBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 120)
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = 13
    searchBox.LayoutOrder = 1
    searchBox.Parent = parent
    Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 6)

    local listFrame = Instance.new("ScrollingFrame")
    listFrame.Size = UDim2.new(1, 0, 0, 260)
    listFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    listFrame.BorderSizePixel = 0
    listFrame.ScrollBarThickness = 4
    listFrame.ScrollBarImageColor3 = Color3.fromRGB(180, 0, 255)
    listFrame.LayoutOrder = 2
    listFrame.Parent = parent
    Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 6)

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 4)
    listLayout.Parent = listFrame
    local lp2 = Instance.new("UIPadding")
    lp2.PaddingLeft = UDim.new(0, 6)
    lp2.PaddingRight = UDim.new(0, 6)
    lp2.PaddingTop = UDim.new(0, 6)
    lp2.Parent = listFrame

    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 12)
    end)

    local rowMap = {}

    local function buildList(filter)
        for _, c in ipairs(listFrame:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        for _, name in ipairs(TrollList) do
            if filter == "" or name:lower():find(filter:lower()) then
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 30)
                row.BackgroundColor3 = (State.SelectedTroll == name)
                    and Color3.fromRGB(80, 0, 160)
                    or  Color3.fromRGB(22, 22, 30)
                row.BorderSizePixel = 0
                row.Parent = listFrame
                Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)
                rowMap[name] = row

                local nameLbl = Instance.new("TextLabel")
                nameLbl.Size = UDim2.new(1, -80, 1, 0)
                nameLbl.Position = UDim2.new(0, 8, 0, 0)
                nameLbl.BackgroundTransparency = 1
                nameLbl.Text = name
                nameLbl.TextColor3 = Color3.fromRGB(220, 180, 255)
                nameLbl.Font = Enum.Font.Gotham
                nameLbl.TextSize = 12
                nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                nameLbl.Parent = row

                local equipBtn = Instance.new("TextButton")
                equipBtn.Size = UDim2.new(0, 60, 0, 22)
                equipBtn.Position = UDim2.new(1, -68, 0.5, -11)
                equipBtn.BackgroundColor3 = Color3.fromRGB(140, 0, 220)
                equipBtn.Text = "Equip"
                equipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                equipBtn.Font = Enum.Font.GothamSemibold
                equipBtn.TextSize = 11
                equipBtn.BorderSizePixel = 0
                equipBtn.Parent = row
                Instance.new("UICorner", equipBtn).CornerRadius = UDim.new(0, 4)

                equipBtn.MouseButton1Click:Connect(function()
                    State.SelectedTroll = name
                    buildList(searchBox.Text)
                    -- Attempt remote fire
                    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                        or ReplicatedStorage:FindFirstChild("Events")
                        or ReplicatedStorage
                    for _, v in ipairs(remotes:GetDescendants()) do
                        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                            local n = v.Name:lower()
                            if n:find("select") or n:find("troll") or n:find("char") then
                                pcall(function()
                                    if v:IsA("RemoteEvent") then
                                        v:FireServer(name)
                                    else
                                        v:InvokeServer(name)
                                    end
                                end)
                            end
                        end
                    end
                end)
            end
        end
    end

    buildList("")
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        buildList(searchBox.Text)
    end)
end

-- ============================================================
-- BUILD TABS
-- ============================================================
local farmTab   = makeTab("Farm")
local trollTab  = makeTab("Trolls")
local playerTab = makeTab("Player")
local miscTab   = makeTab("Misc")

-- ---------- FARM TAB ----------
makeLabel(farmTab, "⚔️ AutoFarm", 0)
makeToggle(farmTab, "AutoFarm (Stabs)", "AutoFarm", 1, nil)
makeToggle(farmTab, "AutoBoss Kill", "AutoBoss", 2, nil)
makeToggle(farmTab, "AutoCollect (Gems/Trollbucks)", "AutoCollect", 3, nil)
makeSlider(farmTab, "Farm Delay (ms)", "FarmDelay", 0, 1, 4)

makeButton(farmTab, "Teleport to Nearest Enemy", 5, function()
    local char = lp.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local closest, dist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Character then
            local r = p.Character:FindFirstChild("HumanoidRootPart")
            if r then
                local d = (r.Position - hrp.Position).Magnitude
                if d < dist then dist = d; closest = r end
            end
        end
    end
    if closest then hrp.CFrame = closest.CFrame + Vector3.new(4, 0, 0) end
end)

makeButton(farmTab, "Teleport to Boss", 6, function()
    local char = lp.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v.Name:lower():find("boss") then
            local r = v:FindFirstChild("HumanoidRootPart")
            if r then hrp.CFrame = r.CFrame + Vector3.new(4, 0, 0) return end
        end
    end
end)

-- ---------- TROLLS TAB ----------
makeTrollSelector(trollTab)

-- ---------- PLAYER TAB ----------
makeLabel(playerTab, "🏃 Player Mods", 0)
makeSlider(playerTab, "WalkSpeed", "WalkSpeed", 16, 250, 1)
makeSlider(playerTab, "JumpPower", "JumpPower", 50, 300, 2)
makeToggle(playerTab, "Infinite Health", "InfHealth", 3, nil)
makeToggle(playerTab, "Noclip", "Noclip", 4, nil)

makeButton(playerTab, "Apply Speed & Jump", 5, function()
    local char = lp.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = State.WalkSpeed
        hum.JumpPower = State.JumpPower
    end
end)

makeButton(playerTab, "Reset Character", 6, function()
    local char = lp.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
    end
end)

-- ---------- MISC TAB ----------
makeLabel(miscTab, "🎲 Misc", 0)

makeButton(miscTab, "Collect All Gems in Map", 1, function()
    local char = lp.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local n = v.Name:lower()
            if n:find("gem") or n:find("coin") or n:find("trollbuck") then
                hrp.CFrame = CFrame.new(v.Position)
                task.wait(0.05)
            end
        end
    end
end)

makeButton(miscTab, "Anti AFK", 2, function()
    local VirtualUser = game:GetService("VirtualUser")
    lp.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end)

makeButton(miscTab, "Rejoin Server", 3, function()
    local TS = game:GetService("TeleportService")
    TS:Teleport(game.PlaceId, lp)
end)

-- Minimize logic
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    makeTween(Main, {
        Size = minimized
            and UDim2.new(0, 480, 0, 46)
            or  UDim2.new(0, 480, 0, 560)
    }, 0.25)
    MinBtn.Text = minimized and "+" or "−"
end)

switchTab("Farm")

-- ============================================================
-- RUNTIME LOOPS
-- ============================================================

-- AutoFarm loop
RunService.Heartbeat:Connect(function()
    if not State.AutoFarm then return end
    local char = lp.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end

    local closest, dist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Character then
            local r = p.Character:FindFirstChild("HumanoidRootPart")
            local h = p.Character:FindFirstChildOfClass("Humanoid")
            if r and h and h.Health > 0 then
                local d = (r.Position - hrp.Position).Magnitude
                if d < dist then dist = d; closest = r end
            end
        end
    end

    if closest then
        hrp.CFrame = CFrame.new(
            closest.Position + Vector3.new(math.random(-3,3), 0, math.random(-3,3))
        )
        -- Fire attack remotes
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            or ReplicatedStorage:FindFirstChild("Events")
            or ReplicatedStorage
        for _, v in ipairs(remotes:GetDescendants()) do
            if v:IsA("RemoteEvent") then
                local n = v.Name:lower()
                if n:find("attack") or n:find("hit") or n:find("stab") then
                    pcall(function() v:FireServer(closest.Parent) end)
                end
            end
        end
    end
end)

-- AutoBoss loop
RunService.Heartbeat:Connect(function()
    if not State.AutoBoss then return end
    local char = lp.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v.Name:lower():find("boss") then
            local r = v:FindFirstChild("HumanoidRootPart")
            local h = v:FindFirstChildOfClass("Humanoid")
            if r and h and h.Health > 0 then
                hrp.CFrame = CFrame.new(r.Position + Vector3.new(3, 0, 0))
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                    or ReplicatedStorage:FindFirstChild("Events")
                    or ReplicatedStorage
                for _, rv in ipairs(remotes:GetDescendants()) do
                    if rv:IsA("RemoteEvent") then
                        local n = rv.Name:lower()
                        if n:find("attack") or n:find("hit") then
                            pcall(function() rv:FireServer(v) end)
                        end
                    end
                end
            end
        end
    end
end)

-- Noclip loop
RunService.Stepped:Connect(function()
    if not State.Noclip then return end
    local char = lp.Character
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            p.CanCollide = false
        end
    end
end)

-- InfHealth loop
RunService.Heartbeat:Connect(function()
    if not State.InfHealth then return end
    local char = lp.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.Health = hum.MaxHealth end
end)

-- AutoCollect loop
RunService.Heartbeat:Connect(function()
    if not State.AutoCollect then return end
    local char = lp.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local n = v.Name:lower()
            if n:find("gem") or n:find("trollbuck") or n:find("pickup") then
                if (v.Position - hrp.Position).Magnitude < 60 then
                    hrp.CFrame = CFrame.new(v.Position)
                end
            end
        end
    end
end)

print("[TIFR Onyx v67] loaded. 6767 gng.")
