AddCSLuaFile()

SWEP.Base = "weapon_swsrc_basegun"
DEFINE_BASECLASS(SWEP.Base)

SWEP.Category = "#spawnmenu.category.swsrc"
SWEP.SubCategory = "#spawnmenu.category.swsrc_snipers"

SWEP.PrintName = "G3SG1"
SWEP.Spawnable = true
SWEP.HoldType = "ar2"
SWEP.WorldModel = "models/weapons/w_snip_g3sg1.mdl"
SWEP.ViewModel = "models/weapons/cstrike/c_snip_g3sg1.mdl"
SWEP.IconOverride = "vgui/gfx/vgui/fav_weap/g3sg1"

SWEP.WeaponData = [=[WeaponData
{
	"MaxPlayerSpeed" 		"210"
	"WeaponType" 			"SniperRifle"
	"FullAuto"				1
	"WeaponPrice" 			"5000"
	"WeaponArmorRatio" 		"1.65"
	"CrosshairMinDistance" 		"6"
	"CrosshairDeltaDistance" 	"4"
	"Team" 				"TERRORIST"
	"BuiltRightHanded" 		"0"
	"PlayerAnimationExtension"	 "g3"
	"MuzzleFlashScale"		"1.5"
	"MuzzleFlashStyle"		"CS_MUZZLEFLASH_X"
	"CanEquipWithShield" 		"0"
	
	
	// Weapon characteristics:
	"Penetration"			"3"
	"Damage"			"80"
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
	"InaccuracyCrouch"			0.01935
	"InaccuracyStand"			0.02580
	"InaccuracyJump"			0.46557
	"InaccuracyLand"			0.04656
	"InaccuracyLadder"			0.11639
	"InaccuracyFire"			0.04989
	"InaccuracyMove"			0.23279
								 
	"SpreadAlt"					0.00030
	"InaccuracyCrouchAlt"		0.00150
	"InaccuracyStandAlt"		0.00200
	"InaccuracyJumpAlt"			0.46557
	"InaccuracyLandAlt"			0.04656
	"InaccuracyLadderAlt"		0.11639
	"InaccuracyFireAlt"			0.04989
	"InaccuracyMoveAlt"			0.23279
								 
	"RecoveryTimeCrouch"		0.22245
	"RecoveryTimeStand"			0.31142
	
	// Weapon data is loaded by both the Game and Client DLLs.
	"printname"			"#Cstrike_WPNHUD_G3SG1"
	"viewmodel"			"models/weapons/v_snip_g3sg1.mdl"
	"playermodel"			"models/weapons/w_snip_g3sg1.mdl"
	
	"anim_prefix"			"anim"
	"bucket"			"0"
	"bucket_position"		"0"

	"clip_size"			"20"
	
	"primary_ammo"			"BULLET_PLAYER_762MM"
	"secondary_ammo"		"None"

	"weight"			"20"
	"item_flags"			"0"

	// Sounds for the weapon. There is a max of 16 sounds per category (i.e. max 16 "single_shot" sounds)
	SoundData
	{
		//"reload"			"Default.Reload"
		//"empty"				"Default.ClipEmpty_Rifle"
		"single_shot"		"Weapon_G3SG1.Single"
		special3			Default.Zoom
	}

	// Weapon Sprite data is loaded by the Client DLL.
	TextureData
	{
		"weapon"
		{
				"font"		"CSweaponsSmall"
				"character"	"I"
		}
		"weapon_s"
		{	
				"font"		"CSweapons"
				"character"	"I"
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
			Mins	"-8 -3 -13"
			Maxs	"33 10 -1"
		}
		World
		{
			Mins	"-11 -9 -4"
			Maxs	"28 9 9"
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
	return WEAPON_AWP
end

local cG3MidZoomFOV = 40
local cG3MaxZoomFOV = 15
local kZoomTime = 0.1

function SWEP:SecondaryAttack()
	local selfTable = self:GetTable()

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return end

	local fov = math.floor(owner:GetFOV())
	if fov == owner:GetDefaultFOV() then
		owner:SetFOV(cG3MidZoomFOV, kZoomTime)
		selfTable.SetWeaponMode(self, Secondary_Mode)
		selfTable.SetAccuracyPenalty(self, selfTable.GetAccuracyPenalty(self) + selfTable.CSWpnData.m_fInaccuracyAltSwitch)
		self:SetHoldType("rpg")
	elseif fov == cG3MidZoomFOV then
		owner:SetFOV(cG3MaxZoomFOV, kZoomTime)
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
			fSpread = 0.035 * (1 - selfTable.GetAccuracy(self))
		else
			fSpread = 0.055 * (1 - selfTable.GetAccuracy(self))
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
    local m_flAccuracy = 0.55 + (0.3 * (curtime - selfTable.GetLastFire(self)))

    m_flAccuracy = math.min(m_flAccuracy, 0.98)
    selfTable.SetAccuracy(self, m_flAccuracy)

    selfTable.SetLastFire(self, curtime)

	local m_weaponMode = selfTable.GetWeaponMode(self)
	if not selfTable.CSBaseGunFire(self, selfTable.CSWpnData.m_flCycleTime, m_weaponMode) then return end

    -- Adjust the punch angle.
    local angleP = selfTable.GetViewPunchPitch()
    local angleY = selfTable.GetViewPunchYaw()
	local x = util.SharedRandom("G3SG1PunchAngleX", 0.75, 1.75) + (angleP * 0.25)
    local y = util.SharedRandom("G3SG1PunchAngleY", -0.75, 0.75)

    angleP = angleP - x
    angleY = angleY + y

	selfTable.SetViewPunchPitch(self, angleP)
	selfTable.SetViewPunchYaw(self, angleY)
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
