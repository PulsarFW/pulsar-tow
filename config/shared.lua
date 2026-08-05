return {
	-- tow truck model -> attach positioning/bone override
	TowTrucks = {
		[`flatbed`] = { position = 2.0, height = 0.4 },
		[`trflat`] = { position = 2.0, height = 0.4 },
		[`trailersmall`] = { position = 5.0, height = -0.25, boneIndex = "chassis" },
		[`20fttrailer`] = { position = 2.0, height = 0.0 },
		-- [`20ramrb`] = {
		--     position = 1.4,
		--     height = 0.12,
		--     classOverrides = {
		--         [8] = {
		--             position = 1.1,
		--             height = 0.12,
		--         }
		--     }
		-- }
	},

	BannedClasses = {
		[15] = true,
		[16] = true,
	},

	BannedModels = {},

	-- where idle tow trucks can be requested/returned
	TowSpaces = {
		vector4(-238.626, -1183.879, 23.131, 269.789),
	},

	AttachSearchDistance = 8.0, -- how far behind the truck to look for a hookable vehicle
	MaxTowDistance = 20.0, -- how far the target vehicle can be from the truck to hook it up
	ParkingSpaceCheckRadius = 2.0, -- radius used to decide if a tow space is occupied

	Yard = {
		coords = vector3(-247.645, -1183.099, 22.090),
		heading = 312.942,
		model = `a_m_m_eastsa_01`,
		scenario = "WORLD_HUMAN_HANG_OUT_STREET",
	},

	ImpoundZone = {
		id = "tow_impound_zone",
		coords = vector3(-236.96, -1173.44, 23.04),
		width = 19.4,
		length = 24.4,
		heading = 270,
		minZ = 22.04,
		maxZ = 26.04,
	},
	ImpoundDistance = 10.0,
	ImpoundDuration = 10 * 1000,

	AttachAction = {
		sound = "tow_truck.ogg",
		duration = 1000,
		animDict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@",
		anim = "machinic_loop_mechandplayer",
		flags = 49,
	},
}
