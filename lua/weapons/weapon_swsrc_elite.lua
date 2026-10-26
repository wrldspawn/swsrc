AddCSLuaFile()

SWEP.Base = "weapon_swsrc_basegun"
DEFINE_BASECLASS(SWEP.Base)

SWEP.Category = "#spawnmenu.category.swsrc"
SWEP.SubCategory = "#spawnmenu.category.swsrc_pistols"

SWEP.PrintName = "Dual Elites"
SWEP.Spawnable = true
SWEP.HoldType = "duel"
SWEP.WorldModel = "models/weapons/w_pist_elite.mdl"
SWEP.ViewModel = "models/weapons/cstrike/c_pist_elite.mdl"
SWEP.IconOverride = "vgui/gfx/vgui/fav_weap/elites"

SWEP.WeaponData = [=[WeaponData
{
	"MaxPlayerSpeed"		"250"
	"WeaponType" 			"Pistol"
	"FullAuto"				0
	"WeaponPrice" 			"800"
	"WeaponArmorRatio" 		"1.05"
	"CrosshairMinDistance" 		"4"
	"CrosshairDeltaDistance" 	"3"
	"Team" 				"TERRORIST"
	"BuiltRightHanded"		"0"
	"PlayerAnimationExtension" 	"elites"
	"MuzzleFlashScale"		"1"

	"CanEquipWithShield"		"0"


	// Weapon characteristics:
	"Penetration"		"1"
	"Damage"			"45"
	"Range"				"4096"
	"RangeModifier"		"0.75"
	"Bullets"			"1"
	"CycleTime"			"0.12"

	// New accuracy model parameters
	"Spread"					0.00400
	"InaccuracyCrouch"			0.00600
	"InaccuracyStand"			0.00800
	"InaccuracyJump"			0.29625
	"InaccuracyLand"			0.05925
	"InaccuracyLadder"			0.01975
	"InaccuracyFire"			0.03162
	"InaccuracyMove"			0.01778

	"RecoveryTimeCrouch"		0.24753
	"RecoveryTimeStand"			0.29703

	// Weapon data is loaded by both the Game and Client DLLs.
	"printname"			"#Cstrike_WPNHUD_Elites"
	"viewmodel"			"models/weapons/v_pist_elite.mdl"
	"playermodel"			"models/weapons/w_pist_elite.mdl"
	"AddonModel"			"models/weapons/w_pist_elite_single.mdl"
	"DroppedModel"			"models/weapons/w_pist_elite_dropped.mdl"

	"anim_prefix"			"anim"
	"bucket"			"1"
	"bucket_position"		"1"

	"clip_size"			"30"

	"primary_ammo"			"BULLET_PLAYER_9MM"
	"secondary_ammo"		"None"

	"weight"			"5"
	"item_flags"			"0"

	// Sounds for the weapon. There is a max of 16 sounds per category (i.e. max 16 "single_shot" sounds)
	SoundData
	{
		"single_shot"		"Weapon_Elite.Single"
	}

	// Weapon Sprite data is loaded by the Client DLL.
	TextureData
	{
		"weapon"
		{
				"font"		"CSweaponsSmall"
				"character"	"S"
		}
		"weapon_s"
		{
				"font"		"CSweapons"
				"character"	"S"
		}
		"ammo"
		{
				"font"		"CSTypeDeath"
				"character"		"R"
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
			Mins	"-3 -12 -12"
			Maxs	"18 11 2"
		}
		World
		{
			Mins	"-1 -7 -4"
			Maxs	"12 9 5"
		}
	}
}]=]

function SWEP:OverrideData(tbl)
	-- TODO: cvar for cs:s slots?
	tbl.Slot = 1
end

function SWEP:GetWeaponID()
	return WEAPON_ELITE
end

function SWEP:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:NetworkVar("Float", "LastFire")

	self:SetLastFire(CurTime())
	self:SetAccuracy(0.88)
end

function SWEP:Deploy()
	self:SetAccuracy(0.88)
	return BaseClass.Deploy(self)
end

function SWEP:FiringLeft()
	return bit.band(self:Clip1(), 1) == 0
end

local weapon_accuracy_model = GetConVar("swsrc_weapon_accuracy_model")
function SWEP:GetInaccuracy()
	local selfTable = self:GetTable()

	if weapon_accuracy_model:GetInt() == 1 then
		local owner = selfTable.GetPlayerOwner(self)
		if not owner then return 0 end

		if not owner:IsOnGround() then
			return 1.3 * (1 - selfTable.GetAccuracy(self))
		elseif owner:GetVelocity():Length2D() > 5 then
			return 0.175 * (1 - selfTable.GetAccuracy(self))
		elseif owner:IsDucking() then
			return 0.08 * (1 - selfTable.GetAccuracy(self))
		else
			return 0.1 * (1 - selfTable.GetAccuracy(self))
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
	m_flAccuracy = m_flAccuracy - 0.275 * (0.325 - (CurTime() - selfTable.GetLastFire(self)))

	if m_flAccuracy > 0.88 then
		m_flAccuracy = 0.88
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

	owner:SetAnimation(PLAYER_ATTACK1)

	selfTable.FX_FireBullets(self, selfTable.FiringLeft(self) and Secondary_Mode or Primary_Mode, CurTime())

	self:SetNextPrimaryFire(CurTime() + selfTable.CSWpnData.m_flCycleTime)
	self:SetNextSecondaryFire(CurTime() + selfTable.CSWpnData.m_flCycleTime)

	selfTable.SetWeaponIdleTime(self, CurTime() + 2.5)

	if selfTable.FiringLeft(self) then
		selfTable.SetWeaponAnim(self, self:Clip1() > 0 and ACT_VM_SECONDARYATTACK or ACT_VM_DRYFIRE)
	else
		selfTable.SetWeaponAnim(self, self:Clip1() > 1 and ACT_VM_PRIMARYATTACK or ACT_VM_DRYFIRE)
	end

	-- update accuracy
	selfTable.SetAccuracyPenalty(self,
		selfTable.GetAccuracyPenalty(self) + selfTable.CSWpnData.m_fInaccuracyFire[Primary_Mode])

	selfTable.SetViewPunchPitch(self, selfTable.GetViewPunchPitch(self) - 2)
end

function SWEP:Reload()
	if not BaseClass.Reload(self) then return false end

	self:SetAccuracy(0.88)
	return true
end

function SWEP:WeaponIdle(tbl)
	local selfTable = tbl or self:GetTable()

	if selfTable.GetWeaponIdleTime(self) > CurTime() then return end

	-- only idle if either slide isn't back
	if self:Clip1() >= 2 then
		selfTable.SetWeaponAnim(self, ACT_VM_IDLE)
	end
end

function SWEP:FireAnimationEvent(pos, ang, event, options, src_ent)
	local selfTable = self:GetTable()

	if event == 5001 then -- AE_ANIMEVENT
		local owner = selfTable.GetPlayerOwner(self)
		if not owner then return true end

		local data = EffectData()
		data:SetFlags(0)
		data:SetEntity(src_ent)
		data:SetAttachment(selfTable.FiringLeft(self) and 1 or 2)
		data:SetScale(selfTable.CSWpnData.m_flMuzzleScale)

		util.Effect("CS_MuzzleFlash", data, not game.SinglePlayer())

		return true
	end

	return BaseClass.FireAnimationEvent(self, pos, ang, event, options, src_ent)
end
