rconsolename("ezmd, @split#1337")

if not syn then
    syn = {
        request = function(tab)
            return {Body=game:HttpGet(tab.Url)}    
        end
    }    
end

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
        RoomSkipKey=false,
        MultiSkipIfDoorLocked=false,
        HideKey=false
        --[[
        DeathTrolls=false,
        Troll_DisableDrawers=false,
        ]]
    },
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
        			local highlight = Instance.new("Highlight",v.LiveHintBook)
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
            if (nearestHideable) then
                if (ezmd.Util_GetDistance(nearestHideable.PrimaryPart)-ezmd.Util_GetDistance(v.PrimaryPart)) > 0 then
                    nearestHideable = v
                end
            else
                nearestHideable = v
            end
        end
        
        -- hide!
        
        ezmd.owner.Character:PivotTo(nearestHideable.PrimaryPart.CFrame)
        task.delay(0.1, function()
            fireproximityprompt(nearestHideable:FindFirstChild("HidePrompt"))
        end)
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
        
        -- on room changed
        
        task.spawn(function()
            ezmd.stats.Knobs:WaitForChild("Rooms Survived").Changed:Connect(function(v) 
                for x,v in pairs(ezmd.cleanupOnRoomPass) do
                    if (v) then
                        v:Destroy()                    
                    end
                end
                ezmd.cleanupOnRoomPass = {}
                
                ezmd.HighlightLoot()
                if (v == 50) then
                    ezmd.LibraryHighlight()                
                end
                
                local currentRoom = workspace.CurrentRooms[ezmd.gamedata.LatestRoom.Value]
                
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
                ezmd.owner.Character:WaitForChild("Humanoid").WalkSpeed = ezmd.owner.Character:WaitForChild("Humanoid").WalkSpeed + 8
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
    rconsoleinput()
    while true do
        ezmd.title()
        ezmd.settings()        
    end
end
