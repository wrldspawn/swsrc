---Euler QAngle -> Basis Vectors.  Each vector is optional
---@param angles Angle
---@param forward Vector
---@param right Vector?
---@param up Vector?
function swsrc.AngleVectors(angles, forward, right, up)
	local ry = math.rad(angles.y)
	local rp = math.rad(angles.p)
	local rr = math.rad(angles.r)

	local sy, cy = math.sin(ry), math.cos(ry)
	local sp, cp = math.sin(rp), math.cos(rp)
	local sr, cr = math.sin(rr), math.cos(rr)

	if forward ~= nil then
		forward.x = cp * cy
		forward.y = cp * sy
		forward.z = -sp
	end

	if right ~= nil then
		right.x = (-1 * sr * sp * cy + -1 * cr * -sy)
		right.y = (-1 * sr * sp * sy + -1 * cr * cy)
		right.z = -1 * sr * cp
	end

	if up ~= nil then
		up.x = (cr * sp * cy + -sr * -sy)
		up.y = (cr * sp * sy + -sr * cy)
		up.z = cr * cp
	end
end

function swsrc.IsPushableEntity(pEnt)
	if not IsValid(pEnt) then return false end

	if pEnt:GetCollisionGroup() == COLLISION_GROUP_NONE then
		local class = pEnt:GetClass()
		if class == "prop_physics" or class == "prop_physics_multiplayer" then
			return true
		end
	end

	return false
end
function swsrc.IsBreakableEntity(pEnt)
	if not IsValid(pEnt) then return false end

	if pEnt:GetInternalVariable("m_takedamage") ~= 2 then -- DAMAGE_YES
		return false
	end

	local cgroup = pEnt:GetCollisionGroup()
	if cgroup ~= COLLISION_GROUP_PUSHAWAY and cgroup ~= COLLISION_GROUP_BREAKABLE_GLASS and cgroup ~= COLLISION_GROUP_NONE then
		return false
	end

	if pEnt:Health() > 200 then return false end

	local class = pEnt:GetClass()
	local phys = pEnt:GetPhysicsObject()
	if class == "func_breakable_surf" then
		if pEnt:GetInternalVariable("m_bIsBroken") then return false end
	elseif phys:IsValid() and bit.band(phys:GetContents(), CONTENTS_PLAYERCLIP) ~= 0 then
		return false
	end

	local m_iMinHealthDmg = pEnt:GetInternalVariable("m_iMinHealthDmg")
	if m_iMinHealthDmg ~= nil and m_iMinHealthDmg >= 50 then return false end

	return true
end
function swsrc.IsPushAwayEntity(pEnt)
	if not IsValid(pEnt) then return false end

	if pEnt:GetCollisionGroup() ~= COLLISION_GROUP_PUSHAWAY then
		if SERVER then
			local class = pEnt:GetClass()
			if class == "func_door_rotating" then
				local m_toggle_state = pEnt:GetInternalVariable("m_toggle_state")
				if m_toggle_state ~= 2 and m_toggle_state ~= 3 then -- TS_GOING_UP, TS_GOING_DOWN
					return false
				end
			elseif class == "prop_door_rotating" then
				local m_eDoorState = pEnt:GetInternalVariable("m_eDoorState")
				if m_eDoorState ~= 1 and m_eDoorState ~= 3 then -- DOOR_STATE_OPENING, DOOR_STATE_CLOSING
					return false
				end
			end
		else
			return false
		end
	end

	return true
end

-- these are only here for custom weapons to replicate logic of other "base" weapons
WEAPON_NONE = 0
WEAPON_P228 = 1
WEAPON_GLOCK = 2
WEAPON_SCOUT = 3
WEAPON_HEGRENADE = 4
WEAPON_XM1014 = 5
WEAPON_C4 = 6
WEAPON_MAC10 = 7
WEAPON_AUG = 8
WEAPON_SMOKEGRENADE = 9
WEAPON_ELITE = 10
WEAPON_FIVESEVEN = 11
WEAPON_UMP45 = 12
WEAPON_SG550 = 13

WEAPON_GALIL = 14
WEAPON_FAMAS = 15
WEAPON_USP = 16
WEAPON_AWP = 17
WEAPON_MP5NAVY = 18
WEAPON_M249 = 19
WEAPON_M3 = 20
WEAPON_M4A1 = 21
WEAPON_TMP = 22
WEAPON_G3SG1 = 23
WEAPON_FLASHBANG = 24
WEAPON_DEAGLE = 25
WEAPON_SG552 = 26
WEAPON_AK47 = 27
WEAPON_KNIFE = 28
WEAPON_P90 = 29

WEAPON_SHIELDGUN = 30 -- BOTPORT: Is this still needed?

WEAPON_KEVLAR = 31
WEAPON_ASSAULTSUIT = 32
WEAPON_NVG = 33

WEAPON_MAX = 34

WEAPONTYPE_KNIFE = 0
WEAPONTYPE_PISTOL = 1
WEAPONTYPE_SUBMACHINEGUN = 2
WEAPONTYPE_RIFLE = 3
WEAPONTYPE_SHOTGUN = 4
WEAPONTYPE_SNIPER_RIFLE = 5
WEAPONTYPE_MACHINEGUN = 6
WEAPONTYPE_C4 = 7
WEAPONTYPE_GRENADE = 8
WEAPONTYPE_UNKNOWN = 9

local s_weaponTypeInfo = {
	{WEAPONTYPE_KNIFE,         "Knife"},
	{WEAPONTYPE_PISTOL,        "Pistol"},
	{WEAPONTYPE_SUBMACHINEGUN, "Submachine Gun"}, -- First match is printable
	{WEAPONTYPE_SUBMACHINEGUN, "SubMachinegun"},
	{WEAPONTYPE_SUBMACHINEGUN, "submachinegun"},
	{WEAPONTYPE_SUBMACHINEGUN, "smg"},
	{WEAPONTYPE_RIFLE,         "Rifle"},
	{WEAPONTYPE_SHOTGUN,       "Shotgun"},
	{WEAPONTYPE_SNIPER_RIFLE,  "Sniper Rifle"}, -- First match is printable
	{WEAPONTYPE_SNIPER_RIFLE,  "SniperRifle"},
	{WEAPONTYPE_MACHINEGUN,    "Machine Gun"}, -- First match is printable
	{WEAPONTYPE_MACHINEGUN,    "Machinegun"},
	{WEAPONTYPE_MACHINEGUN,    "machinegun"},
	{WEAPONTYPE_MACHINEGUN,    "mg"},
	{WEAPONTYPE_C4,            "C4"},
	{WEAPONTYPE_GRENADE,       "Grenade"},
}

ITEM_FLAG_SELECTONEMPTY = bit.lshift(1, 0)
ITEM_FLAG_NOAUTORELOAD = bit.lshift(1, 1)
ITEM_FLAG_NOAUTOSWITCHEMPTY = bit.lshift(1, 2)
ITEM_FLAG_LIMITINWORLD = bit.lshift(1, 3)
ITEM_FLAG_EXHAUSTIBLE = bit.lshift(1, 4) -- A player can totally exhaust their ammo supply and lose this weapon
ITEM_FLAG_DOHITLOCATIONDMG = bit.lshift(1, 5) -- This weapon take hit location into account when applying damage
ITEM_FLAG_NOAMMOPICKUPS = bit.lshift(1, 6) -- Don't draw ammo pickup sprites/sounds when ammo is received
ITEM_FLAG_NOITEMPICKUP = bit.lshift(1, 7) -- Don't draw weapon pickup when this weapon is picked up by the player

local g_ItemFlags = {
	{"ITEM_FLAG_SELECTONEMPTY",     ITEM_FLAG_SELECTONEMPTY},
	{"ITEM_FLAG_NOAUTORELOAD",      ITEM_FLAG_NOAUTORELOAD},
	{"ITEM_FLAG_NOAUTOSWITCHEMPTY", ITEM_FLAG_NOAUTOSWITCHEMPTY},
	{"ITEM_FLAG_LIMITINWORLD",      ITEM_FLAG_LIMITINWORLD},
	{"ITEM_FLAG_EXHAUSTIBLE",       ITEM_FLAG_EXHAUSTIBLE},
	{"ITEM_FLAG_DOHITLOCATIONDMG",  ITEM_FLAG_DOHITLOCATIONDMG},
	{"ITEM_FLAG_NOAMMOPICKUPS",     ITEM_FLAG_NOAMMOPICKUPS},
	{"ITEM_FLAG_NOITEMPICKUP",      ITEM_FLAG_NOITEMPICKUP},
}

local pWeaponSoundCategories = {
	"empty",
	"single_shot",
	"single_shot_npc",
	"double_shot",
	"double_shot_npc",
	"burst",
	"reload",
	"reload_npc",
	"melee_miss",
	"melee_hit",
	"melee_hit_world",
	"special1",
	"special2",
	"special3",
	"taunt",
	"deploy",
}

-- stupid hack because the ammo system SUCKS and doesn't allow overwriting values
local MAX_AMMO_BY_NAME = {
	BULLET_PLAYER_50AE = 35,
	BULLET_PLAYER_762MM = 90,
	BULLET_PLAYER_556MM = 90,
	BULLET_PLAYER_556MM_BOX = 200,
	BULLET_PLAYER_338MAG = 30,
	BULLET_PLAYER_9MM = 120,
	BULLET_PLAYER_BUCKSHOT = 32,
	BULLET_PLAYER_45ACP = 100,
	BULLET_PLAYER_357SIG = 52,
	BULLET_PLAYER_57MM = 100,

	-- these should work since theyre unique but you never know
	swsrc_hegrenade = 1,
	swsrc_flashbang = 2,
	swsrc_smokegrenade = 1,
}

function swsrc.WeaponClassFromString(weaponType)
	for _, info in ipairs(s_weaponTypeInfo) do
		if info[2] == weaponType then
			return info[1]
		end
	end

	return WEAPONTYPE_UNKNOWN
end

local function makeModeValues(pKeyValuesData, key, default)
	return {
		[0] = pKeyValuesData:GetFloat(key, default),
		[1] = pKeyValuesData:GetFloat(key .. "alt", default),
	}
end
function swsrc.ParseWeaponData(WeaponData)
	local pKeyValuesData = swsrc.KeyValuesHelper(WeaponData or "", false, false)
	if not pKeyValuesData then return {} end

	local data = {
		szPrintName               = pKeyValuesData:GetString("printname"),
		szViewModel               = pKeyValuesData:GetString("viewmodel"),
		szWorldModel              = pKeyValuesData:GetString("playermodel"),
		szAnimationPrefix         = pKeyValuesData:GetString("anim_prefix"),
		iSlot                     = pKeyValuesData:GetInt("bucket", 0),
		iPosition                 = pKeyValuesData:GetInt("bucket_position", 0),
		iMaxClip1                 = pKeyValuesData:GetInt("clip_size", -1),
		iMaxClip2                 = pKeyValuesData:GetInt("clip2_size", -1),
		iWeight                   = pKeyValuesData:GetInt("weight", 0),

		iRumbleEffect             = pKeyValuesData:GetInt("rumble", -1),

		iFlags                    = pKeyValuesData:GetInt("item_flags", ITEM_FLAG_LIMITINWORLD),

		bShowUsageHint            = pKeyValuesData:GetBool("showusagehint", false),
		bAutoSwitchTo             = pKeyValuesData:GetBool("autoswitchto", true),
		bAutoSwitchFrom           = pKeyValuesData:GetBool("autoswitchfrom", true),
		m_bBuiltRightHanded       = pKeyValuesData:GetBool("builtrighthanded", true),
		m_bAllowFlipping          = pKeyValuesData:GetBool("allowflipping", true),
		m_bMeleeWeapon            = pKeyValuesData:GetBool("meleeweapon", false),

		szAmmo1                   = pKeyValuesData:GetString("primary_ammo", "None"),
		szAmmo2                   = pKeyValuesData:GetString("secondary_ammo", "None"),

		aShootSounds              = {},
		TextureData               = {},

		-- vvv CS:S specific vvv --

		m_flMaxSpeed              = pKeyValuesData:GetInt("maxplayerspeed", 1),

		m_iWeaponPrice            = pKeyValuesData:GetInt("weaponprice", -1),

		m_flArmorRatio            = pKeyValuesData:GetFloat("weaponarmorratio", 1),
		m_iCrosshairMinDistance   = pKeyValuesData:GetInt("crosshairmindistance", 4),
		m_iCrosshairDeltaDistance = pKeyValuesData:GetInt("crosshairdeltadistance", 3),
		m_bCanUseWithShield       = pKeyValuesData:GetBool("canequipwithshield", false),
		m_flMuzzleScale           = pKeyValuesData:GetFloat("muzzleflashscale", 1),

		m_iPenetration            = pKeyValuesData:GetInt("penetration", 1),
		m_iDamage                 = pKeyValuesData:GetInt("damage", 42), -- Douglas Adams 1952 - 2001
		m_flRange                 = pKeyValuesData:GetFloat("range", 8192),
		m_flRangeModifier         = pKeyValuesData:GetFloat("rangemodifier", 0.98),
		m_iBullets                = pKeyValuesData:GetInt("bullets", 1),
		m_flCycleTime             = pKeyValuesData:GetFloat("cycletime", 0.15),
		m_bAccuracyQuadratic      = pKeyValuesData:GetBool("accuracyquadratic", false),
		m_flAccuracyDivisor       = pKeyValuesData:GetFloat("accuracydivisor", -1), -- -1 = off
		m_flAccuracyOffset        = pKeyValuesData:GetFloat("accuracyoffset", 0),
		m_flMaxInaccuracy         = pKeyValuesData:GetFloat("maxinaccuracy", 0),

		-- new accuracy model parameters
		m_fSpread                 = makeModeValues(pKeyValuesData, "spread", 0),
		m_fInaccuracyCrouch       = makeModeValues(pKeyValuesData, "inaccuracycrouch", 0),
		m_fInaccuracyStand        = makeModeValues(pKeyValuesData, "inaccuracystand", 0),
		m_fInaccuracyJump         = makeModeValues(pKeyValuesData, "inaccuracyjump", 0),
		m_fInaccuracyLand         = makeModeValues(pKeyValuesData, "inaccuracyland", 0),
		m_fInaccuracyLadder       = makeModeValues(pKeyValuesData, "inaccuracyladder", 0),
		m_fInaccuracyFire         = makeModeValues(pKeyValuesData, "inaccuracyfire", 0),
		m_fInaccuracyMove         = makeModeValues(pKeyValuesData, "inaccuracymove", 0),

		m_fInaccuracyReload       = pKeyValuesData:GetFloat("inaccuracyreload", 0),
		m_fInaccuracyAltSwitch    = pKeyValuesData:GetFloat("inaccuracyaltswitch", 0),

		m_fRecoveryTimeCrouch     = pKeyValuesData:GetFloat("recoverytimecrouch", 1),
		m_fRecoveryTimeStand      = pKeyValuesData:GetFloat("recoverytimestand", 1),

		m_flTimeToIdleAfterFire   = pKeyValuesData:GetFloat("timetoidle", 2),
		m_flIdleInterval          = pKeyValuesData:GetFloat("idleinterval", 20),

		m_iTeam                   = -1, -- dont care currently

		m_WrongTeamMsg            = pKeyValuesData:GetString("wrongteammsg", ""),
		m_szShieldViewModel       = pKeyValuesData:GetString("shieldviewmodel", ""),
		m_szAnimExtension         = pKeyValuesData:GetString("playeranimationextension", "m4"),

		m_flBotAudibleRange       = pKeyValuesData:GetFloat("botaudiblerange", 2000),

		m_WeaponType              = swsrc.WeaponClassFromString(pKeyValuesData:GetString("weapontype", "")),

		m_bFullAuto               = pKeyValuesData:GetBool("fullauto"),

		m_szAddonModel            = pKeyValuesData:GetString("addonmodel"),
		m_szDroppedModel          = pKeyValuesData:GetString("droppedmodel"),
		m_szSilencerModel         = pKeyValuesData:GetString("silencermodel"),
	}

	data.iDefaultClip1 = pKeyValuesData:GetInt("default_clip", data.iMaxClip1)
	data.iDefaultClip2 = pKeyValuesData:GetInt("default_clip2", data.iMaxClip2)

	for _, flag in ipairs(g_ItemFlags) do
		local iVal = pKeyValuesData:GetInt(flag[1], -1)
		if iVal == 0 then
			data.iFlags = bit.band(data.iFlags, bit.bnot(flag[2]))
		elseif iVal == 1 then
			data.iFlags = bit.bor(data.iFlags, flag[2])
		end
	end

	if data.szAmmo1 == "None" then data.szAmmo1 = "" end
	data.iAmmoType = game.GetAmmoID(data.szAmmo1)
	if data.szAmmo2 == "None" then data.szAmmo2 = "" end
	data.iAmmo2Type = game.GetAmmoID(data.szAmmo2)

	local pSoundData = pKeyValuesData:FindKey("sounddata")
	if pSoundData then
		for i = 1, 16 do
			local soundname = pSoundData:GetString(pWeaponSoundCategories[i], "")
			if soundname ~= "" then
				data.aShootSounds[i] = soundname
			end
		end
	end

	local pTextureSection = pKeyValuesData:FindKey("texturedata")
	if pTextureSection then
		for key, pTemp in pTextureSection:Iter() do
			if pTemp:GetString("font", "") ~= "" then
				data.TextureData[key] = {
					szShortName = key,
					bRenderedUsingFont = true,
					cCharacterInFont = pTemp:GetString("character", ""),
					szTextureFile = pTemp:GetString("font"),
				}
			else
				data.TextureData[key] = {
					-- i dont think anything in cs:s uses TextureFileRefs?
					szShortName = key,
					szTextureFile = pTemp:GetString("file"),
					bRenderedUsingFont = false,
					rc = {
						left = pTemp:GetInt("x", 0),
						top = pTemp:GetInt("y", 0),
						right = pTemp:GetInt("width", 0),
						bottom = pTemp:GetInt("height", 0),
					},
				}
			end
		end
	end

	data.m_iDefaultPrice = data.m_iWeaponPrice

	local pMuzzleFlashStyle = pKeyValuesData:GetString("muzzleflashstyle", "CS_MUZZLEFLASH_NORM")
	if pMuzzleFlashStyle == "CS_MUZZLEFLASH_X" then
		data.m_iMuzzleFlashStyle = 1
	elseif pMuzzleFlashStyle == "CS_MUZZLEFLASH_NONE" then
		data.m_iMuzzleFlashStyle = -1
	else
		data.m_iMuzzleFlashStyle = 0
	end

	return data
end

function swsrc.RegisterWeapon(WeaponData, SWEP)
	if not SWEP then return end
	if not WeaponData or WeaponData == "" then return end

	local data = swsrc.ParseWeaponData(WeaponData)

	SWEP.CSWpnData = data

	-- fill in swep vars
	SWEP.PrintName = data.szPrintName

	SWEP.Slot = data.iSlot
	SWEP.SlotPos = data.iPosition

	SWEP.Primary.Ammo = data.szAmmo1
	SWEP.Primary.ClipSize = data.iMaxClip1
	if data.iMaxClip1 == -1 then
		SWEP.Primary.DefaultClip = -1
	else
		local clip = data.iDefaultClip1
		if not clip or clip == 0 then
			clip = data.iMaxClip1
		end

		local extra = game.GetAmmoMax(data.iAmmoType)
		if not extra or extra == 0 or extra == 9999 then
			extra = MAX_AMMO_BY_NAME[data.szAmmo1] or clip * 3
		end

		SWEP.Primary.DefaultClip = clip + extra
	end
	SWEP.Primary.Automatic = data.m_bFullAuto

	SWEP.Secondary.Ammo = data.szAmmo2
	SWEP.Secondary.ClipSize = data.iMaxClip2
	if data.iMaxClip2 == -1 then
		SWEP.Secondary.DefaultClip = -1
	else
		local clip = data.iDefaultClip2
		if not clip or clip == 0 then
			clip = data.iMaxClip2
		end

		local extra = game.GetAmmoMax(data.iAmmo2Type)
		if not extra or extra == 0 or extra == 9999 then
			extra = MAX_AMMO_BY_NAME[data.szAmmo2] or clip * 3
		end

		SWEP.Secondary.DefaultClip = clip + game.GetAmmoMax(data.iAmmo2Type)
	end
	SWEP.Secondary.Automatic = data.m_bFullAuto

	if data.m_iMuzzleFlashStyle > -1 then
		SWEP.CSMuzzleFlashes = true
		if data.m_iMuzzleFlashStyle == 1 then
			SWEP.CSMuzzleX = true
		end
	end

	-- let weapons override if desired
	if SWEP.OverrideData then
		SWEP.OverrideData(nil, SWEP)
	end
end

swsrc.RegisteredItems = {}
local COLOR_KILLICON = Color(255, 80, 0, 255)
hook.Add("PreRegisterSWEP", "swsrc.register", function(swep, class)
	local BaseName = swep.Base
	if BaseName and class ~= "weapon_swsrc_basegun" then
		if
			(
				BaseName == "weapon_swsrc_base"
				or BaseName == "weapon_swsrc_basegun"
				or weapons.IsBasedOn(BaseName, "weapon_swsrc_base")
			) and swep.WeaponData
		then
			Msg("[swsrc] ")
			print("Registering " .. class)
			swsrc.RegisterWeapon(swep.WeaponData, swep)
			swsrc.RegisteredItems[class] = swep

			if CLIENT then
				local iconData = swep.CSWpnData.TextureData.weapon
				if iconData then
					if iconData.bRenderedUsingFont then
						local char = iconData.cCharacterInFont
						killicon.AddFont(class, "CSTypeDeath", char, COLOR_KILLICON, 0.5)
					else
						-- TODO?
					end
				end
			end
		end
	end
end)
