local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- CONFIGURATION
local FOV_LIMIT = 3 -- 10 degrees field of view limit

-- State tracking to maintain stable target parts and prevent jitter from random offsets
local lockedPlayer = nil
local lockedPartName = nil -- "Head" or "HumanoidRootPart"
local lockedOffset = Vector3.new(0, 0, 0)

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

-- Check if a position is within the 10-degree FOV from screen center
local function isInFOV(position)
    local cameraLook = Camera.CFrame.LookVector
    local direction = (position - Camera.CFrame.Position).Unit
    local dot = cameraLook:Dot(direction)
    local angle = math.deg(math.acos(math.clamp(dot, -1, 1)))
    return angle <= FOV_LIMIT
end

local function getTargetPosition()
    local closestTargetPos = nil
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
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                local humanoid = character:FindFirstChild("Humanoid")
                
                if head and rootPart and humanoid and humanoid.Health > 0 then
                    -- If already locked onto this player, keep their chosen part, otherwise evaluate head/root
                    local testPart = head
                    if lockedPlayer == player and lockedPartName then
                        testPart = character:FindFirstChild(lockedPartName) or head
                    end
                    
                    -- WALL / VISIBILITY & FOV CHECK
                    if isVisible(testPart, character) and isInFOV(testPart.Position) then
                        local localChar = LocalPlayer.Character
                        if localChar and localChar:FindFirstChild("HumanoidRootPart") then
                            local distance = (localChar.HumanoidRootPart.Position - testPart.Position).Magnitude
                            if distance < shortestDistance then
                                shortestDistance = distance
                                
                                -- Assign target and randomize part/offset if it's a new lock
                                if lockedPlayer ~= player then
                                    lockedPlayer = player
                                    -- 50 percent chance for Head or HumanoidRootPart
                                    lockedPartName = (math.random() < 0.5) and "Head" or "HumanoidRootPart"
                                    
                                    -- Random position offset around the part (randomized offsets across the region)
                                    lockedOffset = Vector3.new(
                                        math.random(-35, 35) / 100,
                                        math.random(-35, 35) / 100,
                                        math.random(-35, 35) / 100
                                    )
                                end
                                
                                local actualPart = character:FindFirstChild(lockedPartName)
                                if actualPart then
                                    closestTargetPos = actualPart.Position + lockedOffset
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Clear lock if no valid targets within FOV/visibility
    if not closestTargetPos then
        lockedPlayer = nil
        lockedPartName = nil
    end
    
    return closestTargetPos
end

-- Primary execution loop running at maximum engine frame rate
RunService.RenderStepped:Connect(function()
    -- Only run the aimbot if the player is holding down the Right Mouse Button (RMB)
    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        if LocalPlayer.Character then
            local targetPos = getTargetPosition()
            
            if targetPos then
                -- CAMERA LOCK ON (Only engages if target is visible and inside the 10-degree FOV)
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPos)
            end
        end
    else
        -- Reset lock when RMB is released
        lockedPlayer = nil
        lockedPartName = nil
    end
end)
