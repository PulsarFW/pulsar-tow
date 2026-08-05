local Config = load(LoadResourceFile(GetCurrentResourceName(), "config/shared.lua"))()
local ServerConfig = load(LoadResourceFile(GetCurrentResourceName(), "config/server.lua"))()

local _activeTowVehicles = {}

_activeTowers = {}

CreateThread(function()
		plsr.Callbacks:RegisterServerCallback("Tow:RequestJob", function(source, data, cb)
			local char = plsr.Fetch:CharacterSource(source)
			if not plsr.Jobs.Permissions:HasJob(source, "tow") and char then
				cb(plsr.Jobs:GiveJob(char:GetData("SID"), "tow", false, ServerConfig.HireGrade))
			else
				cb(false)
			end
		end)

		plsr.Callbacks:RegisterServerCallback("Tow:QuitJob", function(source, data, cb)
			local char = plsr.Fetch:CharacterSource(source)
			if plsr.Jobs.Permissions:HasJob(source, "tow") and char then
				_activeTowers[source] = nil
				cb(plsr.Jobs:RemoveJob(char:GetData("SID"), "tow"))
			else
				cb(false)
			end
		end)

		plsr.Callbacks:RegisterServerCallback("Tow:OnDuty", function(source, data, cb)
			local char = plsr.Fetch:CharacterSource(source)
			local dutyData = plsr.Jobs.Duty:GetDutyData("tow")
			if plsr.Jobs.Permissions:HasJob(source, "tow") and char then
				if not dutyData or (dutyData and dutyData.Count < ServerConfig.MaxActiveTowers) then
					if plsr.Jobs.Duty:On(source, "tow", true) then
						_activeTowers[source] = {
							next = os.time() + (math.random(ServerConfig.NextPickupCooldown.min, ServerConfig.NextPickupCooldown.max) * 60),
						}
						plsr.Execute:Client(
							source,
							"Notification",
							"Info",
							[[
                                You are now on Duty as a Tow Truck Driver.<br><br>
                                Get a Tow Truck from Jerry in the Tow Lot.<br>
                                To Impound Vehicles, Bring them to the Tow Lot and
                                Fill out the Paperwork.
                            ]],
							10000,
							"truck-pickup"
						)
					else
						plsr.Execute:Client(source, "Notification", "Error", "Failed to Go On Duty", 5000, "truck-pickup")
					end
				else
					plsr.Execute:Client(source, "Notification", "Error", "Too Many Tow Employees on Duty", 5000, "truck-pickup")
				end
			else
				plsr.Execute:Client(source, "Notification", "Error", "Failed to Go On Duty", 5000, "truck-pickup")
			end
		end)

		plsr.Callbacks:RegisterServerCallback("Tow:OffDuty", function(source, data, cb)
			local char = plsr.Fetch:CharacterSource(source)
			if char and plsr.Jobs.Duty:Get(source, "tow") then
				local stateId = char:GetData("SID")
				if not _activeTowVehicles[stateId] then
					plsr.Jobs.Duty:Off(source, "tow")
					plsr.Tow:CleanupPickup(source)
					_activeTowers[source] = nil
					plsr.Phone.Notification:RemoveById(source, "TOW_OBJ")
				else
					plsr.Execute:Client(
						source,
						"Notification",
						"Error",
						"Return the Tow Truck Before Going Off Duty",
						5000,
						"truck-pickup"
					)
				end
			else
				plsr.Execute:Client(source, "Notification", "Error", "Failed to Go Off Duty", 5000, "truck-pickup")
			end
		end)

		plsr.Callbacks:RegisterServerCallback("Tow:RequestTruck", function(source, spaceCoords, cb)
			local char = plsr.Fetch:CharacterSource(source)
			if char and plsr.State:Player(source).onDuty == "tow" then
				local stateId = char:GetData("SID")
				if not _activeTowVehicles[stateId] then
					plsr.Vehicles:SpawnTemp(
						source,
						ServerConfig.Truck.model,
						ServerConfig.Truck.class,
						spaceCoords.xyz,
						spaceCoords.w,
						function(spawnedVehicle, VIN, plate)
							if spawnedVehicle then
								plsr.Vehicles.Keys:Add(source, VIN)

								_activeTowVehicles[stateId] = {
									SID = stateId,
									veh = spawnedVehicle,
									net = NetworkGetNetworkIdFromEntity(spawnedVehicle),
									VIN = VIN,
									plate = plate,
								}

								GlobalState[string.format("TowTrucks:%s", stateId)] =
									NetworkGetNetworkIdFromEntity(spawnedVehicle)

								plsr.Execute:Client(
									source,
									"Notification",
									"Success",
									"Your Tow Truck Was Provided",
									5000,
									"truck-pickup"
								)
								cb(spawnedVehicle)
							else
								plsr.Execute:Client(source, "Notification", "Error", "Truck Spawn Failed", 5000, "truck-pickup")
								cb(nil)
							end
						end,
						{
							Make = ServerConfig.Truck.Make,
							Model = ServerConfig.Truck.Model,
							Value = ServerConfig.Truck.Value,
						}
					)
				else
					plsr.Execute:Client(source, "Notification", "Error", "We Already Gave You a Truck", 5000, "truck-pickup")
					cb(nil)
				end
			end
		end)

		plsr.Callbacks:RegisterServerCallback("Tow:ReturnTruck", function(source, data, cb)
			local char = plsr.Fetch:CharacterSource(source)
			if char then
				local stateId = char:GetData("SID")
				local hasTruck = _activeTowVehicles[stateId]
				if hasTruck and hasTruck.veh and DoesEntityExist(hasTruck.veh) then
					local truckCoords = GetEntityCoords(hasTruck.veh)
					if #(truckCoords - Config.TowSpaces[1].xyz) <= ServerConfig.ReturnTruckDistance then
						plsr.Vehicles:Delete(hasTruck.veh, function(success)
							if success then
								_activeTowVehicles[stateId] = nil
								GlobalState[string.format("TowTrucks:%s", stateId)] = false
								plsr.Execute:Client(
									source,
									"Notification",
									"Success",
									"Thanks for Returning Your Tow Truck",
									5000,
									"truck-pickup"
								)
							else
								plsr.Execute:Client(
									source,
									"Notification",
									"Error",
									"Error Returning Truck",
									5000,
									"truck-pickup"
								)
							end
						end)
					else
						plsr.Execute:Client(
							source,
							"Notification",
							"Error",
							"Your Tow Truck Isn't Nearby",
							5000,
							"truck-pickup"
						)
					end
				else
					plsr.Execute:Client(
						source,
						"Notification",
						"Error",
						"You Don't Have a Truck to Return",
						5000,
						"truck-pickup"
					)
				end
			end
		end)
end)

AddEventHandler("Vehicles:Server:Deleted", function(veh, VIN)
	for k, v in pairs(_activeTowVehicles) do
		if v.veh == veh then
			GlobalState[string.format('TowTrucks:%s', v.SID)] = false
			_activeTowVehicles[v.SID] = nil
		end
	end
end)

TOW = {
	PayoutPickup = function(self, source)
		if _activeTowers[source] ~= nil then
			local char = plsr.Fetch:CharacterSource(source)
			plsr.Banking.Balance:Deposit(plsr.Banking.Accounts:GetPersonal(char:GetData("SID")).Account, ServerConfig.PickupFee, {
				type = "paycheck",
				title = "Tow Fee",
				description = "Your Fee For A Vehicle Pickup",
				data = ServerConfig.PickupFee,
			})
			plsr.Phone.Notification:RemoveById(source, "TOW_OBJ")
			plsr.Phone.Notification:Add(
				source,
				"Yard Manager",
				"Good work, I've sent your fee to your account. I'll let you know when I got another job for you",
				os.time(),
				10000,
				ServerConfig.YardBrand,
				{},
				nil
			)

			plsr.Tow:CleanupPickup(source)
		end
	end,
	CleanupPickup = function(self, source)
		if _activeTowers[source] ~= nil then
			if _activeTowers[source].veh ~= nil and DoesEntityExist(_activeTowers[source].veh) then
				plsr.Vehicles:Delete(veh, function(success) end)
				_activeTowers[source].veh = nil
			end

			if _activeTowers[source].location ~= nil then
				_inuse[_activeTowers[source].location] = false
				_activeTowers[source].location = nil
			end

			_activeTowers[source].next = os.time() + (math.random(ServerConfig.NextJobCooldown.min, ServerConfig.NextJobCooldown.max) * 60)
			_activeTowers[source].onTask = false
			TriggerClientEvent("Tow:Client:CleanupPickup", source)
		end
	end,
}

AddEventHandler("Proxy:Shared:RegisterReady", function()
	exports["pulsar_core"]:RegisterComponent("Tow", TOW)
end)

AddEventHandler("Characters:Server:PlayerLoggedOut", function(source)
	plsr.Tow:CleanupPickup(source)
	_activeTowers[source] = nil
end)
AddEventHandler("Characters:Server:PlayerDropped", function(source)
	plsr.Tow:CleanupPickup(source)
	_activeTowers[source] = nil
end)
