local Config = load(LoadResourceFile(GetCurrentResourceName(), "config/shared.lua"))()

AddEventHandler('Tow:Client:RequestJob', function()
    plsr.Callbacks:ServerCallback('Tow:RequestJob', {}, function(success)
        if success then
            plsr.Notification:Success('You are Now Employed at Tow Yard', 5000, 'truck-pickup')
        else
            plsr.Notification:Error('Employement Request Failed', 5000, 'truck-pickup')
        end
    end)
end)

AddEventHandler('Tow:Client:QuitJob', function()
    plsr.Callbacks:ServerCallback('Tow:QuitJob', {}, function(success)
        if not success then
            plsr.Notification:Error('Request to Quit Failed', 5000, 'truck-pickup')
        end
    end)
end)

AddEventHandler('Tow:Client:OnDuty', function()
    plsr.Callbacks:ServerCallback('Tow:OnDuty', {})
end)

AddEventHandler('Tow:Client:OffDuty', function()
    plsr.Callbacks:ServerCallback('Tow:OffDuty', {})
end)

AddEventHandler('Tow:Client:RequestTruck', function()
    local availableSpace = GetClosestAvailableParkingSpace(plsr.State.flags.position, Config.TowSpaces)
    if availableSpace then
        plsr.Callbacks:ServerCallback('Tow:RequestTruck', availableSpace, function(vehNet)
            if vehNet ~= nil then
                SetEntityAsMissionEntity(NetToVeh(vehNet))
            end
        end)
    else
        plsr.Notification:Error('Parking Space Occupied, Move Out the Way!', 7500, 'truck-pickup')
    end
end)

AddEventHandler('Tow:Client:ReturnTruck', function()
    plsr.Callbacks:ServerCallback('Tow:ReturnTruck', {})
end)

AddEventHandler('Tow:Client:RequestImpound', function(entityData)
    local myTowTruck = GlobalState[string.format('TowTrucks:%s', plsr.State.character.SID)]
    if myTowTruck then
        myTowTruck = NetToVeh(myTowTruck)
    end

    if entityData and entityData.entity and DoesEntityExist(entityData.entity) and (not myTowTruck or myTowTruck ~= entityData.entity) and #(GetEntityCoords(entityData.entity) - GetEntityCoords(PlayerPedId())) <= Config.ImpoundDistance and IsVehicleEmpty(entityData.entity) and plsr.Polyzone:IsCoordsInZone(GetEntityCoords(entityData.entity), Config.ImpoundZone.id) then
        plsr.Progress:ProgressWithTickEvent({
            name = 'veh_impound',
            duration = Config.ImpoundDuration,
            label = 'Impounding Vehicle',
            useWhileDead = false,
            canCancel = true,
            vehicle = false,
            disarm = false,
			ignoreModifier = true,
            controlDisables = {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            },
            animation = {
                anim = 'clipboard',
            },
        }, function()
            if not DoesEntityExist(entityData.entity) or (#(GetEntityCoords(entityData.entity) - GetEntityCoords(PlayerPedId())) > 10.0) or not IsVehicleEmpty(entityData.entity) then
                plsr.Progress:Cancel()
            end
        end, function(cancelled)
            if not cancelled and DoesEntityExist(entityData.entity) and (#(GetEntityCoords(entityData.entity) - GetEntityCoords(PlayerPedId())) <= 10.0) and IsVehicleEmpty(entityData.entity) then
                plsr.Callbacks:ServerCallback('Vehicles:Impound', {
                    vNet = VehToNet(entityData.entity),
                    type = 'impound',
                }, function(success)
                    if success then
                        plsr.Notification:Success('Vehicle Impounded Successfully')
                    else
                        plsr.Notification:Error('Impound Failed Miserably')
                    end
                end)
            else
                plsr.Notification:Error('Impound Failed')
            end
        end)
    else
        plsr.Notification:Error('Cannot Impound That Vehicle')
    end
end)