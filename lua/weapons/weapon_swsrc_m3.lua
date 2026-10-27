AddCSLuaFile()

SWEP.Base = "weapon_swsrc_basegun"
DEFINE_BASECLASS(SWEP.Base)

SWEP.Category = "#spawnmenu.category.swsrc"
SWEP.SubCategory = "#spawnmenu.category.swsrc_shotguns"

SWEP.PrintName = "M3"
SWEP.Spawnable = true
SWEP.HoldType = "shotgun"
SWEP.WorldModel = "models/weapons/w_shot_m3super90.mdl"
SWEP.ViewModel = "models/weapons/cstrike/c_shot_m3super90.mdl"
SWEP.IconOverride = "vgui/gfx/vgui/fav_weap/m3"

SWEP.WeaponData = [=[WeaponData
{
	"MaxPlayerSpeed" 		"220"
	"WeaponType"			"Shotgun"
	"FullAuto"				1
	"WeaponPrice"			"1700"
	"WeaponArmorRatio"		"1.0"
	"CrosshairMinDistance"		"8"
	"CrosshairDeltaDistance"	"6"
	"Team"				"ANY"
	"BuiltRightHanded"		"0"
	"PlayerAnimationExtension" 	"m3s90"
	"MuzzleFlashScale"		"1.3"

	"CanEquipWithShield"		"0"


	// Weapon characteristics:
	"Penetration"			"1"
	"Damage"			"26"
	"Range"				"3000"
	"RangeModifier"			"0.70"
	"Bullets"			"9"
	"CycleTime"			"0.88"

	// New accuracy model parameters
	"Spread"					0.04000
	"InaccuracyCrouch"			0.00750
	"InaccuracyStand"			0.01000
	"InaccuracyJump"			0.42000
	"InaccuracyLand"			0.08400
	"InaccuracyLadder"			0.07875
	"InaccuracyFire"			0.04164
	"InaccuracyMove"			0.04320

	"RecoveryTimeCrouch"		0.29605
	"RecoveryTimeStand"			0.41447

	// Weapon data is loaded by both the Game and Client DLLs.
	"printname"			"#Cstrike_WPNHUD_m3"
	"viewmodel"			"models/weapons/v_shot_m3super90.mdl"
	"playermodel"			"models/weapons/w_shot_m3super90.mdl"

	"anim_prefix"			"anim"
	"bucket"			"0"
	"bucket_position"		"0"

	"clip_size"			"8"

	"primary_ammo"			"BULLET_PLAYER_BUCKSHOT"
	"secondary_ammo"		"None"

	"weight"			"20"
	"item_flags"			"0"

	// Sounds for the weapon. There is a max of 16 sounds per category (i.e. max 16 "single_shot" sounds)
	SoundData
	{
		//"reload"			"Default.Reload"
		//"empty"				"Default.ClipEmpty_Rifle"
		"single_shot"		"Weapon_M3.Single"
		special3			Default.Zoom
	}

	// Weapon Sprite data is loaded by the Client DLL.
	TextureData
	{
		"weapon"
		{
				"font"		"CSweaponsSmall"
				"character"	"K"
		}
		"weapon_s"
		{
				"font"		"CSweapons"
				"character"	"K"
		}
		"ammo"
		{
				"font"		"CSTypeDeath"
				"character"		"J"
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
			Mins	"-13 -3 -13"
			Maxs	"26 10 -3"
		}
		World
		{
			Mins	"-9 -8 -5"
			Maxs	"28 9 9"
		}
	}
}]=]

function SWEP:OverrideData(tbl)
	-- TODO: cvar for cs:s slots?
	tbl.Slot = 3
end

function SWEP:GetWeaponID()
	return WEAPON_M3
end

function SWEP:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:NetworkVar("Float", "PumpTime")
	self:NetworkVar("Int", "ReloadState")

	self:SetPumpTime(0)
	self:SetReloadState(0)
end

local weapon_accuracy_model = GetConVar("swsrc_weapon_accuracy_model")
function SWEP:GetInaccuracy()
	if weapon_accuracy_model:GetInt() == 1 then
		return 0
	end

	return BaseClass.GetInaccuracy(self)
end

function SWEP:GetSpread()
	local selfTable = self:GetTable()

	if weapon_accuracy_model:GetInt() == 1 then
		return 0.675
	end

	return selfTable.CSWpnData.m_fSpread[Primary_Mode]
end

function SWEP:PrimaryAttack()
	local selfTable = self:GetTable()

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return end

	local wdat = selfTable.CSWpnData
	local flCycleTime = wdat.m_flCycleTime

	-- don't fire underwater
	if owner:WaterLevel() == 3 then
		selfTable.PlayEmptySound(self, selfTable)
		self:SetNextPrimaryFire(CurTime() + 0.15)
		return
	end

	-- Out of ammo?
	if self:Clip1() <= 0 then
		selfTable.Reload(self)

		if self:Clip1() <= 0 then
			selfTable.PlayEmptySound(self, selfTable)
			self:SetNextPrimaryFire(CurTime() + 0.2)
		end

		return
	end

	selfTable.SetWeaponAnim(self, ACT_VM_PRIMARYATTACK)

	self:SetClip1(self:Clip1() - 1)
	selfTable.DoFireEffects(self, selfTable)

	owner:SetAnimation(PLAYER_ATTACK1)

	local flCurAttack = selfTable.CalculateNextAttackTime(self, flCycleTime)
	selfTable.FX_FireBullets(self, Primary_Mode, flCurAttack)

	if self:Clip1() ~= 0 then
		selfTable.SetPumpTime(self, CurTime() + 0.5)
	end

	if self:Clip1() ~= 0 then
		selfTable.SetWeaponIdleTime(self, CurTime() + 2.5)
	else
		selfTable.SetWeaponIdleTime(self, CurTime() + 0.875)
	end
	selfTable.SetReloadState(self, 0)

	-- update accuracy
	selfTable.SetAccuracyPenalty(self, selfTable.GetAccuracyPenalty(self) + wdat.m_fInaccuracyFire[Primary_Mode])

	-- update punch angles
	local x = math.floor(util.SharedRandom("M3PunchAngleAir", 8, 11))
	if owner:IsOnGround() then
		x = math.floor(util.SharedRandom("M3PunchAngleGround", 4, 6))
	end

	selfTable.SetViewPunchPitch(self, selfTable.GetViewPunchPitch(self) - x)
end

function SWEP:Reload()
	local selfTable = self:GetTable()

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return false end

	if owner:GetAmmoCount(self:GetPrimaryAmmoType()) <= 0 or self:Clip1() == self:GetMaxClip1() then return true end

	if self:GetNextPrimaryFire() > CurTime() then return true end

	if selfTable.GetReloadState(self) == 0 then
		if self:Clip1() < 7 then
			selfTable.ActivityTranslate[ACT_MP_RELOAD_STAND] = ACT_HL2MP_GESTURE_RELOAD_PISTOL
			selfTable.ActivityTranslate[ACT_MP_RELOAD_CROUCH] = ACT_HL2MP_GESTURE_RELOAD_PISTOL
		end

		--owner:SetAnimation(PLAYER_RELOAD)

		selfTable.SetWeaponAnim(self, ACT_SHOTGUN_RELOAD_START)
		selfTable.SetReloadState(self, 1)
		self:SetNextPrimaryFire(CurTime() + 0.5)
		self:SetNextSecondaryFire(CurTime() + 0.5)
		selfTable.SetWeaponIdleTime(self, CurTime() + 0.5)

		--owner:DoCustomAnimEvent(PLAYERANIMEVENT_RELOAD, 0)

		return true
	elseif selfTable.GetReloadState(self) == 1 then
		if selfTable.GetWeaponIdleTime(self) > CurTime() then return true end

		selfTable.SetReloadState(self, 2)

		selfTable.SetWeaponAnim(self, ACT_VM_RELOAD)
		selfTable.SetWeaponIdleTime(self, CurTime() + 0.5)

		if self:Clip1() == 7 then
			selfTable.ActivityTranslate[ACT_MP_RELOAD_STAND] = ACT_HL2MP_GESTURE_RELOAD_SHOTGUN
			selfTable.ActivityTranslate[ACT_MP_RELOAD_CROUCH] = ACT_HL2MP_GESTURE_RELOAD_SHOTGUN
			owner:DoCustomAnimEvent(PLAYERANIMEVENT_RELOAD, 0) -- was RELOAD_END
		else
			owner:DoCustomAnimEvent(PLAYERANIMEVENT_RELOAD, 0) -- was RELOAD_LOOP
		end
	else
		self:SetClip1(self:Clip1() + 1)

		--owner:DoCustomAnimEvent(PLAYERANIMEVENT_RELOAD, 0)
		owner:RemoveAmmo(1, self:GetPrimaryAmmoType())

		selfTable.SetReloadState(self, 1)
	end

	return true
end

function SWEP:WeaponIdle(tbl)
	local selfTable = tbl or self:GetTable()

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return false end

	if selfTable.GetPumpTime(self) < CurTime() then
		selfTable.SetPumpTime(self, 0)
	end

	if selfTable.GetWeaponIdleTime(self) < CurTime() then
		if self:Clip1() == 0 and selfTable.GetReloadState(self) == 0 and owner:GetAmmoCount(self:GetPrimaryAmmoType()) > 0 then
			selfTable.Reload(self)
		elseif selfTable.GetReloadState(self) ~= 0 then
			if self:Clip1() < 8 and owner:GetAmmoCount(self:GetPrimaryAmmoType()) > 0 then
				selfTable.Reload(self)
			else
				selfTable.SetWeaponAnim(self, ACT_SHOTGUN_RELOAD_FINISH)

				selfTable.SetReloadState(self, 0)
				selfTable.SetWeaponIdleTime(self, CurTime() + 1.5)
			end
		else
			selfTable.SetWeaponAnim(self, ACT_VM_IDLE)
		end
	end
end
