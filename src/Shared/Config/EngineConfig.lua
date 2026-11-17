local EngineConfig = {}

EngineConfig.InteractionDistance = 32
EngineConfig.DamageCooldown = 0.18
EngineConfig.RepairCooldown = 0.18
EngineConfig.BuildCooldown = 0.6
EngineConfig.MaximumComponentsPerBuilding = 350
EngineConfig.IntegrityCheckBudget = 120
EngineConfig.ComponentUpdateBatchSize = 40
EngineConfig.CollapseDelay = 0.15
EngineConfig.RepairAmount = 24
EngineConfig.DamageAmount = 35
EngineConfig.MinimumDurability = 0
EngineConfig.MaximumDurability = 100
EngineConfig.SupportReachabilityRequired = true
EngineConfig.DetachedComponentTransparency = 0.12
EngineConfig.HighlightDuration = 0.22
EngineConfig.SelectionColor = Color3.fromRGB(90, 190, 255)
EngineConfig.DamageColor = Color3.fromRGB(255, 105, 75)
EngineConfig.RepairColor = Color3.fromRGB(105, 235, 150)
EngineConfig.BuildColor = Color3.fromRGB(125, 185, 255)
EngineConfig.DefaultComponentColor = Color3.fromRGB(163, 163, 163)
EngineConfig.SampleBuildingOrigin = Vector3.new(0, 5, 0)
EngineConfig.SampleBuildingName = "Workshop"

return table.freeze(EngineConfig)
