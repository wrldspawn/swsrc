AddCSLuaFile()

SWEP.Base = "weapon_base"
SWEP.IsSWSrcWeapon = true

SWEP.AllowDrop = true

SWEP.Slot = 1
SWEP.SlotPos = 2

SWEP.Secondary.Ammo = ""
SWEP.Secondary.ClipSize = -1

SWEP.UseHands = true

local g_bSinglePlayer = game.SinglePlayer()

include("sh_penetration.lua")

hook.Add("Initialize", "swsrc.ammo", function()
	game.AddAmmoType({
		name = "BULLET_PLAYER_50AE",
		dmgtype = DMG_BULLET,
		tracer = TRACER_LINE,
		force = 2400,
		minsplash = 10,
		maxsplash = 14,
	})
	game.AddAmmoType({
		name = "BULLET_PLAYER_762MM",
		dmgtype = DMG_BULLET,
		tracer = TRACER_LINE,
		force = 2400,
		minsplash = 10,
		maxsplash = 14,
	})
	game.AddAmmoType({
		name = "BULLET_PLAYER_556MM",
		dmgtype = DMG_BULLET,
		tracer = TRACER_LINE,
		force = 2400,
		minsplash = 10,
		maxsplash = 14,
	})
	game.AddAmmoType({
		name = "BULLET_PLAYER_556MM_BOX",
		dmgtype = DMG_BULLET,
		tracer = TRACER_LINE,
		force = 2400,
		minsplash = 10,
		maxsplash = 14,
	})
	game.AddAmmoType({
		name = "BULLET_PLAYER_338MAG",
		dmgtype = DMG_BULLET,
		tracer = TRACER_LINE,
		force = 2800,
		minsplash = 12,
		maxsplash = 16,
	})
	game.AddAmmoType({
		name = "BULLET_PLAYER_9MM",
		dmgtype = DMG_BULLET,
		tracer = TRACER_LINE,
		force = 2000,
		minsplash = 5,
		maxsplash = 10,
	})
	game.AddAmmoType({
		name = "BULLET_PLAYER_BUCKSHOT",
		dmgtype = DMG_BULLET,
		tracer = TRACER_LINE,
		force = 600,
		minsplash = 3,
		maxsplash = 6,
	})
	game.AddAmmoType({
		name = "BULLET_PLAYER_45ACP",
		dmgtype = DMG_BULLET,
		tracer = TRACER_LINE,
		force = 2100,
		minsplash = 6,
		maxsplash = 10,
	})
	game.AddAmmoType({
		name = "BULLET_PLAYER_357SIG",
		dmgtype = DMG_BULLET,
		tracer = TRACER_LINE,
		force = 2000,
		minsplash = 4,
		maxsplash = 8,
	})
	game.AddAmmoType({
		name = "BULLET_PLAYER_57MM",
		dmgtype = DMG_BULLET,
		tracer = TRACER_LINE,
		force = 2000,
		minsplash = 4,
		maxsplash = 8,
	})

	game.AddAmmoType({
		name = "swsrc_hegrenade",
		dmgtype = DMG_BLAST,
		maxcarry = 1,
	})
	game.AddAmmoType({
		name = "swsrc_flashbang",
		maxcarry = 2,
	})
	game.AddAmmoType({
		name = "swsrc_smokegrenade",
		maxcarry = 1,
	})
end)

Primary_Mode = 0
Secondary_Mode = 1

function SWEP:Initialize()
	local selfTable = self:GetTable()

	self:SetHoldType(selfTable.HoldType or "pistol")
end

function SWEP:OverrideData(_)
end

function SWEP:SetupDataTables()
	self:NetworkVar("Bool", 0, "InReload")
	self:NetworkVar("Bool", 1, "DelayFire")
	self:NetworkVar("Bool", 2, "ResumeZoom")

	self:NetworkVar("Int", 0, "ShotsFired")
	self:NetworkVar("Int", 1, "LastZoom")
	self:NetworkVar("Int", 2, "WeaponMode")
	self:NetworkVar("Int", 3, "KickDirection")

	self:NetworkVar("Float", 0, "DecreaseShotsFired")
	self:NetworkVar("Float", 1, "WeaponIdleTime")
	self:NetworkVar("Float", 2, "AccuracyPenalty")
	self:NetworkVar("Float", 3, "ReloadFinishTime")

	self:NetworkVar("Float", 4, "ViewPunchPitch")
	self:NetworkVar("Float", 5, "ViewPunchYaw")
	self:NetworkVar("Float", 6, "ViewPunchRoll")

	self:SetDelayFire(true)
	self:SetAccuracyPenalty(0)
	self:SetWeaponMode(Primary_Mode)
	self:SetKickDirection(0)
end

function SWEP:GetViewPunchAngle()
	return Angle(self:GetViewPunchPitch(), self:GetViewPunchYaw(), self:GetViewPunchRoll())
end

function SWEP:SetViewPunchAngle(angle)
	local p, y, r = angle:Unpack()
	self:SetViewPunchPitch(p)
	self:SetViewPunchYaw(y)
	self:SetViewPunchRoll(r)
end

function SWEP:GetPlayerOwner()
	local owner = self:GetOwner()
	if not (owner:IsValid() and owner:IsPlayer()) then return false end

	return owner
end

function SWEP:IsPistol(tbl)
	local selfTable = tbl or self:GetTable()

	return selfTable.CSWpnData.m_WeaponType == WEAPONTYPE_PISTOL
end
function SWEP:IsFullAuto(tbl)
	local selfTable = tbl or self:GetTable()

	return selfTable.CSWpnData.m_bFullAuto
end

function SWEP:GetWeaponFlags(tbl)
	local selfTable = tbl or self:GetTable()
	return selfTable.CSWpnData.iFlags
end

--- Overwrite this
function SWEP:GetWeaponID()
	return WEAPON_NONE
end

function SWEP:PlayEmptySound(tbl)
	local selfTable = tbl or self:GetTable()

	self:EmitSound(selfTable.IsPistol(self, selfTable) and "Default.ClipEmpty_Pistol" or "Default.ClipEmpty_Rifle")
end

function SWEP:SetWeaponAnim(idealAct, flPlaybackRate)
	local owner = self:GetOwner()
	local vm = owner:IsPlayer() and owner:GetViewModel() or self

	if not vm:IsValid() then return false end

	local idealSequence = vm:SelectWeightedSequence(idealAct)
	if idealSequence == nil or idealSequence == ACT_INVALID then return false end
	flPlaybackRate = isnumber(flPlaybackRate) and flPlaybackRate or 1

	self:SendWeaponAnim(idealAct)
	self:SendViewModelMatchingSequence(idealSequence)

	if owner:IsValid() and owner:IsPlayer() then
		vm:SendViewModelMatchingSequence(idealSequence)
		vm:SetPlaybackRate(flPlaybackRate)
	end

	-- Set the next time the weapon will idle
	local playTime = vm:SequenceDuration(idealSequence) * (1 / flPlaybackRate)
	self:SetWeaponIdleTime(CurTime() + playTime)
	return true, playTime
end


function SWEP:WeaponIdle(_)
end

function SWEP:Reload()
	local selfTable = self:GetTable()

	if selfTable.GetInReload(self) then return false end

	local curtime = CurTime()
	if self:GetNextPrimaryFire() > curtime then return false end
	if self:Clip1() >= self:GetMaxClip1() then return false end

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return false end

	owner:SetAnimation(PLAYER_RELOAD)

	selfTable.SetShotsFired(self, 0)

	local ok, duration = selfTable.SetWeaponAnim(self, ACT_VM_RELOAD)
	if not ok then return false end

	selfTable.SetInReload(self, true)
	selfTable.SetReloadFinishTime(self, curtime + duration)
	self:SetNextPrimaryFire(curtime + duration)
	self:SetNextSecondaryFire(curtime + duration)
end

function SWEP:IsUseable()
	local owner = self:GetPlayerOwner()
	if not owner then return false end

	if self:Clip1() <= 0 then
		if self:Ammo1() <= 0 and self:GetMaxClip1() ~= -1 then
			-- clip is empty (or nonexistant) and the player has no more ammo of this type.
			return false
		end
	end

	return true
end

function SWEP:Think_ProcessPrimaryAttack(tbl)
	--[[if self:Clip1() == 0 or (self:GetMaxClip1() == -1 and self:Ammo1() <= 0) then
		tbl.m_bFireOnEmpty = true
	end--]]

	if self:Clip1() == 0 and not tbl.m_bFireOnEmpty then return end

	if tbl.GetShotsFired(self) > 0 and not tbl.IsFullAuto(self, tbl) then return end

	-- gameevent?

	self:PrimaryAttack()
end

function SWEP:Think_ProcessSecondaryAttack(tbl)
	--[[if self:Clip2() ~= -1 and self:Ammo2() ~= 0 then
		tbl.m_bFireOnEmpty = true
	end--]]

	self:SecondaryAttack()
	return true
end

function SWEP:Think_ProcessReloadAction(selfTable)
	-- gameevent?

	selfTable.Reload(self)
end

local weapon_accuracy_model = GetConVar("swsrc_weapon_accuracy_model")
function SWEP:Think_ProcessIdleNoAction(selfTable)
	if weapon_accuracy_model:GetInt() == 2 then
		if selfTable.GetShotsFired(self) > 0 and (not selfTable.IsFullAuto(self, selfTable) or self:Clip1() == 0) then
			selfTable.SetShotsFired(self, 0)
		end
	end

	if selfTable.GetDelayFire(self) then
		selfTable.SetDelayFire(self, false)

		if selfTable.GetShotsFired(self) > 15 then
			selfTable.SetShotsFired(self, 15)
		end

		selfTable.SetDecreaseShotsFired(self, CurTime() + 0.4)
	end

	selfTable.m_bFireOnEmpty = true

	if selfTable.IsPistol(self, selfTable) then
		selfTable.SetShotsFired(self, 0)
	else
		if selfTable.GetShotsFired(self) > 0 and selfTable.GetDecreaseShotsFired(self) < CurTime() then
			selfTable.SetDecreaseShotsFired(self, CurTime() + 0.0225)
			selfTable.SetShotsFired(self, selfTable.GetShotsFired(self) - 1)
		end
	end

	if selfTable.IsUseable(self) or self:GetNextPrimaryFire() >= CurTime() then
		if
			self:Clip1() == 0
			and bit.band(selfTable.GetWeaponFlags(self, selfTable), ITEM_FLAG_NOAUTORELOAD) == 0
			and self:GetNextPrimaryFire() < CurTime()
		then
			selfTable.Reload(self)
			return
		end
	end

	selfTable.WeaponIdle(self, selfTable)
end

function SWEP:Think()
	local selfTable = self:GetTable()

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return end

	selfTable.UpdateAccuracyPenalty(self, selfTable)
	selfTable.DecayPunchAngle(self, selfTable)

	if selfTable.GetInReload(self) and selfTable.GetReloadFinishTime(self) <= CurTime() then
		local clip1 = self:Clip1()
		local j = math.min(self:GetMaxClip1() - clip1, self:Ammo1())

		self:SetClip1(clip1 + j)
		owner:RemoveAmmo(j, self:GetPrimaryAmmoType())

		selfTable.SetInReload(self, false)
		selfTable.SetReloadFinishTime(self, 0)
	end

	selfTable.m_bProcessActivities = true
end

SWEP.m_bProcessActivities = false
hook.Add("PlayerTick", "swsrc.ProcessActivities", function(ply)
	if not IsValid(ply) then return end
	local wep = ply:GetActiveWeapon()

	local wepTable = wep:GetTable()
	if not wep:IsValid() or not weapons.IsBasedOn(wepTable.ClassName, "weapon_swsrc_base") then return end

	if wepTable.m_bProcessActivities then
		wepTable.ProcessActivities(wep, wepTable)
		wepTable.m_bProcessActivities = false
	end
end)

function SWEP:ProcessExtraActivities(_)
end

function SWEP:ProcessActivities(tbl)
	local selfTable = tbl or self:GetTable()

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return end

	local cmd
	if g_bSinglePlayer then
		cmd = owner.m_LastUserCommand
	elseif owner == GetPredictionPlayer() then
		cmd = owner:GetCurrentCommand()

		owner.m_LastUserCommand = cmd
		owner.m_LastUserCommandNumber = cmd:CommandNumber()
	else
		cmd = owner.m_LastUserCommand
	end

	local o_btns = owner:GetInternalVariable("m_nButtons")
	local btns = g_bSinglePlayer and o_btns or (cmd and cmd:GetButtons() or o_btns)

	selfTable.m_bProcessingActivities = true

	selfTable.ProcessExtraActivities(self, selfTable)

	local bInReload = selfTable.GetInReload(self)

	if bit.band(btns, IN_ATTACK2) ~= 0 and self:GetNextSecondaryFire() <= CurTime() and not bInReload then
		if selfTable.Think_ProcessSecondaryAttack(self, selfTable) then
			btns = bit.band(btns, bit.bnot(IN_ATTACK2))
		end
	elseif bit.band(btns, IN_ATTACK) ~= 0 and self:GetNextPrimaryFire() <= CurTime() and not bInReload then
		selfTable.Think_ProcessPrimaryAttack(self, selfTable)
	elseif
		bit.band(btns, IN_RELOAD) ~= 0
		and self:GetMaxClip1() ~= -1
		and not bInReload
		and self:GetNextPrimaryFire() < CurTime()
	then
		selfTable.Think_ProcessReloadAction(self, selfTable)
	elseif bit.band(btns, bit.bor(IN_ATTACK, IN_ATTACK2)) == 0 then
		selfTable.Think_ProcessIdleNoAction(self, selfTable)
	end

	selfTable.m_bProcessingActivities = false
end

local function RemapClamped(value, A, B, C, D)
	if A == B then
		return value >= B and D or C
	end

	local cVal = (value - A) / (B - A)
	cVal = math.Clamp(cVal, 0, 1)

	return C + (D - C) * cVal
end

function SWEP:GetInaccuracy()
	local selfTable = self:GetTable()

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return 0 end

	local fMaxSpeed = selfTable.GetMaxSpeed(self)
	local mode = selfTable.GetWeaponMode(self)

	return selfTable.GetAccuracyPenalty(self) +
			RemapClamped(owner:GetVelocity():Length2D(),
				fMaxSpeed * 0.34, -- CS_PLAYER_SPEED_DUCK_MODIFIER
				fMaxSpeed * 0.95,
				0.0, selfTable.CSWpnData.m_fInaccuracyMove[mode])
end

function SWEP:GetSpread()
	if weapon_accuracy_model:GetInt() == 1 then
		return 0
	end

	local selfTable = self:GetTable()
	local mode = selfTable.GetWeaponMode(self)

	return selfTable.CSWpnData.m_fSpread[mode]
end

function SWEP:GetMaxSpeed()
	return self:GetTable().CSWpnData.m_flMaxSpeed
end

function SWEP:CalculateNextAttackTime(fCycleTime)
	local fCurAttack = self:GetNextPrimaryFire()
	local fDeltaAttack = CurTime() - fCurAttack
	if fDeltaAttack < 0 or fDeltaAttack > engine.TickInterval() then
		fCurAttack = CurTime()
	end
	self:SetNextPrimaryFire(fCurAttack + fCycleTime)
	self:SetNextSecondaryFire(fCurAttack + fCycleTime)

	return fCurAttack
end

function SWEP:Holster()
	local selfTable = self:GetTable()
	local owner = selfTable.GetPlayerOwner(self)

	if not owner then return true end

	if math.floor(owner:GetFOV()) ~= owner:GetDefaultFOV() then
		owner:SetFOV(0, 0.01)
	end

	return true
end

function SWEP:Deploy()
	local selfTable = self:GetTable()

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return false end

	self:SetHoldType(selfTable.HoldType)
	self:SetDeploySpeed(1) -- FIXME: cvar

	selfTable.SetDecreaseShotsFired(self, CurTime())

	selfTable.SetShotsFired(self, 0)
	selfTable.SetResumeZoom(self, false)
	selfTable.SetLastZoom(self, 0)

	if math.floor(owner:GetFOV()) ~= owner:GetDefaultFOV() then
		owner:SetFOV(0, 0.01)
	end

	owner:SetSaveValue("m_flNextAttack", SERVER and 0 or CurTime())

	selfTable.SetAccuracyPenalty(self, 0)

	local vm = owner:GetViewModel(self:ViewModelIndex())
	if vm:IsValid() then
		vm:SetPlaybackRate(self:GetDeploySpeed())
		selfTable.SetWeaponIdleTime(self, CurTime() + (self:SequenceDuration() * (1 / self:GetDeploySpeed())))

		local oPrim = self:GetNextPrimaryFire()
		local oSec = self:GetNextSecondaryFire()
		local idle = selfTable.GetWeaponIdleTime(self)
		self:SetNextPrimaryFire(oPrim < idle and idle or oPrim)
		self:SetNextSecondaryFire(oSec < idle and idle or oSec)
	end

	return true
end

function SWEP:OnDrop()
	local selfTable = self:GetTable()

	selfTable.SetInReload(self, false)
end


function SWEP:UpdateAccuracyPenalty(tbl)
	local selfTable = tbl or self:GetTable()

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return end

	local fNewPenalty = 0

	local wdat = selfTable.CSWpnData
	local mode = selfTable.GetWeaponMode(self)

	if owner:GetMoveType() == MOVETYPE_LADDER then
		fNewPenalty = fNewPenalty + wdat.m_fInaccuracyStand[mode] + wdat.m_fInaccuracyLadder[mode]
	elseif owner:IsDucking() then
		fNewPenalty = fNewPenalty + wdat.m_fInaccuracyCrouch[mode]
	else
		fNewPenalty = fNewPenalty + wdat.m_fInaccuracyStand[mode]
	end

	if selfTable.GetInReload(self) then
		fNewPenalty = fNewPenalty + wdat.m_fInaccuracyReload
	end

	if fNewPenalty > selfTable.GetAccuracyPenalty(self) then
		selfTable.SetAccuracyPenalty(self, fNewPenalty)
	else
		local fDecayFactor = 0

		if owner:GetMoveType() == MOVETYPE_LADDER then
			fDecayFactor = math.log(10) / wdat.m_fRecoveryTimeStand
		elseif not owner:IsOnGround() then
			fDecayFactor = math.log(10) / (wdat.m_fRecoveryTimeCrouch * 3)
		elseif owner:IsDucking() then
			fDecayFactor = math.log(10) / wdat.m_fRecoveryTimeCrouch
		else
			fDecayFactor = math.log(10) / wdat.m_fRecoveryTimeStand
		end

		selfTable.SetAccuracyPenalty(self,
			Lerp(math.exp(engine.TickInterval() * -fDecayFactor), fNewPenalty, selfTable.GetAccuracyPenalty(self)))
	end
end

function SWEP:KickBack(up_base, lateral_base, up_modifier, lateral_modifier, up_max, lateral_max, direction_change)
	local selfTable = self:GetTable()

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return end

	local flKickUp = 0
	local flKickLateral = 0

	local m_iShotsFired = selfTable.GetShotsFired(self)
	if m_iShotsFired == 1 then
		flKickUp = up_base
		flKickLateral = lateral_base
	else
		flKickUp = up_base + m_iShotsFired * up_modifier
		flKickLateral = lateral_base + m_iShotsFired * lateral_modifier
	end

	local angle = self:GetViewPunchAngle()
	angle.x = angle.x - flKickUp
	if angle.x < -up_max then
		angle.x = -up_max
	end

	if selfTable.GetKickDirection(self) == 1 then
		angle.y = angle.y + flKickLateral
		if angle.y > lateral_max then
			angle.y = lateral_max
		end
	else
		angle.y = angle.y - flKickLateral
		if angle.y < -lateral_max then
			angle.y = -lateral_max
		end
	end

	if math.floor(util.SharedRandom("KickBack", 0, direction_change)) == 0 then
		selfTable.SetKickDirection(self, 1 - selfTable.GetKickDirection(self))
	end

	self:SetViewPunchAngle(angle)
end

hook.Add("OnPlayerJump", "swsrc", function(ply, speed)
	local wep = ply:GetActiveWeapon()
	if not wep:IsValid() then return end

	local wepTable = wep:GetTable()
	if not wepTable.IsSWSrcWeapon then return end

	if wepTable.OnJump then
		wepTable.OnJump(wep, ply, speed, wepTable)
	end
end)

hook.Add("OnPlayerHitGround", "swsrc", function(ply, water, floater, speed)
	local wep = ply:GetActiveWeapon()
	if not wep:IsValid() then return end

	local wepTable = wep:GetTable()
	if not wepTable.IsSWSrcWeapon then return end

	if wepTable.OnLand then
		wepTable.OnLand(wep, ply, speed, wepTable)
	end
end)

function SWEP:OnJump(owner, impulse, selfTable)
	local selfTable = self:GetTable() or selfTable
	local wdat = selfTable.CSWpnData

	local mode = selfTable.GetWeaponMode(self)
	selfTable.SetAccuracyPenalty(self,
		selfTable.GetAccuracyPenalty(self) + (wdat.m_fInaccuracyJump[mode] * (impulse / owner:GetJumpPower())))
end

function SWEP:OnLand(owner, speed, selfTable)
	local selfTable = self:GetTable() or selfTable
	local wdat = selfTable.CSWpnData

	local mode = selfTable.GetWeaponMode(self)
	selfTable.SetAccuracyPenalty(self,
		selfTable.GetAccuracyPenalty(self) + (wdat.m_fInaccuracyLand[mode] * (speed / owner:GetJumpPower())))
end

function SWEP:DecayPunchAngle(tbl)
	tbl = tbl or self:GetTable()
	local ang = tbl.GetViewPunchAngle(self)
	local p, y, r = ang:Unpack()
	local dir = Vector(p, y, r)

	local length = dir:Length()
	if length <= 0 then return end

	dir:Normalize()
	p, y, r = dir:Unpack()

	local decayed = math.max(0, length - FrameTime() * ((0.5 * length) + 10))
	tbl.SetViewPunchPitch(self, p * decayed)
	tbl.SetViewPunchYaw(self, y * decayed)
	tbl.SetViewPunchRoll(self, r * decayed)
end

function SWEP:PrimaryAttack()
	-- Derived classes should implement this and call CSBaseGunFire.
end
function SWEP:SecondaryAttack()
end
