local RSGCore = exports['rsg-core']:GetCoreObject()
local lib = exports.ox_lib
local missionActive = false
local wagon, passengers, dropoffBlip = nil, {}, nil
local DropoffPrompts, PromptGroups = {}, {}
local SpawnPrompts, SpawnPromptGroups = {}, {} -- Tables for spawn prompts
local SpawnBlips = {} -- Table for spawn location blips
local passengerData = {} -- Tracks each passenger's drop-off location
local noNPCTimeout = 0 -- For fallback spawning
local processedNPCs = {} -- Track NPCs we've already processed to avoid duplicates
local dropoffAssignmentCounts = {}
local hasExitedWagon = true -- Track if player has exited wagon since last drop-off
local smoking = false -- Track smoking animation state
local cursedActive = false -- Assume mod-specific flag, initialize as false
local cigarProp = nil -- Track cigar prop for cleanup

-- Notification cooldown system
local notificationCooldowns = {}
local NOTIFICATION_COOLDOWN_TIME = 5000 -- 5 seconds cooldown

-- Enhanced notification function with cooldown
local function Notify(msg, type, cooldownKey)
    -- If cooldownKey is provided, check for cooldown
    if cooldownKey then
        local currentTime = GetGameTimer()
        if notificationCooldowns[cooldownKey] and (currentTime - notificationCooldowns[cooldownKey]) < NOTIFICATION_COOLDOWN_TIME then
            return -- Skip notification if still in cooldown
        end
        notificationCooldowns[cooldownKey] = currentTime
    end
    
    if lib then
        lib:notify({
            title = 'Passenger Transport',
            description = msg,
            type = type or 'success',
            duration = 4000,
            position = 'top-centre'
        })
    else
        -- Fallback to RSGCore if ox_lib is not available
        pcall(function() RSGCore.Functions.Notify(msg, type or 'success') end)
    end
end

-- Validate coordinates
local function AreCoordsValid(c)
    return c and type(c) == 'vector3' and (math.abs(c.x) <= 10000 and math.abs(c.y) <= 10000 and math.abs(c.z) <= 1000)
end

function ResetMissionState()
    if dropoffBlip and DoesBlipExist(dropoffBlip) then
        RemoveBlip(dropoffBlip)
        dropoffBlip = nil
    end
    if Config.ShowGPS then
        ClearGpsMultiRoute()
        SetGpsMultiRouteRender(false)
    end
    dropoffAssignmentCounts = {}
    noNPCTimeout = 0 -- Reset the timeout to allow immediate spawning
end

-- Create prompt
local function CreatePrompt(name, key, holdDuration)
    local prompt = PromptRegisterBegin()
    PromptSetControlAction(prompt, RSGCore.Shared.Keybinds[key] or 0xF3830D8E) -- Space key
    PromptSetText(prompt, CreateVarString(10, 'LITERAL_STRING', name))
    PromptSetEnabled(prompt, true)
    PromptSetVisible(prompt, true)
    PromptSetHoldMode(prompt, holdDuration or 1000)
    local group = GetRandomIntInRange(0, 0xffffff)
    PromptSetGroup(prompt, group)
    PromptRegisterEnd(prompt)
    return prompt, group
end

-- Initialize prompts and blips for drop-offs and spawn locations
Citizen.CreateThread(function()
    if not Config.EnablePassengerTransport then
        return
    end
    -- Drop-off prompts
    for i, dropoff in ipairs(Config.Dropoffs) do
        DropoffPrompts[i], PromptGroups[i] = CreatePrompt("Drop Off Passenger", "Space", 1000)
    end
    -- Spawn prompts and blips
    for i, spawn in ipairs(Config.SpawnLocations) do
        SpawnPrompts[i], SpawnPromptGroups[i] = CreatePrompt(spawn.PromptLabel, "Space", 1000)
        if AreCoordsValid(spawn.PromptCoords) then
            local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, spawn.PromptCoords.x, spawn.PromptCoords.y, spawn.PromptCoords.z)
            SetBlipSprite(blip, spawn.Blip.Sprite)
            BlipAddModifier(blip, spawn.Blip.ColorModifier)
            Citizen.InvokeNative(0x9CB1A1623062F402, blip, spawn.Blip.Label)
            Citizen.InvokeNative(0xD3A0DAFBF374FDB1, blip, spawn.Blip.Scale)
            if spawn.Blip.ShortRange then
                Citizen.InvokeNative(0xB7C6D71F8B188BC4, blip, true)
            end
            SpawnBlips[i] = blip
        end
    end
end)

-- Register context menu for manual drop-off
Citizen.CreateThread(function()
    if not Config.EnablePassengerTransport then return end
    if lib then
        lib:registerContext({
            id = 'passenger_dropoff_menu',
            title = 'Passenger Drop-Off',
            options = {
                {
                    title = 'Drop Off Passengers',
                    onSelect = function()
                        DropOffPassengers(nil, true) -- Manual drop-off for all passengers
                        Notify('Passengers dropped off manually!', 'success', 'manual_dropoff')
                    end
                }
            }
        })
    else
        Notify('Error: ox_lib not loaded', 'error', 'lib_error')
    end
end)

-- Check if player has taxi job
local function HasTaxiJob()
    local playerData = RSGCore.Functions.GetPlayerData()
    return playerData and playerData.job and playerData.job.name == "taxi"
end

-- Check if wagon is nearly stationary
local function IsWagonStationary()
    if wagon and DoesEntityExist(wagon) then
        local speed = GetEntitySpeed(wagon) -- Returns speed in meters per second
        return speed < 1.0 -- Increased from 0.5 to 1.0 m/s
    end
    return false
end

-- Check if player is in a valid wagon
local function IsPlayerInValidWagon()
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        local vehicleModel = GetEntityModel(vehicle)
        for _, model in ipairs(Config.AllowedWagonModels) do
            if vehicleModel == GetHashKey(model) then
                wagon = vehicle
                return true
            end
        end
    end
    return false
end

-- Get available seats
local function GetAvailableSeats()
    local availableSeats = {}
    if wagon and DoesEntityExist(wagon) then
        for _, seatIndex in ipairs({3, 4, 5, 10, 11, 12}) do
            if IsVehicleSeatFree(wagon, seatIndex) then
                table.insert(availableSeats, seatIndex)
            end
        end
    end
    return availableSeats
end

-- Spawn passenger near wagon
local function SpawnPassengerNearWagon(wagonCoords)
    local models = {
        "a_m_m_valtownfolk_01",
        "a_f_m_valtownfolk_01",
        "a_m_m_valtownfolk_02",
        "a_f_m_valtownfolk_02"
    }
    local model = GetHashKey(models[math.random(#models)])
    RequestModel(model)
    local timeout = GetGameTimer() + 1000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do
        Wait(100)
    end
    if HasModelLoaded(model) then
        if not Config.PassengerPickupRadius or type(Config.PassengerPickupRadius) ~= "number" or Config.PassengerPickupRadius <= 0 then
            Config.PassengerPickupRadius = 15.0
        end
        local spawnRadius = math.floor(Config.PassengerPickupRadius * 0.5)
        local spawnOffset = {
            x = math.random(-spawnRadius, spawnRadius),
            y = math.random(-spawnRadius, spawnRadius),
            z = 0
        }
        local spawnCoords = vector3(
            wagonCoords.x + spawnOffset.x,
            wagonCoords.y + spawnOffset.y,
            wagonCoords.z + spawnOffset.z
        )
        local found, groundZ = GetGroundZFor_3dCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z + 10.0)
        if found then
            spawnCoords = vector3(spawnCoords.x, spawnCoords.y, groundZ)
        end
        local ped = CreatePed(model, spawnCoords.x, spawnCoords.y, spawnCoords.z, 0.0, true, false)
        if DoesEntityExist(ped) then
            SetModelAsNoLongerNeeded(model)
            TaskStandStill(ped, -1)
            return ped
        end
    end
    return nil
end

-- Find nearby passenger
local function FindNearbyPassenger(wagonCoords)
    local searchRadius = Config.PassengerPickupRadius or 35.0
    local peds = {}
    local playerPed = PlayerPedId()
    local found, ped = GetClosestPed(wagonCoords.x, wagonCoords.y, wagonCoords.z, searchRadius, true, true, true, true, -1)
    if found and DoesEntityExist(ped) and ped ~= playerPed then
        if IsPedHuman(ped) and not IsPedDeadOrDying(ped, true) and not IsPedInCombat(ped, playerPed) and
           not IsPedInAnyVehicle(ped, true) and not IsEntityAMissionEntity(ped) and not processedNPCs[ped] then
            return ped
        end
    end
    local pedPool = GetGamePool('CPed')
    for _, p in ipairs(pedPool) do
        if p ~= playerPed and DoesEntityExist(p) and #(GetEntityCoords(p) - wagonCoords) <= searchRadius then
            if IsPedHuman(p) and not IsPedDeadOrDying(p, true) and not IsPedInCombat(p, playerPed) and
               not IsPedInAnyVehicle(p, true) and not IsEntityAMissionEntity(p) and not processedNPCs[p] then
                table.insert(peds, p)
            end
        end
    end
    if #peds > 0 then
        local selectedPed = peds[math.random(#peds)]
        return selectedPed
    end
    local passenger = SpawnPassengerNearWagon(wagonCoords)
    if not passenger then
        Notify("No passengers available at this time!", "error", "no_passengers")
    end
    return passenger
end

-- Stop smoking animation
local function StopSmokingAnimation()
    if not smoking then return end
    local playerPed = PlayerPedId()
    smoking = false
    cursedActive = false
    ClearPedSecondaryTask(playerPed)
    if cigarProp and DoesEntityExist(cigarProp) then
        DeleteObject(cigarProp)
        cigarProp = nil
    end
    RemoveAnimDict("amb_rest@world_human_smoke_cigar@male_a@idle_b")
end

-- Start smoking animation
local function startSmokingAnimation()
    if smoking then return end
    local playerPed = PlayerPedId()
    
    -- Sound effect
    Citizen.InvokeNative(0xF6A7C08DF2E28B28, playerPed, 0, 1000.0, false)
    PlaySoundFrontend("Core_Full", "Consumption_Sounds", true, 0)
    
    local prop_name = 'P_CIGAR01X'
    local dict = 'amb_rest@world_human_smoke_cigar@male_a@idle_b'
    local anim = 'idle_d'
    local x, y, z = table.unpack(GetEntityCoords(playerPed, true))
    local prop = CreateObject(GetHashKey(prop_name), x, y, z + 0.2, true, true, true)
    local boneIndex = GetEntityBoneIndexByName(playerPed, 'SKEL_R_Finger12')
    
    if not IsEntityPlayingAnim(playerPed, dict, anim, 3) then
        local waiting = 0
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            waiting = waiting + 100
            Wait(100)
            if waiting > 5000 then
                Notify('Issue with animation loading', 'error', 'anim_error')
                break
            end
        end
        
        Wait(100)
        AttachEntityToEntity(prop, playerPed, boneIndex, 0.01, -0.00500, 0.01550, 0.024, 300.0, -40.0, true, true, false, true, 1, true)
        TaskPlayAnim(playerPed, dict, anim, 8.0, -8.0, 7000, 31, 0, true, 0, false, 0, false) -- 7000ms = 7 seconds
        
        smoking = true
        cursedActive = true
        cigarProp = prop
        
        Citizen.CreateThread(function()
            Wait(7000) -- Wait for exactly 7 seconds
            if smoking then
                StopSmokingAnimation()
            end
        end)
    end
end

-- Optimized version of BoardNPCIntoWagon function
local function BoardNPCIntoWagon(ped, seatIndex, dropoffIndex)
    local dropoff = Config.Dropoffs[dropoffIndex]
    local wagonCoords = GetEntityCoords(wagon)
    
    processedNPCs[ped] = true
    table.insert(passengers, ped)
    passengerData[ped] = { dropoffIndex = dropoffIndex, seatIndex = seatIndex }
    dropoffAssignmentCounts[dropoffIndex] = (dropoffAssignmentCounts[dropoffIndex] or 0) + 1
    
    Citizen.InvokeNative(0x283978A15512B2FE, ped, true) -- Set ped as mission entity
    ClearPedTasks(ped)
    
    -- Calculate door position
    local doorOffset
    if seatIndex == 3 or seatIndex == 4 or seatIndex == 5 then
        doorOffset = GetOffsetFromEntityInWorldCoords(wagon, 2.0, -1.0, 0.0)
    elseif seatIndex == 10 or seatIndex == 11 or seatIndex == 12 then
        doorOffset = GetOffsetFromEntityInWorldCoords(wagon, -2.0, -1.0, 0.0)
    else
        doorOffset = GetOffsetFromEntityInWorldCoords(wagon, 0.0, -3.0, 0.0)
    end
    
    -- Start pathfinding to door
    TaskGoToCoordAnyMeans(ped, doorOffset.x, doorOffset.y, doorOffset.z, 2.0, 0, false, 786603, 0) -- Increased speed to 2.0
    
    -- REMOVED: Wait(5000) - This was causing the main delay
    Notify('Passenger heading to wagon for seat ' .. seatIndex .. ', destined for ' .. dropoff.Name .. '!', 'info', 'passenger_boarding')
    
    Citizen.CreateThread(function()
        local boardingTimeout = GetGameTimer() + 12000 -- Reduced from 20000 to 12000
        local hasBoarded = false
        
        -- Wait for NPC to reach door (shorter timeout)
        while DoesEntityExist(ped) and DoesEntityExist(wagon) and
              #(GetEntityCoords(ped) - doorOffset) > 1.0 and -- Reduced precision from 0.5 to 1.0
              GetGameTimer() < boardingTimeout do
            Wait(100)
        end
        
        if DoesEntityExist(ped) and DoesEntityExist(wagon) then
            if IsVehicleSeatFree(wagon, seatIndex) then
                ClearPedTasks(ped)
                
                -- SIMPLIFIED: Skip door animation for faster boarding
                -- Just directly enter the vehicle
                TaskEnterVehicle(ped, wagon, 5000, seatIndex, 2.0, 1, 0) -- Reduced timeout and increased speed
                
                local enterTimeout = GetGameTimer() + 6000 -- Reduced from 10000 to 6000
                while DoesEntityExist(ped) and DoesEntityExist(wagon) and
                      not IsPedInVehicle(ped, wagon, false) and
                      GetGameTimer() < enterTimeout do
                    Wait(100)
                end
                
                -- Ensure NPC is in correct seat
                if IsPedInVehicle(ped, wagon, false) then
                    local currentSeat = -1
                    for i = -1, 11 do
                        if GetPedInVehicleSeat(wagon, i) == ped then
                            currentSeat = i
                            break
                        end
                    end
                    
                    if currentSeat ~= seatIndex then
                        -- Force warp if in wrong seat
                        ClearPedTasks(ped)
                        TaskWarpPedIntoVehicle(ped, wagon, seatIndex)
                    end
                    hasBoarded = true
                else
                    -- Force warp as fallback
                    ClearPedTasks(ped)
                    TaskWarpPedIntoVehicle(ped, wagon, seatIndex)
                    hasBoarded = true
                end
                
                -- Set up GPS and blips after successful boarding
                if hasBoarded then
                    if Config.ShowGPS then
                        StartGpsMultiRoute(joaat("COLOR_RED"), true, true)
                        AddPointToGpsMultiRoute(dropoff.Coords.x, dropoff.Coords.y, dropoff.Coords.z)
                        SetGpsMultiRouteRender(true)
                    else
                        SetNewWaypoint(dropoff.Coords.x, dropoff.Coords.y)
                    end
                    
                    dropoffBlip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, dropoff.Coords.x, dropoff.Coords.y, dropoff.Coords.z)
                    SetBlipSprite(dropoffBlip, Config.Blips.Dropoff.Sprite)
                    BlipAddModifier(dropoffBlip, Config.Blips.Dropoff.ColorModifier)
                    Citizen.InvokeNative(0x9CB1A1623062F402, dropoffBlip, Config.Blips.Dropoff.Label)
                    Citizen.InvokeNative(0xD3A0DAFBF374FDB1, dropoffBlip, Config.Blips.Dropoff.Scale)
                    
                    if Config.Blips.Dropoff.ShortRange then
                        Citizen.InvokeNative(0xB7C6D71F8B188BC4, dropoffBlip, true)
                    end
                    if Config.Blips.Dropoff.Flashing then
                        Citizen.InvokeNative(0x3E2F588AFD9B0FC7, dropoffBlip, true)
                    end
                end
            end
        end
        
        -- Cleanup if boarding failed
        if not hasBoarded and DoesEntityExist(ped) then
            for i, p in ipairs(passengers) do
                if p == ped then
                    table.remove(passengers, i)
                    break
                end
            end
            passengerData[ped] = nil
            processedNPCs[ped] = nil
            
            if not IsEntityAMissionEntity(ped) then
                ClearPedTasks(ped)
            else
                DeletePed(ped)
            end
            Notify('Passenger could not board!', 'error', 'boarding_failed')
        end
    end)
end

-- Try to spawn and board a new passenger
local function TrySpawnNewPassenger()
    if not missionActive or not IsPlayerInValidWagon() or not IsWagonStationary() then
        return
    end
    local wagonCoords = GetEntityCoords(wagon)
    local availableSeats = GetAvailableSeats()
    if #availableSeats > 0 and #passengers < Config.MaxPassengers then
        local availableDestinations = {}
        for i, dest in ipairs(Config.Dropoffs) do
            if AreCoordsValid(dest.Coords) and #(wagonCoords - dest.Coords) > Config.PassengerPickupRadius then
                table.insert(availableDestinations, i)
            end
        end
        if #availableDestinations > 0 then
            local passenger = FindNearbyPassenger(wagonCoords)
            if passenger then
                local destinationIndex = availableDestinations[math.random(#availableDestinations)]
                BoardNPCIntoWagon(passenger, availableSeats[1], destinationIndex)
            end
        else
            Notify("Drive further from drop-off points to pick up new passengers.", "warning", "too_close_dropoff")
        end
    end
end

-- Spawn taxi wagon
local function SpawnTaxiWagon(coords, heading)
    if not Config.EnablePassengerTransport then
        Notify("Passenger transport is disabled in the config.", "error", "transport_disabled")
        return false
    end
    if not HasTaxiJob() then
        Notify("You must be a taxi driver to spawn a taxi!", "error", "not_taxi_driver")
        return false
    end
    if IsPedInAnyVehicle(PlayerPedId(), false) then
        Notify("You are already in a vehicle!", "error", "already_in_vehicle")
        return false
    end
    if wagon and DoesEntityExist(wagon) then
        Notify("You already have an active taxi wagon! Please use or delete the existing one.", "error", "taxi_exists")
        return false
    end
    local playerPed = PlayerPedId()
    local model = GetHashKey("coach3_cutscene")
    RequestModel(model)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do
        Wait(100)
    end
    if HasModelLoaded(model) then
        local found, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 2.0)
        if found then
            coords = vector3(coords.x, coords.y, groundZ)
        end
        local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z, heading, true, false)
        if DoesEntityExist(vehicle) then
            SetEntityAsMissionEntity(vehicle, true, true)
            SetVehicleOnGroundProperly(vehicle)
            SetModelAsNoLongerNeeded(model)
            TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
            wagon = vehicle
            Notify("Taxi wagon spawned!", "success")
            return true
        else
            Notify("Failed to spawn taxi!", "error", "spawn_failed")
            SetModelAsNoLongerNeeded(model)
            return false
        end
    else
        Notify("Failed to load taxi model!", "error", "model_load_failed")
        return false
    end
end

-- Spawn prompt interaction thread
Citizen.CreateThread(function()
    if not Config.EnablePassengerTransport then return end
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local anyPromptShown = false

        for i, spawn in ipairs(Config.SpawnLocations) do
            if AreCoordsValid(spawn.PromptCoords) and #(playerCoords - spawn.PromptCoords) < 5.0 then
                anyPromptShown = true
                local promptName = CreateVarString(10, 'LITERAL_STRING', spawn.PromptLabel)
                PromptSetActiveGroupThisFrame(SpawnPromptGroups[i], promptName)
                PromptSetEnabled(SpawnPrompts[i], true)
                PromptSetVisible(SpawnPrompts[i], true)

                if PromptHasHoldModeCompleted(SpawnPrompts[i]) then
                    if SpawnTaxiWagon(spawn.WagonSpawnCoords, spawn.WagonHeading) then
                        Citizen.Wait(1000) -- Prevent rapid triggers
                    end
                end
            else
                PromptSetEnabled(SpawnPrompts[i], false)
                PromptSetVisible(SpawnPrompts[i], false)
            end
        end

        if not anyPromptShown then
            Citizen.Wait(500) -- Reduce CPU usage
        end
    end
end)

-- Prompt interaction thread with automatic drop-off
Citizen.CreateThread(function()
    if not Config.EnablePassengerTransport then return end
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local anyPromptShown = false

        if missionActive then
            for i, dropoff in ipairs(Config.Dropoffs) do
                for _, data in pairs(passengerData) do
                    if data.dropoffIndex == i and #(playerCoords - dropoff.Coords) < 15.0 then
                        anyPromptShown = true
                        local promptName = CreateVarString(10, 'LITERAL_STRING', "Drop Off Passenger")
                        PromptSetActiveGroupThisFrame(PromptGroups[i], promptName)
                        PromptSetEnabled(DropoffPrompts[i], true)
                        PromptSetVisible(DropoffPrompts[i], true)

                        -- Automatic drop-off if wagon is stationary
                        if IsWagonStationary() then
                            DropOffPassengers(i) -- Auto drop-off for passengers at this location
                            Citizen.Wait(1000) -- Prevent rapid triggers
                        -- Manual drop-off via prompt
                        elseif PromptHasHoldModeCompleted(DropoffPrompts[i]) then
                            lib:showContext('passenger_dropoff_menu')
                            Citizen.Wait(1000) -- Prevent rapid triggers
                        end
                    else
                        PromptSetEnabled(DropoffPrompts[i] or {}, false)
                        PromptSetVisible(DropoffPrompts[i] or {}, false)
                    end
                end
            end
        end

        if not anyPromptShown then
            Citizen.Wait(500) -- Reduce CPU usage
        end
    end
end)

-- Main passenger spawning and boarding thread
Citizen.CreateThread(function()
    if not Config.EnablePassengerTransport then
        Notify('Passenger transport mission is disabled.', 'error', 'transport_disabled')
        return
    end
    local wasInWagon = false
    while true do
        Wait(2000)
        if IsPlayerInValidWagon() and HasTaxiJob() then
            if not missionActive then
                missionActive = true
                hasExitedWagon = true -- Allow initial pickup when starting mission
            end
            -- Detect if player exited wagon since last check
            if not wasInWagon then
                hasExitedWagon = true
                wasInWagon = true
                StopSmokingAnimation() -- Stop smoking when re-entering wagon
            end
            if IsWagonStationary() and hasExitedWagon then
                TrySpawnNewPassenger()
            end
        else
            -- Player is not in wagon, mark as exited
            wasInWagon = false
            if missionActive then
                if not HasTaxiJob() then
                    FailMission('You are not a taxi driver!')
                else
                    FailMission('You left the wagon!')
                end
            end
        end
    end
end)

-- Drop off passengers
function DropOffPassengers(dropoffIndex, manual)
    if not passengers or #passengers == 0 then
        if manual then
            Notify('Error: No passengers to drop off!', 'error', 'no_passengers_dropoff')
        end
        return
    end
    local passengersToRemove = {}
    local playerPed = PlayerPedId()
    for i, passenger in ipairs(passengers) do
        if DoesEntityExist(passenger) and IsPedInVehicle(passenger, wagon, false) then
            local passengerDropoffIndex = passengerData[passenger].dropoffIndex
            if not dropoffIndex or passengerDropoffIndex == dropoffIndex then
                local dropoff = Config.Dropoffs[passengerDropoffIndex]
                if not dropoff then
                    return
                end
                TaskLeaveVehicle(passenger, wagon, 256)
                Citizen.CreateThread(function()
                    Wait(1500)
                    if DoesEntityExist(passenger) then
                        TaskGoToCoordAnyMeans(passenger, dropoff.DoorCoords.x, dropoff.DoorCoords.y, dropoff.DoorCoords.z,
                            1.0, 0, false, 786603, 0)
                        while DoesEntityExist(passenger) and
                              #(GetEntityCoords(passenger) - dropoff.DoorCoords) > 1.5 do
                            Wait(250)
                        end
                        if DoesEntityExist(passenger) then
                            DeletePed(passenger)
                            processedNPCs[passenger] = nil
                            Notify('Passenger dropped off!', 'success', 'passenger_dropped')
                            TriggerServerEvent('passengerTransport:rewardPlayer', dropoff.Name)
                            passengerData[passenger] = nil
                            table.insert(passengersToRemove, i)
                            -- Force player to exit wagon and start smoking
                            if IsPedInVehicle(playerPed, wagon, false) then
                                TaskLeaveVehicle(playerPed, wagon, 256) -- Eject player
                                Wait(1000) -- Wait for exit animation
                                startSmokingAnimation()
                            end
                        end
                    end
                end)
            end
        end
    end
    for i = #passengersToRemove, 1, -1 do
        table.remove(passengers, passengersToRemove[i])
    end
    if manual and #passengersToRemove == 0 then
        Notify('No passengers for this drop-off location!', 'warning', 'no_passengers_location')
    end
    -- Clean up previous blip
    if dropoffBlip and DoesBlipExist(dropoffBlip) then
        RemoveBlip(dropoffBlip)
        dropoffBlip = nil
    end
    if Config.ShowGPS then
        ClearGpsMultiRoute()
        SetGpsMultiRouteRender(false)
    end
    -- Require player to re-enter wagon before next pickup
    hasExitedWagon = false
    noNPCTimeout = 0
    dropoffAssignmentCounts = {}
end

-- Mission failure logic with cooldown
function FailMission(reason)
    Notify(reason, 'error', 'mission_fail')
    EndMission()
end

-- End mission
function EndMission()
    missionActive = false
    StopSmokingAnimation() -- Clean up smoking animation
    if dropoffBlip and DoesBlipExist(dropoffBlip) then RemoveBlip(dropoffBlip); dropoffBlip = nil end
    for _, passenger in ipairs(passengers) do
        if DoesEntityExist(passenger) then DeletePed(passenger) end
    end
    passengers = {}
    passengerData = {}
    processedNPCs = {}
    dropoffAssignmentCounts = {}
    hasExitedWagon = true -- Reset to allow new mission start
    if Config.ShowGPS then
        ClearGpsMultiRoute()
        SetGpsMultiRouteRender(false)
    end
    Notify('Passenger transport ended. Get back on wagon to resume.', 'info', 'mission_ended')
end

-- Mission monitoring thread with cooldowns
Citizen.CreateThread(function()
    if not Config.EnablePassengerTransport then return end
    while true do
        Wait(1000)
        if missionActive then
            if not HasTaxiJob() then
                FailMission('You are not a taxi driver!')
            elseif wagon and not DoesEntityExist(wagon) then
                FailMission('Wagon destroyed!')
            elseif IsPlayerDead(PlayerId()) then
                FailMission('You died!')
            end
        end
    end
end)

-- Command to delete taxi with cooldown
RegisterCommand("deletetaxi", function(source, args, rawCommand)
    if not Config.EnablePassengerTransport or not HasTaxiJob() then
        Notify("You must be a taxi driver to use this command!", "error", "delete_taxi_job")
        return
    end
    if wagon and DoesEntityExist(wagon) then
        DeleteVehicle(wagon)
        wagon = nil
        Notify("Taxi wagon deleted.", "success", "taxi_deleted")
    else
        Notify("No active taxi wagon to delete!", "error", "no_taxi_delete")
    end
end, false)

-- Register notification event
RegisterNetEvent('passengerTransport:notify')
AddEventHandler('passengerTransport:notify', function(msg, type)
    Notify(msg, type)
end)
