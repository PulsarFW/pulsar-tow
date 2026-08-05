local Config = load(LoadResourceFile(GetCurrentResourceName(), "config/shared.lua"))()

CreateThread(function()
		plsr.PedInteraction:Add("veh_tow_jerry", Config.Yard.model, Config.Yard.coords, Config.Yard.heading, 50.0, {
			{
				icon = "truck-pickup",
				text = "Request Tow Truck",
				event = "Tow:Client:RequestTruck",
				jobPerms = {
					{
						job = "tow",
						reqDuty = true,
					},
				},
				isEnabled = function()
					return not GlobalState[string.format("TowTrucks:%s", plsr.State.character.SID)]
				end,
			},
			{
				icon = "truck-pickup",
				text = "Return Tow Truck",
				event = "Tow:Client:ReturnTruck",
				jobPerms = {
					{
						job = "tow",
						reqDuty = true,
					},
				},
				isEnabled = function()
					return GlobalState[string.format("TowTrucks:%s", plsr.State.character.SID)]
				end,
			},
		}, "truck-pickup", Config.Yard.scenario)

		plsr.Polyzone.Create:Box(Config.ImpoundZone.id, Config.ImpoundZone.coords, Config.ImpoundZone.width, Config.ImpoundZone.length, {
			heading = Config.ImpoundZone.heading,
			minZ = Config.ImpoundZone.minZ,
			maxZ = Config.ImpoundZone.maxZ,
		})
end)

_TOW = {
	IsTowTruck = function(self, entity)
		local model = GetEntityModel(entity)
		return Config.TowTrucks[model]
	end,
}

AddEventHandler("Proxy:Shared:RegisterReady", function()
	exports["pulsar_core"]:RegisterComponent("Tow", _TOW)
end)

local _towingAction = false

AddEventHandler("Vehicles:Client:BeginTow", function(entityData)
	local truck = entityData.entity
	local truckState = plsr.State.Entity(truck)
	local truckModel = GetEntityModel(truck)
	if not _towingAction and Config.TowTrucks[truckModel] and truckState and not truckState.towingVehicle then
		local targetVehicle = GetVehicleBehindTowTruck(truck, Config.AttachSearchDistance)
		local canTow, errorMessage = CanFuckingTowVehicle(truck, targetVehicle)
		if canTow then
			plsr.Sounds.Play:Distance(5.0, Config.AttachAction.sound, 0.2)
			plsr.Progress:ProgressWithStartAndTick({
				name = "tow_attaching",
				duration = Config.AttachAction.duration,
				label = "Starting Tow",
				canCancel = true,
				tickrate = 1000,
				ignoreModifier = true,
				controlDisables = {
					disableMovement = true,
					disableCarMovement = true,
					disableMouse = false,
					disableCombat = true,
				},
				animation = {
					animDict = Config.AttachAction.animDict,
					anim = Config.AttachAction.anim,
					flags = Config.AttachAction.flags,
				},
			}, function()
				_towingAction = true
			end, function()
				local canTow, errorMessage = CanFuckingTowVehicle(truck, targetVehicle)
				if not canTow then
					plsr.Progress:Cancel()
					plsr.Notification:Error(errorMessage, 5000, "truck-pickup")
				end
			end, function(wasCancelled)
				_towingAction = false
				if not wasCancelled then
					local success = AttachVehicleToTow(truck, targetVehicle, truckModel)
					if success then
						truckState.towingVehicle = VehToNet(success)
						plsr.Notification:Success("Vehicle Now on Tow Truck", 5000, "truck-pickup")

						if plsr.State.Entity(success).towObjective then
							plsr.Blips:Remove("towjob-pickup")
							plsr.Phone.Notification:Update("TOW_OBJ", "Yard Manager", "Great, bring it back to the yard")
						end
					else
						truckState.towingVehicle = false
						plsr.Notification:Error("Failed to Tow Vehicle", 5000, "truck-pickup")
					end
				end
			end)
		else
			plsr.Notification:Error(errorMessage, 5000, "truck-pickup")
		end
	end
end)

AddEventHandler("Vehicles:Client:ReleaseTow", function(entityData)
	local truck = entityData.entity
	local truckState = plsr.State.Entity(truck)
	local truckModel = GetEntityModel(truck)
	if Config.TowTrucks[truckModel] and truckState then
		if truckState.towingVehicle then
			local success = DetachVehicleFromTow(truck, NetToVeh(truckState.towingVehicle))
			if success then
				plsr.Notification:Success("Vehicle Released from Truck", 5000, "truck-pickup")
				truckState.towingVehicle = false
			end
		else
			plsr.Notification:Error("No Vehicle Being Towed", 5000, "truck-pickup")
		end
	end
end)

RegisterNetEvent("Tow:Client:MarkPickup", function(coords, vehNet)
	plsr.Blips:Add("towjob-pickup", "Vehicle Pickup", coords, 326, 65, 0.8, 2, false, true)
	SetEntityAsMissionEntity(NetToVeh(vehNet))
end)

RegisterNetEvent("Tow:Client:CleanupPickup", function()
	plsr.Blips:Remove("towjob-pickup")
end)

function AttachVehicleToTow(towTruck, targetVeh, truckModel)
	local boneIndex = (Config.TowTrucks[truckModel] and Config.TowTrucks[truckModel].boneIndex) or "bodyshell"

	local attachOffset = GetVehicleAttachOffset(GetEntityModel(towTruck), targetVeh)

	local towTruckControl = RequestControlWithTimeout(towTruck, 1500)
	local targetVehControl = RequestControlWithTimeout(targetVeh, 1500)

	if attachOffset and towTruckControl and targetVehControl then
		AttachEntityToEntity(
			targetVeh,
			towTruck,
			GetEntityBoneIndexByName(towTruck, boneIndex),
			attachOffset.x,
			attachOffset.y,
			attachOffset.z,
			0,
			0,
			0,
			1,
			1,
			0,
			1,
			0,
			1
		)
		--SetCanClimbOnEntity(targetVeh, false)
		return targetVeh
	end
	return false
end

function DetachVehicleFromTow(towTruck, towedVehicle)
	if towedVehicle and DoesEntityExist(towedVehicle) then
		local towTruckControl = RequestControlWithTimeout(towTruck, 1500)
		local towedVehControl = RequestControlWithTimeout(towedVehicle, 1500)

		if towTruckControl and towedVehControl and IsEntityAttachedToEntity(towTruck, towedVehicle) then
			local releaseCoords = GetOffsetFromEntityInWorldCoords(towTruck, 0.0, -10.0, 0.0)
			DetachEntity(towedVehicle, true)
			Wait(150)
			SetEntityCoords(towedVehicle, releaseCoords)
			Wait(50)
			SetVehicleOnGroundProperly(towedVehicle)

			if plsr.State.Entity(towedVehicle).towObjective then
				SetVehicleDoorsLockedForAllPlayers(veh, true)
			end

			return true
		end
	end
	return false
end
