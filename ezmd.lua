rconsolename("ezmd, @split#1337")

local ezmd = {
    game_patch = tostring(game.PlaceVersion),
    decode = function(v) return game:GetService("HttpService"):JSONDecode(v) end,
    encode = function(v) return game:GetService("HttpService"):JSONEncode(v) end,
    configs = {
        SkipScreech = false,
    },
    b2eng = function(v) return v and "on" or "off" end,
}

function ezmd.reinject_on_rejoin()
    local ezmd = game:HttpGet("https://raw.githubusercontent.com/nbitzz/ezmd/main/ezmd.lua")
    syn.queue_on_teleport(ezmd)
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

function ezmd.log(txt)
    rconsoleprint("\n "..txt)
end

-- detect current game

if (game.PlaceId == 6839171747) then
    ezmd.title()
    rconsoleprint(" EZMD is loading...")
    rconsoleprint("@@DARK_GRAY@@")
    
    ezmd.log("Waiting for game to load...")
    if (not game:IsLoaded()) then
        game.Loaded:Wait()
    end
    
    -- loading procedure
    do 
        -- get game version
        
        local logHistory = game:GetService("LogService"):GetLogHistory()
        for x,v in pairs(logHistory) do
            if (v.message:sub(1,7) == "PATCH: ") then
                ezmd.game_patch = v.message:sub(8,v.message:len())            
            end
        end
        ezmd.log("Game version: "..ezmd.game_patch)  
        
        -- hooks
        
        ezmd.log("Making hooks...")
        
        -- reinject
        
        ezmd.reinject_on_rejoin()
    end
else
    ezmd.title()
    rconsoleprint(" EZMD is deactivated but will reinject when you join a game.")
    rconsoleprint("@@DARK_GRAY@@")
    ezmd.reinject_on_rejoin()
end
