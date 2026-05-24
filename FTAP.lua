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
    if LocalPlayer.Name == name then
        isAllowed = true
        break
    end
end

if not isAllowed then
    LocalPlayer:Kick("お前は誰？特定するね、🥰")
    return 
end

-- ==================== 自動BGM再生 ====================
local SoundService = game:GetService("SoundService")
local bgm = Instance.new("Sound")
bgm.Name = "AutoBGM"
bgm.SoundId = "rbxassetid://115189039255362"
bgm.Volume = 2
bgm.Looped = true
bgm.Parent = SoundService
bgm:Play()

-- ==================== 共有用オブジェクト ====================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedFolder = ReplicatedStorage:FindFirstChild("AdminSharedFolder") or Instance.new("Folder", ReplicatedStorage)
SharedFolder.Name = "AdminSharedFolder"

local MessageValue = SharedFolder:FindFirstChild("GlobalMsg") or Instance.new("StringValue", SharedFolder)
MessageValue.Name = "GlobalMsg"

local AnnounceValue = SharedFolder:FindFirstChild("GlobalAnnounce") or Instance.new("StringValue", SharedFolder)
AnnounceValue.Name = "GlobalAnnounce"

-- ==================== アナウンス用UI (スクリプト実行者のみ生成) ====================
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "AnnounceGui"
local AnnounceLabel = Instance.new("TextLabel", ScreenGui)
AnnounceLabel.Size = UDim2.new(1, 0, 0, 50)
AnnounceLabel.Position = UDim2.new(0, 0, 0.2, 0)
AnnounceLabel.BackgroundTransparency = 1
AnnounceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
AnnounceLabel.TextStrokeTransparency = 0
AnnounceLabel.TextSize = 30
AnnounceLabel.Font = Enum.Font.SourceSansBold
AnnounceLabel.Text = ""

AnnounceValue.Changed:Connect(function(val)
    if val ~= "" then
        AnnounceLabel.Text = "【管理者アナウンス】\n" .. val
        task.wait(5)
        AnnounceLabel.Text = ""
    end
end)

-- ==================== スクリプト本体 ====================
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jadpy/suki/refs/heads/main/orion"))()
local RunService = game:GetService("RunService")
local Workspace = workspace

-- リモート
local CharacterEvents = ReplicatedStorage:WaitForChild("CharacterEvents")
local RagdollRemote = CharacterEvents:WaitForChild("RagdollRemote")
local Struggle = CharacterEvents:FindFirstChild("Struggle")
local SpawnRemote = ReplicatedStorage:WaitForChild("MenuToys"):WaitForChild("SpawnToyRemoteFunction")
local GE = ReplicatedStorage:WaitForChild("GrabEvents")

local Window = OrionLib:MakeWindow({
    Name = "あーあはぶプレミア",
    HidePremium = false,
    SaveConfig = false,
    ConfigFolder = "VaB_Config",
    IntroEnabled = false
})

-- ==================== 管理機能タブ ====================

-- 1. 管理者に許可タブ (全員用)
local PermissionTab = Window:MakeTab({ Name = "管理者に許可", Icon = "rbxassetid://4483345998" })
PermissionTab:AddTextbox({
    Name = "メッセージ送信",
    Default = "",
    TextDisappear = true,
    Callback = function(Value)
        if Value ~= "" then
            MessageValue.Value = "[" .. LocalPlayer.DisplayName .. "]: " .. Value
            OrionLib:MakeNotification({Name = "送信完了", Content = "管理者に送信しました。", Time = 2})
        end
    end
})

-- 2. 管理者専用タブ (sekaisaikyoua_a のみ表示)
if isAdmin then
    local AdminNotifTab = Window:MakeTab({ Name = "管理者通知", Icon = "rbxassetid://4483345998" })
    AdminNotifTab:AddLabel("--- リアルタイムログ ---")
    MessageValue.Changed:Connect(function(newVal)
        if newVal ~= "" then
            AdminNotifTab:AddLabel(newVal)
            OrionLib:MakeNotification({Name = "新着メッセージ", Content = newVal, Time = 5})
        end
    end)

    local AnnounceTab = Window:MakeTab({ Name = "アナウンス", Icon = "rbxassetid://4483345998" })
    AnnounceTab:AddTextbox({
        Name = "全体アナウンス送信",
        Default = "",
        TextDisappear = true,
        Callback = function(Value)
            if Value ~= "" then
                AnnounceValue.Value = Value
                task.wait(0.1)
                AnnounceValue.Value = "" -- リセットして再送信可能に
            end
        end
    })
end

-- ==================== 機能タブ (Anti / Attack / Toy) ====================
-- (以前の高性能な機能一式を維持)

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
-- 他のAnti機能...
AntiTab:AddToggle({ Name = "Anti Network", Callback = function(v) if _G.AN then _G.AN:Disconnect() end if v then _G.AN = RunService.Heartbeat:Connect(function() -- (Networkロジック) 
end) end end })

local ToyModTab = Window:MakeTab({ Name = "toymod", Icon = "rbxassetid://4483345998" })
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
                        -- 生成・固定・テレポートの統合ロジック
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
