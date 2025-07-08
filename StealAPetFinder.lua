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

-- Find all matching mesh models
local foundModels = {}
for _, pet in ipairs(standPetsFolder:GetChildren()) do
    local main = pet:FindFirstChild("Main")
    if main then
        local mesh = main:FindFirstChild("Mesh")
        if mesh and mesh:IsA("SpecialMesh") and mesh.MeshId == targetMeshId then
            table.insert(foundModels, pet)
        end
    end
end

-- Notify player of results
local count = #foundModels
if count == 0 then
    NotificationCmds.Message.Bottom({
        Message = "No mesh was found",
        Color = Color3.fromRGB(255, 50, 50)
    })
    return
end

NotificationCmds.Message.Bottom({
    Message = count .. "x mesh" .. (count > 1 and "es were" or " was") .. " found",
    Color = Color3.fromRGB(0, 255, 0)
})

-- Find closest model to player
local closestModel = nil
local closestDist = math.huge
local rootPos = rootPart.Position

for _, model in ipairs(foundModels) do
    local primaryPart = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
    if primaryPart then
        local dist = (primaryPart.Position - rootPos).Magnitude
        if dist < closestDist then
            closestDist = dist
            closestModel = model
        end
    end
end

if not closestModel then
    warn("Closest model has no valid primary part")
    return
end

-- Find closest special point to the closest model
local closestSpecialPoint = nil
local closestPointDist = math.huge
local closestPrimaryPart = closestModel.PrimaryPart or closestModel:FindFirstChild("HumanoidRootPart") or closestModel:FindFirstChildWhichIsA("BasePart")
local closestModelPos = closestPrimaryPart and closestPrimaryPart.Position or closestModel:GetModelCFrame().p

for _, point in ipairs(specialPoints) do
    local dist = (closestModelPos - point).Magnitude
    if dist < closestPointDist then
        closestPointDist = dist
        closestSpecialPoint = point
    end
end

local destination = closestSpecialPoint or Vector3.new(4.608, 0.794, 1129.493) -- fallback

-- Pathfinding to destination
local path = PathfindingService:CreatePath()
path:ComputeAsync(rootPos, destination)

if path.Status == Enum.PathStatus.Success then
    local waypoints = path:GetWaypoints()
    for _, waypoint in ipairs(waypoints) do
        humanoid:MoveTo(waypoint.Position)
        local reached = humanoid.MoveToFinished:Wait()
        if not reached then
            break
        end
    end
else
    warn("Pathfinding failed: " .. tostring(path.Status))
end

-- Add local-only Highlight to closest model
do
    local existingHighlight = closestModel:FindFirstChildWhichIsA("Highlight")
    if existingHighlight then
        existingHighlight:Destroy()
    end

    local highlight = Instance.new("Highlight")
    highlight.Adornee = closestModel
    highlight.FillColor = Color3.fromRGB(0, 255, 0)
    highlight.OutlineColor = Color3.fromRGB(0, 150, 0)
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = true
    highlight.Parent = workspace -- local script: only local player sees this highlight
end
