local ServerConfig = load(LoadResourceFile(GetCurrentResourceName(), "config/server.lua"))()

_inuse = {}

CreateThread(function()
	while true do
		for k, v in pairs(_activeTowers) do
			if not v.onTask and v.next < os.time() then
				v.onTask = true

				local cId = math.random(#ServerConfig.Spawns)
				while _inuse[cId] do
					cId = math.random(#ServerConfig.Spawns)
					Wait(1)
				end

				_inuse[cId] = k

				plsr.Vehicles:SpawnTemp(
					-1,
					plsr.Vehicles.RandomModel:DClass(),
					'automobile',
					vector3(ServerConfig.Spawns[cId][1], ServerConfig.Spawns[cId][2], ServerConfig.Spawns[cId][3]),
					ServerConfig.Spawns[cId][4],
					function(veh, VIN, plate)
						SetVehicleDoorsLocked(veh, 2)
		
						v.location = cId
						v.veh = veh
		
						local ent = plsr.State.Entity(veh)
						ent.towObjective = true
						TriggerClientEvent("Tow:Client:MarkPickup", k, ServerConfig.Spawns[cId], veh)
		
						plsr.Phone.Notification:AddWithId(
							k,
							"TOW_OBJ",
							"Yard Manager",
							"Got a pickup for you, check your GPS (flashing gray car)",
							os.time() * 1000,
							-1,
							ServerConfig.YardBrand,
							{},
							nil
						)
					end
				)
			end
		end
		Wait(ServerConfig.PickupThreadInterval)
	end
end)