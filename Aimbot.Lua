local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Helper function to determine if teams are active in the game
local function areTeamsActive()
    local teamList = Teams:GetTeams()
    return #teamList > 0
end

-- Visibility / Line of sight check using Raycasting
local function isVisible(targetPart, targetCharacter)
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true
    
    -- Exclude local player from raycast collision checking
    local ignoreList = {}
    if LocalPlayer.Character then
        table.insert(ignoreList, LocalPlayer.Character)
    end
    raycastParams.FilterDescendantsInstances = ignoreList
    
    local result = workspace:Raycast(origin, direction, raycastParams)
    if result then
        -- If the ray hits a part belonging to the target character, they are visible
        if result.Instance:IsDescendantOf(targetCharacter) then
            return true
        end
        return false
    end
    
    -- If nothing was hit between camera and target, it's clear
    return true
end

local function getClosestPlayerHead()
    local closestHead = nil
    local shortestDistance = math.huge
    local teamsExist = areTeamsActive()
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            
            -- DYNAMIC TEAM CHECK
            local shouldTarget = true
            if teamsExist then
                -- Check if target is on your team
                if LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team then
                    shouldTarget = false
                end
                
                -- EXCLUSION CHECK: Ignore players on teams named "Lobby" or "Neutral"
                if player.Team then
                    local teamName = player.Team.Name
                    if teamName == "Lobby" or teamName == "Neutral" then
                        shouldTarget = false
                    end
                end
            end
            
            if shouldTarget then
                local character = player.Character
                local head = character:FindFirstChild("Head")
                local humanoid = character:FindFirstChild("Humanoid")
                
                if head and humanoid and humanoid.Health > 0 then
                    -- WALL / VISIBILITY CHECK: Ensure target has a clear line of sight
                    if isVisible(head, character) then
                        local localChar = LocalPlayer.Character
                        if localChar and localChar:FindFirstChild("HumanoidRootPart") then
                            local distance = (localChar.HumanoidRootPart.Position - head.Position).Magnitude
                            if distance < shortestDistance then
                                shortestDistance = distance
                                closestHead = head
                            end
                        end
                    end
                end
            end
        end
    end
    return closestHead
end

-- Primary execution loop running at maximum engine frame rate
RunService.RenderStepped:Connect(function()
    -- Only run the aimbot if the player is holding down the Right Mouse Button (RMB)
    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        if LocalPlayer.Character then
            local targetHead = getClosestPlayerHead()
            
            if targetHead then
                -- CAMERA LOCK ON (Only engages if the target is visible)
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetHead.Position)
                -- (Triggerbot functions and accuracy checks have been fully removed)
            end
        end
    end
end)
