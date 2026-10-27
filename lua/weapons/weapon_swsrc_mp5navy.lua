AddCSLuaFile()

SWEP.Base = "weapon_swsrc_basegun"
DEFINE_BASECLASS(SWEP.Base)

SWEP.Category = "#spawnmenu.category.swsrc"
SWEP.SubCategory = "#spawnmenu.category.swsrc_smgs"

SWEP.PrintName = "MP5"
SWEP.Spawnable = true
SWEP.HoldType = "smg"
SWEP.WorldModel = "models/weapons/w_smg_mp5.mdl"
SWEP.ViewModel = "models/weapons/cstrike/c_smg_mp5.mdl"
SWEP.IconOverride = "vgui/gfx/vgui/fav_weap/mp5"

SWEP.WeaponData = [=[WeaponData
{
	"MaxPlayerSpeed"		"250"
	"WeaponType"			"SubMachinegun"
	"FullAuto"				1
	"WeaponPrice"			"1500"
	"WeaponArmorRatio"		"1.0"
	"CrosshairMinDistance"		"6"
	"CrosshairDeltaDistance"	"2"
	"Team"				"ANY"
	"BuiltRightHanded"		"0"
	"PlayerAnimationExtension"	"mp5"
	"MuzzleFlashScale"		"1.1"
	
	"CanEquipWithShield"		"0"
	
	
	// Weapon characteristics:
	"Penetration"			"1"
	"Damage"			"26"
	"Range"				"4096"
	"RangeModifier"			"0.84"
	"Bullets"			"1"
	"CycleTime"			"0.08"
	"AccuracyDivisor"		"220"
	"AccuracyOffset"		"0.45"
	"MaxInaccuracy"			"0.75"
	"TimeToIdle"			"2"
	"IdleInterval"			"20"
	
	// New accuracy model parameters
	"Spread"					0.00100
	"InaccuracyCrouch"			0.01289
	"InaccuracyStand"			0.01718
	"InaccuracyJump"			0.23025
	"InaccuracyLand"			0.04605
	"InaccuracyLadder"			0.05756
	"InaccuracyFire"			0.00638
	"InaccuracyMove"			0.01785
								 
	"RecoveryTimeCrouch"		0.27960
	"RecoveryTimeStand"			0.39144
	
	// Weapon data is loaded by both the Game and Client DLLs.
	"printname"			"#Cstrike_WPNHUD_MP5"
	"viewmodel"			"models/weapons/v_smg_mp5.mdl"
	"playermodel"			"models/weapons/w_smg_mp5.mdl"
	
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
		"single_shot"		"Weapon_MP5Navy.Single"
	}

	// Weapon Sprite data is loaded by the Client DLL.
	TextureData
	{
		"weapon"
		{
				"font"		"CSweaponsSmall"
				"character"	"X"
		}
		"weapon_s"
		{	
				"font"		"CSweapons"
				"character"	"X"
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
			Mins	"-10 -4 -13"
			Maxs	"21 9 -1"
		}
		World
		{
			Mins	"-10 -7 -6"
			Maxs	"22 8 9"
		}
	}
}]=]

function SWEP:OverrideData(tbl)
	-- TODO: cvar for cs:s slots?
	tbl.Slot = 2
end

function SWEP:GetWeaponID()
	return WEAPON_MP5NAVY
end

local weapon_accuracy_model = GetConVar("swsrc_weapon_accuracy_model")
function SWEP:GetInaccuracy()
	local selfTable = self:GetTable()

	if weapon_accuracy_model:GetInt() == 1 then
		local owner = selfTable.GetPlayerOwner(self)
		if not owner then return 0 end

		if not owner:IsOnGround() then
			return 0.2 * selfTable.GetAccuracy(self)
		else
			return 0.04 * selfTable.GetAccuracy(self)
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
		selfTable.KickBack(self, 0.9, 0.475, 0.35, 0.0425, 5, 3, 6)
	elseif owner:GetVelocity():Length2D() > 5 then
		selfTable.KickBack(self, 0.5, 0.275, 0.2, 0.03, 3, 2, 10)
	elseif owner:IsDucking() then
		selfTable.KickBack(self, 0.225, 0.15, 0.1, 0.015, 2, 1, 10)
	else
		selfTable.KickBack(self, 0.25, 0.175, 0.125, 0.02, 2.25, 1.25, 10)
	end
end
