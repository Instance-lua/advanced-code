local ComponentConfig = {}

ComponentConfig.Definitions = {
    Foundation = {
        MaximumDurability = 180,
        Weight = 5,
        IsSupport = true,
        CanCollapse = false,
        Material = Enum.Material.Concrete,
        Color = Color3.fromRGB(105, 105, 110),
    },
    Pillar = {
        MaximumDurability = 125,
        Weight = 3,
        IsSupport = true,
        CanCollapse = true,
        Material = Enum.Material.Metal,
        Color = Color3.fromRGB(120, 135, 150),
    },
    Beam = {
        MaximumDurability = 100,
        Weight = 2,
        IsSupport = false,
        CanCollapse = true,
        Material = Enum.Material.Wood,
        Color = Color3.fromRGB(142, 103, 70),
    },
    Wall = {
        MaximumDurability = 75,
        Weight = 2,
        IsSupport = false,
        CanCollapse = true,
        Material = Enum.Material.Brick,
        Color = Color3.fromRGB(166, 126, 105),
    },
    Floor = {
        MaximumDurability = 90,
        Weight = 3,
        IsSupport = false,
        CanCollapse = true,
        Material = Enum.Material.WoodPlanks,
        Color = Color3.fromRGB(174, 143, 105),
    },
    Roof = {
        MaximumDurability = 65,
        Weight = 2,
        IsSupport = false,
        CanCollapse = true,
        Material = Enum.Material.Slate,
        Color = Color3.fromRGB(80, 91, 110),
    },
}

function ComponentConfig.GetDefinition(componentType)
    return ComponentConfig.Definitions[componentType]
end

function ComponentConfig.IsValid(componentType)
    return ComponentConfig.GetDefinition(componentType) ~= nil
end

return table.freeze(ComponentConfig)
