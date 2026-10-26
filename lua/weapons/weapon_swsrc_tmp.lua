AddCSLuaFile()

SWEP.Base = "weapon_swsrc_basegun"
DEFINE_BASECLASS(SWEP.Base)

SWEP.Category = "#spawnmenu.category.swsrc"
SWEP.SubCategory = "#spawnmenu.category.swsrc_smgs"

SWEP.PrintName = "TMP"
SWEP.Spawnable = true
SWEP.HoldType = "smg"
SWEP.WorldModel = "models/weapons/w_smg_tmp.mdl"
SWEP.ViewModel = "models/weapons/cstrike/c_smg_tmp.mdl"
SWEP.IconOverride = "vgui/gfx/vgui/fav_weap/tmp"

SWEP.WeaponData = [=[WeaponData
{
	"MaxPlayerSpeed"		"250"
	"WeaponType"			"SubMachinegun"
	"FullAuto"				1
	"WeaponPrice"			"1250"
	"WeaponArmorRatio"		"1.0"
	"CrosshairMinDistance"		"7"
	"CrosshairDeltaDistance"	"3"
	"Team"				"CT"
	"BuiltRightHanded"		"0"
	"PlayerAnimationExtension"	"tmp"
	"MuzzleFlashScale"		"0.8"
	"MuzzleFlashStyle"		"CS_MUZZLEFLASH_NONE"

	"CanEquipWithShield"		"0"


	// Weapon characteristics:
	"Penetration"			"1"
	"Damage"			"26"
	"Range"				"4096"
	"RangeModifier"			"0.84"
	"Bullets"			"1"
	"CycleTime"			"0.07"
	"AccuracyDivisor"		"200"
	"AccuracyOffset"		"0.55"
	"MaxInaccuracy"			"1.4"
	"TimeToIdle"			"2"
	"IdleInterval"			"20"

	// New accuracy model parameters
	"Spread"					0.00100
	"InaccuracyCrouch"			0.01500
	"InaccuracyStand"			0.02000
	"InaccuracyJump"			0.11180
	"InaccuracyLand"			0.02236
	"InaccuracyLadder"			0.02795
	"InaccuracyFire"			0.01594
	"InaccuracyMove"			0.00389

	"RecoveryTimeCrouch"		0.15131
	"RecoveryTimeStand"			0.21184

	// Weapon data is loaded by both the Game and Client DLLs.
	"printname"			"#Cstrike_WPNHUD_Tmp"
	"viewmodel"			"models/weapons/v_smg_tmp.mdl"
	"playermodel"			"models/weapons/w_smg_tmp.mdl"

	"anim_prefix"			"anim"
	"bucket"			"0"
	"bucket_position"		"0"

	"clip_size"			"30"

	"primary_ammo"			"BULLET_PLAYER_9MM"
	"secondary_ammo"		"None"

	"weight"			"25"
	"item_flags"			"0"

	// Sounds for the weapon. There is a max of 16 sounds per category (i.e. max 16 "single_shot" sounds)
	SoundData
	{
		//"reload"			"Default.Reload"
		//"empty"				"Default.ClipEmpty_Rifle"
		"single_shot"			"Weapon_TMP.Single"
	}

	// Weapon Sprite data is loaded by the Client DLL.
	TextureData
	{
		"weapon"
		{
				"font"		"CSweaponsSmall"
				"character"	"D"
		}
		"weapon_s"
		{
				"font"		"CSweapons"
				"character"	"D"
		}
		"ammo"
		{
				"font"		"CSTypeDeath"
				"character"		"R"
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
			Mins	"-7 -4 -12"
			Maxs	"27 10 -1"
		}
		World
		{
			Mins	"-1 -5 -7"
			Maxs	"22 6 6"
		}
	}
}]=]

function SWEP:OverrideData(tbl)
	-- TODO: cvar for cs:s slots?
	tbl.Slot = 2
end

function SWEP:GetWeaponID()
	return WEAPON_TMP
end

local weapon_accuracy_model = GetConVar("swsrc_weapon_accuracy_model")
function SWEP:GetInaccuracy()
	local selfTable = self:GetTable()

	if weapon_accuracy_model:GetInt() == 1 then
		local owner = selfTable.GetPlayerOwner(self)
		if not owner then return 0 end

		if not owner:IsOnGround() then
			return 0.25 * selfTable.GetAccuracy(self)
		else
			return 0.03 * selfTable.GetAccuracy(self)
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
		selfTable.KickBack(self, 1.1, 0.5, 0.35, 0.045, 4.5, 3.5, 6)
	elseif owner:GetVelocity():Length2D() > 5 then
		selfTable.KickBack(self, 0.8, 0.4, 0.2, 0.03, 3, 2.5, 7)
	elseif owner:IsDucking() then
		selfTable.KickBack(self, 0.7, 0.35, 0.125, 0.025, 2.5, 2, 10)
	else
		selfTable.KickBack(self, 0.725, 0.375, 0.15, 0.025, 2.75, 2.25, 9)
	end
end

function SWEP:DoFireEffects(_)
	-- TMP is silenced, so do nothing
end
