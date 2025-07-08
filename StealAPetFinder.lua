local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local standPetsFolder = workspace:WaitForChild("__THINGS"):WaitForChild("StandPets")
local targetMeshId = "rbxassetid://7774443834"

local NotificationCmds = require(ReplicatedStorage.Library.Client.NotificationCmds)

local specialPoints = {
    Vector3.new(-182.728, 0.794, 1213.844),
    Vector3.new(-49.682, 0.794, 1213.295),
    Vector3.new(88.978, 0.794, 1213.764),
    Vector3.new(221.831, 0.794, 1212.925),
    Vector3.new(219.318, 0.794, 1086.552),
    Vector3.new(86.112, 0.794, 1086.1),
    Vector3.new(-51.749, 0.794, 1086.564),
    Vector3.new(-185.072, 0.794, 1086.936),
}

-- Find all models where a child SpecialMesh with targetMeshId exists
local foundEntries = {}
for _, pet in ipairs(standPetsFolder:GetChildren()) do
    local main = pet:FindFirstChild("Main")
    if main then
        local mesh = main:FindFirstChild("Mesh")
        if mesh and mesh:IsA("SpecialMesh") and mesh.MeshId == targetMeshId then
            if main:IsA("BasePart") then
                table.insert(foundEntries, {Model = pet, HighlightPart = main})

                -- Create bright local highlight for this part
                local highlight = Instance.new("Highlight")
                highlight.Adornee = main
                highlight.FillColor = Color3.fromRGB(0, 255, 255)        -- Neon cyan
                highlight.OutlineColor = Color3.fromRGB(255, 255, 0)     -- Bright yellow outline
                highlight.FillTransparency = 0.15                        -- Slight glow
                highlight.OutlineTransparency = 0                        -- Solid outline
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Enabled = true
                highlight.Parent = workspace -- Local only highlight
            end
        end
    end
end

local count = #foundEntries

-- Kick player if none found
if count == 0 then
    player:Kick("Required pet mesh not found in the world. You have been kicked.")
    return
end

-- Notify how many were found
NotificationCmds.Message.Bottom({
    Message = count .. " mesh" .. (count > 1 and "es" or "") .. " found and highlighted.",
    Color = Color3.fromRGB(0, 255, 0)
})

-- Find the closest highlight part
local closestEntry = nil
local closestDist = math.huge
local rootPos = rootPart.Position

for _, entry in ipairs(foundEntries) do
    local part = entry.HighlightPart
    local dist = (part.Position - rootPos).Magnitude
    if dist < closestDist then
        closestDist = dist
        closestEntry = entry
    end
end

if not closestEntry then
    warn("No valid BasePart to walk to.")
    return
end

local closestPart = closestEntry.HighlightPart

-- Find closest special point to the mesh
local closestSpecialPoint = nil
local closestPointDist = math.huge
for _, point in ipairs(specialPoints) do
    local dist = (closestPart.Position - point).Magnitude
    if dist < closestPointDist then
        closestPointDist = dist
        closestSpecialPoint = point
    end
end

local destination = closestSpecialPoint or Vector3.new(4.608, 0.794, 1129.493)

-- Walk to it
local path = PathfindingService:CreatePath()
path:ComputeAsync(rootPos, destination)

if path.Status == Enum.PathStatus.Success then
    for _, waypoint in ipairs(path:GetWaypoints()) do
        humanoid:MoveTo(waypoint.Position)
        local reached = humanoid.MoveToFinished:Wait()
        if not reached then
            break
        end
    end
else
    warn("Pathfinding failed: " .. tostring(path.Status))
end
