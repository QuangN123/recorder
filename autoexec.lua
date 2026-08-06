local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteFunction = ReplicatedStorage:WaitForChild("RemoteFunction")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local LOBBY_PLACE_ID = 3260590327
local ME_NAME = "LucasLiorLE"
local TARGET_NAME = "mibam00"

local function waitLoaded()
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end

    local lp = LocalPlayer
    if not lp then
        lp = Players.PlayerAdded:Wait()
    end
    repeat task.wait(0.5) until lp:FindFirstChild("PlayerGui")
    return lp
end

local function tryInviteLoop()
    pcall(function()
        RemoteFunction:InvokeServer("Party", "CreateParty")
    end)

    while true do
        local targetPlayer = Players:FindFirstChild(TARGET_NAME)
        local arg = targetPlayer or TARGET_NAME
        local ok, res = pcall(function()
            return RemoteFunction:InvokeServer("Party", "InvitePlayer", arg)
        end)
        if ok and res then
            print("Invite sent/accepted result:", res)
            return true
        end
        task.wait(0.8 + math.random() * 0.4)
    end
end

local function tryAcceptLoop()
    while true do
        local inviter = Players:FindFirstChild(ME_NAME) or ME_NAME
        local ok, res = pcall(function()
            return RemoteFunction:InvokeServer("Party", "AcceptInvite", inviter)
        end)
        if ok and res then
            print("Accepted invite from", ME_NAME)
            return true
        end
        task.wait(0.8)
    end
end

local function startMultiplayer()
    local payload = {
        difficulty = "Frost",
        mode = "survival",
        count = 2,
    }
    pcall(function()
        RemoteFunction:InvokeServer("Multiplayer", "v2:start", payload)
    end)
end

task.spawn(function()
    if game.PlaceId ~= LOBBY_PLACE_ID then return end
    local lp = waitLoaded()
    if not lp then return end

    if lp.Name == ME_NAME then
        -- host: create party and keep inviting until the target is present, then start multiplayer
        local invited = tryInviteLoop()
        if invited then
            repeat
                task.wait(0.5)
            until Players:FindFirstChild(TARGET_NAME)
            task.wait(1)
            startMultiplayer()
        end
    elseif lp.Name == TARGET_NAME then
        -- target: accept invites when available
        tryAcceptLoop()
    end
end)

-- If we're not in the lobby, load the main loader script
-- If we're not in the lobby, load a player-specific script
if game.PlaceId ~= LOBBY_PLACE_ID then
    local url
    if LocalPlayer and LocalPlayer.Name == ME_NAME then
        url = "https://raw.githubusercontent.com/QuangN123/recorder/refs/heads/main/p1.lua"
    elseif LocalPlayer and LocalPlayer.Name == TARGET_NAME then
        url = "https://raw.githubusercontent.com/QuangN123/recorder/refs/heads/main/p2.lua"
    else
        url = "https://raw.githubusercontent.com/QuangN123/recorder/refs/heads/main/loader.lua"
    end

    if url then
        local ok, code = pcall(function() return game:HttpGet(url) end)
        if ok and code then
            local func = loadstring(code)
            if func then pcall(func) end
        end
    end
end

