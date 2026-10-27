AddCSLuaFile()

SWEP.Base = "weapon_swsrc_basegun"
DEFINE_BASECLASS(SWEP.Base)

SWEP.Category = "#spawnmenu.category.swsrc"
SWEP.SubCategory = "#spawnmenu.category.swsrc_snipers"

SWEP.PrintName = "Scout"
SWEP.Spawnable = true
SWEP.HoldType = "ar2"
SWEP.WorldModel = "models/weapons/w_snip_scout.mdl"
SWEP.ViewModel = "models/weapons/cstrike/c_snip_scout.mdl"
SWEP.IconOverride = "vgui/gfx/vgui/fav_weap/scout"

SWEP.WeaponData = [=[WeaponData
{
	"MaxPlayerSpeed" 		"260"
	"WeaponType" 			"SniperRifle"
	"FullAuto"				0
	"WeaponPrice"			"2750"
	"WeaponArmorRatio"		"1.7"
	"CrosshairMinDistance"		"5"
	"CrosshairDeltaDistance"	"3"
	"Team"				"ANY"
	"BuiltRightHanded"		"0"
	"PlayerAnimationExtension"	"scout"
	"MuzzleFlashScale"		"1.1"
	
	"CanEquipWithShield"		"0"
	
	
	// Weapon characteristics:
	"Penetration"			"3"
	"Damage"			"75"
	"Range"				"8192"
	"RangeModifier"			"0.98"
	"Bullets"			"1"
	"CycleTime"			"1.25"
	"AccuracyDivisor"		"-1"
	"AccuracyOffset"		"0"
	"MaxInaccuracy"			"0"
	"TimeToIdle"			"1.8"
	"IdleInterval"			"60"

	// New accuracy model parameters
	"Spread"					0.00030
	"InaccuracyCrouch"			0.02378
	"InaccuracyStand"			0.03170
	"InaccuracyJump"			0.38195
	"InaccuracyLand"			0.03819
	"InaccuracyLadder"			0.09549
	"InaccuracyFire"			0.06667
	"InaccuracyMove"			0.19097
								 
	"SpreadAlt"					0.00030
	"InaccuracyCrouchAlt"		0.00300
	"InaccuracyStandAlt"		0.00400
	"InaccuracyJumpAlt"			0.38195
	"InaccuracyLandAlt"			0.03819
	"InaccuracyLadderAlt"		0.09549
	"InaccuracyFireAlt"			0.06667
	"InaccuracyMoveAlt"			0.19097
								 
	"RecoveryTimeCrouch"		0.17681
	"RecoveryTimeStand"			0.24753
	
	// Weapon data is loaded by both the Game and Client DLLs.
	"printname"			"#Cstrike_WPNHUD_Scout"
	"viewmodel"			"models/weapons/v_snip_scout.mdl"
	"playermodel"			"models/weapons/w_snip_scout.mdl"
	
	"anim_prefix"			"anim"
	"bucket"			"0"
	"bucket_position"		"0"

	"clip_size"			"10"
	
	"primary_ammo"			"BULLET_PLAYER_762MM"
	"secondary_ammo"		"None"

	"weight"			"30"
	"item_flags"			"0"

	// Sounds for the weapon. There is a max of 16 sounds per category (i.e. max 16 "single_shot" sounds)
	SoundData
	{
		//"reload"			"Weapon_AWP.Reload"
		//"empty"				"Default.ClipEmpty_Rifle"
		"single_shot"		"Weapon_Scout.Single"
		special3			Default.Zoom
	}

	// Weapon Sprite data is loaded by the Client DLL.
	TextureData
	{
		"weapon"
		{
				"font"		"CSweaponsSmall"
				"character"	"N"
		}
		"weapon_s"
		{	
				"font"		"CSweapons"
				"character"	"N"
		}
		"ammo"
		{
				"font"		"CSTypeDeath"
				"character"		"V"
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
			Mins	"-12 -4 -11"
			Maxs	"27 12 -1"
		}
		World
		{
			Mins	"-10 -4 -13"
			Maxs	"32 8 12"
		}
	}
}]=]

function SWEP:OverrideData(tbl)
	-- TODO: cvar for cs:s slots?
	tbl.Slot = 3
end

function SWEP:GetWeaponID()
	return WEAPON_SCOUT
end

local cScoutMidZoomFOV = 40
local cScoutMaxZoomFOV = 15
local kZoomTime = 0.1

function SWEP:SecondaryAttack()
	local selfTable = self:GetTable()

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return end

	local fov = math.floor(owner:GetFOV())
	if fov == owner:GetDefaultFOV() then
		owner:SetFOV(cScoutMidZoomFOV, kZoomTime)
		selfTable.SetWeaponMode(self, Secondary_Mode)
		selfTable.SetAccuracyPenalty(self, selfTable.GetAccuracyPenalty(self) + selfTable.CSWpnData.m_fInaccuracyAltSwitch)
		self:SetHoldType("rpg")
	elseif fov == cScoutMidZoomFOV then
		owner:SetFOV(cScoutMaxZoomFOV, kZoomTime)
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
			fSpread = 0.2
		elseif vel > 170 then
			fSpread = 0.075
		elseif owner:IsDucking() then
			fSpread = 0
		else
			fSpread = 0.007
		end

		-- If we are not zoomed in, or we have very recently zoomed and are still transitioning, the bullet diverts more.
		if math.floor(owner:GetFOV()) == owner:GetDefaultFOV() or CurTime() < selfTable.GetZoomFullyActiveTime(self) then
			fSpread = fSpread + 0.025
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
		local midFOVdistance = math.abs(fov - cScoutMidZoomFOV)
		local farFOVdistance = math.abs(fov - cScoutMaxZoomFOV)
		if midFOVdistance < farFOVdistance then
			selfTable.SetLastZoom(self, cScoutMidZoomFOV)
		else
			selfTable.SetLastZoom(self, cScoutMaxZoomFOV)
		end

		self:SetHoldType(selfTable.HoldType)
		selfTable.SetResumeZoom(self, true)
		owner:SetFOV(0, 0.1)
		selfTable.SetWeaponMode(self, Primary_Mode)
	end

	selfTable.SetViewPunchPitch(self, selfTable.GetViewPunchPitch(self) - 2)
end

function SWEP:GetMaxSpeed()
	local selfTable = self:GetTable()

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return BaseClass.GetMaxSpeed(self) end

	if math.floor(owner:GetFOV()) == owner:GetDefaultFOV() then
		return BaseClass.GetMaxSpeed(self)
	else
		-- Slower speed when zoomed in.
		return 220
	end
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
