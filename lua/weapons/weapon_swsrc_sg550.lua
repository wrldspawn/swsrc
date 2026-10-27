AddCSLuaFile()

SWEP.Base = "weapon_swsrc_basegun"
DEFINE_BASECLASS(SWEP.Base)

SWEP.Category = "#spawnmenu.category.swsrc"
SWEP.SubCategory = "#spawnmenu.category.swsrc_snipers"

SWEP.PrintName = "SG550"
SWEP.Spawnable = true
SWEP.HoldType = "ar2"
SWEP.WorldModel = "models/weapons/w_snip_sg550.mdl"
SWEP.ViewModel = "models/weapons/cstrike/c_snip_sg550.mdl"
SWEP.IconOverride = "vgui/gfx/vgui/fav_weap/sg550"

SWEP.WeaponData = [=[WeaponData
{
	"MaxPlayerSpeed"		"210"
	"WeaponType"			"SniperRifle"
	"FullAuto"				1
	"WeaponPrice"			"4200"
	"WeaponArmorRatio"		"1.45"
	"CrosshairMinDistance"		"5"
	"CrosshairDeltaDistance"	"3"
	"Team"				"CT"
	"BuiltRightHanded"		"0"
	"PlayerAnimationExtension"	"sg550"
	"MuzzleFlashScale"		"1.6"
	"MuzzleFlashStyle"		"CS_MUZZLEFLASH_X"
	"CanEquipWithShield"		"0"
	
	
	// Weapon characteristics:
	"Penetration"			"2"
	"Damage"			"70"
	"Range"				"8192"
	"RangeModifier"			"0.98"
	"Bullets"			"1"
	"CycleTime"			"0.25"
	"AccuracyDivisor"		"-1"
	"AccuracyOffset"		"0"
	"MaxInaccuracy"			"0"
	"TimeToIdle"			"1.8"
	"IdleInterval"			"60"

	// New accuracy model parameters
	"Spread"					0.00030
	"InaccuracyCrouch"			0.01928
	"InaccuracyStand"			0.02570
	"InaccuracyJump"			0.43727
	"InaccuracyLand"			0.04373
	"InaccuracyLadder"			0.10932
	"InaccuracyFire"			0.03829
	"InaccuracyMove"			0.21864
								 
	"SpreadAlt"					0.00030
	"InaccuracyCrouchAlt"		0.00150
	"InaccuracyStandAlt"		0.00200
	"InaccuracyJumpAlt"			0.43727
	"InaccuracyLandAlt"			0.04373
	"InaccuracyLadderAlt"		0.10932
	"InaccuracyFireAlt"			0.03829
	"InaccuracyMoveAlt"			0.21864
								 
	"RecoveryTimeCrouch"		0.20970
	"RecoveryTimeStand"			0.29358
	
	// Weapon data is loaded by both the Game and Client DLLs.
	"printname"			"#Cstrike_WPNHUD_SG550"
	"viewmodel"			"models/weapons/v_snip_sg550.mdl"
	"playermodel"			"models/weapons/w_snip_sg550.mdl"
	
	"anim_prefix"			"anim"
	"bucket"			"0"
	"bucket_position"		"0"

	"clip_size"			"30"
	
	"primary_ammo"			"BULLET_PLAYER_556MM"
	"secondary_ammo"		"None"

	"weight"			"20"
	"item_flags"			"0"

	// Sounds for the weapon. There is a max of 16 sounds per category (i.e. max 16 "single_shot" sounds)
	SoundData
	{
		//"reload"			"Weapon_AWP.Reload"
		//"empty"				"Default.ClipEmpty_Rifle"
		"single_shot"		"Weapon_SG550.Single"
		special3			Default.Zoom
	}

	// Weapon Sprite data is loaded by the Client DLL.
	TextureData
	{
		"weapon"
		{
				"font"		"CSweaponsSmall"
				"character"	"O"
		}
		"weapon_s"
		{	
				"font"		"CSweapons"
				"character"	"O"
		}
		"ammo"
		{
				"font"		"CSTypeDeath"
				"character"		"N"
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
			Mins	"-3 -3 -12"
			Maxs	"40 14 -1"
		}
		World
		{
			Mins	"-7 -8 -3"
			Maxs	"32 9 9"
		}
	}
}]=]

function SWEP:SetupDataTables()
    BaseClass.SetupDataTables(self)

    self:NetworkVar("Float", "LastFire")

    self:SetLastFire(CurTime())
    self:SetAccuracy(0.98)
end

function SWEP:OverrideData(tbl)
	-- TODO: cvar for cs:s slots?
	tbl.Slot = 3

end

function SWEP:GetWeaponID()
	return WEAPON_SG550
end

local cSG550MidZoomFOV = 40
local cSG550MaxZoomFOV = 15
local kZoomTime = 0.1

function SWEP:SecondaryAttack()
	local selfTable = self:GetTable()

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return end

	local fov = math.floor(owner:GetFOV())
	if fov == owner:GetDefaultFOV() then
		owner:SetFOV(cSG550MidZoomFOV, kZoomTime)
		selfTable.SetWeaponMode(self, Secondary_Mode)
		selfTable.SetAccuracyPenalty(self, selfTable.GetAccuracyPenalty(self) + selfTable.CSWpnData.m_fInaccuracyAltSwitch)
		self:SetHoldType("rpg")
	elseif fov == cSG550MidZoomFOV then
		owner:SetFOV(cSG550MaxZoomFOV, kZoomTime)
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
	selfTable.SetZoomFullyActiveTime(self, CurTime() + 0.3)
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
			fSpread = 0.45 * (1 - selfTable.GetAccuracy(self))
		elseif vel > 5 then
			fSpread = 0.15
		elseif owner:IsDucking() then
			fSpread = 0.04 * (1 - selfTable.GetAccuracy(self))
		else
			fSpread = 0.05 * (1 - selfTable.GetAccuracy(self))
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

    local curtime = CurTime()

    -- Mark the time of this shot and determine the accuracy modifier based on the last shot fired...
    local m_flAccuracy = 0.65 + (0.35 * (curtime - selfTable.GetLastFire(self)))

    m_flAccuracy = math.min(m_flAccuracy, 0.98)
    selfTable.SetAccuracy(self, m_flAccuracy)

    selfTable.SetLastFire(self, curtime)

	if not selfTable.CSBaseGunFire(self, selfTable.CSWpnData.m_flCycleTime, selfTable.GetWeaponMode(self)) then return end

    -- Adjust the punch angle.
    local angleP = selfTable.GetViewPunchPitch()
    local angleY = selfTable.GetViewPunchYaw()
	local x = util.SharedRandom("SG550PunchAngleX", 0.75, 1.25) + (angleP * 0.25)
    local y = util.SharedRandom("SG550PunchAngleY", -0.75, 0.75)

	selfTable.SetViewPunchPitch(self, angleP - x)
	selfTable.SetViewPunchYaw(self, angleY + y)
end

function SWEP:Reload()
	local selfTable = self:GetTable()
    selfTable.SetAccuracy(self, 0.98)
	selfTable.SetWeaponMode(self, Primary_Mode)
	self:SetHoldType(selfTable.HoldType)

	return BaseClass.Reload(self)
end

function SWEP:Deploy()
	local selfTable = self:GetTable()

	local oPri = self:GetNextPrimaryFire()
	local oSec = self:GetNextSecondaryFire()

	if not BaseClass.Deploy(self) then return false end

    selfTable.SetAccuracy(self, 0.98)
	selfTable.SetWeaponMode(self, Primary_Mode)

	self:SetNextPrimaryFire(math.max(self:GetNextPrimaryFire(), oPri))
	self:SetNextSecondaryFire(math.max(self:GetNextSecondaryFire(), oSec))
	return true
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
