-- ==================== ホワイトリスト設定 ====================
local AllowedUsers = {
    "sekaisaikyoua_a", "Tjrvovh30", "bananasabu85", "yuttan1029", "moro101971", 
    "apmp2286", "attj636", "pokotin0413", "akannde12121"
}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local isAdmin = (LocalPlayer.Name == "sekaisaikyoua_a")
local isAllowed = false

for _, name in ipairs(AllowedUsers) do
    if LocalPlayer.Name == name then isAllowed = true break end
end

if not isAllowed then
    LocalPlayer:Kick("お前は誰？特定するね、🥰")
    return 
end

-- ==================== ビジュアルUI設定 (RGB & Watermark) ====================
local RunService = game:GetService("RunService")
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "VisualOverlays"

-- 1. 画面右上の透かし (Watermark)
local Watermark = Instance.new("TextLabel", ScreenGui)
Watermark.Size = UDim2.new(0, 200, 0, 30)
Watermark.Position = UDim2.new(1, -210, 0, 10)
Watermark.BackgroundTransparency = 0.5
Watermark.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Watermark.TextColor3 = Color3.fromRGB(255, 255, 255)
Watermark.TextSize = 14
Watermark.Font = Enum.Font.Code
Watermark.Text = "あーあはぶプレミア | " .. LocalPlayer.Name
local uiCorner = Instance.new("UICorner", Watermark)

-- 2. アナウンス用RGBラベル
local AnnounceLabel = Instance.new("TextLabel", ScreenGui)
AnnounceLabel.Size = UDim2.new(1, 0, 0, 80)
AnnounceLabel.Position = UDim2.new(0, 0, 0.15, 0)
AnnounceLabel.BackgroundTransparency = 1
AnnounceLabel.TextSize = 45
AnnounceLabel.Font = Enum.Font.GothamBold
AnnounceLabel.Text = ""
AnnounceLabel.TextStrokeTransparency = 0.5

-- RGBアニメーション
task.spawn(function()
    while true do
        local hue = tick() % 5 / 5
        local color = Color3.fromHSV(hue, 1, 1)
        AnnounceLabel.TextColor3 = color
        Watermark.BorderColor3 = color
        RunService.RenderStepped:Wait()
    end
end)

-- ==================== 共有オブジェクト ====================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedFolder = ReplicatedStorage:FindFirstChild("AdminSharedFolder") or Instance.new("Folder", ReplicatedStorage)
SharedFolder.Name = "AdminSharedFolder"
local MessageValue = SharedFolder:FindFirstChild("GlobalMsg") or Instance.new("StringValue", SharedFolder)
local AnnounceValue = SharedFolder:FindFirstChild("GlobalAnnounce") or Instance.new("StringValue", SharedFolder)

AnnounceValue.Changed:Connect(function(val)
    if val ~= "" then
        AnnounceLabel.Text = "【管理者通知】\n" .. val
        task.wait(7)
        AnnounceLabel.Text = ""
    end
end)

-- ==================== スクリプト本体 (Orion HUB) ====================
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jadpy/suki/refs/heads/main/orion"))()
local Workspace = workspace
local CharacterEvents = ReplicatedStorage:WaitForChild("CharacterEvents")
local RagdollRemote = CharacterEvents:WaitForChild("RagdollRemote")
local SpawnRemote = ReplicatedStorage:WaitForChild("MenuToys"):WaitForChild("SpawnToyRemoteFunction")
local GE = ReplicatedStorage:WaitForChild("GrabEvents")

local Window = OrionLib:MakeWindow({
    Name = "あーあはぶプレミア",
    HidePremium = false,
    SaveConfig = false,
    IntroEnabled = true,
    IntroText = "Welcome to あーあはぶプレミア"
})

-- 自動BGM再生
local SoundService = game:GetService("SoundService")
local bgm = Instance.new("Sound")
bgm.SoundId = "rbxassetid://115189039255362"
bgm.Volume = 1.5
bgm.Looped = true
bgm.Parent = SoundService
bgm:Play()

-- ==================== 管理者タブ ====================
local PermissionTab = Window:MakeTab({ Name = "管理者に許可", Icon = "rbxassetid://4483345998" })
PermissionTab:AddTextbox({
    Name = "メッセージを管理者に送る",
    Default = "",
    TextDisappear = true,
    Callback = function(Value)
        if Value ~= "" then
            MessageValue.Value = "[" .. LocalPlayer.DisplayName .. "]: " .. Value
        end
    end
})

if isAdmin then
    local AdminNotifTab = Window:MakeTab({ Name = "管理者通知", Icon = "shield" })
    MessageValue.Changed:Connect(function(newVal)
        if newVal ~= "" then AdminNotifTab:AddLabel(newVal) end
    end)

    local AnnounceTab = Window:MakeTab({ Name = "アナウンス", Icon = "megaphone" })
    AnnounceTab:AddTextbox({
        Name = "全体に虹色アナウンスを流す",
        Default = "",
        TextDisappear = true,
        Callback = function(Value)
            if Value ~= "" then
                AnnounceValue.Value = Value
                task.wait(0.1)
                AnnounceValue.Value = ""
            end
        end
    })
end

-- ==================== メイン機能 (Anti/Attack/Toy) ====================
local AntiTab = Window:MakeTab({ Name = " anti", Icon = "shield" })
AntiTab:AddToggle({
    Name = "Anti KilI (Ultra Fast)", 
    Callback = function(v) 
        if _G.AK then _G.AK:Disconnect() end 
        if v then 
            _G.AK = RunService.RenderStepped:Connect(function() 
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then RagdollRemote:FireServer(hrp, 999999) end 
            end) 
        end 
    end 
})

local ToyModTab = Window:MakeTab({ Name = "toymod", Icon = "hammer" })
local targetPlayer = nil
ToyModTab:AddDropdown({
    Name = "Select Target",
    Options = (function() local n = {} for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(n, p.DisplayName) end end return n end)(),
    Callback = function(v) for _, p in pairs(Players:GetPlayers()) do if p.DisplayName == v then targetPlayer = p end end end
})

ToyModTab:AddToggle({
    Name = "Missile Fix & Campfire TP Loop",
    Callback = function(v)
        _G.ToyLoop = v
        task.spawn(function()
            while _G.ToyLoop do
                RunService.Heartbeat:Wait()
                if targetPlayer and targetPlayer.Character then
                    local tRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if tRoot then
                        local folder = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
                        local missileCF = tRoot.CFrame * CFrame.new(2, -3, 0) * CFrame.Angles(math.rad(-45), math.rad(45), 0)
                        pcall(function()
                            local m = folder:FindFirstChild("BombMissile") or SpawnRemote:InvokeServer("BombMissile", missileCF, Vector3.new(0,90,0))
                            if m then (m:FindFirstChild("Body") or m.PrimaryPart).CFrame = missileCF end
                            local c = folder:FindFirstChild("Campfire") or SpawnRemote:InvokeServer("Campfire", missileCF, Vector3.new(0,-137,0))
                            if c then for _,p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CFrame = missileCF; GE.SetNetworkOwner:FireServer(p, p.CFrame) end end end
                        end)
                    end
                end
            end
        end)
    end
})

OrionLib:Init()
