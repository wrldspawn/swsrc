AddCSLuaFile()

SWEP.Base = "weapon_swsrc_basegun"
DEFINE_BASECLASS(SWEP.Base)

SWEP.Category = "#spawnmenu.category.swsrc"
SWEP.SubCategory = "#spawnmenu.category.swsrc_smgs"

SWEP.PrintName = "MAC10"
SWEP.Spawnable = true
SWEP.HoldType = "smg"
SWEP.WorldModel = "models/weapons/w_smg_mac10.mdl"
SWEP.ViewModel = "models/weapons/cstrike/c_smg_mac10.mdl"
SWEP.IconOverride = "vgui/gfx/vgui/fav_weap/mac10"

SWEP.WeaponData = [=[WeaponData
{
	"MaxPlayerSpeed"		"250"
	"WeaponType"			"SubMachinegun"
	"FullAuto"				1
	"WeaponPrice"			"1400"
	"WeaponArmorRatio"		"0.95"
	"CrosshairMinDistance"		"9"
	"CrosshairDeltaDistance"	"3"
	"Team"				"TERRORIST"
	"BuiltRightHanded"		"0"
	"PlayerAnimationExtension"	"mac10"
	"MuzzleFlashScale"		"1.1"
	
	"CanEquipWithShield"		"0"
	
	
	// Weapon characteristics:
	"Penetration"			"1"
	"Damage"			"29"
	"Range"				"4096"
	"RangeModifier"			"0.82"
	"Bullets"			"1"
	"CycleTime"			"0.075"
	"AccuracyDivisor"		"200"
	"AccuracyOffset"		"0.6"
	"MaxInaccuracy"			"1.65"
	"TimeToIdle"			"2"
	"IdleInterval"			"20"

	// New accuracy model parameters
	"Spread"					0.00100
	"InaccuracyCrouch"			0.01425
	"InaccuracyStand"			0.01900
	"InaccuracyJump"			0.13704
	"InaccuracyLand"			0.02741
	"InaccuracyLadder"			0.03426
	"InaccuracyFire"			0.00845
	"InaccuracyMove"			0.00620
								 
	"RecoveryTimeCrouch"		0.25263
	"RecoveryTimeStand"			0.35368
	
	// Weapon data is loaded by both the Game and Client DLLs.
	"printname"			"#Cstrike_WPNHUD_MAC10"
	"viewmodel"			"models/weapons/v_smg_mac10.mdl"
	"playermodel"			"models/weapons/w_smg_mac10.mdl"
	
	"anim_prefix"			"anim"
	"bucket"			"0"
	"bucket_position"		"0"

	"clip_size"			"30"
	
	"primary_ammo"			"BULLET_PLAYER_45ACP"
	"secondary_ammo"		"None"

	"weight"			"25"
	"item_flags"			"0"

	// Sounds for the weapon. There is a max of 16 sounds per category (i.e. max 16 "single_shot" sounds)
	SoundData
	{
		//"reload"			"Default.Reload"
		//"empty"				"Default.ClipEmpty_Rifle"
		"single_shot"		"Weapon_MAC10.Single"
	}

	// Weapon Sprite data is loaded by the Client DLL.
	TextureData
	{
		"weapon"
		{
				"font"		"CSweaponsSmall"
				"character"	"L"
		}
		"weapon_s"
		{	
				"font"		"CSweapons"
				"character"	"L"
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
			Mins	"-4 -5 -14"
			Maxs	"20 10 0"
		}
		World
		{
			Mins	"-2 -4 -7"
			Maxs	"13 4 7"
		}
	}
}]=]

function SWEP:OverrideData(tbl)
	-- TODO: cvar for cs:s slots?
	tbl.Slot = 2
end

function SWEP:GetWeaponID()
	return WEAPON_MAC10
end

local weapon_accuracy_model = GetConVar("swsrc_weapon_accuracy_model")
function SWEP:GetInaccuracy()
	local selfTable = self:GetTable()

	if weapon_accuracy_model:GetInt() == 1 then
		local owner = selfTable.GetPlayerOwner(self)
		if not owner then return 0 end

		if not owner:IsOnGround() then
			return 0.375 * selfTable.GetAccuracy(self)
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
		selfTable.KickBack(self, 1.3, 0.55, 0.4, 0.05, 4.75, 3.75, 5)
	elseif owner:GetVelocity():Length2D() > 5 then
		selfTable.KickBack(self, 0.9, 0.45, 0.25, 0.035, 3.5, 2.75, 7)
	elseif owner:IsDucking() then
		selfTable.KickBack(self, 0.75, 0.4, 0.175, 0.03, 2.75, 2.5, 10)
	else
		selfTable.KickBack(self, 0.775, 0.425, 0.2, 0.03, 3, 2.75, 9)
	end
end
