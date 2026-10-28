AddCSLuaFile()

SWEP.Base = "weapon_swsrc_base"
DEFINE_BASECLASS(SWEP.Base)

local g_bSinglePlayer = game.SinglePlayer()

function SWEP:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:NetworkVar("Bool", "Redraw")
	self:NetworkVar("Bool", "PinPulled")
	self:NetworkVar("Float", "ThrowTime")

	self:SetRedraw(false)
	self:SetPinPulled(false)
	self:SetThrowTime(0)
end

function SWEP:Deploy()
	local selfTable = self:GetTable()

	selfTable.SetRedraw(self, false)
	selfTable.SetPinPulled(self, false)
	selfTable.SetThrowTime(self, 0)

	if SERVER then
		local owner = selfTable.GetPlayerOwner(self)
		if not owner then return false end

		if owner:GetAmmoCount(self:GetPrimaryAmmoType()) <= 0 then
			owner:DropWeapon(self)
			SafeRemoveEntity(self)
			return false
		end
	end

	return BaseClass.Deploy(self)
end

function SWEP:Holster(pSwitchingTo)
	local selfTable = self:GetTable()

	selfTable.SetRedraw(self, false)
	selfTable.SetPinPulled(self, false)
	selfTable.SetThrowTime(self, 0)

	if SERVER then
		local owner = selfTable.GetPlayerOwner(self)
		if not owner then return false end

		if owner:GetAmmoCount(self:GetPrimaryAmmoType()) <= 0 then
			owner:DropWeapon(self)
			SafeRemoveEntity(self)
		end
	end

	return BaseClass.Holster(self, pSwitchingTo)
end

function SWEP:PrimaryAttack()
	local selfTable = self:GetTable()

	if selfTable.GetRedraw(self) or selfTable.GetPinPulled(self) or selfTable.GetThrowTime(self) > 0 then return end

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return end

	selfTable.SetWeaponAnim(self, ACT_VM_PULLPIN)
	selfTable.SetPinPulled(self, true)

	local duration = CurTime() + self:SequenceDuration()
	selfTable.SetWeaponIdleTime(self, duration)
	self:SetNextPrimaryFire(duration)
end

function SWEP:SecondaryAttack()
	local selfTable = self:GetTable()

	if selfTable.GetRedraw(self) then return end

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return end

	selfTable.SetWeaponAnim(self, owner:IsDucking() and ACT_VM_SECONDARYATTACK or ACT_VM_HAULBACK)

	local duration = CurTime() + self:SequenceDuration()
	selfTable.SetWeaponIdleTime(self, duration)
	self:SetNextSecondaryFire(duration)
end

function SWEP:Reload()
	local selfTable = self:GetTable()

	if selfTable.GetRedraw(self) and self:GetNextPrimaryFire() <= CurTime() and self:GetNextSecondaryFire() <= CurTime() then
		selfTable.SetWeaponAnim(self, ACT_VM_DRAW)

		local duration = CurTime() + self:SequenceDuration()
		self:SetNextPrimaryFire(duration)
		self:SetNextSecondaryFire(duration)

		selfTable.SetRedraw(self, false)

		selfTable.SetWeaponIdleTime(self, duration)
	end

	return true
end

function SWEP:ProcessActivities(tbl)
	local selfTable = tbl or self:GetTable()

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return end

	local vm = owner:GetViewModel(self:ViewModelIndex())
	if not vm:IsValid() then return end

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

	local m_fThrowTime = selfTable.GetThrowTime(self)
	local m_bRedraw = selfTable.GetRedraw(self)

	if selfTable.GetPinPulled(self) and bit.band(btns, IN_ATTACK) == 0 then
		owner:DoCustomAnimEvent(PLAYERANIMEVENT_ATTACK_GRENADE, 0)

		selfTable.StartGrenadeThrow(self, selfTable)

		selfTable.SetPinPulled(self, false)
		selfTable.SetWeaponAnim(self, ACT_VM_THROW)

		local duration = CurTime() + self:SequenceDuration()
		selfTable.SetWeaponIdleTime(self, duration)
		self:SetNextSecondaryFire(duration)

		-- gameevent?
	elseif m_fThrowTime > 0 and m_fThrowTime < CurTime() then
		owner:RemoveAmmo(1, self:GetPrimaryAmmoType())

		selfTable.ThrowGrenade(self, selfTable)
	elseif m_bRedraw then
		if selfTable.GetWeaponIdleTime(self) < CurTime() then
			if owner:GetAmmoCount(self:GetPrimaryAmmoType()) <= 0 then
				if SERVER then
					owner:DropWeapon(self)
					SafeRemoveEntity(self)
				end
			else
				selfTable.Reload(self)
			end

			return
		end
	elseif not m_bRedraw then
		return BaseClass.ProcessActivities(self, selfTable)
	end
end

function SWEP:StartGrenadeThrow(tbl)
	local selfTable = tbl or self:GetTable()

	selfTable.SetThrowTime(self, CurTime() + 0.1)
end

local ANG_ZERO = Angle()
local GRENADE_MAXS = Vector(2, 2, 2)
local GRENADE_MINS = GRENADE_MAXS * -1
function SWEP:ThrowGrenade(tbl)
	local selfTable = tbl or self:GetTable()

	if SERVER then
		local owner = selfTable.GetPlayerOwner(self)
		if not owner then return end

		local angThrow = owner:EyeAngles()
		local vForward, vRight, vUp = Vector(), Vector(), Vector()

		if angThrow.x < 0 then
			angThrow.x = angThrow.x + 360
		end

		if angThrow.x < 90 then
			angThrow.x = -10 + angThrow.x * ((90 + 10) / 90)
		else
			angThrow.x = 360 - angThrow.x;
			angThrow.x = -10 + angThrow.x * -((90 - 10) / 90)
		end

		local flVel = (90 - angThrow.x) * 6
		if flVel > 750 then
			flVel = 750
		end

		swsrc.AngleVectors(angThrow, vForward, vRight, vUp)

		local vecSrc = owner:EyePos()

		local trace = util.TraceHull({
			start = vecSrc,
			endpos = vecSrc + vForward * 16,
			mins = GRENADE_MINS,
			maxs = GRENADE_MAXS,
			mask = MASK_SOLID,
			collisiongroup = COLLISION_GROUP_NONE,
			filter = {owner},
		})
		vecSrc:Set(trace.HitPos)

		local vecThrow = vForward * flVel + owner:GetVelocity()

		local angularImpulse = Angle(600, math.floor(util.SharedRandom("SWSrc:ThrowGrenade Impulse", -1200, 1200)), 0)

		local hProjectile = selfTable.EmitGrenade(self, selfTable)
		if hProjectile:IsValid() then
			hProjectile:SetOwner(owner)
			hProjectile:SetPos(vecSrc)
			hProjectile:SetAngles(angThrow)
			hProjectile:SetVelocity(vecThrow)
			hProjectile:SetLocalAngularVelocity(angularImpulse)
			--hProjectile:Create(vecSrc, ANG_ZERO, vecThrow, angularImpulse)
			hProjectile:Spawn()

			hook.Run("PlayerThrowSWSrcGrenade", owner, hProjectile, false)

			if hProjectile:IsValid() then
				hProjectile:Spawn()
				hook.Run("PlayerSpawnedSENT", owner, hProjectile)
			end
		end
	end

	selfTable.SetRedraw(self, true)
	selfTable.SetThrowTime(self, 0)

	-- fire in the hole easter egg cvar maybe
end

function SWEP:DropGrenade(tbl)
	local selfTable = tbl or self:GetTable()

	if SERVER then
		local owner = selfTable.GetPlayerOwner(self)
		if not owner then return end

		local vForward = Vector()
		local angles = owner:EyeAngles()
		swsrc.AngleVectors(angles, vForward)
		local vecSrc = owner:EyePos() + vForward * 16

		local vecVel = owner:GetVelocity()

		local angularImpulse = Angle(600, math.floor(util.SharedRandom("SWSrc:DropGrenade Impulse", -1200, 1200)), 0)

		local hProjectile = selfTable.EmitGrenade(self, selfTable)
		if hProjectile:IsValid() then
			hProjectile:SetOwner(owner)
			hProjectile:SetPos(vecSrc)
			hProjectile:SetAngles(angles)
			hProjectile:SetVelocity(vecVel)
			hProjectile:SetLocalAngularVelocity(angularImpulse)
			--hProjectile:Create(vecSrc, ANG_ZERO, vecVel, angularImpulse)
			hProjectile:Spawn()

			hook.Run("PlayerThrowSWSrcGrenade", owner, hProjectile, true)

			if hProjectile:IsValid() then
				hProjectile:Spawn()
				hook.Run("PlayerSpawnedSENT", owner, hProjectile)
			end
		end
	end

	selfTable.SetRedraw(self, true)
	selfTable.SetThrowTime(self, 0)
end

function SWEP:EmitGrenade(tbl, vecSrc, vecAngles, vecVel, angImpulse)
	return assert(NULL,
		"swsrc_basegrenade:EmitGrenade should not be called. Make sure to implement this in your subclass!\n")
end
