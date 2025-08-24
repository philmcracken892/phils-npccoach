Config = {}


Config.EnablePassengerTransport = true -- Set to false to disable the mission

-- Spawn Locations for Wagon
Config.SpawnLocations = {
    {
        Name = "Valentine Taxi Depot",
        PromptCoords = vector3(-215.23, 681.06, 113.63), 
        WagonSpawnCoords = vector3(-208.34, 684.56, 113.34), 
        WagonHeading = 180.0, 
        PromptLabel = "Spawn Taxi Wagon",
        Blip = {
            Sprite = 1012165077, 
            ColorModifier = joaat('BLIP_MODIFIER_MP_COLOR_4'), 
            Scale = 0.8,
            Label = "Taxi Depot",
            ShortRange = false
        }
    },
	{
        Name = "St Denis  Taxi Depot",
        PromptCoords = vector3(2520.44, -1353.93, 46.75), 
        WagonSpawnCoords = vector3(2527.97, -1353.30, 46.75), 
        WagonHeading = 180.0, 
        PromptLabel = "Spawn Taxi Wagon",
        Blip = {
            Sprite = 1012165077, 
            ColorModifier = joaat('BLIP_MODIFIER_MP_COLOR_4'), 
            Scale = 0.8,
            Label = "Taxi Depot",
            ShortRange = false
        }
    }
}

-- Drop-off Locations
Config.Dropoffs = {
    {
        Name = "Saint Denis Bank",
        Coords = vector3(2632.45, -1299.98, 51.92),
        DoorCoords = vector3(2637.17, -1299.29, 52.03),
        Reward = 10000 --100
    },
    {
        Name = "Rhodes bank",
        Coords = vector3(1299.07, -1294.42, 76.44),
        DoorCoords = vector3(1294.92, -1299.14, 77.04),
        Reward = 15000 --150
    },
    {
        Name = "Blackwater sheriffs",
        Coords = vector3(-750.73, -1266.74, 43.27),
        DoorCoords = vector3(-758.51, -1269.33, 44.04),
        Reward = 8000  --$80
    },
    {
        Name = "Valentine gunstore",
        Coords = vector3(-274.73, 795.13, 118.67),
        DoorCoords = vector3(-283.06, 784.20, 119.50),
        Reward = 8000-- $80
    },
    {
        Name = "Strawberry postoffice",
        Coords = vector3(-1772.71, -388.49, 156.71),
        DoorCoords = vector3(-1768.03, -382.60, 157.74),
        Reward = 8000 --$80
    },
    {
        Name = "Armadillo saloon",
        Coords = vector3(-3709.32, -2607.53, -13.53),
        DoorCoords = vector3(-3706.85, -2599.44, -13.32),
        Reward = 8000-- $80
    },
	{
        Name = "Starwberry post office",
        Coords = vector3(-1771.45, -389.99, 156.61),
        DoorCoords = vector3(-1768.56, -383.20, 157.75),
        Reward = 8000 --$80
    },
	{
        Name = "Flatneck station",
        Coords = vector3(-354.25, -367.84, 86.47),
        DoorCoords = vector3(-339.73, -362.10, 88.02),
        Reward = 8000 --$80
    }
}

Config.AllowedWagonModels = {
    "coach3_cutscene",
}

Config.PassengerPickupRadius = 35.0 
Config.MaxPassengers = 1 
Config.ShowGPS = true 
Config.Debug = false 

Config.TaxiBlip = {
    Scale = 0.8,
    ColorModifier = joaat('BLIP_MODIFIER_MP_COLOR_10'), 
    ShortRange = false,
    Label = "Coach Service",
    Sprite = 1012165077
}

Config.Blips = {
    Dropoff = {
        Sprite = 1012165077,
        ColorModifier = joaat('BLIP_MODIFIER_MP_COLOR_2'), 
        Scale = 1.0,
        Label = "Passenger Drop-Off",
        ShortRange = true,
        Flashing = true
    }
}
