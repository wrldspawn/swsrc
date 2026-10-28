AddCSLuaFile()

ENT.Type = "anim"

ENT.Spawnable = false

ENT.Model = "models/weapons/w_eq_fraggrenade_thrown.mdl"

-- Constants for all CS Grenades
function ENT:GetGrenadeGravity() return 0.4 end
function ENT:GetGrenadeFriction() return 0.2 end
function ENT:GetGrenadeElasticity() return 0.45 end

function ENT:Initialize()
    self:SetModel(self.Model)

    self:SetSolidFlags(FSOLID_NOT_STANDABLE)
    self:SetMoveType(MOVETYPE_FLYGRAVITY)
    self:SetMoveCollide(MOVECOLLIDE_FLY_CUSTOM)
    self:SetSolid(SOLID_BBOX) -- So it will collide with physics props!

    self:SetGravity(self:GetGrenadeGravity())
    self:SetFriction(self:GetGrenadeFriction())
    self:SetElasticity(self:GetGrenadeElasticity())

    -- smaller, cube bounding box so we rest on the ground
    self:SetCollisionBounds(Vector(-2,-2,-2), Vector(2,2,2))
end

local STOP_EPSILON = 0.1
local function PhysicsClipVelocity(vin, normal, overbounce)
	local backoff = vin:Dot(normal) * overbounce

	local nX, nY, nZ = normal:Unpack()
	local iX, iY, iZ = vin:Unpack()
	local dX, dY, dZ = nX * backoff, nY * backoff, nZ * backoff

	nX = iX - dX
	nY = iY - dY
	nZ = iZ - dZ

	if math.abs(nX) < STOP_EPSILON then
		nX = 0
	end
	if math.abs(nY) < STOP_EPSILON then
		nY = 0
	end
	if math.abs(nZ) < STOP_EPSILON then
		nZ = 0
	end

	return Vector(nX,nY,nZ)
end

local function IsBSPModel(pEnt, iSolid)
	if iSolid == SOLID_BSP then
		return true
	end

	local model = pEnt:GetModel()
	if iSolid == SOLID_VPHYSICS and model:find("^%*(%d+)") then
		return true
	end

	return false
end

local function IsStandable(pEnt)
	if bit.band(pEnt:GetSolidFlags(), FSOLID_NOT_STANDABLE) ~= 0 then
		return false
	end

	local iSolid = pEnt:GetSolid()
	if iSolid == SOLID_BSP or iSolid == SOLID_VPHYSICS or iSolid == SOLID_BBOX then
		return true
	end

	return IsBSPModel(pEnt, iSolid)
end

function ENT:ResolveCustomFlyCollision(trace, vel)
    -- Assume all surfaces have the same elasticity
    local surfaceElasticity = 1

    -- Don't bounce off of players with perfect elasticity
    if trace.Entity:IsValid() and trace.Entity:IsPlayer() then
        surfaceElasticity = 0.3
    end

    -- if its breakable glass and we kill it, don't bounce.
    -- give some damage to the glass, and if it breaks, pass
    -- through it.
    local breakthrough = false

    if trace.Entity:IsValid() then
        local classname = trace.Entity:GetClass()
        if classname == "func_breakable" or classname == "func_breakable_surf" then
            breakthrough = true
        end
    end

    if breakthrough and SERVER then
        local info = DamageInfo()
        info:SetInflictor(self)
        info:SetAttacker(self)
        info:SetDamage(10)
        info:SetDamageType(DMG_CLUB)
        trace.Entity:TakeDamageInfo(info)

        if trace.Entity:Health() <= 0 then
            -- slow our flight a little bit
            local velocity = self:GetVelocity()
            velocity:Mul(0.4)
            self:SetLocalVelocity(velocity)
            return
        end
    end

    local totalElasticity = math.Clamp(self:GetElasticity() * surfaceElasticity, 0, 0.9)

    -- NOTE: A backoff of 2.0 is a reflection
    local absVelocity = self:GetVelocity()
    absVelocity = PhysicsClipVelocity(absVelocity, trace.HitNormal, 2.0)
    absVelocity:Mul(totalElasticity)

    -- Get the total velocity (player + conveyors, etc.)
    absVelocity:Add(self:GetBaseVelocity())
    local flSpeedSqr = absVelocity:LengthSqr()

    -- Stop if on ground.
    if trace.HitNormal.z > 0.7 then -- Floor
        -- Verify that we have an entity.
        local entity = trace.Entity

        self:SetLocalVelocity(absVelocity)

        if flSpeedSqr < (30 * 30) then
            if IsStandable(entity) then
                self:SetGroundEntity(entity)
            end

            -- Reset velocities.
            self:SetLocalVelocity(Vector())
            self:SetLocalAngularVelocity(Angle())

            -- align to the ground so we're not standing on end
            local angle = trace.HitNormal:Angle()

            -- rotate randomly in yaw
            angle.y = math.Rand(0, 360)

            self:SetAngles(angle)
        else
            local baseVel = self:GetBaseVelocity()
            local delta = baseVel - absVelocity
            local baseDir = Vector(baseVel)
            baseDir:Normalize()
            local scale = delta:Dot(baseDir)

            vel:Set(absVelocity)
            vel:Mul((1 - trace.Fraction) * FrameTime())
            --vel:Add(baseVel * (scale * (1 - trace.Fraction) * FrameTime()))
            self:SetLocalVelocity(absVelocity)
        end
    else
        -- If we get *too* slow, we'll stick without ever coming to rest because
        -- we'll get pushed down by gravity faster than we can escape from the wall.
        if flSpeedSqr < (30 * 30) then
            -- Reset velocities.
            self:SetLocalVelocity(Vector())
            self:SetLocalAngularVelocity(Angle())
        else
            self:SetLocalVelocity(absVelocity)
        end
    end

    self:BounceSound()
end

function ENT:BounceSound()
    --print("tink")
end
