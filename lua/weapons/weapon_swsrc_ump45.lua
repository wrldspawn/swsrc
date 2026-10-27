AddCSLuaFile()

SWEP.Base = "weapon_swsrc_basegun"
DEFINE_BASECLASS(SWEP.Base)

SWEP.Category = "#spawnmenu.category.swsrc"
SWEP.SubCategory = "#spawnmenu.category.swsrc_smgs"

SWEP.PrintName = "UMP45"
SWEP.Spawnable = true
SWEP.HoldType = "smg"
SWEP.WorldModel = "models/weapons/w_smg_ump45.mdl"
SWEP.ViewModel = "models/weapons/cstrike/c_smg_ump45.mdl"
SWEP.IconOverride = "vgui/gfx/vgui/fav_weap/ump45"

SWEP.WeaponData = [=[WeaponData
{
	"MaxPlayerSpeed"		"250"
	"WeaponType"			"SubMachinegun"
	"FullAuto"				1
	"WeaponPrice"			"1700"
	"WeaponArmorRatio"		"1.0"
	"CrosshairMinDistance"		"6"
	"CrosshairDeltaDistance"	"3"
	"Team"				"ANY"
	"BuiltRightHanded"		"0"
	"PlayerAnimationExtension"	"ump45"
	"MuzzleFlashScale"		"1.15"
	
	"CanEquipWithShield"		"0"
	
	
	// Weapon characteristics:
	"Penetration"			"1"
	"Damage"			"30"
	"Range"				"4096"
	"RangeModifier"			"0.82"
	"Bullets"			"1"
	"CycleTime"			"0.105"
	"AccuracyQuadratic"		"1"
	"AccuracyDivisor"		"210"
	"AccuracyOffset"		"0.5"
	"MaxInaccuracy"			"1"
	"TimeToIdle"			"2"
	"IdleInterval"			"20"
	
	// New accuracy model parameters
	"Spread"					0.00100
	"InaccuracyCrouch"			0.01439
	"InaccuracyStand"			0.01919
	"InaccuracyJump"			0.16941
	"InaccuracyLand"			0.03388
	"InaccuracyLadder"			0.04235
	"InaccuracyFire"			0.01129
	"InaccuracyMove"			0.01366
	
	"RecoveryTimeCrouch"		0.21710
	"RecoveryTimeStand"			0.30394
	
	// Weapon data is loaded by both the Game and Client DLLs.
	"printname"			"#Cstrike_WPNHUD_UMP45"
	"viewmodel"			"models/weapons/v_smg_ump45.mdl"
	"playermodel"			"models/weapons/w_smg_ump45.mdl"
	
	"anim_prefix"			"anim"
	"bucket"			"0"
	"bucket_position"		"0"

	"clip_size"			"25"
	
	"primary_ammo"			"BULLET_PLAYER_45ACP"
	"secondary_ammo"		"None"

	"weight"			"25"
	"item_flags"			"0"

	// Sounds for the weapon. There is a max of 16 sounds per category (i.e. max 16 "single_shot" sounds)
	SoundData
	{
		//"reload"			"Default.Reload"
		//"empty"				"Default.ClipEmpty_Rifle"
		"single_shot"		"Weapon_UMP45.Single"
	}

	// Weapon Sprite data is loaded by the Client DLL.
	TextureData
	{
		"weapon"
		{
				"font"		"CSweaponsSmall"
				"character"	"Q"
		}
		"weapon_s"
		{	
				"font"		"CSweapons"
				"character"	"Q"
		}
		"ammo"
		{
				"font"		"CSTypeDeath"
				"character"		"M"
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
			Mins	"-7 -1 -15"
			Maxs	"27 11 -2"
		}
		World
		{
			Mins	"-10 -7 -8"
			Maxs	"20 8 8"
		}
	}
}]=]

function SWEP:OverrideData(tbl)
	-- TODO: cvar for cs:s slots?
	tbl.Slot = 2
end

function SWEP:GetWeaponID()
	return WEAPON_UMP45
end

local weapon_accuracy_model = GetConVar("swsrc_weapon_accuracy_model")
function SWEP:GetInaccuracy()
	local selfTable = self:GetTable()

	if weapon_accuracy_model:GetInt() == 1 then
		local owner = selfTable.GetPlayerOwner(self)
		if not owner then return 0 end

		if not owner:IsOnGround() then
			return 0.24 * selfTable.GetAccuracy(self)
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
		selfTable.KickBack(self, 0.125, 0.65, 0.55, 0.0475, 5.5, 4, 10)
	elseif owner:GetVelocity():Length2D() > 5 then
		selfTable.KickBack(self, 0.55, 0.3, 0.225, 0.03, 3.5, 2.5, 10)
	elseif owner:IsDucking() then
		selfTable.KickBack(self, 0.25, 0.175, 0.125, 0.02, 2.25, 1.25, 10)
	else
		selfTable.KickBack(self, 0.275, 0.2, 0.15, 0.0225, 2.5, 1.5, 10)
	end
end
