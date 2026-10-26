AddCSLuaFile()

SWEP.Base = "weapon_swsrc_base"
DEFINE_BASECLASS(SWEP.Base)

function SWEP:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:NetworkVar("Float", "Accuracy")
	self:NetworkVar("Float", "ZoomFullyActiveTime")

	self:SetAccuracy(0.2)
	self:SetZoomFullyActiveTime(-1)
end

function SWEP:Deploy()
	local selfTable = self:GetTable()

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return false end

	selfTable.SetAccuracy(self, 0.2)
	selfTable.SetShotsFired(self, 0)
	selfTable.SetDelayFire(self, false)
	selfTable.SetZoomFullyActiveTime(self, -1)

	return BaseClass.Deploy(self)
end

function SWEP:ProcessExtraActivities(selfTable)
	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return false end

	-- Return zoom level back to previous zoom level before we fired a shot. This is used only for the AWP and Scout.
	if self:GetNextPrimaryFire() <= CurTime() and selfTable.GetResumeZoom(self) then
		selfTable.SetResumeZoom(self, false)

		if self:Clip1() ~= 0 or bit.band(selfTable.GetWeaponFlags(self, selfTable), ITEM_FLAG_NOAUTORELOAD) ~= 0 then
			selfTable.SetWeaponMode(self, Secondary_Mode)
			self:SetHoldType("rpg")
			owner:SetFOV(selfTable.GetLastZoom(self), 0.05)
			selfTable.SetZoomFullyActiveTime(self, CurTime() + 0.05)
		end
	end
end

function SWEP:CSBaseGunFire(flCycleTime, weaponMode)
	local selfTable = self:GetTable()

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return false end

	local pCSInfo = selfTable.CSWpnData

	selfTable.SetDelayFire(self, true)

	if self:Clip1() > 0 then
		selfTable.SetShotsFired(self, selfTable.GetShotsFired(self) + 1)

		-- These modifications feed back into flSpread eventually.
		if pCSInfo.m_flAccuracyDivisor ~= -1 then
			local iShotsFired = selfTable.GetShotsFired(self)

			if pCSInfo.m_bAccuracyQuadratic then
				iShotsFired = iShotsFired * iShotsFired
			else
				iShotsFired = iShotsFired * iShotsFired * iShotsFired
			end

			local m_flAccuracy = (iShotsFired / pCSInfo.m_flAccuracyDivisor) + pCSInfo.m_flAccuracyOffset
			if m_flAccuracy > pCSInfo.m_flMaxInaccuracy then
				m_flAccuracy = pCSInfo.m_flMaxInaccuracy
			end

			selfTable.SetAccuracy(self, m_flAccuracy)
		end
	else
		selfTable.SetAccuracy(self, 0)

		if selfTable.m_bFireOnEmpty then
			selfTable.PlayEmptySound(self, selfTable)

			selfTable.m_bFireOnEmpty = false
			self:SetNextPrimaryFire(CurTime() + 0.1)
		end

		return false
	end

	local flCurAttack = selfTable.CalculateNextAttackTime(self, flCycleTime)

	selfTable.SetWeaponAnim(self, ACT_VM_PRIMARYATTACK)

	self:SetClip1(self:Clip1() - 1)

	owner:SetAnimation(PLAYER_ATTACK1)

	selfTable.FX_FireBullets(self, weaponMode, flCurAttack)

	selfTable.DoFireEffects(self, selfTable)

	selfTable.SetWeaponIdleTime(self, CurTime() + pCSInfo.m_flTimeToIdleAfterFire)

	selfTable.SetAccuracyPenalty(self, selfTable.GetAccuracyPenalty(self) + pCSInfo.m_fInaccuracyFire[weaponMode])

	return true
end

local weapon_accuracy_logging = GetConVar("swsrc_weapon_accuracy_logging")

--- This runs on both the client and the server.
--- On the server, it only does the damage calculations.
--- On the client, it does all the effects.
function SWEP:FX_FireBullets(iMode, flCurAttack, fInaccuracy, fSpread)
	local selfTable = self:GetTable()

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return end

	local bDoEffects = true

	local vOrigin = owner.m_vSavedShootPos or owner:GetShootPos()
	local vAngles = owner:GetAimVector():Angle() + (2 * self:GetViewPunchAngle())
	vAngles:Normalize()
	local iWeaponID = selfTable.GetWeaponID(self)
	if fInaccuracy == nil then
		fInaccuracy = selfTable.GetInaccuracy(self)
	end
	if fSpread == nil then
		fSpread = selfTable.GetSpread(self)
	end

	if SERVER and weapon_accuracy_logging:GetBool() then
		local szFlags = " "

		if owner:GetMoveType() == MOVETYPE_LADDER then
			szFlags = szFlags .. "LADDER "
		end
		if owner:IsOnGround() then
			szFlags = szFlags .. "GROUND "
		end
		if owner:IsDucking() then
			szFlags = szFlags .. "DUCKING "
		end

		local fVelocity = owner:GetVelocity():Length2D()

		MsgN(Format(
			"FireBullets @ %10f [ %s ]: inaccuracy=%f  spread=%f  max dispersion=%f  mode=%2i  vel=%10f  %s",
			CurTime(), self:GetClass(), fInaccuracy, fSpread, fInaccuracy + fSpread, iMode, fVelocity, szFlags
		))
	end

	local pWeaponInfo = selfTable.CSWpnData

	owner:DoCustomAnimEvent(iMode == Primary_Mode and PLAYERANIMEVENT_ATTACK_PRIMARY or PLAYERANIMEVENT_ATTACK_SECONDARY, 0)

	if SERVER then
		bDoEffects = false
	end

	local iDamage = pWeaponInfo.m_iDamage
	local flRange = pWeaponInfo.m_flRange
	local iPenetration = pWeaponInfo.m_iPenetration
	local flRangeModifier = pWeaponInfo.m_flRangeModifier
	local iAmmoType = pWeaponInfo.szAmmo1

	local sound_type = 1 -- SINGLE

	if iMode == Secondary_Mode then
		if iWeaponID == WEAPON_GLOCK then
			iDamage = 18 -- reduced power for burst shots
			flRangeModifier = 0.9
		elseif iWeaponID == WEAPON_M4A1 then
			flRangeModifier = 0.95 -- slower bullets in slienced mode
			sound_type = 11 -- SPECIAL1
		elseif iWeaponID == WEAPON_USP then
			iDamage = 30 -- reduced damage in silenced mode
			sound_type = 11 -- SPECIAL1
		end
	end

	if bDoEffects then
		EmitSound(pWeaponInfo.aShootSounds[sound_type + 1], vOrigin, owner:EntIndex(), CHAN_WEAPON)
	end

	owner:LagCompensation(true)

	local fTheta0 = util.SharedRandom("", 0, 2 * math.pi)
	local fRadius0 = util.SharedRandom("", 0, fInaccuracy)
	local x0 = fRadius0 * math.cos(fTheta0)
	local y0 = fRadius0 * math.sin(fTheta0)

	local kMaxBullets = 16
	local x1, y1 = {}, {}
	local iBullets = pWeaponInfo.m_iBullets
	assert(iBullets <= kMaxBullets)

	-- the RNG can be desynchronized by FireBullet(), so pre-generate all spread offsets
	for iBullet = 1, iBullets do
		local fTheta1 = util.SharedRandom("", 0, 2 * math.pi, iBullet)
		local fRadius1 = util.SharedRandom("", 0, fSpread, iBullet)
		x1[iBullet] = fRadius1 * math.cos(fTheta1)
		y1[iBullet] = fRadius1 * math.sin(fTheta1)
	end

	for iBullet = 1, iBullets do
		selfTable.CS_FireBullet(self,
			vOrigin,
			vAngles,
			flRange,
			iPenetration,
			iAmmoType,
			iDamage,
			flRangeModifier,
			owner,
			bDoEffects,
			x0 + x1[iBullet], y0 + y1[iBullet])
	end

	owner:LagCompensation(false)
end

function SWEP:Reload(act)
	local selfTable = self:GetTable()

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return false end

	if owner:GetAmmoCount(self:GetPrimaryAmmoType()) <= 0 then return false end

	owner:SetFOV(0, 0)

	local iResult = self:DefaultReload(act or ACT_VM_RELOAD)
	if not iResult then return false end

	owner:SetAnimation(PLAYER_RELOAD)

	if iResult and math.floor(owner:GetFOV()) ~= owner:GetDefaultFOV() then
		owner:SetFOV(0)
	end

	selfTable.SetAccuracy(self, 0.2)
	selfTable.SetShotsFired(self, 0)
	selfTable.SetDelayFire(self, false)

	return true
end

function SWEP:WeaponIdle(tbl)
	local selfTable = tbl or self:GetTable()

	if selfTable.GetWeaponIdleTime(self) > CurTime() then return end

	-- only idle if the slid isn't back
	if self:Clip1() ~= 0 then
		selfTable.SetWeaponIdleTime(self, CurTime() + selfTable.CSWpnData.m_flIdleInterval)
		selfTable.SetWeaponAnim(self, ACT_VM_IDLE)
	end
end

function SWEP:DoFireEffects(tbl)
	local selfTable = tbl or self:GetTable()

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return end

	owner:MuzzleFlash()
end
