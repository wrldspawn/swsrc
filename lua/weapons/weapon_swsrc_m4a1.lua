AddCSLuaFile()

SWEP.Base = "weapon_swsrc_basegun"
DEFINE_BASECLASS(SWEP.Base)

SWEP.Category = "#spawnmenu.category.swsrc"
SWEP.SubCategory = "#spawnmenu.category.swsrc_rifles"

SWEP.PrintName = "M4A1"
SWEP.Spawnable = true
SWEP.HoldType = "ar2"
SWEP.WorldModel = "models/weapons/w_rif_m4a1.mdl"
SWEP.ViewModel = "models/weapons/cstrike/c_rif_m4a1.mdl"
SWEP.IconOverride = "vgui/gfx/vgui/fav_weap/m4a1"

local g_SilencedTranslations = {
	[ACT_VM_RELOAD] = ACT_VM_RELOAD_SILENCED,
	[ACT_VM_PRIMARYATTACK] = ACT_VM_PRIMARYATTACK_SILENCED,
	[ACT_VM_DRAW] = ACT_VM_DRAW_SILENCED,
	[ACT_VM_IDLE] = ACT_VM_IDLE_SILENCED,
}

SWEP.WeaponData = [=[WeaponData
{
	"MaxPlayerSpeed" 		"230" 
	"WeaponType" 			"Rifle"
	"FullAuto"				1
	"WeaponPrice" 			"3100"
	"WeaponArmorRatio" 		"1.4"
	"CrosshairMinDistance" 		"4"
	"CrosshairDeltaDistance" 	"3"
	"Team" 				"CT"
	"BuiltRightHanded" 		"0"
	"PlayerAnimationExtension" 	"m4"
	"MuzzleFlashScale"		"1.6"
	
	"CanEquipWithShield"		"0"
	
	
	// Weapon characteristics:
	"Penetration"			"2"
	"Damage"			"33"
	"Range"				"8192"
	"RangeModifier"			"0.97"
	"Bullets"			"1"
	"CycleTime"			"0.09"
	"AccuracyDivisor"		"220"
	"AccuracyOffset"		"0.3"
	"MaxInaccuracy"			"1.0"
	"TimeToIdle"			"1.5"
	"IdleInterval"			"60"
	
	// New accuracy model parameters
	"Spread"					0.00060
	"InaccuracyCrouch"			0.00525
	"InaccuracyStand"			0.00700
	"InaccuracyJump"			0.34151
	"InaccuracyLand"			0.06830
	"InaccuracyLadder"			0.08538
	"InaccuracyFire"			0.01266
	"InaccuracyMove"			0.06872
								 
	"SpreadAlt"					0.00054
	"InaccuracyCrouchAlt"		0.00525
	"InaccuracyStandAlt"		0.00700
	"InaccuracyJumpAlt"			0.34846
	"InaccuracyLandAlt"			0.06969
	"InaccuracyLadderAlt"		0.08712
	"InaccuracyFireAlt"			0.01165
	"InaccuracyMoveAlt"			0.07039
								 
	"RecoveryTimeCrouch"		0.26973
	"RecoveryTimeStand"			0.37762
	
	// Weapon data is loaded by both the Game and Client DLLs.
	"printname"			"#Cstrike_WPNHUD_M4A1"
	"viewmodel"			"models/weapons/v_rif_m4a1.mdl"
	"playermodel"			"models/weapons/w_rif_m4a1.mdl"
	"SilencerModel"			"models/weapons/w_rif_m4a1_silencer.mdl"
	
	"anim_prefix"			"anim"
	"bucket"			"0"
	"bucket_position"		"0"

	"clip_size"			"30"
	
	"primary_ammo"			"BULLET_PLAYER_556MM"
	"secondary_ammo"		"None"

	"weight"			"25"
	"item_flags"			"0"

	// Sounds for the weapon. There is a max of 16 sounds per category (i.e. max 16 "single_shot" sounds)
	SoundData
	{
		//"reload"			"Weapon_AWP.Reload"
		//"empty"				"Default.ClipEmpty_Rifle"
		"single_shot"		"Weapon_M4A1.Single"
		"special1"			"Weapon_M4A1.Silenced"
		"special2"			"Weapon_M4A1.Silencer_Off"
		"special3"			"Weapon_M4A1.Silencer_On"
	}

	// Weapon Sprite data is loaded by the Client DLL.
	TextureData
	{
		"weapon"
		{
				"font"		"CSweaponsSmall"
				"character"	"W"
		}
		"weapon_s"
		{	
				"font"		"CSweapons"
				"character"	"W"
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
			Mins	"-10 -2 -13"
			Maxs	"30 10 0"
		}
		World
		{
			Mins	"-8 -9 -6"
			Maxs	"29 9 8"
		}
	}
}]=]

function SWEP:OverrideData(tbl)
	-- TODO: cvar for cs:s slots?
	tbl.Slot = 2
end

function SWEP:GetWeaponID()
	return WEAPON_M4A1
end

function SWEP:SetupWeaponHoldTypeForAI(t)
	-- change player holdtypes
	self.ActivityTranslate[ACT_MP_RELOAD_STAND] = ACT_HL2MP_GESTURE_RELOAD_PISTOL
	self.ActivityTranslate[ACT_MP_RELOAD_CROUCH] = ACT_HL2MP_GESTURE_RELOAD_PISTOL

	BaseClass.SetupWeaponHoldTypeForAI(self, t)

	-- change NPC holdtypes
end

function SWEP:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:NetworkVar("Float", "LastFire")
	self:NetworkVar("Float", "DoneSwitchingSilencer")
	self:NetworkVar("Bool", "SilencerOn")

	self:SetLastFire(CurTime())
	self:SetSilencerOn(false)
	self:SetDoneSwitchingSilencer(0)
	self:SetAccuracy(0.92)
end

function SWEP:Deploy()
	local selfTable = self:GetTable()
	local wdat = selfTable.CSWpnData

	local m_bSilencerOn = selfTable.GetSilencerOn(self)
	selfTable.WorldModel = m_bSilencerOn and wdat.m_szSilencerModel or wdat.szWorldModel
	selfTable.SetWeaponAnim(self, ACT_VM_DRAW)

	selfTable.SetAccuracy(self, 0.92)
	return BaseClass.Deploy(self)
end

function SWEP:Holster(pSwitchingTo)
	local selfTable = self:GetTable()

	if CurTime() < selfTable.GetDoneSwitchingSilencer(self) then
		-- still switching the silencer.  Cancel the switch.
		selfTable.SetSilencerOn(self, not selfTable.GetSilencerOn(self))
		selfTable.SetWeaponMode(self, selfTable.GetSilencerOn(self) and Secondary_Mode or Primary_Mode)
	end

	return BaseClass.Holster(self, pSwitchingTo)
end

function SWEP:SecondaryAttack()
	local selfTable = self:GetTable()
	local wdat = selfTable.CSWpnData

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return end

	local m_bSilencerOn = selfTable.GetSilencerOn(self)
	selfTable.SetWeaponAnim(self, m_bSilencerOn and ACT_VM_DETACH_SILENCER or ACT_VM_ATTACH_SILENCER)
	m_bSilencerOn = not m_bSilencerOn
	selfTable.SetSilencerOn(self, m_bSilencerOn)
	selfTable.SetWeaponMode(self, m_bSilencerOn and Secondary_Mode or Primary_Mode)

	local delay = CurTime() + 2
	selfTable.SetDoneSwitchingSilencer(self, delay)
	self:SetNextPrimaryFire(delay)
	self:SetNextSecondaryFire(delay)
	selfTable.SetWeaponIdleTime(self, delay)

	selfTable.WorldModel = m_bSilencerOn and wdat.m_szSilencerModel or wdat.szWorldModel

	owner:AnimRestartGesture(GESTURE_SLOT_CUSTOM, ACT_GMOD_GESTURE_ITEM_PLACE, true)
end

local weapon_accuracy_model = GetConVar("swsrc_weapon_accuracy_model")
function SWEP:GetInaccuracy()
	local selfTable = self:GetTable()

	if weapon_accuracy_model:GetInt() == 1 then
		local owner = selfTable.GetPlayerOwner(self)
		if not owner then return 0 end

        if not owner:IsOnGround() then
            return 0.035 + (0.4 * selfTable.GetAccuracy(self))
        elseif owner:GetVelocity():Length2D() > 140 then
            return 0.035 + (0.07 * selfTable.GetAccuracy(self))
        elseif owner:IsDucking() then
            return 0.125 * (1 - selfTable.GetAccuracy(self))
        else
            if selfTable.GetSilencerOn(self) then
                return 0.025 * selfTable.GetAccuracy(self)
            else
                return 0.02 * selfTable.GetAccuracy(self)
            end
        end
	else
		return BaseClass.GetInaccuracy(self)
	end
end

function SWEP:PrimaryAttack()
	local selfTable = self:GetTable()

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return end

    if not selfTable.CSBaseGunFire(self, selfTable.CSWpnData.m_flCycleTime, selfTable.GetWeaponMode(self)) then return end

    if selfTable.GetSilencerOn(self) then
        selfTable.SetWeaponAnim(self, ACT_VM_PRIMARYATTACK_SILENCED)
    end

    if owner:GetVelocity():Length2D() > 5 then
		selfTable.KickBack(self, 1.0, 0.45, 0.28, 0.045, 3.75, 3, 7)
	elseif not owner:IsOnGround() then
		selfTable.KickBack(self, 1.2, 0.5, 0.23, 0.15, 5.5, 3.5, 6)
	elseif owner:IsDucking() then
		selfTable.KickBack(self, 0.6, 0.3, 0.2, 0.0125, 3.25, 2, 7)
	else
		selfTable.KickBack(self, 0.65, 0.35, 0.25, 0.015, 3.5, 2.25, 7)
	end
end

function SWEP:Reload()
	local selfTable = self:GetTable()

	if not BaseClass.Reload(self) then return false end

	selfTable.SetAccuracy(self, 0.2)
	return true
end

function SWEP:WeaponIdle(tbl)
	local selfTable = tbl or self:GetTable()

	if selfTable.GetWeaponIdleTime(self) > CurTime() then return end

	-- only idle if the slid isn't back
	if self:Clip1() ~= 0 then
		selfTable.SetWeaponIdleTime(self, CurTime() + 6)
		selfTable.SetWeaponAnim(self, ACT_VM_IDLE)
	end
end

function SWEP:SetWeaponAnim(idealAct, flPlaybackRate)
	if self:GetSilencerOn() then
		idealAct = g_SilencedTranslations[idealAct] or idealAct
	end

	return BaseClass.SetWeaponAnim(self, idealAct, flPlaybackRate)
end
