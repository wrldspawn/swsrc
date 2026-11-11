AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "swsrc_base_grenade"
DEFINE_BASECLASS(ENT.Base)

ENT.Spawnable = false

ENT.Model = "models/weapons/w_eq_fraggrenade_thrown.mdl"

ENT.m_flDamage = 100
ENT.m_flDamageRadius = 350
AccessorFunc(ENT, "m_flDamage", "Damage", FORCE_NUMBER)
AccessorFunc(ENT, "m_flDamageRadius", "DamageRadius", FORCE_NUMBER)

ENT.m_flDetonateTimerLength = 1.5

function ENT:BounceSound()
	self:EmitSound("HEGrenade.Bounce")
end

if SERVER then
	function ENT:Detonate()
		local owner = self:GetOwner()

		local origin = self:GetPos()
		local vecSpot = origin + Vector(0,0,8)
		local tr = util.TraceLine({
			start = vecSpot,
			endpos = vecSpot - Vector(0,0,32),
			filter = self,
			mask = MASK_SHOT_HULL
		})

		if tr.StartSolid then
			util.TraceLine({
				start = origin,
				endpos = origin - Vector(0,0,32),
				filter = self,
				mask = MASK_SHOT_HULL,

				output = tr
			})
		end

		self:Explode(tr, DMG_BLAST)

		local amplitude = self:GetShakeAmplitude()
		if amplitude > 0 then
			util.ScreenShake(origin, amplitude, 150, 1, self:GetShakeRadius(), false)
		end

		hook.Run("SWSrcHEGrenadeDetonated", self, owner)

		self:Remove()
	end

	DAMAGE_NO = 0
	DAMAGE_EVENTS_ONLY = 1
	DAMAGE_YES = 2
	DAMAGE_AIM = 3

	function ENT:Explode(tr, dmgBits)
		self:SetModel("")
		self:SetNotSolid(true)

		self:SetSaveValue("m_takedamage", DAMAGE_NO)

		if tr.Fraction ~= 1 then
			self:SetPos(tr.HitPos + (tr.HitNormal * 0.6))
		end

		local origin = self:GetPos()
		local contents = util.PointContents(origin)
		local damageRadius = self:GetDamageRadius()

		local data = EffectData()
		data:SetOrigin(origin)
		local effectName = bit.band(contents, MASK_WATER) == 0 and "Explosion" or "WaterSurfaceExplosion"
		data:SetScale(damageRadius * 0.03)
		--data:Setframerate(25)
		data:SetFlags(0)
		data:SetRadius(damageRadius)
		data:SetMagnitude(self:GetDamage())

		if tr.Fraction ~= 1 then
			--local surfaceData = tr.SurfaceProps ~= -1 and util.GetSurfaceData(tr.SurfaceProps)
			--if surfaceData then
				data:SetNormal(tr.HitNormal)
				data:SetMaterialIndex(tr.MatType)
			--end
		else
			data:SetNormal(Vector(0,0,1))
			data:SetMaterialIndex(MAT_CONCRETE)
		end

		util.Effect(effectName, data, true, not game.SinglePlayer())

		sound.EmitHint(SOUND_COMBAT, origin, 1024 --[[BASEGRENADE_EXPLOSION_VOLUME]], 3.0, self)

		local thrower = self:GetOwner()
		local throwerValid = thrower:IsValid()

		local info = DamageInfo()
		info:SetInflictor(self)
		info:SetAttacker(throwerValid and thrower or self)
		info:SetDamageForce(Vector()--[[self:GetBlastForce()]])
		info:SetDamagePosition(origin)
		info:SetDamage(self:GetDamage())
		info:SetDamageType(dmgBits)
		info:SetReportedPosition(throwerValid and thrower:GetPos() or origin)

		util.BlastDamageInfo(info, origin, damageRadius)

		util.Decal("Scorch", tr.StartPos, tr.HitPos + (tr.Normal * 1.1), self)

		self:EmitSound("BaseGrenade.Explode")

		self:SetSolid(SOLID_NONE)
		self:SetNoDraw(true)
		self:SetLocalVelocity(Vector())

		self:NextThink(CurTime() + 0.1)
	end
end
