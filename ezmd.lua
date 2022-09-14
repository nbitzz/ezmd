rconsolename("ezmd, @split#1337")

if not syn then
    syn = {
        request = request,
        queue_on_teleport = queue_on_teleport
    }    
end

local Assets = loadstring(game:HttpGet("https://raw.githubusercontent.com/nbitzz/random-things/main/luau/Assets.lua"))()

local ezmd
ezmd = {
    game_patch = game.PlaceVersion,
    decode = function(v) return game:GetService("HttpService"):JSONDecode(v) end,
    encode = function(v) return game:GetService("HttpService"):JSONEncode(v) end,
    cleanupOnRoomPass = {},
    configs = {
        ShowKeyLocation=true,
        ShowLeverLocation=true,
        RemoveGate=false,
        RemoveBookshelvesFromGateRoom=false,
        ShowBookLocationInLibrary=true,
        DisableScreech = true,
        RoomCounter = true,
        ReturnResetCharacterButton = true,
        HighlightDoors=true,
        SpeedBoost=false,
        SubtleSpeedBoost=true,
        RoomSkipKey=false,
        MultiSkipIfDoorLocked=false,
        HideKey=false,
        SkipRoom100=true,
        RemoveElectricalDoor=true,
        CatchUpKey=true,
        ShowFigureLocation=true,
        AutoHideOnRush=true,
        TpOutOfMapOnAmbush=false
        --[[
        DeathTrolls=false,
        Troll_DisableDrawers=false,
        ]]
    },
    assets = Assets.new("ezmd"),
    justBoosted = false,
    b2eng = function(v) return v and "on" or "off" end,
    log = function(txt)
        rconsoleprint("\n "..txt)
    end,
    owner = game:GetService("Players").LocalPlayer,
    LibraryHighlight = function()
        local room50 = workspace.CurrentRooms:FindFirstChild("50")

        if (room50) then
            for x,v in pairs(room50.Assets:GetChildren()) do
        		if v:FindFirstChild("LiveHintBook") then
        			local highlight = Instance.new("Highlight",ezmd.owner.PlayerGui)
        			highlight.Adornee = v.LiveHintBook
                    highlight.FillColor = Color3.new(0.5,0.5,0.5)
                    table.insert(ezmd.cleanupOnRoomPass,highlight)
        		end
            end
        end
    end,
    GetAllLoot = function()
        local currentRoom = workspace.CurrentRooms[ezmd.gamedata.LatestRoom.Value]
        local loot = {}
        
        local LookingFor = {}
        
        -- code here sucks
        --[[
        if (ezmd.configs.ShowGoldLocation) then
            table.insert(LookingFor,"GoldPile")
        end
        if (ezmd.configs.ShowLockpickLocation) then
            table.insert(LookingFor,"Lockpick")
        end
        if (ezmd.configs.ShowLighterLocation) then
            table.insert(LookingFor,"Lighter")
        end
        if (ezmd.configs.ShowFlashlightLocation) then
            table.insert(LookingFor,"Flashlight")
        end
        if (ezmd.configs.ShowBatteryLocation) then
            table.insert(LookingFor,"Battery")
        end
        ]]
        for x,v in pairs(currentRoom.Assets:GetDescendants()) do
            --[[
            if v.Parent.Name == "DrawerContainer" and table.find(LookingFor,v.Name) then
                table.insert(loot,v)         
            end
            ]]
            if (v.Name == "KeyObtain" and ezmd.configs.ShowKeyLocation) then
                table.insert(loot,v)
            end
            
            if (v.Name == "LeverForGate" and ezmd.configs.ShowLeverLocation) then
                table.insert(loot,v)
            end
        end
        
        return loot
    end,
    HighlightLoot = function()
        local loot = ezmd.GetAllLoot()
        for x,v in pairs(loot) do
            local highlight = Instance.new("Highlight",v)
            highlight.FillColor = Color3.new(0.5,0.5,0.5)
            table.insert(ezmd.cleanupOnRoomPass,highlight)
        end
    end,
    settings = function()
        rconsoleprint("@@DARK_GRAY@@")
        ezmd.log("Type in a number and press ENTER to toggle a setting.")
        ezmd.log("Green is on, red is off.\n")
        rconsoleprint("@@WHITE@@")
        local currentInd = 0
        local indTable = {}
        
        for x,v in pairs(ezmd.configs) do
            currentInd = currentInd + 1
            rconsoleprint("\n")
            rconsoleprint(v and "@@LIGHT_GREEN@@" or "@@LIGHT_RED@@")
            rconsoleprint(" ["..currentInd.."] ")
            rconsoleprint("@@WHITE@@")
            rconsoleprint(x)
            
            table.insert(indTable,x)
        end
        
        rconsoleprint("\n\n Choose a setting to change: ")
        local num = rconsoleinput()
        local v = indTable[tonumber(num)]
        if (v) then
            ezmd.configs[v] = not ezmd.configs[v]
            ezmd.log(v.." is now "..ezmd.b2eng(ezmd.configs[v]))
            
            writefile("ezmd_cfg.json",ezmd.encode(ezmd.configs))
        else
            ezmd.settings()
        end
    end,
    load_configs = function()
        if (isfile("ezmd_cfg.json")) then
            ezmd.log("Loading config file")
            local s,e = pcall(function() 
                local dc = ezmd.decode(readfile("ezmd_cfg.json"))
                for x,v in pairs(dc) do
                    ezmd.configs[x] = v
                end
            end)
            if (e) then
                rconsoleprint("@@LIGHT_RED@@")
                ezmd.log("Failed to load configs: "..e)            
                rconsoleprint("@@DARK_GRAY@@")
            end
        else
            ezmd.log("No config file found. Using defaults.")    
        end
        
        rconsoleprint("@@LIGHT_GRAY@@")
        ezmd.log("------- [ Current cfg ] --------")
        rconsoleprint("@@DARK_GRAY@@")
        
        for x,v in pairs(ezmd.configs) do
            ezmd.log(x.." is ")
            rconsoleprint(v and "@@LIGHT_GREEN@@" or "@@LIGHT_RED@@")
            rconsoleprint(ezmd.b2eng(v))
            rconsoleprint("@@DARK_GRAY@@")
        end
    end,
    -- this code sucks
    SkipRoom = function()
        local currentRoom = workspace.CurrentRooms[ezmd.gamedata.LatestRoom.Value]
        if (currentRoom:FindFirstChild("Door")) then
            if currentRoom.Door:FindFirstChild("Lock") then
                if (ezmd.configs.MultiSkipIfDoorLocked) then
                    ezmd.owner.Character:PivotTo(workspace.CurrentRooms[ezmd.gamedata.LatestRoom.Value+1].RoomEnd.CFrame)   
                else
                    game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage",{Text="You cannot skip this door as it is locked. Enable MultiSkipIfDoorLocked to skip 2 doors if a door is locked.",Color = Color3.new(0.5,0.5,0.5)})
                end
            else
                   ezmd.owner.Character:PivotTo(workspace.CurrentRooms[ezmd.gamedata.LatestRoom.Value].RoomEnd.CFrame)         
            end
        end
    end,
    Util_GetDistance = function(v) 
        return (v.Position-ezmd.owner.Character.PrimaryPart.Position).Magnitude    
    end,
    HideInNearestCloset = function()
        -- collect all objects that you can hide in
        
        local hideables = {}
        
        for x,v in pairs(workspace.CurrentRooms:GetChildren()) do
            if (v:FindFirstChild("Assets")) then
                for x,v in pairs(v.Assets:GetChildren()) do
                    if v:FindFirstChild("HidePrompt") then
                        table.insert(hideables,v)
                    end
                end
            end
        end
        
        -- get nearest hideable
        
        local nearestHideable = nil
        
        for x,v in pairs(hideables) do
            local canHideInCloset = false
            if (v:FindFirstChild("HiddenPlayer")) then
                canHideInCloset = v.HiddenPlayer.Value == nil
            end
            if canHideInCloset then
                if (nearestHideable) then
                    if (ezmd.Util_GetDistance(nearestHideable.PrimaryPart)-ezmd.Util_GetDistance(v.PrimaryPart)) > 0 then
                        nearestHideable = v
                    end
                else
                    nearestHideable = v
                end
            end
        end
        
        -- hide!
        
        ezmd.owner.Character:PivotTo(nearestHideable.PrimaryPart.CFrame)
        task.delay(0.15, function()
            fireproximityprompt(nearestHideable:FindFirstChild("HidePrompt"))
        end)
    end,
    CatchUp = function() 
        local latestPlayer = nil
        for x,v in pairs(game:GetService("Players"):GetChildren()) do
            if (v.Character and v:GetAttribute("Alive") and v ~= ezmd.owner) then
                if (latestPlayer) then
                    if (v:GetAttribute("CurrentRoom") > latestPlayer:GetAttribute("CurrentRoom")) then
                        latestPlayer = v                                    
                    end
                else
                    latestPlayer = v
                end
            end
        end
    
        ezmd.owner.Character:PivotTo(latestPlayer.Character.PrimaryPart.CFrame)    
    end
    --[[,
    disable_drawer = function(drawer)
		local prox = drawer:FindFirstChild("Knobs"):FindFirstChild("ActionEventPrompt")
		drawer.PrimaryPart.Changed:Connect(function(v) 
			if v == "Position" then
				ezmd.owner.Character:PivotTo(drawer.PrimaryPart.CFrame)
				task.delay(0.5,function() 
					fireproximityprompt(prox)
				end)
			end
		end)
    end]]
}

Assets.Logger = ezmd.log

function ezmd.reinject_on_rejoin()
    local ezmd_me = syn.request({
    Url = "https://raw.githubusercontent.com/nbitzz/ezmd/main/ezmd.lua",
    Method = "GET"
}).Body
    syn.queue_on_teleport(ezmd_me)
    ezmd.log("Queued EZMD to run on teleport.")    
end

function ezmd.title(dfTxCl)
    rconsoleclear()
    rconsoleprint("@@LIGHT_RED@@")
    rconsoleprint([[     ______     ______     __    __     _____    
    /\  ___\   /\___  \   /\ "-./  \   /\  __-.  
    \ \  __\   \/_/  /__  \ \ \-./\ \  \ \ \/\ \ 
     \ \_____\   /\_____\  \ \_\ \ \_\  \ \____- 
      \/_____/   \/_____/   \/_/  \/_/   \/____/ ]])
    rconsoleprint("@@DARK_GRAY@@")
    rconsoleprint("\n       @split#1337")
    rconsoleprint("@@LIGHT_RED@@")
    rconsoleprint("\n\n"..string.rep("-",100).."\n")
    rconsoleprint("@@"..(dfTxCl or "WHITE").."@@")
end

-- detect current game

if (game.PlaceId == 6839171747) then
    ezmd.title()
    rconsoleprint(" EZMD is loading...")
    rconsoleprint("@@DARK_GRAY@@")
    ezmd.log("Loading configs...")
    
    ezmd.load_configs()
    
    rconsoleprint("@@LIGHT_GRAY@@")
    ezmd.log("------- [ Loading.... ] --------")
    rconsoleprint("@@DARK_GRAY@@")
    ezmd.log("Waiting for player to load...")
    if (not game:IsLoaded()) then
        game.Loaded:Wait()
    end
    ezmd.owner = game:GetService("Players").LocalPlayer
    if (not ezmd.owner.Character) then
        ezmd.owner.CharacterAdded:Wait()
    end
    
    ezmd.log("Waiting for game to load...")
    
    local logHistory = game:GetService("LogService"):GetLogHistory()
    for x,v in pairs(logHistory) do
        if (v.message:sub(1,7) == "PATCH: ") then
            ezmd.game_patch = v.message:sub(8,v.message:len())            
        end
    end
    
    if (typeof(ezmd.game_patch) == "number") then
        local mo = game:GetService("LogService").MessageOut:Connect(function(msg) 
            if (msg:sub(1,7) == "PATCH: ") then
                ezmd.game_patch = msg:sub(8,msg:len())            
            end
        end)
        
        repeat task.wait() until (typeof(ezmd.game_patch) == "string")
        mo:Disconnect()
    end
    
    if (ezmd.configs.GhostbusterMode) then
        ezmd.log("Preparing Ghostbuster Mode™...")
        ezmd.ghostbusters = {
            ezmd.assets:Get("https://archive.org/download/SuperGhostbusters2018/02%20Ghost%20Buster.mp3"),
            ezmd.assets:Get("https://archive.org/download/SuperGhostbusters2018/01%20Ghostbusters.mp3"),
            ezmd.assets:Get("https://archive.org/download/SuperGhostbusters2018/10%20Ghooooostbuster.mp3")
        }
    end
    
    ezmd.HornyAssets = Assets.new("ezmd_horny_mode")
    
    if (ezmd.configs.Gay) then
        ezmd.log("Preparing Gay mode...")
        ezmd.prem_g = {
            liquid = Instance.new("Texture")
        }
        ezmd.prem_g.liquid.Texture = "rbxassetid://10120358857"
        ezmd.prem_g.liquid.Transparency = 0.65
        ezmd.prem_g.StudsPerTileU = 6
        ezmd.prem_g.StudsPerTileV = 6
        
        -- pink vignette
        
        local ggui = Instance.new("ScreenGui",ezmd.owner.PlayerGui)
        ggui.IgnoreGuiInset = true
        ggui.ResetOnSpawn = false
        local img = Instance.new("ImageLabel",ggui)
        img.BorderSizePixel = 0
        img.BackgroundTransparency = 0.95
        img.BackgroundColor3 = Color3.fromRGB(255, 0, 234)
        img.ImageColor3 = Color3.fromRGB(255, 74, 246)
        img.ImageTransparency = 0.5
        img.Image = "http://www.roblox.com/asset/?id=5945121255"
        img.ScaleType = Enum.ScaleType.Slice
        img.SliceScale = 1
        img.SliceCenter = Rect.new(213, 156, 811, 420)
        img.Size = UDim2.new(1,0,1,0)
        local steam = Instance.new("ImageLabel",img)
        steam.BackgroundTransparency = 1
        steam.ImageTransparency = 1
        steam.ImageColor3 = Color3.fromRGB(255, 175, 255)
        steam.Image = "rbxassetid://1077212019"
        steam.ScaleType = Enum.ScaleType.Crop
        steam.Size = UDim2.new(1,0,1,0)
        
        ezmd.flashSteam = function() 
            steam.ImageTransparency = 0.5
            game:GetService("TweenService"):Create(steam,TweenInfo.new(math.random(200,300)/100,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out,0,false,0),{ImageTransparency=1}):Play()
        end
        
        ezmd.gay = {
            DoorKissVideo = ezmd.assets:Get("https://cdn.discordapp.com/attachments/985317502076739586/1019450225938665493/doorkiss.webm"),
            CatboyFigurexSeek = ezmd.assets:Get("https://media.discordapp.net/attachments/985317502076739586/1019452081406480435/unknown.png")
        }
        if (ezmd.configs.Horny) then
            ezmd.log("!! HORNY MODE ACTIVE !!")
            ezmd.log("WARNING: NSFW - Disable Horny mode and rejoin the game to delete all images linked to Horny mode.")
            ezmd.horny = {}
            
            if (ezmd.HornyAssets.length > 0) then
                for x,v in pairs(ezmd.HornyAssets.AssetList) do
                    table.insert(ezmd.horny,Assets.getAsset(v))                    
                end
            else
                local url = string.format("https://api.rule34.xxx/index.php?page=dapi&s=post&q=index&tags=%s&limit=75&json=1",game:GetService("HttpService"):UrlEncode("doors_(roblox)"))
        		local images = game:GetService("HttpService"):JSONDecode(game:GetService("HttpService"):GetAsync(url))
        		for x,v in pairs(images) do
                    table.insert(ezmd.horny,ezmd.HornyAssets:Get(v.file_url))        		    
        		end
            end
        else
            ezmd.horny = {ezmd.gay.CatboyFigurexSeek}    
        end
    end
    
    if (not ezmd.configs.Horny and ezmd.HornyAssets.length > 0) then
        ezmd.HornyAssets:wipe()
    end
    
    rconsoleprint("@@GREEN@@")
    ezmd.log("------- [ Game loaded ] --------")
    rconsoleprint("@@DARK_GRAY@@")
    
    -- loading procedure
    do 
        ezmd.log(string.format("Running on DOORS %s (%s)",ezmd.game_patch,game.PlaceVersion)) 
        
        ezmd.log("Locating essentials...")
        
        ezmd.handler = ezmd.owner.PlayerGui:WaitForChild("MainUI"):WaitForChild("Initiator"):WaitForChild("Main_Game")
        ezmd.bricks = game:GetService("ReplicatedStorage"):WaitForChild("Bricks")
        ezmd.stats = game:GetService("ReplicatedStorage"):WaitForChild("GameStats"):WaitForChild("Player_"..ezmd.owner.Name).Total
        ezmd.gamedata = game:GetService("ReplicatedStorage"):WaitForChild("GameData")
        
        -- room counter
        
        if (ezmd.configs.RoomCounter) then
            ezmd.log("Creating room counter...")
            local roomCntr_GUI = Instance.new("ScreenGui",game:GetService("CoreGui"))
            local roomCntr_TL = Instance.new("TextLabel",roomCntr_GUI)
            roomCntr_TL.BackgroundTransparency = 1
            roomCntr_TL.TextColor3 = Color3.new(255,255,0)
            roomCntr_TL.Font = Enum.Font.RobotoMono
            roomCntr_TL.AnchorPoint = Vector2.new(1,1)
            roomCntr_TL.Size = UDim2.new(0,200,0,50)
            roomCntr_TL.TextSize = 25
            roomCntr_TL.TextXAlignment = Enum.TextXAlignment.Right
            roomCntr_TL.TextYAlignment = Enum.TextYAlignment.Bottom
            roomCntr_TL.Text = "ROOM: "..ezmd.gamedata.LatestRoom.Value
            roomCntr_TL.Position = UDim2.new(1,-5,1,-5)
            
            ezmd.gamedata.LatestRoom.Changed:Connect(function(v) 
                 roomCntr_TL.Text = "ROOM: "..v
            end)
        end
        
        -- disable screech
            
        if ezmd.configs.DisableScreech then
            local screech = ezmd.bricks:WaitForChild("Screech")
            rconsoleprint("@@LIGHT_GRAY@@")
            ezmd.log("Disabling Screech...")
            rconsoleprint("@@DARK_GRAY@@")
            local oldIndex
            oldIndex = hookmetamethod(screech,"__index",function(_self,key) 
                if not checkcaller() and _self == screech and key == "OnClientEvent" then
                    return Instance.new("BindableEvent").Event
                end
                
                return oldIndex(_self,key)
            end)
            ezmd.log("  [.] Disabled new event connections.")
            local conns = getconnections(screech.OnClientEvent)
            for x,v in pairs(conns) do
                v:Disable()
            end
            ezmd.log("  [.] Disabled current connections ("..#conns..")")
            screech.OnClientEvent:Connect(function() 
                screech:FireServer(true)
            end)
            ezmd.log("  [.] Reconnected event.")
            local sc_model = game:GetService("ReplicatedStorage"):WaitForChild("Entities"):WaitForChild("Screech",2)
            if (sc_model) then
                sc_model:Destroy()
                ezmd.log("  [.] Removed Screech model.")
            end
            ezmd.log("  [!] Screech has been disabled.")
        end
        
        if ezmd.configs.SkipRoom100 then
            -- TODO: make this ONLY disable the room 100 minigame.
            
            local screech = ezmd.bricks:WaitForChild("EngageMinigame")
            rconsoleprint("@@LIGHT_GRAY@@")
            ezmd.log("Disabling minigames...")
            rconsoleprint("@@DARK_GRAY@@")
            local oldIndex
            oldIndex = hookmetamethod(screech,"__index",function(_self,key) 
                if not checkcaller() and _self == screech and key == "OnClientEvent" then
                    return Instance.new("BindableEvent").Event
                end
                
                return oldIndex(_self,key)
            end)
            ezmd.log("  [.] Disabled new event connections.")
            local conns = getconnections(screech.OnClientEvent)
            for x,v in pairs(conns) do
                v:Disable()
            end
            ezmd.log("  [.] Disabled current connections ("..#conns..")")
            screech.OnClientEvent:Connect(function() 
                -- best i could do lol
                game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage",{Text="Attempting to spam elevator...",Color = Color3.new(1,0.2,0.2)})
                while true do
                    ezmd.bricks.EBF:FireServer();
                    task.wait();
                end
            end)
            ezmd.log("  [.] Reconnected event.")
            ezmd.log("  [!] Minigames have been disabled. The Room 100 minigame skip can now be performed.")
        end
        
        -- on room changed
        
        task.spawn(function()
            --[[ezmd.stats.Knobs:WaitForChild("Rooms Survived")]]ezmd.gamedata.LatestRoom.Changed:Connect(function(v) 
                for x,v in pairs(ezmd.cleanupOnRoomPass) do
                    if (v) then
                        v:Destroy()                    
                    end
                end
                ezmd.cleanupOnRoomPass = {}
                
                ezmd.HighlightLoot()
                
                local currentRoom = workspace.CurrentRooms[ezmd.gamedata.LatestRoom.Value]
                
                if (ezmd.configs.Gay) then
                    ezmd.flashSteam()
                    if (math.random(1,8) == 8) then
                        for x,v in pairs(currentRoom:GetDescendants()) do
                            if (v:IsA("BasePart")) then
                                for _,a in pairs(Enum.NormalId:GetEnumItems()) do
                                    local liq = ezmd.prem_g.liquid:Clone()
                                    liq.Parent = v
                                    liq.Face = a
                                    table.insert(ezmd.cleanupOnRoomPass,liq)
                                end
                            end
                            
                            if v:IsA("MeshPart") then
                                v,TextureId = ezmd.prem_g.liquid.Texture                                
                            end
                        end
                    end
                    if (currentRoom:FindFirstChild("Assets")) then
                        for x,v in pairs(currentRoom.Assets:GetChildren()) do
                            if (v.Name:match("Painting_")) then
                                if (v:FindFirstChild("Canvas")) then
                                    if (v.Canvas:FindFirstChild("SurfaceGui")) then
                                        if (v.Canvas.SurfaceGui:FindFirstChild("ImageLabel")) then
                                            v.Canvas.SurfaceGui.ImageLabel.Image = ezmd.horny[math.random(1,#ezmd.horny)]                                 
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                
                if (currentRoom:FindFirstChild("FigureSetup") and ezmd.configs.ShowFigureLocation) then
                    if (currentRoom.FigureSetup:FindFirstChild("FigureRagdoll")) then
                        local highlight = Instance.new("Highlight",currentRoom.FigureSetup.FigureRagdoll)
                        highlight.FillColor = Color3.new(0.5,0.5,0.5)
                        table.insert(ezmd.cleanupOnRoomPass,highlight)                  
                    end
                    -- doesn't work and I don't know why.
                    --[[
                    if (ezmd.configs.Gay) then
                        local g = Instance.new("ScreenGui",ezmd.owner.PlayerGui)
                        g.IgnoreGuiInset = true
                        g.ResetOnSpawn = false
                        local w = Instance.new("VideoFrame",g)
                        w.BackgroundTransparency = 1
                        w.Size = UDim2.new(1,0,1,0)
                        w.Video = ezmd.gay.DoorKissVideo
                        w.ZIndex = 1000
                        w.Looped = true
                        w.Volume = 0
                        w.Playing = true
                        local con
                        con = game:GetService("RunService").RenderStepped:Connect(function() if not g then con:Disconnect() return end w.Visible = not w.Visible end)
                        table.insert(ezmd.cleanupOnRoomPass,g)
                    end
                    ]]
                end
                
                if (v == 1 and ezmd.configs.GhostbusterMode) then
                    -- ghost buster !!!
                    -- this code sucks LOL whatever idc its a joke
                    
                    local old = UserSettings().GameSettings:InFullScreen()

                    if not UserSettings().GameSettings:InFullScreen() then
                        game:GetService("GuiService"):ToggleFullscreen()                        
                    end
                    
                    game:GetService("CoreGui"):ClearAllChildren()
                    ezmd.owner.PlayerGui:ClearAllChildren()
                    
                    -- thing
                    local song = ezmd.ghostbusters[math.random(1,#ezmd.ghostbusters)]
                    
                    local snd = Instance.new("Sound",game.CoreGui)
                    snd.SoundId = song
                    snd.Volume = 10
                    
                    local dist = Instance.new("DistortionSoundEffect",snd)
                    dist.Level = 0
                    
                    local cce = Instance.new("ColorCorrectionEffect",game.Lighting)
                    cce.TintColor = Color3.new(1,1,1)
                    
                    local blur = Instance.new("BlurEffect",game.Lighting)
                    blur.Size = 0
                    
                    game.Lighting.Ambient = Color3.new(1,1,1)
                    
                    game:GetService("UserInputService").WindowFocusReleased:Connect(function() 
                        if (old == false) then
                            game:GetService("GuiService"):ToggleFullscreen()                            
                        end
                        game:Shutdown() 
                    end)
                    
                    game:GetService("RunService").RenderStepped:Connect(function() 
                        dist.Level = snd.PlaybackLoudness/1000
                        game:GetService("TweenService"):Create(workspace.CurrentCamera,TweenInfo.new(0.1,Enum.EasingStyle.Quint,Enum.EasingDirection.Out,0,false,0),{CFrame=CFrame.Angles(math.rad(math.random(-360,360)),math.rad(math.random(-360,360)),math.rad(math.random(-360,360)))+ezmd.owner.Character.Head.Position}):Play()
                        game:GetService("TweenService"):Create(blur,TweenInfo.new(0.25,Enum.EasingStyle.Quint,Enum.EasingDirection.Out,0,false,0),{Size=snd.PlaybackLoudness/350*24}):Play()
                        game:GetService("TweenService"):Create(snd,TweenInfo.new(0.25,Enum.EasingStyle.Quint,Enum.EasingDirection.Out,0,false,0),{PlaybackSpeed=math.random(0.75,2)}):Play()
                        game:GetService("TweenService"):Create(cce,TweenInfo.new(0.25,Enum.EasingStyle.Quint,Enum.EasingDirection.Out,0,false,0),{TintColor=Color3.new(snd.PlaybackLoudness/100*math.random(),snd.PlaybackLoudness/100*math.random(),snd.PlaybackLoudness/100*math.random())}):Play()
                    end)
                    
                    snd.Ended:Connect(function()
                        if (old == false) then
                            game:GetService("GuiService"):ToggleFullscreen()                            
                        end
                        game:Shutdown()    
                    end)
                    snd:Play()
                end
                
                if (v == 50 and ezmd.configs.ShowBookLocationInLibrary) then
                    ezmd.LibraryHighlight()    
                end
                
                if (v == 100) then
                    if (ezmd.configs.RemoveElectricalDoor) then
                        currentRoom.ElectricalDoor:Destroy()
                    elseif ezmd.configs.ShowKeyLocation then
                        -- ElectricalKeyObtain is key name.
                        local highlight = Instance.new("Highlight"--[[,currentRoom.ElectricalKeyObtain]])
                        highlight.FillColor = Color3.new(0.5,0.5,0.5)
                        table.insert(ezmd.cleanupOnRoomPass,highlight)
                    end
                    
                    -- this is a mess
                    
                    if (ezmd.configs.SkipRoom100) then
                        game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage",{Text="Beginning skip, please wait. (If you do not see \"Attempting to spam elevator\", go down to the breaker and interact with it.)",Color = Color3.new(1,0.2,0.2)})
                        ezmd.owner.Character:PivotTo(currentRoom.ElevatorBreaker.PrimaryPart.CFrame)
                        task.delay(1,function() fireproximityprompt(currentRoom.ElevatorBreaker.ActivateEventPrompt)
                            task.delay(0.5,function() ezmd.owner.Character:PivotTo(currentRoom.ElevatorCar.Spawns:GetChildren()[1]) end)
                        end)
                    end
                end
                
                if ezmd.configs.HighlightDoors and currentRoom:FindFirstChild("Door") then
                    local highlight = Instance.new("Highlight",currentRoom.Door)
                    highlight.FillColor = Color3.new(0.5,0.5,0.5)
                    table.insert(ezmd.cleanupOnRoomPass,highlight)
                end
                
                if (currentRoom:FindFirstChild("Gate")) then
                    -- room is a gate room
                    if ezmd.configs.RemoveGate then
                        currentRoom.Gate:Destroy()                        
                    end
                    
                    if (ezmd.configs.RemoveBookshelvesFromGateRoom) then
                        for x,v in pairs(currentRoom.Assets:GetChildren()) do
                            if v.Name == "Modular_Bookshelf" then
                                v:Destroy()                                
                            end
                        end
                    end
                end
            end)
        end)
        
        ezmd.log("Loot highlighter ready.")
        
        if (ezmd.configs.ReturnResetCharacterButton) then
            game:GetService("StarterGui"):SetCore("ResetButtonCallback",true)
            ezmd.log("Restored reset character button.")            
        end
        
        ezmd.owner.Character:WaitForChild("Humanoid").Changed:Connect(function(v) 
            if (ezmd.justBoosted) then
                ezmd.justBoosted = false
                return
            end
            if (v == "WalkSpeed" and ezmd.configs.SpeedBoost) then
                ezmd.justBoosted = true
                ezmd.owner.Character:WaitForChild("Humanoid").WalkSpeed = ezmd.owner.Character:WaitForChild("Humanoid").WalkSpeed + (8/(ezmd.configs.SubtleSpeedBoost and 2 or 1))
            end
        end)
        
        workspace.ChildAdded:Connect(function(v) 
            if (v.Name == "RushMoving" and ezmd.configs.AutoHideOnRush) then
                game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage",{Text="Rush detected. Auto Hide will be activated once Rush is in range.",Color = Color3.new(0.5,0.5,0.5)})
                v:WaitForChild("RushNew")
                repeat task.wait();--[[ ezmd.log(ezmd.Util_GetDistance(v.RushNew))]] until ezmd.Util_GetDistance(v.RushNew) <= 75
                ezmd.HideInNearestCloset()
            end
            if (v.Name == "AmbushMoving" and ezmd.configs.TpOutOfMapOnAmbush) then
                game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage",{Text="Ambush detected. You have been teleported out of the map. You will be teleported to the nearest player after Ambush is finished.",Color = Color3.new(0.5,0.5,0.5)})
                ezmd.owner.Character:PivotTo(ezmd.owner.Character.PrimaryPart.CFrame+Vector3.new(0,100,0))
                ezmd.owner.Character.PrimaryPart.Anchored = true
                repeat task.wait() until not v
                ezmd.owner.Character.PrimaryPart.Anchored = false
                ezmd.CatchUp()
            end
        end)
        
        --[[
        if (ezmd.configs.DeathTrolls) then
            ezmd.log("Warning: DeathTrolls is enabled - revives are no longer available")
            ezmd.handler.Parent.Parent.HodlerRevive.Visible = false
            ezmd.handler.Parent.Parent.HodlerRevive.Changed:Connect(function(v) 
                if (v == "Visible") then
                    ezmd.handler.Parent.Parent.HodlerRevive.Visible = false             
                end
            end)
            
            ezmd.owner.Character:WaitForChild("Humanoid").Died:Connect(function() 
                -- DeathTrolls
                
                ezmd.log("--------------------------------------------------------------------------------")
                ezmd.log("DeathTrolls is now active.")
                
                if (ezmd.configs.Troll_DisableDrawers) then
                    ezmd.log("DisableDrawers active")
                    
                    function disableDrawersInRoom(room)
                        for x,v in pairs(room.Assets:GetDescendants()) do
                            if v.Name == "DrawerContainer" then
                                ezmd.disable_drawer(v)                                
                            end
                        end
                    end
                    
                    for x,v in pairs(workspace.CurrentRooms:GetChildren()) do
                        if v:FindFirstChild("Assets") then
                            disableDrawersInRoom(v)
                        end
                    end
                    
                    workspace.CurrentRooms.ChildAdded:Connect(function(c) 
                        task.delay(1,function() 
                            disableDrawersInRoom(c)    
                        end)    
                    end)
                    
                end
            end)
        end
        ]]
        
        -- room skip
        
        if (ezmd.configs.RoomSkipKey) then
            rconsoleprint("@@CYAN@@")
            ezmd.log("Room Skip key is active. Press F to skip a room.")
            game:GetService("UserInputService").InputBegan:Connect(function(kc) 
                
                if kc.KeyCode == Enum.KeyCode.F and not game:GetService("UserInputService"):GetFocusedTextBox() then
                    ezmd.SkipRoom()                    
                end
        
            end)
            rconsoleprint("@@DARK_GRAY@@")
        end
        
        if (ezmd.configs.HideKey) then
            rconsoleprint("@@LIGHT_RED@@")
            ezmd.log("Hide key is active. Press R to hide in a closet.")
            game:GetService("UserInputService").InputBegan:Connect(function(kc) 
                
                if kc.KeyCode == Enum.KeyCode.R and not game:GetService("UserInputService"):GetFocusedTextBox() then
                    ezmd.HideInNearestCloset()                    
                end
        
            end)
            rconsoleprint("@@DARK_GRAY@@")
        end
        
        if (ezmd.configs.CatchUpKey) then
            rconsoleprint("@@LIGHT_GREEN@@")
            ezmd.log("Catch up key is active. Press G to teleport to the player in the latest room.")
            game:GetService("UserInputService").InputBegan:Connect(function(kc) 
                
                if kc.KeyCode == Enum.KeyCode.G and not game:GetService("UserInputService"):GetFocusedTextBox() then
                    ezmd.CatchUp()
                end
                
            end)
            rconsoleprint("@@DARK_GRAY@@")
        end
        
        if (ezmd.configs.SubtleSpeedBoost) then
            rconsoleprint("@@YELLOW@@")
            ezmd.log(ezmd.configs.SpeedBoost and "SubtleSpeedBoost is active - speed will only be boosted by 4ws." or "[WARN!] SubtleSpeedBoost is active, but SpeedBoost is not. No speed boost will be applied.")
            rconsoleprint("@@DARK_GRAY@@")
        end
        
        -- reinject
        
        ezmd.reinject_on_rejoin()
    end
else
    ezmd.title()
    rconsoleprint(" EZMD is deactivated but will reinject when you join a game.")
    rconsoleprint("@@DARK_GRAY@@")
    ezmd.reinject_on_rejoin()
    ezmd.log("Loading configs...")
    ezmd.load_configs()
    rconsoleprint("@@LIGHT_GRAY@@")
    ezmd.log("--------------------------------")
    rconsoleprint("@@DARK_GRAY@@")
    ezmd.log("Press Enter to change settings.")
    
    -- secrets, i don't care about this code much lol this is mostly just for fun
    
    local keys = {}
    for x,v in pairs(ezmd.configs) do
        table.insert(keys,x)        
    end
    
    if (isfile("ghostbuster.mp3") and not table.find(keys,"GhostbusterMode")) then ezmd.log("Ghostbuster Mode unlocked!");v = "GhostbusterMode"; ezmd.configs[v] = not ezmd.configs[v]; ezmd.log(v.." is now "..ezmd.b2eng(ezmd.configs[v])); writefile("ezmd_cfg.json",ezmd.encode(ezmd.configs)); delfile("ghostbuster.mp3") end
    if (isfile("closeted.txt")) then
        if (not table.find(keys,"Yassify")) then ezmd.log("Yassify unlocked!");v = "Yassify"; ezmd.configs[v] = not ezmd.configs[v]; ezmd.log(v.." is now "..ezmd.b2eng(ezmd.configs[v])); writefile("ezmd_cfg.json",ezmd.encode(ezmd.configs)); end
        if (not table.find(keys,"Gay")) then ezmd.log("Gay mode unlocked!");v = "Gay"; ezmd.configs[v] = not ezmd.configs[v]; ezmd.log(v.." is now "..ezmd.b2eng(ezmd.configs[v])); writefile("ezmd_cfg.json",ezmd.encode(ezmd.configs)); end
        -- the username check here is only to f**k with my friend, remind me to remove this if you're seeing this kthxbye
        if (not table.find(keys,"Horny")) then ezmd.log("Horny mode unlocked!");v = "Horny"; ezmd.configs[v] = ezmd.owner.Name == "VelosDayAtDisneyland"; ezmd.log(v.." is now "..ezmd.b2eng(ezmd.configs[v])); writefile("ezmd_cfg.json",ezmd.encode(ezmd.configs)); end
        delfile("closeted.txt")
    end
    
    rconsoleinput()
    while true do
        ezmd.title()
        ezmd.settings()        
    end
end
