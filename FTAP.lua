-- ==================== ホワイトリスト設定 ====================
local AllowedUsers = {
    "sekaisaikyoua_a", "Tjrvovh30", "bananasabu85", "yuttan1029", "moro101971", 
    "apmp2286", "attj636", "pokotin0413", "akannde12121", "wdsauj1" -- wdsauj1を追加しました
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

-- ==================== リアルタイム同期用オブジェクト ====================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedFolder = ReplicatedStorage:FindFirstChild("AdminSharedFolder") or Instance.new("Folder", ReplicatedStorage)
SharedFolder.Name = "AdminSharedFolder"
local MessageValue = SharedFolder:FindFirstChild("GlobalMsg") or Instance.new("StringValue", SharedFolder)
MessageValue.Name = "GlobalMsg"

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

if isAdmin then
    local AdminNotifTab = Window:MakeTab({ Name = "管理者通知", Icon = "rbxassetid://4483345998" })
    AdminNotifTab:AddLabel("--- リアルタイムログ ---")
    MessageValue.Changed:Connect(function(newVal)
        if newVal ~= "" then
            AdminNotifTab:AddLabel(newVal)
            OrionLib:MakeNotification({Name = "新着メッセージ", Content = newVal, Time = 5})
        end
    end)
end

-- ==================== 1. anti タブ (高速化修正) ====================
local AntiTab = Window:MakeTab({ Name = " anti", Icon = "shield" })

AntiTab:AddToggle({
    Name = "Anti Network",
    Callback = function(v)
        if _G.AN then _G.AN:Disconnect() end
        if v then
            _G.AN = RunService.Heartbeat:Connect(function()
                local myToys = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
                local burger = myToys and myToys:FindFirstChild("FoodHamburger")
                if not burger then
                    SpawnRemote:InvokeServer("FoodHamburger", CFrame.new(-153.3, -5.6, 62.6), Vector3.new(0, 92.6, 0))
                else
                    local hp = burger:FindFirstChild("HoldPart")
                    if hp then
                        pcall(function()
                            hp.HoldItemRemoteFunction:InvokeServer(burger, LocalPlayer.Character)
                            hp.DropItemRemoteFunction:InvokeServer(burger, CFrame.new(-160.7, -8.6, 62.9), Vector3.new(0, 92.6, 0))
                        end)
                    end
                end
            end)
        end
    end
})

AntiTab:AddToggle({
    Name = "Anti KilI (Ultra Fast)", 
    Callback = function(v) 
        if _G.AK then _G.AK:Disconnect() end 
        if v then 
            _G.AK = RunService.RenderStepped:Connect(function() 
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then 
                    RagdollRemote:FireServer(hrp, 999999) 
                end 
            end) 
        end 
    end 
})

AntiTab:AddToggle({ Name = "Anti Grab", Callback = function(v) if _G.AG then _G.AG:Disconnect() end if v then _G.AG = RunService.Heartbeat:Connect(function() if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head"):FindFirstChild("PartOwner") then Struggle:FireServer(LocalPlayer) end end) end end })
AntiTab:AddToggle({ Name = "Anti Blobman", Callback = function(on) _G.AB = on Workspace.DescendantAdded:Connect(function(t) if t.Name == "CreatureBlobman" and _G.AB then pcall(function() t.LeftDetector:Destroy() t.RightDetector:Destroy() end) end end) end })
AntiTab:AddToggle({ Name = "Anti Explosion", Callback = function(on) _G.AE = on Workspace.ChildAdded:Connect(function(m) local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart") if m.Name == "Part" and _G.AE and hrp and (m.Position - hrp.Position).Magnitude <= 20 then hrp.Anchored = true; task.wait(0.1); hrp.Anchored = false end end) end })
AntiTab:AddToggle({ Name = "Anti Void", Callback = function(v) if _G.AV then _G.AV:Disconnect() end if v then _G.AV = RunService.Heartbeat:Connect(function() local p = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart if p and p.Position.Y < -50 then LocalPlayer.Character:SetPrimaryPartCFrame(CFrame.new(p.Position.X, 50, p.Position.Z)) end end) end end })

-- ==================== 2. Attack タブ ====================
local AttackTab = Window:MakeTab({ Name = "Attack", Icon = "swords" })
local targetPlayer = nil
local attackMode = "Blobman kill"
local attackEnabled = false

AttackTab:AddDropdown({ Name = "Mode", Options = {"Blobman kill", "Blobman kick＋spam"}, Default = "Blobman kill", Callback = function(v) attackMode = v end })
AttackTab:AddToggle({
    Name = "Auto Attack Loop",
    Callback = function(v)
        attackEnabled = v
        task.spawn(function()
            while attackEnabled do
                RunService.Heartbeat:Wait()
                local target = targetPlayer
                if target and target.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local tRoot = target.Character.HumanoidRootPart
                    local lRoot = LocalPlayer.Character.HumanoidRootPart
                    local blob = (function() local h = LocalPlayer.Character:FindFirstChildOfClass("Humanoid") if h and h.SeatPart and h.SeatPart.Parent.Name == "CreatureBlobman" then return h.SeatPart.Parent end return nil end)()
                    if not blob then
                        SpawnRemote:InvokeServer("CreatureBlobman", lRoot.CFrame, Vector3.new(0, 127, 0))
                        task.wait(0.5)
                        local folder = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys") or Workspace
                        for _, b in pairs(folder:GetChildren()) do if b.Name == "CreatureBlobman" then b.VehicleSeat:Sit(LocalPlayer.Character.Humanoid) blob = b break end end
                    end
                    if blob and tRoot then
                        if attackMode == "Blobman kill" then
                            lRoot.CFrame = tRoot.CFrame
                            pcall(function() target.Character.Humanoid.BreakJointsOnDeath = false target.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Dead) end)
                            local d = blob:FindFirstChild("LeftDetector") or blob:FindFirstChild("RightDetector")
                            for i=1, 5 do blob.BlobmanSeatAndOwnerScript.CreatureGrab:FireServer(d, tRoot, d:FindFirstChildWhichIsA("Weld")) task.wait(0.02) blob.BlobmanSeatAndOwnerScript.CreatureRelease:FireServer(d:FindFirstChildWhichIsA("Weld")) task.wait(0.02) end
                        end
                    end
                end
            end
        end)
    end
})

-- ==================== 3. toymod タブ ====================
local ToyModTab = Window:MakeTab({ Name = "toymod", Icon = "rbxassetid://4483345998" })
local toyLoopEnabled = false

ToyModTab:AddDropdown({
    Name = "Select Target",
    Options = (function() local n = {} for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(n, p.DisplayName) end end return n end)(),
    Callback = function(v) for _, p in pairs(Players:GetPlayers()) do if p.DisplayName == v then targetPlayer = p end end end
})

ToyModTab:AddToggle({
    Name = "Missile Fix & Campfire TP Loop",
    Callback = function(v)
        toyLoopEnabled = v
        if v then
            task.spawn(function()
                while toyLoopEnabled do
                    RunService.Heartbeat:Wait()
                    local target = targetPlayer
                    if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                        local tRoot = target.Character.HumanoidRootPart
                        local folder = Workspace:FindFirstChild(LocalPlayer.Name .. "SpawnedInToys")
                        local missileCF = tRoot.CFrame * CFrame.new(2, -3, 0) * CFrame.Angles(math.rad(-45), math.rad(45), 0)

                        local missile = folder and folder:FindFirstChild("BombMissile")
                        if not missile then
                            SpawnRemote:InvokeServer("BombMissile", missileCF, Vector3.new(0, 90, 0))
                        else
                            local mBody = missile:FindFirstChild("Body") or missile:FindFirstChildWhichIsA("BasePart", true)
                            if mBody then mBody.CFrame = missileCF end
                        end

                        local campfire = folder and folder:FindFirstChild("Campfire")
                        if campfire then
                            for _, part in pairs(campfire:GetDescendants()) do
                                if part:IsA("BasePart") then
                                    part.CFrame = missileCF
                                    GE.SetNetworkOwner:FireServer(part, part.CFrame)
                                end
                            end
                        else
                            SpawnRemote:InvokeServer("Campfire", missileCF, Vector3.new(0, -137.667, 0))
                        end
                    end
                end
            end)
        end
    end
})

OrionLib:Init()
