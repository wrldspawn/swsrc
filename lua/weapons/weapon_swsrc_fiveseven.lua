AddCSLuaFile()

SWEP.Base = "weapon_swsrc_basegun"
DEFINE_BASECLASS(SWEP.Base)

SWEP.Category = "#spawnmenu.category.swsrc"
SWEP.SubCategory = "#spawnmenu.category.swsrc_pistols"

SWEP.PrintName = "Five-SeveN"
SWEP.Spawnable = true
SWEP.HoldType = "revolver"
SWEP.WorldModel = "models/weapons/w_pist_fiveseven.mdl"
SWEP.ViewModel = "models/weapons/cstrike/c_pist_fiveseven.mdl"
SWEP.IconOverride = "vgui/gfx/vgui/fav_weap/fiveseven"

SWEP.WeaponData = [=[WeaponData
{
	"MaxPlayerSpeed"		"250"
	"WeaponType"			"Pistol"
	"FullAuto"				0
	"WeaponPrice"			"750"
	"WeaponArmorRatio"		"1.5"
	"CrosshairMinDistance"		"8"
	"CrosshairDeltaDistance"	"3"
	"Team"				"CT"
	"BuiltRightHanded"		"0"
	"PlayerAnimationExtension"	"pistol"
	"MuzzleFlashScale"		"1"

	"CanEquipWithShield"		"1"


	// Weapon characteristics:
	"Penetration"			"1"
	"Damage"			"25"
	"Range"				"4096"
	"RangeModifier"			"0.885"
	"Bullets"			"1"
	"CycleTime"			"0.15"

	// New accuracy model parameters
	"Spread"					0.00400
	"InaccuracyCrouch"			0.00600
	"InaccuracyStand"			0.01000
	"InaccuracyJump"			0.25635
	"InaccuracyLand"			0.05127
	"InaccuracyLadder"			0.01709
	"InaccuracyFire"			0.05883
	"InaccuracyMove"			0.01538

	"RecoveryTimeCrouch"		0.18628
	"RecoveryTimeStand"			0.22353

	// Weapon data is loaded by both the Game and Client DLLs.
	"printname"			"#Cstrike_WPNHUD_FiveSeven"
	"viewmodel"			"models/weapons/v_pist_fiveseven.mdl"
	"playermodel"			"models/weapons/w_pist_fiveseven.mdl"
	"shieldviewmodel"		"models/weapons/v_shield_fiveseven_r.mdl"
	"anim_prefix"			"anim"
	"bucket"			"1"
	"bucket_position"		"1"

	"clip_size"			"20"

	"primary_ammo"			"BULLET_PLAYER_57MM"
	"secondary_ammo"		"None"

	"weight"			"5"
	"item_flags"			"0"

	// Sounds for the weapon. There is a max of 16 sounds per category (i.e. max 16 "single_shot" sounds)
	SoundData
	{
		//"reload"			"Default.Reload"
		//"empty"				"Default.ClipEmpty_Rifle"
		"single_shot"		"Weapon_FiveSeven.Single"
	}

	// Weapon Sprite data is loaded by the Client DLL.
	TextureData
	{
		"weapon"
		{
				"font"		"CSweaponsSmall"
				"character"	"U"
		}
		"weapon_s"
		{
				"font"		"CSweapons"
				"character"	"U"
		}
		"ammo"
		{
				"font"		"CSTypeDeath"
				"character"		"S"
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
			Mins	"-8 -4 -16"
			Maxs	"18 9 -3"
		}
		World
		{
			Mins	"-1 -3 -2"
			Maxs	"11 4 5"
		}
	}
}]=]

function SWEP:OverrideData(tbl)
	-- TODO: cvar for cs:s slots?
	tbl.Slot = 1
end

function SWEP:GetWeaponID()
	return WEAPON_FIVESEVEN
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

	self:SetLastFire(CurTime())
	self:SetAccuracy(0.92)
end

function SWEP:Deploy()
	self:SetAccuracy(0.92)
	return BaseClass.Deploy(self)
end

local weapon_accuracy_model = GetConVar("swsrc_weapon_accuracy_model")
function SWEP:GetInaccuracy()
	local selfTable = self:GetTable()

	if weapon_accuracy_model:GetInt() == 1 then
		local owner = selfTable.GetPlayerOwner(self)
		if not owner then return 0 end

		if not owner:IsOnGround() then
			return 1.5 * (1 - selfTable.GetAccuracy(self))
		elseif owner:GetVelocity():Length2D() > 5 then
			return 0.255 * (1 - selfTable.GetAccuracy(self))
		elseif owner:IsDucking() then
			return 0.075 * (1 - selfTable.GetAccuracy(self))
		else
			return 0.15 * (1 - selfTable.GetAccuracy(self))
		end
	else
		return BaseClass.GetInaccuracy(self)
	end
end

function SWEP:PrimaryAttack()
	local selfTable = self:GetTable()

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return end

	-- Mark the time of this shot and determine the accuracy modifier based on the last shot fired...
	local m_flAccuracy = selfTable.GetAccuracy(self)
	m_flAccuracy = m_flAccuracy - 0.25 * (0.275 - (CurTime() - selfTable.GetLastFire(self)))

	if m_flAccuracy > 0.92 then
		m_flAccuracy = 0.92
	elseif m_flAccuracy < 0.725 then
		m_flAccuracy = 0.725
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

	self:SetClip1(self:Clip1() - 1)

	owner:MuzzleFlash()

	selfTable.SetWeaponAnim(self, ACT_VM_PRIMARYATTACK)
	owner:SetAnimation(PLAYER_ATTACK1)

	selfTable.FX_FireBullets(self, Primary_Mode, CurTime())

	self:SetNextPrimaryFire(CurTime() + selfTable.CSWpnData.m_flCycleTime)
	self:SetNextSecondaryFire(CurTime() + selfTable.CSWpnData.m_flCycleTime)

	selfTable.SetWeaponIdleTime(self, CurTime() + 2)

	-- update accuracy
	selfTable.SetAccuracyPenalty(self,
		selfTable.GetAccuracyPenalty(self) + selfTable.CSWpnData.m_fInaccuracyFire[Primary_Mode])

	selfTable.SetViewPunchPitch(self, selfTable.GetViewPunchPitch(self) - 2)
end

function SWEP:Reload()
	if not BaseClass.Reload(self) then return false end

	self:SetAccuracy(0.92)
	return true
end

function SWEP:WeaponIdle(tbl)
	local selfTable = tbl or self:GetTable()

	if selfTable.GetWeaponIdleTime(self) > CurTime() then return end

	-- only idle if the slid isn't back
	if self:Clip1() ~= 0 then
		selfTable.SetWeaponIdleTime(self, CurTime() + 4)
		selfTable.SetWeaponAnim(self, ACT_VM_IDLE)
	end
end
