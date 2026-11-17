export type ComponentType = "Foundation" | "Pillar" | "Beam" | "Wall" | "Floor" | "Roof"

export type ComponentState = {
    Id: string,
    Type: ComponentType,
    Instance: BasePart,
    Durability: number,
    MaximumDurability: number,
    Weight: number,
    IsSupport: boolean,
    IsGrounded: boolean,
    IsDetached: boolean,
    Connections: {[string]: boolean},
    BuildingId: string,
}

export type BuildingState = {
    Id: string,
    Name: string,
    Model: Model,
    Components: {[string]: ComponentState},
    ComponentCount: number,
    Revision: number,
    IsProcessing: boolean,
}

return {}
