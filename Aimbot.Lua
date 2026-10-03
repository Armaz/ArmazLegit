local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Teams = game:GetService("Teams")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- CONFIGURATION FOR HUMAN-LIKE MOVEMENT
local SMOOTHNESS = 0.15 -- Lower = smoother/slower turn speed (range 0.01 to 1.0)
local LOCK_THRESHOLD = 0.05 -- Distance threshold to consider "locked on"
local OSCILLATION_SPEED = 6 -- Speed of the up-and-down body/head movement
local OSCILLATION_HEIGHT = 1.2 -- Height range between chest and head (in studs)

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
    
    local ignoreList = {}
    if LocalPlayer.Character then
        table.insert(ignoreList, LocalPlayer.Character)
    end
    raycastParams.FilterDescendantsInstances = ignoreList
    
    local result = workspace:Raycast(origin, direction, raycastParams)
    if result then
        if result.Instance:IsDescendantOf(targetCharacter) then
            return true
        end
        return false
    end
    
    return true
end

local function getClosestPlayerPart()
    local closestPart = nil
    local shortestDistance = math.huge
    local teamsExist = areTeamsActive()
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local shouldTarget = true
            if teamsExist then
                if LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team then
                    shouldTarget = false
                end
                
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
                    if isVisible(head, character) then
                        local localChar = LocalPlayer.Character
                        if localChar and localChar:FindFirstChild("HumanoidRootPart") then
                            local distance = (localChar.HumanoidRootPart.Position - head.Position).Magnitude
                            if distance < shortestDistance then
                                shortestDistance = distance
                                closestPart = head
                            end
                        end
                    end
                end
            end
        end
    end
    return closestPart
end

-- Primary execution loop running at maximum engine frame rate
RunService.RenderStepped:Connect(function(dt)
    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        if LocalPlayer.Character then
            local targetHead = getClosestPlayerPart()
            
            if targetHead then
                -- Generate a dynamic up-and-down offset shifting between chest and head over time
                local verticalOffset = math.sin(tick() * OSCILLATION_SPEED) * (OSCILLATION_HEIGHT / 2)
                local dynamicTargetPosition = targetHead.Position + Vector3.new(0, verticalOffset - 0.3, 0)
                
                -- Compute target orientation
                local currentCFrame = Camera.CFrame
                local goalCFrame = CFrame.new(currentCFrame.Position, dynamicTargetPosition)
                
                -- Smoothly interpolate (lerp) toward the target to mimic human turning speed
                local smoothedCFrame = currentCFrame:Lerp(goalCFrame, math.clamp(SMOOTHNESS * (dt * 60), 0, 1))
                Camera.CFrame = smoothedCFrame
            end
        end
    end
end)
