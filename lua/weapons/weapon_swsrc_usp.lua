AddCSLuaFile()

SWEP.Base = "weapon_swsrc_basegun"
DEFINE_BASECLASS(SWEP.Base)

SWEP.Category = "#spawnmenu.category.swsrc"
SWEP.SubCategory = "#spawnmenu.category.swsrc_pistols"

SWEP.PrintName = "USP-S"
SWEP.Spawnable = true
SWEP.HoldType = "revolver"
SWEP.WorldModel = "models/weapons/w_pist_usp.mdl"
SWEP.ViewModel = "models/weapons/cstrike/c_pist_usp.mdl"
SWEP.IconOverride = "vgui/gfx/vgui/fav_weap/usp45"

local g_SilencedTranslations = {
	[ACT_VM_RELOAD] = ACT_VM_RELOAD_SILENCED,
	[ACT_VM_PRIMARYATTACK] = ACT_VM_PRIMARYATTACK_SILENCED,
	[ACT_VM_DRAW] = ACT_VM_DRAW_SILENCED,
	[ACT_VM_IDLE] = ACT_VM_IDLE_SILENCED,
}

SWEP.WeaponData = [=[WeaponData
{
	"MaxPlayerSpeed"		"250"
	"WeaponType"			"Pistol"
	"FullAuto"				0
	"WeaponPrice"			"500"
	"WeaponArmorRatio"		"1.0"
	"CrosshairMinDistance"		"8"
	"CrosshairDeltaDistance" 	"3"
	"Team" 				"ANY"
	"BuiltRightHanded" 		"0"
	"PlayerAnimationExtension" 	"pistol"
	"MuzzleFlashScale"		"1"

	"CanEquipWithShield" 		"1"


	// Weapon characteristics:
	"Penetration"			"1"
	"Damage"			"34"
	"Range"				"4096"
	"RangeModifier"			"0.79"
	"Bullets"			"1"
	"CycleTime"			"0.15"

	// New accuracy model parameters
	"Spread"					0.00400
	"InaccuracyCrouch"			0.00600
	"InaccuracyStand"			0.00800
	"InaccuracyJump"			0.28725
	"InaccuracyLand"			0.05745
	"InaccuracyLadder"			0.01915
	"InaccuracyFire"			0.03495
	"InaccuracyMove"			0.01724

	"SpreadAlt"					0.00300
	"InaccuracyCrouchAlt"		0.00600
	"InaccuracyStandAlt"		0.00800
	"InaccuracyJumpAlt"			0.29625
	"InaccuracyLandAlt"			0.05925
	"InaccuracyLadderAlt"		0.01975
	"InaccuracyFireAlt"			0.02504
	"InaccuracyMoveAlt"			0.01778

	"RecoveryTimeCrouch"		0.23371
	"RecoveryTimeStand"			0.28045

	// Weapon data is loaded by both the Game and Client DLLs.
	"printname"			"#Cstrike_WPNHUD_USP45"
	"viewmodel"			"models/weapons/v_pist_usp.mdl"
	"playermodel"			"models/weapons/w_pist_usp.mdl"
	"shieldviewmodel"		"models/weapons/v_shield_usp_r.mdl"
	"SilencerModel"			"models/weapons/w_pist_usp_silencer.mdl"
	"anim_prefix"			"anim"
	"bucket"			"1"
	"bucket_position"		"1"

	"clip_size"			"12"

	"primary_ammo"			"BULLET_PLAYER_45ACP"
	"secondary_ammo"		"None"

	"weight"			"5"
	"item_flags"			"0"

	// Sounds for the weapon. There is a max of 16 sounds per category (i.e. max 16 "single_shot" sounds)
	SoundData
	{
		//"reload"			"Default.Reload"
		//"empty"				"Default.ClipEmpty_Rifle"
		"single_shot"		"Weapon_USP.Single"
		"special1"			"Weapon_USP.SilencedShot"
		"special2"			"Weapon_USP.DetachSilencer"
		"special3"			"Weapon_USP.AttachSilencer"
	}

	// Weapon Sprite data is loaded by the Client DLL.
	TextureData
	{
		"weapon"
		{
				"font"		"CSweaponsSmall"
				"character"	"A"
		}
		"weapon_s"
		{
				"font"		"CSweapons"
				"character"	"A"
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
			Mins	"-7 -4 -14"
			Maxs	"24 9 -2"
		}
		World
		{
			Mins	"-1 -4 -3"
			Maxs	"17 5 6"
		}
	}
}]=]

function SWEP:OverrideData(tbl)
	-- TODO: cvar for cs:s slots?
	tbl.Slot = 1
end

function SWEP:GetWeaponID()
	return WEAPON_USP
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

	local delay = CurTime() + 3
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

		if selfTable.GetSilencerOn(self) then
			if not owner:IsOnGround() then
				return 1.3 * (1 - selfTable.GetAccuracy(self))
			elseif owner:GetVelocity():Length2D() > 5 then
				return 0.25 * (1 - selfTable.GetAccuracy(self))
			elseif owner:IsDucking() then
				return 0.125 * (1 - selfTable.GetAccuracy(self))
			else
				return 0.15 * (1 - selfTable.GetAccuracy(self))
			end
		else
			if not owner:IsOnGround() then
				return 1.2 * (1 - selfTable.GetAccuracy(self))
			elseif owner:GetVelocity():Length2D() > 5 then
				return 0.225 * (1 - selfTable.GetAccuracy(self))
			elseif owner:IsDucking() then
				return 0.08 * (1 - selfTable.GetAccuracy(self))
			else
				return 0.1 * (1 - selfTable.GetAccuracy(self))
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

	local m_weaponMode = selfTable.GetWeaponMode(self)
	local flCycleTime = selfTable.CSWpnData.m_flCycleTime

	-- Mark the time of this shot and determine the accuracy modifier based on the last shot fired...
	local m_flAccuracy = selfTable.GetAccuracy(self)
	m_flAccuracy = m_flAccuracy - 0.275 * (0.3 - (CurTime() - selfTable.GetLastFire(self)))

	if m_flAccuracy > 0.92 then
		m_flAccuracy = 0.92
	elseif m_flAccuracy < 0.6 then
		m_flAccuracy = 0.6
	end

	selfTable.SetAccuracy(self, m_flAccuracy)
	selfTable.SetLastFire(self, CurTime())

	if self:Clip1() <= 0 then
		if selfTable.m_bFireOnEmpty then
			selfTable.PlayEmptySound(self, selfTable)
			self:SetNextPrimaryFire(CurTime() + 0.1)
			selfTable.m_bFireOnEmpty = false
		end

		return
	end

	selfTable.SetShotsFired(self, selfTable.GetShotsFired(self) + 1)

	self:SetNextPrimaryFire(CurTime() + flCycleTime)
	self:SetNextSecondaryFire(CurTime() + flCycleTime)

	self:SetClip1(self:Clip1() - 1)

	owner:MuzzleFlash()

	selfTable.SetWeaponAnim(self, ACT_VM_PRIMARYATTACK)
	owner:SetAnimation(PLAYER_ATTACK1)

	selfTable.FX_FireBullets(self, m_weaponMode, CurTime())

	selfTable.SetWeaponIdleTime(self, CurTime() + 2)

	-- update accuracy
	selfTable.SetAccuracyPenalty(self,
		selfTable.GetAccuracyPenalty(self) + selfTable.CSWpnData.m_fInaccuracyFire[m_weaponMode])

	selfTable.SetViewPunchPitch(self, selfTable.GetViewPunchPitch(self) - 2)
end

function SWEP:Reload()
	local selfTable = self:GetTable()

	if not BaseClass.Reload(self, selfTable.GetSilencerOn(self) and ACT_VM_RELOAD_SILENCED or ACT_VM_RELOAD) then return false end

	selfTable.SetAccuracy(self, 0.92)
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
