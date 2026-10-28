AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "swsrc_base_grenade"

ENT.Spawnable = false

ENT.Model = "models/weapons/w_eq_smokegrenade_thrown.mdl"

ENT.m_DidSmokeEffect = false

function ENT:BounceSound()
    if not self.m_DidSmokeEffect then
        self:EmitSound("SmokeGrenade.Bounce")
    end
end
