AddCSLuaFile()

SWEP.Base = "weapon_swsrc_basegun"
DEFINE_BASECLASS(SWEP.Base)

SWEP.Category = "#spawnmenu.category.swsrc"
SWEP.SubCategory = "#spawnmenu.category.swsrc_pistols"

SWEP.PrintName = "Desert Eagle"
SWEP.Spawnable = true
SWEP.HoldType = "revolver"
SWEP.WorldModel = "models/weapons/w_pist_deagle.mdl"
SWEP.ViewModel = "models/weapons/cstrike/c_pist_deagle.mdl"
SWEP.IconOverride = "vgui/gfx/vgui/fav_weap/deserteagle"

SWEP.WeaponData = [=[WeaponData
{
	"MaxPlayerSpeed"		"250"
	"WeaponType"			"Pistol"
	"FullAuto"				0
	"WeaponPrice"			"650"
	"WeaponArmorRatio"		"1.5"
	"CrosshairMinDistance"		"8"
	"CrosshairDeltaDistance"	"3"
	"Team"				"ANY"
	"BuiltRightHanded"		"0"
	"PlayerAnimationExtension"	"pistol"
	"MuzzleFlashScale"		"1.2"

	"CanEquipWithShield"		"1"


	// Weapon characteristics:
	"Penetration"			"2"
	"Damage"			"54"
	"Range"				"4096"
	"RangeModifier"			"0.81"
	"Bullets"			"1"
	"CycleTime"			"0.225"

	// New accuracy model parameters
	"Spread"					0.00400
	"InaccuracyCrouch"			0.00975
	"InaccuracyStand"			0.01300
	"InaccuracyJump"			0.34500
	"InaccuracyLand"			0.06900
	"InaccuracyLadder"			0.02300
	"InaccuracyFire"			0.05500
	"InaccuracyMove"			0.02070

	"RecoveryTimeCrouch"		0.32236
	"RecoveryTimeStand"			0.38683

	// Weapon data is loaded by both the Game and Client DLLs.
	"printname"			"#Cstrike_WPNHUD_DesertEagle"
	"viewmodel"			"models/weapons/v_pist_deagle.mdl"
	"playermodel"			"models/weapons/w_pist_deagle.mdl"
	"shieldviewmodel"		"models/weapons/v_shield_de_r.mdl"
	"anim_prefix"			"anim"
	"bucket"			"1"
	"bucket_position"		"1"

	"clip_size"			"7"

	"primary_ammo"			"BULLET_PLAYER_50AE"
	"secondary_ammo"		"None"

	"weight"			"7"
	"item_flags"			"0"

	// Sounds for the weapon. There is a max of 16 sounds per category (i.e. max 16 "single_shot" sounds)
	SoundData
	{
		//"reload"			"Default.Reload"
		//"empty"				"Default.ClipEmpty_Rifle"
		"single_shot"		"Weapon_DEagle.Single"
	}

	// Weapon Sprite data is loaded by the Client DLL.
	TextureData
	{
		"weapon"
		{
				"font"		"CSweaponsSmall"
				"character"	"F"
		}
		"weapon_s"
		{
				"font"		"CSweapons"
				"character"	"F"
		}
		"ammo"
		{
				"font"		"CSTypeDeath"
				"character"		"U"
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
			Mins	"-7 -3 -14"
			Maxs	"19 10 -2"
		}
		World
		{
			Mins	"-1 -3 -2"
			Maxs	"13 4 6"
		}
	}
}]=]

function SWEP:OverrideData(tbl)
	-- TODO: cvar for cs:s slots?
	tbl.Slot = 1
end

function SWEP:GetWeaponID()
	return WEAPON_DEAGLE
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
	self:SetAccuracy(0.9)
end

function SWEP:Deploy()
	self:SetAccuracy(0.9)
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
			return 0.25 * (1 - selfTable.GetAccuracy(self))
		elseif owner:IsDucking() then
			return 0.115 * (1 - selfTable.GetAccuracy(self))
		else
			return 0.13 * (1 - selfTable.GetAccuracy(self))
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
	m_flAccuracy = m_flAccuracy - 0.35 * (0.4 - (CurTime() - selfTable.GetLastFire(self)))

	if m_flAccuracy > 0.9 then
		m_flAccuracy = 0.9
	elseif m_flAccuracy < 0.55 then
		m_flAccuracy = 0.55
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

	if self:Clip1() > 0 then
		selfTable.SetWeaponAnim(self, ACT_VM_PRIMARYATTACK)
	else
		selfTable.SetWeaponAnim(self, ACT_VM_DRYFIRE)
	end

	owner:SetAnimation(PLAYER_ATTACK1)

	selfTable.FX_FireBullets(self, Primary_Mode, CurTime())

	self:SetNextPrimaryFire(CurTime() + selfTable.CSWpnData.m_flCycleTime)

	selfTable.SetWeaponIdleTime(self, CurTime() + 1.8)

	-- update accuracy
	selfTable.SetAccuracyPenalty(self,
		selfTable.GetAccuracyPenalty(self) + selfTable.CSWpnData.m_fInaccuracyFire[Primary_Mode])

	selfTable.SetViewPunchPitch(self, selfTable.GetViewPunchPitch(self) - 2)
end

function SWEP:Reload()
	if not BaseClass.Reload(self) then return false end

	self:SetAccuracy(0.9)
	return true
end

function SWEP:WeaponIdle(tbl)
	local selfTable = tbl or self:GetTable()

	if selfTable.GetWeaponIdleTime(self) > CurTime() then return end

	selfTable.SetWeaponIdleTime(self, CurTime() + 20)

	if self:Clip1() ~= 0 then
		selfTable.SetWeaponAnim(self, ACT_VM_IDLE)
	end
end
