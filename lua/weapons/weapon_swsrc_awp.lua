AddCSLuaFile()

SWEP.Base = "weapon_swsrc_basegun"
DEFINE_BASECLASS(SWEP.Base)

SWEP.Category = "#spawnmenu.category.swsrc"
SWEP.SubCategory = "#spawnmenu.category.swsrc_snipers"

SWEP.PrintName = "AWP"
SWEP.Spawnable = true
SWEP.HoldType = "ar2"
SWEP.WorldModel = "models/weapons/w_snip_awp.mdl"
SWEP.ViewModel = "models/weapons/cstrike/c_snip_awp.mdl"
SWEP.IconOverride = "vgui/gfx/vgui/fav_weap/awp"

SWEP.WeaponData = [=[WeaponData
{
	"MaxPlayerSpeed"			"210"
	"WeaponType" 			"SniperRifle"
	"FullAuto"				0
	"WeaponPrice"			"4750"
	"WeaponArmorRatio"		"1.95"
	"CrosshairMinDistance"		"8"
	"CrosshairDeltaDistance"	"3"
	"Team"				"ANY"
	"BuiltRightHanded"		"0"
	"PlayerAnimationExtension" 	"awp"
	"MuzzleFlashScale"		"1.35"

	"CanEquipWithShield"		"0"


	// Weapon characteristics:
	"Penetration"			"3"
	"Damage"			"115"
	"Range"				"8192"
	"RangeModifier"			"0.99"
	"Bullets"			"1"
	"CycleTime"			"1.5"	// 1.455
	"AccuracyDivisor"		"-1"
	"AccuracyOffset"		"0"
	"MaxInaccuracy"			"0"
	"TimeToIdle"			"2"
	"IdleInterval"			"60"

	// New accuracy model parameters
	"Spread"					0.00020
	"InaccuracyCrouch"			0.06060
	"InaccuracyStand"			0.08080
	"InaccuracyJump"			0.54600
	"InaccuracyLand"			0.05460
	"InaccuracyLadder"			0.13650
	"InaccuracyFire"			0.14000
	"InaccuracyMove"			0.27300

	"SpreadAlt"					0.00020
	"InaccuracyCrouchAlt"		0.00150
	"InaccuracyStandAlt"		0.00200
	"InaccuracyJumpAlt"			0.54600
	"InaccuracyLandAlt"			0.05460
	"InaccuracyLadderAlt"		0.13650
	"InaccuracyFireAlt"			0.14000
	"InaccuracyMoveAlt"			0.27300

	"RecoveryTimeCrouch"		0.24671
	"RecoveryTimeStand"			0.34539

	// Weapon data is loaded by both the Game and Client DLLs.
	"printname"			"#Cstrike_WPNHUD_AWP"
	"viewmodel"			"models/weapons/v_snip_awp.mdl"
	"playermodel"			"models/weapons/w_snip_awp.mdl"

	"anim_prefix"			"anim"
	"bucket"			"0"
	"bucket_position"		"0"

	"clip_size"			"10"

	"primary_ammo"			"BULLET_PLAYER_338MAG"
	"secondary_ammo"		"None"

	"weight"			"30"
	"item_flags"			"0"

	// Sounds for the weapon. There is a max of 16 sounds per category (i.e. max 16 "single_shot" sounds)
	SoundData
	{
		//"reload"			"Weapon_AWP.Reload"
		//"empty"				"Default.ClipEmpty_Rifle"
		"single_shot"		"Weapon_AWP.Single"
		special3			Default.Zoom
	}

	// Weapon Sprite data is loaded by the Client DLL.
	TextureData
	{
		"weapon"
		{
				"font"		"CSweaponsSmall"
				"character"	"R"
		}
		"weapon_s"
		{
				"font"		"CSweapons"
				"character"	"R"
		}
		"ammo"
		{
				"font"		"CSTypeDeath"
				"character"		"W"
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
			Mins	"-11 -3 -12"
			Maxs	"32 10 0"
		}
		World
		{
			Mins	"-12 -6 -15"
			Maxs	"38 9 15"
		}
	}
}]=]

function SWEP:OverrideData(tbl)
	-- TODO: cvar for cs:s slots?
	tbl.Slot = 3
end

function SWEP:GetWeaponID()
	return WEAPON_AWP
end

local cAWPMidZoomFOV = 40
local cAWPMaxZoomFOV = 10
local kZoomTime = 0.1

function SWEP:SecondaryAttack()
	local selfTable = self:GetTable()

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return end

	local fov = math.floor(owner:GetFOV())
	if fov == owner:GetDefaultFOV() then
		owner:SetFOV(cAWPMidZoomFOV, kZoomTime)
		selfTable.SetWeaponMode(self, Secondary_Mode)
		selfTable.SetAccuracyPenalty(self, selfTable.GetAccuracyPenalty(self) + selfTable.CSWpnData.m_fInaccuracyAltSwitch)
		self:SetHoldType("rpg")
	elseif fov == cAWPMidZoomFOV then
		owner:SetFOV(cAWPMaxZoomFOV, kZoomTime)
		selfTable.SetWeaponMode(self, Secondary_Mode)
		self:SetHoldType("rpg")
	else
		owner:SetFOV(0, kZoomTime)
		selfTable.SetWeaponMode(self, Primary_Mode)
		self:SetHoldType(selfTable.HoldType)
	end

	if SERVER then
		owner:EmitSound("Default.Zoom")
	end

	self:SetNextSecondaryFire(CurTime() + 0.3)
	selfTable.SetZoomFullyActiveTime(self, CurTime() + 0.15)
end

local weapon_accuracy_model = GetConVar("swsrc_weapon_accuracy_model")
function SWEP:GetInaccuracy()
	local selfTable = self:GetTable()

	if weapon_accuracy_model:GetInt() == 1 then
		local owner = selfTable.GetPlayerOwner(self)
		if not owner then return 0 end

		local fSpread = 0

		local vel = owner:GetVelocity():Length2D()
		if not owner:IsOnGround() then
			fSpread = 0.85
		elseif vel > 140 then
			fSpread = 0.25
		elseif vel > 10 then
			fSpread = 0.1
		elseif owner:IsDucking() then
			fSpread = 0
		else
			fSpread = 0.001
		end

		-- If we are not zoomed in, or we have very recently zoomed and are still transitioning, the bullet diverts more.
		if math.floor(owner:GetFOV()) == owner:GetDefaultFOV() or CurTime() < selfTable.GetZoomFullyActiveTime(self) then
			fSpread = fSpread + 0.08
		end

		return fSpread
	else
		return BaseClass.GetInaccuracy(self)
	end
end

function SWEP:PrimaryAttack()
	local selfTable = self:GetTable()

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return end

	local m_weaponMode = selfTable.GetWeaponMode(self)
	if not selfTable.CSBaseGunFire(self, selfTable.CSWpnData.m_flCycleTime, m_weaponMode) then return end

	if m_weaponMode == Secondary_Mode then
		local fov = math.floor(owner:GetFOV())
		local midFOVdistance = math.abs(fov - cAWPMidZoomFOV)
		local farFOVdistance = math.abs(fov - cAWPMaxZoomFOV)
		if midFOVdistance < farFOVdistance then
			selfTable.SetLastZoom(self, cAWPMidZoomFOV)
		else
			selfTable.SetLastZoom(self, cAWPMaxZoomFOV)
		end

		self:SetHoldType(selfTable.HoldType)
		selfTable.SetResumeZoom(self, true)
		owner:SetFOV(0, 0.1)
		selfTable.SetWeaponMode(self, Primary_Mode)
	end

	owner:ViewPunch(Angle(-2, 0, 0))
end

function SWEP:GetMaxSpeed()
	local selfTable = self:GetTable()

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return BaseClass.GetMaxSpeed(self) end

	if math.floor(owner:GetFOV()) == owner:GetDefaultFOV() then
		return BaseClass.GetMaxSpeed(self)
	else
		-- Slower speed when zoomed in.
		return 150
	end
end

function SWEP:IsAwp()
	return true
end

function SWEP:Reload()
	local selfTable = self:GetTable()
	selfTable.SetWeaponMode(self, Primary_Mode)
	self:SetHoldType(selfTable.HoldType)

	return BaseClass.Reload(self)
end

function SWEP:Deploy()
	local selfTable = self:GetTable()

	local oPri = self:GetNextPrimaryFire()
	local oSec = self:GetNextSecondaryFire()

	if not BaseClass.Deploy(self) then return false end

	selfTable.SetWeaponMode(self, Primary_Mode)

	self:SetNextPrimaryFire(math.max(self:GetNextPrimaryFire(), oPri))
	self:SetNextSecondaryFire(math.max(self:GetNextSecondaryFire(), oSec))
	return true
end
