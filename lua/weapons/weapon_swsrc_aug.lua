AddCSLuaFile()

SWEP.Base = "weapon_swsrc_basegun"
DEFINE_BASECLASS(SWEP.Base)

SWEP.Category = "#spawnmenu.category.swsrc"
SWEP.SubCategory = "#spawnmenu.category.swsrc_rifles"

SWEP.PrintName = "AUG"
SWEP.Spawnable = true
SWEP.HoldType = "ar2"
SWEP.WorldModel = "models/weapons/w_rif_aug.mdl"
SWEP.ViewModel = "models/weapons/cstrike/c_rif_aug.mdl"
SWEP.IconOverride = "vgui/gfx/vgui/fav_weap/aug"

SWEP.WeaponData = [=[WeaponData
{
	"MaxPlayerSpeed"		"221"
	"WeaponType"			"Rifle"
	"FullAuto"				1
	"WeaponPrice"			"3500"
	"WeaponArmorRatio"		"1.4"
	"CrosshairMinDistance"		"3"
	"CrosshairDeltaDistance"	"3"
	"Team"				"CT"
	"BuiltRightHanded"		"0"
	"PlayerAnimationExtension"	"aug"
	"MuzzleFlashScale"		"1.3"
	"MuzzleFlashStyle"		"CS_MUZZLEFLASH_X"
	"CanEquipWithShield"		"0"


	// Weapon characteristics:
	"Penetration"			"2"
	"Damage"			"32"
	"Range"				"8192"
	"RangeModifier"			"0.96"
	"Bullets"			"1"
	"CycleTime"			"0.09"
	"AccuracyDivisor"		"215"
	"AccuracyOffset"		"0.3"
	"MaxInaccuracy"			"1.0"
	"TimeToIdle"			"1.9"
	"IdleInterval"			"20"

	// New accuracy model parameters
	"Spread"					0.00060
	"InaccuracyCrouch"			0.00412
	"InaccuracyStand"			0.00549
	"InaccuracyJump"			0.36936
	"InaccuracyLand"			0.07387
	"InaccuracyLadder"			0.09234
	"InaccuracyFire"			0.01090
	"InaccuracyMove"			0.07268

	"SpreadAlt"					0.00060
	"InaccuracyCrouchAlt"		0.00288
	"InaccuracyStandAlt"		0.00385
	"InaccuracyJumpAlt"			0.36936
	"InaccuracyLandAlt"			0.07387
	"InaccuracyLadderAlt"		0.09234
	"InaccuracyFireAlt"			0.01090
	"InaccuracyMoveAlt"			0.07268

	"RecoveryTimeCrouch"		0.30263
	"RecoveryTimeStand"			0.42368

	// Weapon data is loaded by both the Game and Client DLLs.
	"printname"			"#Cstrike_WPNHUD_Aug"
	"viewmodel"			"models/weapons/v_rif_aug.mdl"
	"playermodel"			"models/weapons/w_rif_aug.mdl"

	"anim_prefix"			"anim"
	"bucket"			"0"
	"bucket_position"		"0"

	"clip_size"			"30"

	"primary_ammo"			"BULLET_PLAYER_762MM"
	"secondary_ammo"		"None"

	"weight"			"25"
	"item_flags"			"0"

	// Sounds for the weapon. There is a max of 16 sounds per category (i.e. max 16 "single_shot" sounds)
	SoundData
	{
		//"reload"			"Default.Reload"
		//"empty"				"Default.ClipEmpty_Rifle"
		"single_shot"		"Weapon_AUG.Single"
	}

	// Weapon Sprite data is loaded by the Client DLL.
	TextureData
	{
		"weapon"
		{
				"font"		"CSweaponsSmall"
				"character"	"E"
		}
		"weapon_s"
		{
				"font"		"CSweapons"
				"character"	"E"
		}
		"ammo"
		{
				"font"		"CSTypeDeath"
				"character"		"V"
		}
		"zoom"
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
			Mins	"-9 -3 -15"
			Maxs	"25 12 -1"
		}
		World
		{
			Mins	"-11 -1 -5"
			Maxs	"23 4 10"
		}
	}
}]=]

function SWEP:OverrideData(tbl)
	-- TODO: cvar for cs:s slots?
	tbl.Slot = 2
end

function SWEP:GetWeaponID()
	return WEAPON_AUG
end

function SWEP:SecondaryAttack()
	local selfTable = self:GetTable()

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return end

	local fov = math.floor(owner:GetFOV())
	if fov == owner:GetDefaultFOV() then
		owner:SetFOV(55, 0.2)
		selfTable.SetWeaponMode(self, Secondary_Mode)
	elseif fov == 55 then
		owner:SetFOV(0, 0.15)
		selfTable.SetWeaponMode(self, Primary_Mode)
	else
		owner:SetFOV(0)
		selfTable.SetWeaponMode(self, Primary_Mode)
	end

	self:SetNextSecondaryFire(CurTime() + 0.3)
end

local weapon_accuracy_model = GetConVar("swsrc_weapon_accuracy_model")
function SWEP:GetInaccuracy()
	local selfTable = self:GetTable()

	if weapon_accuracy_model:GetInt() == 1 then
		local owner = selfTable.GetPlayerOwner(self)
		if not owner then return 0 end

		if not owner:IsOnGround() then
			return 0.035 + 0.4 * selfTable.GetAccuracy(self)
		elseif owner:GetVelocity():Length2D() > 140 then
			return 0.035 + 0.07 * selfTable.GetAccuracy(self)
		else
			return 0.02 * selfTable.GetAccuracy(self)
		end
	else
		return BaseClass.GetInaccuracy(self)
	end
end

function SWEP:PrimaryAttack()
	local selfTable = self:GetTable()

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return end

	local bZoomed = math.floor(owner:GetFOV()) < owner:GetDefaultFOV()

	local flCycleTime = selfTable.CSWpnData.m_flCycleTime

	if bZoomed then
		flCycleTime = 0.135
	end

	if not self:CSBaseGunFire(flCycleTime, selfTable.GetWeaponMode(self)) then return end

	if owner:GetVelocity():Length2D() > 5 then
		selfTable.KickBack(self, 1, 0.45, 0.275, 0.05, 4, 2.5, 7)
	elseif not owner:IsOnGround() then
		selfTable.KickBack(self, 1.25, 0.45, 0.22, 0.18, 5.5, 4, 5)
	elseif owner:IsDucking() then
		selfTable.KickBack(self, 0.575, 0.325, 0.2, 0.011, 3.25, 2, 8)
	else
		selfTable.KickBack(self, 0.625, 0.375, 0.25, 0.0125, 3.5, 2.25, 8)
	end
end

function SWEP:Reload()
	self:SetWeaponMode(Primary_Mode)
	return BaseClass.Reload(self)
end
function SWEP:Deploy()
	self:SetWeaponMode(Primary_Mode)
	return BaseClass.Deploy(self)
end
