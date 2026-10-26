AddCSLuaFile()

SWEP.Base = "weapon_swsrc_basegun"
DEFINE_BASECLASS(SWEP.Base)

SWEP.Category = "#spawnmenu.category.swsrc"
SWEP.SubCategory = "#spawnmenu.category.swsrc_mgs"

SWEP.PrintName = "M249"
SWEP.Spawnable = true
SWEP.HoldType = "shotgun"
SWEP.WorldModel = "models/weapons/w_mach_m249para.mdl"
SWEP.ViewModel = "models/weapons/cstrike/c_mach_m249para.mdl"
SWEP.IconOverride = "vgui/gfx/vgui/fav_weap/m249"

SWEP.WeaponData = [=[WeaponData
{
	"MaxPlayerSpeed"		"220"
	"WeaponType"			"Machinegun"
	"FullAuto"				1
	"WeaponPrice"			"5750"
	"WeaponArmorRatio"		"1.6"
	"CrosshairMinDistance"		"6"
	"CrosshairDeltaDistance"	"3"
	"Team"				"ANY"
	"BuiltRightHanded"		"1"
	"PlayerAnimationExtension"	"m249"
	"MuzzleFlashScale"		"1.5"
	"MuzzleFlashStyle"		"CS_MUZZLEFLASH_X"
	"CanEquipWithShield" 		"0"


	// Weapon characteristics:
	"Penetration"			"2"
	"Damage"			"35"
	"Range"				"8192"
	"RangeModifier"			"0.97"
	"Bullets"			"1"
	"CycleTime"			"0.08"
	"AccuracyDivisor"		"175"
	"AccuracyOffset"		"0.4"
	"MaxInaccuracy"			"0.9"
	"TimeToIdle"			"1.6"
	"IdleInterval"			"20"

	// New accuracy model parameters
	"Spread"					0.00200
	"InaccuracyCrouch"			0.00763
	"InaccuracyStand"			0.01017
	"InaccuracyJump"			0.70830
	"InaccuracyLand"			0.14166
	"InaccuracyLadder"			0.13281
	"InaccuracyFire"			0.00427
	"InaccuracyMove"			0.10618

	"RecoveryTimeCrouch"		0.55920
	"RecoveryTimeStand"			0.78288

	// Weapon data is loaded by both the Game and Client DLLs.
	"printname"			"#Cstrike_WPNHUD_M249"
	"viewmodel"			"models/weapons/v_mach_m249para.mdl"
	"playermodel"			"models/weapons/w_mach_m249para.mdl"

	"anim_prefix"			"anim"
	"bucket"			"0"
	"bucket_position"		"0"

	"clip_size"			"100"

	"primary_ammo"			"BULLET_PLAYER_556MM_BOX"
	"secondary_ammo"		"None"

	"weight"			"25"
	"item_flags"			"0"

	// Sounds for the weapon. There is a max of 16 sounds per category (i.e. max 16 "single_shot" sounds)
	SoundData
	{
		//"reload"			"Default.Reload"
		//"empty"				"Default.ClipEmpty_Rifle"
		"single_shot"		"Weapon_M249.Single"
		special3			Default.Zoom
	}

	// Weapon Sprite data is loaded by the Client DLL.
	TextureData
	{
		"weapon"
		{
				"font"		"CSweaponsSmall"
				"character"	"Z"
		}
		"weapon_s"
		{
				"font"		"CSweapons"
				"character"	"Z"
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
			Mins	"-8 -8 -15"
			Maxs	"30 5 0"
		}
		World
		{
			Mins	"-4 -8 -6"
			Maxs	"31 8 10"
		}
	}
}]=]

function SWEP:OverrideData(tbl)
	-- TODO: cvar for cs:s slots?
	tbl.Slot = 2
end

function SWEP:GetWeaponID()
	return WEAPON_M249
end

function SWEP:SetupWeaponHoldTypeForAI(t)
	-- change player holdtypes
	self.ActivityTranslate[ACT_MP_RELOAD_STAND] = ACT_HL2MP_GESTURE_RELOAD_AR2
	self.ActivityTranslate[ACT_MP_RELOAD_CROUCH] = ACT_HL2MP_GESTURE_RELOAD_AR2

	self.ActivityTranslate[ACT_MP_ATTACK_STAND_PRIMARYFIRE] = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2
	self.ActivityTranslate[ACT_MP_ATTACK_CROUCH_PRIMARYFIRE] = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2
	self.ActivityTranslate[ACT_RANGE_ATTACK1] = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2

	BaseClass.SetupWeaponHoldTypeForAI(self, t)

	-- change NPC holdtypes
	self.ActivityTranslateAI[ACT_RANGE_ATTACK1] = ACT_RANGE_ATTACK_AR2
	self.ActivityTranslateAI[ACT_RELOAD] = ACT_RELOAD_SMG1

	self.ActivityTranslateAI[ACT_GESTURE_RANGE_ATTACK1] = ACT_GESTURE_RANGE_ATTACK_AR2
	self.ActivityTranslateAI[ACT_RANGE_ATTACK1_LOW] = ACT_RANGE_ATTACK_SMG1_LOW

	self.ActivityTranslateAI[ACT_RELOAD_LOW] = ACT_RELOAD_SMG1_LOW
	self.ActivityTranslateAI[ACT_GESTURE_RELOAD] = ACT_GESTURE_RELOAD_SMG1
end

local weapon_accuracy_model = GetConVar("swsrc_weapon_accuracy_model")
function SWEP:GetInaccuracy()
	local selfTable = self:GetTable()

	if weapon_accuracy_model:GetInt() == 1 then
		local owner = selfTable.GetPlayerOwner(self)
		if not owner then return 0 end

		if not owner:IsOnGround() then
			return 0.045 + 0.5 * selfTable.GetAccuracy(self)
		elseif owner:GetVelocity():Length2D() > 140 then
			return 0.045 + 0.095 * selfTable.GetAccuracy(self)
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
		selfTable.KickBack(self, 1.8, 0.65, 0.45, 0.125, 5, 3.5, 8)
	elseif owner:GetVelocity():Length2D() > 5 then
		selfTable.KickBack(self, 1.1, 0.5, 0.3, 0.06, 4, 3, 8)
	elseif owner:IsDucking() then
		selfTable.KickBack(self, 0.75, 0.325, 0.25, 0.025, 3.5, 2.5, 9)
	else
		selfTable.KickBack(self, 0.8, 0.35, 0.3, 0.03, 3.75, 3, 9)
	end
end
