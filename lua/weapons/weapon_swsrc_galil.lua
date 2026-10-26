AddCSLuaFile()

SWEP.Base = "weapon_swsrc_basegun"
DEFINE_BASECLASS(SWEP.Base)

SWEP.Category = "#spawnmenu.category.swsrc"
SWEP.SubCategory = "#spawnmenu.category.swsrc_rifles"

SWEP.PrintName = "Galil"
SWEP.Spawnable = true
SWEP.HoldType = "ar2"
SWEP.WorldModel = "models/weapons/w_rif_galil.mdl"
SWEP.ViewModel = "models/weapons/cstrike/c_rif_galil.mdl"
SWEP.IconOverride = "vgui/gfx/vgui/fav_weap/galil"

SWEP.WeaponData = [=[WeaponData
{
	"MaxPlayerSpeed"		"215"
	"WeaponType"			"Rifle"
	"FullAuto"				1
	"WeaponPrice"			"2000"
	"WeaponArmorRatio"		"1.55"
	"CrosshairMinDistance"		"4"
	"CrosshairDeltaDistance"	"3"
	"Team"				"TERRORIST"
	"BuiltRightHanded" 		"1"
	"PlayerAnimationExtension"	"galil"
	"MuzzleFlashScale"		"1.6"
	"MuzzleFlashStyle"		"CS_MUZZLEFLASH_X"
	"CanEquipWithShield" 		"0"


	// Weapon characteristics:
	"Penetration"			"2"
	"Damage"			"30"
	"Range"				"8192"
	"RangeModifier"			"0.98"
	"Bullets"			"1"
	"CycleTime"			"0.09"
	"AccuracyDivisor"		"200"
	"AccuracyOffset"		"0.35"
	"MaxInaccuracy"			"1.25"
	"TimeToIdle"			"1.28"
	"IdleInterval"			"20"

	// New accuracy model parameters
	"Spread"					0.00060
	"InaccuracyCrouch"			0.00939
	"InaccuracyStand"			0.01253
	"InaccuracyJump"			0.45434
	"InaccuracyLand"			0.09087
	"InaccuracyLadder"			0.11358
	"InaccuracyFire"			0.00984
	"InaccuracyMove"			0.10561

	"RecoveryTimeCrouch"		0.35197
	"RecoveryTimeStand"			0.49275

	// Weapon data is loaded by both the Game and Client DLLs.
	"printname"			"#Cstrike_WPNHUD_Galil"
	"viewmodel"			"models/weapons/v_rif_galil.mdl"
	"playermodel"			"models/weapons/w_rif_galil.mdl"

	"anim_prefix"			"anim"
	"bucket"			"0"
	"bucket_position"		"0"

	"clip_size"			"35"

	"primary_ammo"			"BULLET_PLAYER_556MM"
	"secondary_ammo"		"None"

	"weight"			"25"
	"item_flags"			"0"

	// Sounds for the weapon. There is a max of 16 sounds per category (i.e. max 16 "single_shot" sounds)
	SoundData
	{
		//"reload"			"Default.Reload"
		//"empty"				"Default.ClipEmpty_Rifle"
		"single_shot"		"Weapon_Galil.Single"
		special3			Default.Zoom
	}

	// Weapon Sprite data is loaded by the Client DLL.
	TextureData
	{
		"weapon"
		{
				"font"		"CSweaponsSmall"
				"character"	"V"
		}
		"weapon_s"
		{
				"font"		"CSweapons"
				"character"	"V"
		}
		"ammo"
		{
				"font"		"CSTypeDeath"
				"character"		"N"
		}
		"crosshair"
		{
				"file"		"sprites/crosshairs"
				"x"			"0"
				"y"			"48"
				"width"		"24"
				"height"	"24"
		}
		"autoaim"
		{
				"file"		"sprites/crosshairs"
				"x"			"0"
				"y"			"48"
				"width"		"24"
				"height"	"24"
		}
	}
	ModelBounds
	{
		Viewmodel
		{
			Mins	"-6 -8 -15"
			Maxs	"36 4 0"
		}
		World
		{
			Mins	"-10 -9 -7"
			Maxs	"31 10 8"
		}
	}
}]=]

function SWEP:OverrideData(tbl)
	-- TODO: cvar for cs:s slots?
	tbl.Slot = 2
end

function SWEP:GetWeaponID()
	return WEAPON_GALIL
end

local weapon_accuracy_model = GetConVar("swsrc_weapon_accuracy_model")
function SWEP:GetInaccuracy()
	local selfTable = self:GetTable()

	if weapon_accuracy_model:GetInt() == 1 then
		local owner = selfTable.GetPlayerOwner(self)
		if not owner then return 0 end

		if not owner:IsOnGround() then
			return 0.04 + 0.3 * selfTable.GetAccuracy(self)
		elseif owner:GetVelocity():Length2D() > 140 then
			return 0.04 + 0.07 * selfTable.GetAccuracy(self)
		else
			return 0.0375 * selfTable.GetAccuracy(self)
		end
	else
		return BaseClass.GetInaccuracy(self)
	end
end

function SWEP:PrimaryAttack()
	local selfTable = self:GetTable()

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return end

	-- don't fire underwater
	if owner:WaterLevel() == 3 then
		selfTable.PlayEmptySound(self, selfTable)
		self:SetNextPrimaryFire(CurTime() + 0.15)
		return
	end

	if not selfTable.CSBaseGunFire(self, selfTable.CSWpnData.m_flCycleTime, Primary_Mode) then return end

	if owner:GetVelocity():Length2D() > 5 then
		selfTable.KickBack(self, 1.0, 0.45, 0.28, 0.045, 3.75, 3, 7)
	elseif not owner:IsOnGround() then
		selfTable.KickBack(self, 1.2, 0.5, 0.23, 0.15, 5.5, 3.5, 6)
	elseif owner:IsDucking() then
		selfTable.KickBack(self, 0.6, 0.3, 0.2, 0.0125, 3.25, 2, 7)
	else
		selfTable.KickBack(self, 0.65, 0.35, 0.25, 0.015, 3.5, 2.25, 7)
	end
end
