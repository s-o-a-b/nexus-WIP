--[[
`7MN.   `7MF' .g8""8q.  MMP""MM""YMM `7MM"""YMM         
  MMN.    M .dP'    `YM.P'   MM   `7   MM    `7         
  M YMb   M dM'      `MM     MM        MM   d        
  M  `MN. M MM        MM     MM        MMmmMM        
  M   `MM.M MM.      ,MP     MM        MM   Y  ,        
  M     YMM `Mb.    ,dP'     MM        MM     ,M     
.JML.    YM   `"bmmd"'     .JMML.    .JMMmmmmMMM     
                                                        
Please be aware that this code is outdated and may not represent the best coding practices.
It was written before I had access to a decompiler, so it's a simple script not intended for educational purposes.
]]--

local HttpService = Services.HttpService
local TeleportService = Services.TeleportService
local Players = Services.Players
local RunService = Services.RunService
local Workspace = Services.Workspace
local UserInputService = Services.UserInputService
local GetPlayerDataRemote = Services.ReplicatedStorage:FindFirstChild("GetPlayerData", true)
local LocalPlayer = Players.LocalPlayer
local highlights = {}
local Murderer, Sheriff = nil, nil
local confirmedwalk, confirmedjump = false, false
local infJumpConnection

local function FindMap()
    for _, v in pairs(workspace:GetChildren()) do
        if v:FindFirstChild("CoinContainer") then
            return v.CoinContainer
        elseif v:FindFirstChild("Map") then
            if pcall(function() local view = v.Map.CoinContainer end) then
                return v.Map.CoinContainer
            end
        end
    end
    return nil
end

local function IsAlive(Player, roles)
    local role = roles and roles[Player.Name]
    return role and not role.Killed and not role.Dead
end

local function updatePlayerData()
    if GetPlayerDataRemote then
        return GetPlayerDataRemote:InvokeServer()
    else
        warn("GetPlayerData remote not found!")
        return nil
    end
end

local function CreateHighlight()
    for _, v in pairs(Players:GetChildren()) do
        if v ~= LocalPlayer then 
            pcall(function()
                if v.Character and not v.Character:FindFirstChild("Highlight") then
                    Instance.new("Highlight", v.Character)  
                end
            end)
        end
    end
end

local function UpdateHighlights()
    for _, v in pairs(Players:GetChildren()) do
        local highlight = v.Character and v.Character:FindFirstChild("Highlight")
        if highlight then
            if IsAlive(v, roles) then
                local role = roles[v.Name]
                if role then
                    if role.Role == "Murderer" then
                        highlight.FillColor = Color3.fromRGB(225, 0, 0)
                    elseif role.Role == 'Sheriff' then
                        highlight.FillColor = Color3.fromRGB(0, 0, 225)
                    elseif role.Role == 'Hero' then
                        highlight.FillColor = Color3.fromRGB(0, 0, 225)
                    else
                        highlight.FillColor = Color3.fromRGB(76, 215, 134)
                    end
                else
                    highlight.FillColor = Color3.fromRGB(76, 215, 134)
                end
            else
                highlight.FillColor = Color3.fromRGB(255, 255, 255)
            end
        end
    end
end

local function DestroyHighlight()
    for i,v in next, Players:GetPlayers() do
        if v.Name ~= Players.LocalPlayer.Name then
            pcall(function()
                v.Character.Highlight:Destroy()
            end)
        end 
    end  
end 

local function GetMurderer()
    for _, player in ipairs(game.Players:GetPlayers()) do 
        if player.Backpack:FindFirstChild("Knife") or (player.Character and player.Character:FindFirstChild("Knife")) then
            return player.Name
        end
    end   
    return nil 
end

local function GetSheriff()
    for _, player in ipairs(game.Players:GetPlayers()) do 
        if player.Backpack:FindFirstChild("Gun") or (player.Character and player.Character:FindFirstChild("Gun")) then
            return player.Name
        end
    end   
    return nil 
end

local function setWalkSpeed(walkSpeed)
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = walkSpeed
    end
end
 
local function setJumpPower(jumpPower)
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.JumpPower = jumpPower
    end
end
 
local function tween_teleport(TargetFrame)
    local player = game.Players.LocalPlayer
    local character = player.Character
    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
        
    if humanoidRootPart then
        local distance = (humanoidRootPart.Position - TargetFrame.p).Magnitude
        local tweenInfo = TweenInfo.new(distance / 70, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
             
        local move = Services.TweenService:Create(humanoidRootPart, tweenInfo, {CFrame = TargetFrame})
        move:Play()
        move.Completed:Wait()
    end
end

local Fluent = loadstring(game:HttpGet("https://github.com/s-o-a-b/nexus/releases/download/aYXKCuZPip/aYXKCuZPip.txt"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/s-o-a-b/nexus/main/assets/SaveManager"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/s-o-a-b/nexus/main/assets/InterfaceManager"))()

local Options = Fluent.Options
SaveManager:SetLibrary(Fluent)

local Window = Fluent:CreateWindow({
    Title = "nexus ", "",
    SubTitle = "",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
})

local Tabs = {
    Main = Window:AddTab({
        Title = "Main",
        Icon = "rbxassetid://10734884548"
    }),
    Sheriff = Window:AddTab({
        Title = "Sheriff",
        Icon = "rbxassetid://10747372702"
    }),
    Murderer = Window:AddTab({
        Title = "Murderer",
        Icon = "rbxassetid://10747372992"
    }),
    Power = Window:AddTab({
        Title = "Powers",
        Icon = "rbxassetid://10723396107"
    }),
    Player = Window:AddTab({
        Title = "Player",
        Icon = "rbxassetid://10747373176"
    }),
    Emotes = Window:AddTab({
        Title = "Emotes",
        Icon = "rbxassetid://4335480896"
    }),
    Server = Window:AddTab({
        Title = "Server",
        Icon = "rbxassetid://10734949856"
    }),
    Settings = Window:AddTab({
        Title = "Settings",
        Icon = "settings"
    }),
}

local Toggle = Tabs.Main:AddToggle("AutoFarm", {
    Title = "Auto Farm",
    Default = false,
    Callback = function(value)
        if value then
            repeat task.wait() 
                local success, result = pcall(function() 

                    local Map = FindMap()
                    if Map then
                        if LocalPlayer.PlayerGui.MainGUI.Game.CoinBags.Container.Coin.Full.Visible and LocalPlayer.PlayerGui.MainGUI.Game.CoinBags.Container.Egg.Full.Visible then
                            game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-108, 138, -11)
                        elseif IsAlive(LocalPlayer, roles) then
                            local minimum_distance = math.huge
                            local minimum_object = nil
                            for _, v in pairs(Map:GetChildren()) do
                                if v.Name == 'Coin_Server' then
                                    local partPosition
                                    if v:FindFirstChild("CoinVisual") and v.CoinVisual:IsA("BasePart") then
                                        partPosition = v.CoinVisual.Position
                                    else  
                                        partPosition = v.Position
                                    end
                                
                                    local distance = (LocalPlayer.Character:FindFirstChild("HumanoidRootPart").Position - partPosition).Magnitude
                                    if distance < minimum_distance then
                                        minimum_distance = distance
                                        minimum_object = v
                                    end
                                end
                            end
                            if minimum_object then
                                local partPosition
                                if minimum_object:FindFirstChild("CoinVisual") and minimum_object.CoinVisual:IsA("BasePart") then
                                    partPosition = minimum_object.CoinVisual.Position
                                else
                                    partPosition = minimum_object.Position
                                end
                            
                                tween_teleport(CFrame.new(partPosition))
                                for rotation = 0, 10, 1 do
                                    LocalPlayer.Character:SetPrimaryPartCFrame(LocalPlayer.Character.PrimaryPart.CFrame * CFrame.Angles(0, math.rad(rotation), 0))
                                    wait(0.02)
                                end
                                minimum_object.Name = 'False_Coin'
                                repeat
                                    wait()
                                until minimum_object.Name ~= 'Coin_Server'
                                wait(1)
                            end
                        end
                    end
                end)
            until not Options.AutoFarm.Value
        end
    end
})

local Toggle = Tabs.Main:AddToggle("CoinChams", {
    Title = "Coin Chams",
    Default = false,
    Callback = function(value)
        if value then 
            repeat task.wait()
                local Map = FindMap()

                if Map then
                    for _, v in pairs(Map:GetChildren()) do
                        if v.Name == 'Coin_Server' and not highlights[v] then
                            local esp = Instance.new("Highlight")
                            esp.Name = "CoinESP"
                            esp.FillTransparency = 0.5
                            esp.FillColor = Color3.new(94/255, 1, 255/255)
                            esp.OutlineColor = Color3.new(94/255, 1, 255/255)
                            esp.OutlineTransparency = 0
                            esp.Parent = v.Parent
                            highlights[v] = esp  
                        end
                    end
                end 
            until not Options.CoinChams.Value
            for _, highlight in pairs(highlights) do
                highlight:Destroy()
            end         
        end
    end
})

local Toggle = Tabs.Main:AddToggle("PlayerESP", {
    Title = "Player Chams",
    Default = false,
    Callback = function(value)
        if value then 
        repeat task.wait()
            CreateHighlight() 
            UpdateHighlights()
        until not Options.PlayerESP.Value
        DestroyHighlight()
        end 
    end
})  

local Toggle = Tabs.Main:AddToggle("GrabGun", {
    Title = "Automatically Grab Gun",
    Default = false,
    Callback = function(value)
        if value then 
            repeat task.wait()
                local GunDrop = Services.Workspace:FindFirstChild("GunDrop")
                if Murderer ~= nil then 
                    if GunDrop and Murderer ~= LocalPlayer.Name and IsAlive(LocalPlayer, roles) then
                        local savedPosition = LocalPlayer.Character.HumanoidRootPart.CFrame
                        wait(.5)
                        LocalPlayer.Character.HumanoidRootPart.CFrame = GunDrop.CFrame
                        LocalPlayer.Character.Humanoid.Jump = true
                        wait(.2)
                        LocalPlayer.Character.HumanoidRootPart.CFrame = savedPosition
                        wait(1)
                    end 
                end  
            until not Options.GrabGun.Value 
        end
    end
})

local Toggle = Tabs.Main:AddToggle("GunCham", {
    Title = "Gun Dropped ESP",
    Default = false,
    Callback = function(value)
        if value then 
            local esp 
            repeat task.wait()
                local gunDrop = Services.Workspace:FindFirstChild("GunDrop")

                if gunDrop then
                    esp = gunDrop:FindFirstChild("GunESP")
                    if not esp then
                        esp = Instance.new("Highlight")
                        esp.Name = "GunESP"
                        esp.FillTransparency = 0.5
                        esp.FillColor = Color3.new(94, 1, 255)
                        esp.OutlineColor = Color3.new(94, 1, 255)
                        esp.OutlineTransparency = 0
                        esp.Parent = gunDrop
                    end
                end
            until not Options.GunCham.Value
            if esp then 
                esp:Destroy() 
            end
        end
    end
})

local Toggle = Tabs.Murderer:AddToggle("KillAll", {
    Title = "Kill Aura",
    Default = false,
    Callback = function(value)
        if value then 
            repeat task.wait()
                local success, result = pcall(function() 
                    local Knife = LocalPlayer.Backpack:FindFirstChild("Knife") or LocalPlayer.Character:FindFirstChild("Knife")
                    local Distance = tonumber(Options.Distance.Value)
    
                    for i, v in ipairs(Players:GetPlayers()) do wait(.1)
                        if v ~= LocalPlayer and v.Character ~= nil then
                            local EnemyRoot = v.Character.HumanoidRootPart
                            local EnemyPosition = EnemyRoot.Position
                            local EnemyDistance = (EnemyPosition - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                            if (EnemyDistance <= Distance) then
                                firetouchinterest(EnemyRoot, Knife.Handle, 1)
                                firetouchinterest(EnemyRoot, Knife.Handle, 0)
                            end
                        end  
                    end
                end)
            until not Options.KillAll.Value
        end
    end
})
    
local Slider = Tabs.Murderer:AddSlider("Distance", {
	Title = "Aura Distance",
	Default = 5,
	Min = 5,
	Max = 50,
	Rounding = 0,
	Callback = function(Value)
	end
})

local Toggle = Tabs.Sheriff:AddToggle("SilentAim", {
    Title = "Silent Aim",
    Default = false,
    Callback = function(value)
    end
})

local Slider = Tabs.Sheriff:AddSlider("Slider", {
    Title = "Accuracy",
    Default = 5,
    Min = 25,
    Max = 100,
    Rounding = 0,
    Callback = function(value)
    end
})  

local Toggle = Tabs.Sheriff:AddToggle("KillMurder", {
    Title = "Kill Murder",
    Default = false,
    Callback = function(value)
        if value then
            repeat task.wait() 
                local player = game.Players.LocalPlayer                
                local Murderer = GetMurderer()  
                    
                if Murderer then
                    if Murderer ~= player.Name then
                        local Gun = player.Backpack:FindFirstChild("Gun") 
                        local Equipped = player.Character:FindFirstChild("Gun")
                        if Gun then 
                            local humanoid = player.Character:WaitForChild("Humanoid")
                            humanoid:EquipTool(Gun)
                        end
    
                        if Equipped and Equipped.Handle.Reload.Playing then 
                            repeat task.wait()  
                                player.Character.HumanoidRootPart.CFrame = CFrame.new(Vector3.new(-109, 138.1, -17))  
                            until not Equipped or not Equipped.Handle.Reload.Playing or not value
                        end
    
                        local murdererCharacter = workspace:FindFirstChild(Murderer)
                        local murdererRootPart = murdererCharacter and murdererCharacter:FindFirstChild("HumanoidRootPart")
                        local playerCharacter = player.Character
                        local playerRootPart = playerCharacter and playerCharacter:FindFirstChild("HumanoidRootPart")
    
                        if Equipped and murdererRootPart and playerRootPart and not Equipped.Handle.Reload.Playing then
                            local offset = (murdererRootPart.Position - playerRootPart.Position).unit * -10
                            local targetPosition = murdererRootPart.Position + offset
                            playerCharacter:SetPrimaryPartCFrame(CFrame.new(targetPosition))
    
                            local directionToMurderer = (murdererRootPart.Position - playerRootPart.Position).unit
     
                            local Camera = workspace.CurrentCamera
                            Camera.CFrame = CFrame.new(playerRootPart.Position, playerRootPart.Position + directionToMurderer)
     
                            spawn(function()
                                wait(0.1)
                                local args = {
                                    [1] = 1,
                                    [2] =  murdererRootPart.Position,
                                    [3] = "AH", 
                                }  
                                workspace[player.Name].Gun.KnifeServer.ShootGun:InvokeServer(unpack(args))
                            end) 
                        end 
                    end
                end
            until not Options.KillMurder.Value
        end
    end
})

Tabs.Sheriff:AddButton({
    Title = "Shoot Murder",
    Callback = function()
        local gun = LocalPlayer.Backpack:FindFirstChild("Gun") or LocalPlayer.Character:FindFirstChild("Gun")
        local murderer = game.Players:FindFirstChild(Murderer)
        local murdererHRP = murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart")

        if Sheriff ~= LocalPlayer.Name then
            return
        elseif gun then 
            local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
            humanoid:EquipTool(gun)
        end  

        local args = {
            [1] = 1,
            [2] = murdererHRP.Position + (murdererHRP.Velocity * 0.5) * (4 / 15),
            [3] = "AH"
        }

        gun.KnifeServer.ShootGun:InvokeServer(unpack(args))
    end
})

local Toggle = Tabs.Murderer:AddToggle("AutoKill", {
    Title = "Auto Kill All",
    Default = false,
    Callback = function(value)
        if value then
            repeat task.wait()
                local success, result = pcall(function() 
                    local myKnife = LocalPlayer.Backpack:FindFirstChild("Knife") or LocalPlayer.Character:FindFirstChild("Knife")
                    if myKnife and myKnife:IsA("Tool") then
                        local initialPosition = LocalPlayer.Character.HumanoidRootPart.CFrame
                        
                        local character = LocalPlayer.Character
                        local humanoid = character:WaitForChild("Humanoid")
                        humanoid:EquipTool(myKnife)
                        
                            local success, result = pcall(function() 
                                for i, v in ipairs(Players:GetPlayers()) do task.wait()
                                    if v ~= LocalPlayer and v.Character then
                                        for i, player in pairs(game.Players:GetChildren()) do
                                            v.Character.HumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -2)
                                            character.Knife.Stab:FireServer('Down') 
                                        end        
                                    end
                                end
                            end)  
                        character.HumanoidRootPart.CFrame = initialPosition
                    end
                end)
            until not Options.AutoKill.Value
        end
    end
})

Tabs.Main:AddButton({
    Title = "End Round (BETA)",
    Callback = function()
        local murderer = game.Players:FindFirstChild(Murderer)
        module:fling(murderer)

        if Murderer ~= LocalPlayer.Name and murderer and murderer.Parent and murderer:FindFirstChild("Humanoid") and murderer.Humanoid.Health > 0 then
            repeat task.wait() 
            module:fling(murderer) wait(1)
            until not murderer or not murderer.Parent or not murderer:FindFirstChild("Humanoid") and murderer.Humanoid.Health > 0
        end
    end
})

Tabs.Murderer:AddButton({
    Title = "Kill All",
    Callback = function()
        local myKnife = LocalPlayer.Backpack:FindFirstChild("Knife") or LocalPlayer.Character:FindFirstChild("Knife")
        if myKnife and myKnife:IsA("Tool") then
            local initialPosition = LocalPlayer.Character.HumanoidRootPart.CFrame
            
            local character = LocalPlayer.Character
            local humanoid = character:WaitForChild("Humanoid")
            humanoid:EquipTool(myKnife)
            
            for i = 1, 3 do
                local success, result = pcall(function() 
                    for i, v in ipairs(Players:GetPlayers()) do task.wait()
                        if v ~= LocalPlayer and v.Character then
                            for i, player in pairs(game.Players:GetChildren()) do
                                v.Character.HumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -2)
                                character.Knife.Stab:FireServer('Down') 
                            end        
                        end
                    end
                end)  
            end
            character.HumanoidRootPart.CFrame = initialPosition
        end
    end
})

local function playerHasItem(itemName)
    repeat task.wait() 
         MainGUI = LocalPlayer.PlayerGui:FindFirstChild("MainGUI")
    until MainGUI

    for _, child in pairs(MainGUI.Game.Inventory.Main.Perks.Items.Container.Current.Container:GetChildren()) do
        if child:IsA("Frame") and child.ItemName.Label.Text == itemName then
            return true
        end
    end

    return false
end

local Toggle = Tabs.Power:AddToggle("InfiGhost", {
    Title = "Infinite Ghost",
    Default = false,
    Callback = function(value)
        if value then
            if not playerHasItem("Ghost") then 
                Fluent:Notify({Title = 'Missing Ghost', Content = 'Must own trap \n800 gems or 6K coins', Duration = 5 })
                return
            end  
            repeat
                task.wait()    
                if Murderer == nil then -- These are some bad checks
                    Services.ReplicatedStorage.Remotes.Gameplay.Stealth:FireServer(false)
                elseif Murderer == LocalPlayer.Name and LocalPlayer.PlayerGui.MainGUI["Menu/GUI"].Victory.MurdererVictory.Visible == true then 
                    LocalPlayer.PlayerGui.MainGUI.Game.EarnedXP.Visible = false 
                elseif LocalPlayer.PlayerGui.MainGUI.Game.EarnedXP.XPText.Text == "900" and LocalPlayer.PlayerGui.MainGUI.Game.Timer.Visible == false and Murderer ~= LocalPlayer.Name then 
                    Services.ReplicatedStorage.Remotes.Gameplay.Stealth:FireServer(false)
                elseif LocalPlayer.PlayerGui.MainGUI.Game.EarnedXP.Visible == true or LocalPlayer.PlayerGui.MainGUI.Game.Timer.Visible == true or LocalPlayer.PlayerGui.MainGUI.Game.EarnedXP.Visible == true then 
                    Services.ReplicatedStorage.Remotes.Gameplay.Stealth:FireServer(true)
                else                
                    Services.ReplicatedStorage.Remotes.Gameplay.Stealth:FireServer(false)

                end
            until not Options.InfiGhost.Value 
            Services.ReplicatedStorage.Remotes.Gameplay.Stealth:FireServer(false)
        end
    end
})

local Toggle = Tabs.Power:AddToggle("TrapTrail", {
    Title = "Trap Trail",
    Default = false,
    Callback = function(value)
        if value then
            if not playerHasItem("Trap") then 
                Fluent:Notify({Title = 'Missing Trap', Content = 'Must own trap \n400 gems or 3K coins', Duration = 5 })
                return
            end  
            repeat task.wait()
                local success, result = pcall(function()
                    if LocalPlayer then
                        local humanoidRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if humanoidRootPart then
                            local trapCFrame = CFrame.new(humanoidRootPart.Position)
                            local trapSystem = Services.ReplicatedStorage:FindFirstChild("TrapSystem")
                            if trapSystem and trapSystem:FindFirstChild("PlaceTrap") then
                                trapSystem.PlaceTrap:InvokeServer(trapCFrame)
                            end
                        end
                    end
                end)
            until not Options.TrapTrail.Value
        end
    end
})

local Toggle = Tabs.Power:AddToggle("AutoTrap", {
    Title = "Trap All",
    Default = false,
    Callback = function(value)
        if value then
            if not playerHasItem("Trap") then 
                Fluent:Notify({Title = 'Missing Trap', Content = 'Must own trap \n400 gems or 3K coins', Duration = 5 })
                return
            end  
            repeat task.wait()
                local trapSystem = Services.ReplicatedStorage:FindFirstChild("TrapSystem")
                
                    for _, player in ipairs(game.Players:GetPlayers()) do
                        if player ~= LocalPlayer then
                            local humanoidRootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                            if humanoidRootPart then
                                local trapCFrame = CFrame.new(humanoidRootPart.Position)
                                trapSystem.PlaceTrap:InvokeServer(trapCFrame)
                            end
                        end
                end 
            until not Options.AutoTrap.Value
        end
    end
})

local Toggle = Tabs.Power:AddToggle("AutoDestroy", {
    Title = "Auto Destroy Traps",
    Default = false,
    Callback = function(value)
        if value then 
            Fluent:Notify({Title = 'Destroy Traps', Content = 'This will delete traps visually [less lag]', Duration = 5 })
            repeat
                task.wait()
                local success, result = pcall(function()
                    local characterModel = workspace:FindFirstChild(LocalPlayer.Name)

                    if characterModel and characterModel:IsA("Model") then
                        for _, descendant in pairs(characterModel:GetDescendants()) do
                            if descendant.Name == "Trap" then
                                if descendant.Parent then
                                    descendant:Destroy()
                                end
                            end
                        end
                    end 
                end)
            until not Options.AutoDestroy.Value
        end
    end
})

local Toggle = Tabs.Player:AddToggle("WalkSpeed", {
    Title = "Walkspeed",
    Default = false,
    Callback = function(value)  
        if value then 
            if not confirmedwalk then 
                Window:Dialog({
                    Title = "Risk [ WalkSpeed ]",
                    Content = "There's a chance you might get kicked. Do you want to continue?",
                    Buttons = {
                        {
                            Title = "Confirm",
                            Callback = function()
                                confirmedwalk = true  
                            end
                        },
                        {
                            Title = "Cancel",
                            Callback = function()
                                Options.WalkSpeed:SetValue(false) 
                            end
                        }
                    }
                }) 
                repeat task.wait() until confirmedwalk or not Options.WalkSpeed.Value
            end

            repeat task.wait()  
                setWalkSpeed(Options.Walk.Value)  
            until not Options.WalkSpeed.Value
            setWalkSpeed(16) 
        end
    end
})

local Slider = Tabs.Player:AddSlider("Walk", {
    Title = "Walk Speed",
    Default = 16,
    Min = 16,
    Max = 200,
    Rounding = 0,
    Callback = function(Value)
    end
})

local Toggle = Tabs.Player:AddToggle("JumpPower", {
    Title = "Jump Power",
    Default = false,
    Callback = function(value)  
        if value then 
            if not confirmedjump then 
                Window:Dialog({
                    Title = "Risk [ Jump Power ]",
                    Content = "There's a chance you might get kicked. Do you want to continue?",
                    Buttons = {
                        {
                            Title = "Confirm",
                            Callback = function()
                                confirmedjump = true  
                            end
                        },
                        {
                            Title = "Cancel",
                            Callback = function()
                                Options.JumpPower:SetValue(false)  
                            end
                        }
                    }
                })
    
                repeat task.wait() until confirmedjump or not Options.JumpPower.Value
            end
    
            repeat task.wait()  
                setJumpPower(Options.Jump.Value) 
            until not Options.JumpPower.Value
            setJumpPower(50) 
        end
    end
})

local Slider = Tabs.Player:AddSlider("Jump", {
    Title = "Jump Power",
    Default = 50,
    Min = 50,
    Max = 200,
    Rounding = 0,
    Callback = function(Value)
    end
})

local Toggle = Tabs.Player:AddToggle("InfiniteJump", {
    Title = "Infinite Jump",
    Default = false,
    Callback = function(value)
        if value then 
            infJumpConnection = UserInputService.JumpRequest:Connect(function()
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)  
            end)
            repeat task.wait() until not Options.InfiniteJump.Value
            infJumpConnection:Disconnect()
        end
    end 
})

Tabs.Emotes:AddButton({
    Title = "Ninja",
    Callback = function()
        module:emote("ninja")
    end
})

Tabs.Emotes:AddButton({
    Title = "Dab",
    Callback = function()
        module:emote("dab")
    end
})

Tabs.Emotes:AddButton({
    Title = "Floss",
    Callback = function()
        module:emote("floss")
    end
})

Tabs.Emotes:AddButton({
    Title = "Headless",
    Callback = function()
        module:emote("headless")
    end
})

Tabs.Emotes:AddButton({
    Title = "Zen",
    Callback = function()
        module:emote("zen")
    end
})

Tabs.Emotes:AddButton({
    Title = "Zombie",
    Callback = function()
        module:emote("zombie")
    end
}) 

Tabs.Emotes:AddButton({
    Title = "Sit",
    Callback = function()
        module:emote("sit")
    end
})

local Toggle = Tabs.Settings:AddToggle("Settings", {
    Title = "Save Settings",
	Default = false,
    Callback = function(value)
		if value then 
            repeat task.wait() 
                if _G.FB35D == true then return end SaveManager:Save(game.PlaceId) 
            until not Options.Settings.Value
		end
	end
})
Tabs.Settings:AddButton({
	Title = "Delete Setting Config",
	Callback = function()
		delfile("nexus-001/settings/".. game.PlaceId ..".json")
	end  
})  

local Toggle = Tabs.Server:AddToggle("AutoRejoin", {
	Title = "Auto Rejoin",
	Default = false,
	Callback = function(value)
        if value then 
            Fluent:Notify({Title = 'Auto Rejoin', Content = 'You will rejoin if you are kicked or disconnected from the game', Duration = 5 })
            repeat task.wait() 
                local lp,po,ts = Players.LocalPlayer,game.CoreGui.RobloxPromptGui.promptOverlay,Services.TeleportService
                po.ChildAdded:connect(function(a)
                    if a.Name == 'ErrorPrompt' then
                        ts:Teleport(game.PlaceId) 
                        task.wait(2)
                    end
                end)
            until Options.AutoRejoin.Value
        end
	end
})
 
local Toggle = Tabs.Server:AddToggle("ReExecute", {
    Title = "Auto ReExecute",
    Default = false,
    Callback = function(value)
        if value then 
            repeat 
                task.wait()
                local queueteleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
                if queueteleport then
                    if not game:IsLoaded() then 
                        game.Loaded:Wait()
                    end
                    queueteleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/s-o-a-b/nexus-WIP/main/loadstring"))()')
                end  
            until not Options.ReExecute.Value
        end  
    end 
})

Tabs.Server:AddButton({
	Title = "Rejoin-Server",
	Callback = function()
		Services.TeleportService:Teleport(game.PlaceId, Player)
	end
})  

Tabs.Server:AddButton({
	Title = "Server-Hop", 
	Callback = function()
	   local Http = Services.HttpService
		local TPS = Services.TeleportService
		local Api = "https://games.roblox.com/v1/games/"
		local _place,_id = game.PlaceId, game.JobId
		local _servers = Api.._place.."/servers/Public?sortOrder=Desc&limit=100"
		local function ListServers(cursor)
			local Raw = game:HttpGet(_servers .. ((cursor and "&cursor="..cursor) or ""))
			return Http:JSONDecode(Raw)
		end
		local Next; repeat
			local Servers = ListServers(Next)
			for i,v in next, Servers.data do
				if v.playing < v.maxPlayers and v.id ~= _id then
					local s,r = pcall(TPS.TeleportToPlaceInstance,TPS,_place,v.id,Player)
					if s then break end
				end
			end
			Next = Servers.nextPageCursor
		until not Next
	end
})

coroutine.wrap(function()
    while true do
        task.wait(.1)
        if _G.FB35D == true then 
            return 
        end
        local success, err = pcall(function()
            Murderer = GetMurderer()
            Sheriff = GetSheriff()
            roles = updatePlayerData()
        end)
    end
end)()

local GunHook
GunHook = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = { ... }
    if not checkcaller() then
        if typeof(self) == "Instance" then
            if self.Name == "ShootGun" and method == "InvokeServer" then
                if Options.SilentAim.Value then 
                    if Murderer then
                        local Root = workspace[tostring(Murderer)].HumanoidRootPart;
                        local Veloc = Root.AssemblyLinearVelocity;
                        local Pos = Root.Position 
                        args[2] = Pos;
                    end;
                else
                    return GunHook(self, unpack(args));
                end;
            end;
        end;
    end;
    return GunHook(self, unpack(args));
end);

local __namecall
__namecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = { ... }
    if not checkcaller() then
        if tostring(method) == "InvokeServer" and tostring(self) == "GetChance" then
            wait(13)
        end
    end
    return __namecall(self, unpack(args))
end)

-- Set libraries and folders
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:SetIgnoreIndexes({})
SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("nexus-001")
SaveManager:SetFolder("nexus-001")

-- Build interface section and load the game
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:Load(game.PlaceId)

-- Select the first tab in the window
Window:SelectTab(1)
