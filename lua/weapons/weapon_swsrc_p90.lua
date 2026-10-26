AddCSLuaFile()

SWEP.Base = "weapon_swsrc_basegun"
DEFINE_BASECLASS(SWEP.Base)

SWEP.Category = "#spawnmenu.category.swsrc"
SWEP.SubCategory = "#spawnmenu.category.swsrc_smgs"

SWEP.PrintName = "P90"
SWEP.Spawnable = true
SWEP.HoldType = "smg"
SWEP.WorldModel = "models/weapons/w_smg_p90.mdl"
SWEP.ViewModel = "models/weapons/cstrike/c_smg_p90.mdl"
SWEP.IconOverride = "vgui/gfx/vgui/fav_weap/p90"

SWEP.WeaponData = [=[WeaponData
{
	"MaxPlayerSpeed"		"245"
	"WeaponType"			"SubMachinegun"
	"FullAuto"				1
	"WeaponPrice"			"2350"
	"WeaponArmorRatio"		"1.5"
	"CrosshairMinDistance"		"7"
	"CrosshairDeltaDistance"	"3"
	"Team"				"ANY"
	"BuiltRightHanded"		"0"
	"PlayerAnimationExtension"	"p90"
	"MuzzleFlashScale"		"1.2"
	"MuzzleFlashStyle"		"CS_MUZZLEFLASH_X"
	"CanEquipWithShield"		"0"


	// Weapon characteristics:
	"Penetration"			"1"
	"Damage"			"26"
	"Range"				"4096"
	"RangeModifier"			"0.84"
	"Bullets"			"1"
	"CycleTime"			"0.07"
	"AccuracyQuadratic"		"1"
	"AccuracyDivisor"		"175"
	"AccuracyOffset"		"0.45"
	"MaxInaccuracy"			"1.0"
	"TimeToIdle"			"2"
	"IdleInterval"			"20"

	// New accuracy model parameters
	"Spread"					0.00100
	"InaccuracyCrouch"			0.01463
	"InaccuracyStand"			0.01951
	"InaccuracyJump"			0.16494
	"InaccuracyLand"			0.03299
	"InaccuracyLadder"			0.04124
	"InaccuracyFire"			0.00732
	"InaccuracyMove"			0.01062

	"RecoveryTimeCrouch"		0.23289
	"RecoveryTimeStand"			0.32605

	// Weapon data is loaded by both the Game and Client DLLs.
	"printname"			"#Cstrike_WPNHUD_P90"
	"viewmodel"			"models/weapons/v_smg_p90.mdl"
	"playermodel"			"models/weapons/w_smg_p90.mdl"

	"anim_prefix"			"anim"
	"bucket"			"0"
	"bucket_position"		"0"

	"clip_size"			"50"

	"primary_ammo"			"BULLET_PLAYER_57MM"
	"secondary_ammo"		"None"

	"weight"			"26"
	"item_flags"			"0"

	// Sounds for the weapon. There is a max of 16 sounds per category (i.e. max 16 "single_shot" sounds)
	SoundData
	{
		//"reload"			"Default.Reload"
		//"empty"				"Default.ClipEmpty_Rifle"
		"single_shot"		"Weapon_P90.Single"
	}

	// Weapon Sprite data is loaded by the Client DLL.
	TextureData
	{
		"weapon"
		{
				"font"		"CSweaponsSmall"
				"character"	"M"
		}
		"weapon_s"
		{
				"font"		"CSweapons"
				"character"	"M"
		}
		"ammo"
		{
				"font"		"CSTypeDeath"
				"character"		"S"
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
			Mins	"-8 -3 -13"
			Maxs	"19 9 -1"
		}
		World
		{
			Mins	"-8 -1 -3"
			Maxs	"14 3 9"
		}
	}
}]=]

function SWEP:OverrideData(tbl)
	-- TODO: cvar for cs:s slots?
	tbl.Slot = 2
end

function SWEP:GetWeaponID()
	return WEAPON_P90
end

local weapon_accuracy_model = GetConVar("swsrc_weapon_accuracy_model")
function SWEP:GetInaccuracy()
	local selfTable = self:GetTable()

	if weapon_accuracy_model:GetInt() == 1 then
		local owner = selfTable.GetPlayerOwner(self)
		if not owner then return 0 end

		if not owner:IsOnGround() then
			return 0.3 * selfTable.GetAccuracy(self)
		elseif owner:GetVelocity():Length2D() > 170 then
			return 0.115 * selfTable.GetAccuracy(self)
		else
			return 0.045 * selfTable.GetAccuracy(self)
		end
	else
		return BaseClass.GetInaccuracy(self)
	end
end

function SWEP:PrimaryAttack()
	local selfTable = self:GetTable()

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return end

	if not selfTable.CSBaseGunFire(self, selfTable.CSWpnData.m_flCycleTime, Primary_Mode) then return end

	if not owner:IsOnGround() then
		selfTable.KickBack(self, 0.9, 0.45, 0.35, 0.04, 5.25, 3.5, 4)
	elseif owner:GetVelocity():Length2D() > 5 then
		selfTable.KickBack(self, 0.45, 0.3, 0.2, 0.0275, 4, 2.25, 7)
	elseif owner:IsDucking() then
		selfTable.KickBack(self, 0.275, 0.2, 0.125, 0.02, 3, 1, 9)
	else
		selfTable.KickBack(self, 0.3, 0.225, 0.125, 0.02, 3.25, 1.25, 8)
	end
end
