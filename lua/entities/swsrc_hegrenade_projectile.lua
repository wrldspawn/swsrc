AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "swsrc_base_grenade"

ENT.Spawnable = false

ENT.Model = "models/weapons/w_eq_fraggrenade_thrown.mdl"

function ENT:BounceSound()
    self:EmitSound("HEGrenade.Bounce")
end
