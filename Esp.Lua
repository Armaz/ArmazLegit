local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

local LocalPlayer = Players.LocalPlayer

-- SETTINGS
local WALK_SPEED = 24

-- Helper function to determine if teams are active in the game
local function areTeamsActive()
    local teamList = Teams:GetTeams()
    return #teamList > 0
end

-- Uses your exact team-checking logic to determine highlight colors
local function getTeamColor(player)
    local teamsExist = areTeamsActive()
    
    if teamsExist then
        -- 1. EXCLUSION CHECK: Lobby or Neutral teams are Gray
        if player.Team then
            local teamName = player.Team.Name
            if teamName == "Lobby" or teamName == "Neutral" then
                return Color3.fromRGB(128, 128, 128) -- Gray
            end
        end
        
        -- 2. TEAM CHECK: Check if target is on your team (Green)
        if LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team then
            return Color3.fromRGB(0, 255, 0) -- Green
        end
    end
    
    -- 3. DEFAULT/OPPOSING: Everyone else is Red
    return Color3.fromRGB(255, 0, 0) -- Red
end

local function addOrUpdateHighlight(player, character)
    if not character then return end

    local highlight = character:FindFirstChild("GlobalHighlight")
    
    -- Create highlight if it doesn't exist
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "GlobalHighlight"
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.5
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = character
    end

    -- Apply color based on team logic
    highlight.FillColor = getTeamColor(player)
end

local function setupCharacter(player, character)
    local humanoid = character:WaitForChild("Humanoid")

    -- Speed boost
    humanoid.WalkSpeed = WALK_SPEED

    -- Add or update the colored ESP highlight
    addOrUpdateHighlight(player, character)
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        setupCharacter(player, character)
    end)

    -- If already spawned
    if player.Character then
        setupCharacter(player, player.Character)
    end
end)

-- Handle existing players
for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then
        setupCharacter(player, player.Character)
    end
    player.CharacterAdded:Connect(function(char)
        setupCharacter(player, char)
    end)
end
