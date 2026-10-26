AddCSLuaFile()

local sv_showimpacts = GetConVar("sv_showimpacts")
local sv_showimpacts_time = GetConVar("sv_showimpacts_time")
local phys_pushscale = GetConVar("phys_pushscale")

local SWITCH_BulletTypeParameters = {
	["BULLET_PLAYER_50AE"] = {
		fPenetrationPower = 30,
		flPenetrationDistance = 1000,
	},
	["BULLET_PLAYER_762MM"] = {
		fPenetrationPower = 39,
		flPenetrationDistance = 5000,
	},
	["BULLET_PLAYER_556MM"] = {
		fPenetrationPower = 35,
		flPenetrationDistance = 4000,
	},
	["BULLET_PLAYER_338MAG"] = {
		fPenetrationPower = 45,
		flPenetrationDistance = 8000,
	},
	["BULLET_PLAYER_9MM"] = {
		fPenetrationPower = 21,
		flPenetrationDistance = 800,
	},
	["BULLET_PLAYER_BUCKSHOT"] = {
		fPenetrationPower = 0,
		flPenetrationDistance = 0,
	},
	["BULLET_PLAYER_45ACP"] = {
		fPenetrationPower = 15,
		flPenetrationDistance = 500,
	},
	["BULLET_PLAYER_357SIG"] = {
		fPenetrationPower = 25,
		flPenetrationDistance = 800,
	},
	["BULLET_PLAYER_57MM"] = {
		fPenetrationPower = 30,
		flPenetrationDistance = 2000,
	},
}
SWITCH_BulletTypeParameters["BULLET_PLAYER_556MM_BOX"] = SWITCH_BulletTypeParameters["BULLET_PLAYER_556MM"]

SWITCH_MaterialParameters = {
	[MAT_METAL] = { -- If we hit metal, reduce the thickness of the brush we can't penetrate
		flPenetrationModifier = 0.5,
		flDamageModifier = 0.3,
	},
	[MAT_CONCRETE] = {
		flPenetrationModifier = 0.4,
		flDamageModifier = 0.25,
	},
	[MAT_GRATE] = {
		flPenetrationModifier = 1,
		flDamageModifier = 0.99,
	},
	[MAT_VENT] = {
		flPenetrationModifier = 0.5,
		flDamageModifier = 0.45,
	},
	[MAT_TILE] = {
		flPenetrationModifier = 0.65,
		flDamageModifier = 0.3,
	},
	[MAT_COMPUTER] = {
		flPenetrationModifier = 0.4,
		flDamageModifier = 0.45,
	},
	[MAT_WOOD] = {
		flPenetrationModifier = 1,
		flDamageModifier = 0.6,
	},
}
SWITCH_MaterialParameters[MAT_DIRT] = SWITCH_MaterialParameters[MAT_METAL]

CS_MASK_SHOOT = bit.bor(MASK_SOLID, CONTENTS_DEBRIS)

local IMPACT_MAXS = Vector(2, 2, 2)
local IMPACT_MINS = IMPACT_MAXS * -1
local IMPACT_COLOR = CLIENT and Color(255, 0, 0, 127) or Color(0, 0, 255, 127)
local MAT_IMPACT = Material(util.DecalMaterial("Impact.Concrete"))

local function TraceToExit(start, dir, endpos, flStepSize, flMaxDistance)
	local flDistance = 0

	while flDistance <= flMaxDistance do
		flDistance = flDistance + flStepSize

		endpos:Set(start)
		endpos:Add(dir * flDistance)

		if bit.band(util.PointContents(endpos), MASK_SOLID) == 0 then
			return true
		end
	end

	return false
end

-- penetration is too intertwined with this function to be able to extract it out into subfunctions
function SWEP:CS_FireBullet(vecSrc, shootAngles, flDistance, iPenetration, iBulletType, iDamage, flRangeModifier,
														pevAttacker, bDoEffects, xSpread, ySpread)
	local selfTable = self:GetTable()
	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return end

	local iShowImpacts = sv_showimpacts:GetInt()
	local bDrawDebug = (CLIENT and (iShowImpacts == 1 or iShowImpacts == 2) and IsFirstTimePredicted()) or
			(SERVER and (iShowImpacts == 1 or iShowImpacts == 3))
	local flDebugTime = 0
	if bDrawDebug then
		flDebugTime = sv_showimpacts_time:GetFloat()
	end

	local fCurrentDamage = iDamage
	local flCurrentDistance = 0

	local vecDirShooting, vecRight, vecUp = Vector(), Vector(), Vector()
	swsrc.AngleVectors(shootAngles, vecDirShooting, vecRight, vecUp)

	local flPenetrationPower = 0 -- thickness of a wall that this bullet can penetrate
	local flPenetrationDistance = 0 -- distance at which the bullet is capable of penetrating a wall
	local flDamageModifier = 0.5 -- default modification of bullets power after they go through a wall.
	local flPenetrationModifier = 1

	local params = SWITCH_BulletTypeParameters[iBulletType]
	if params then
		flPenetrationPower = params.fPenetrationPower
		flPenetrationDistance = params.flPenetrationDistance
	end

	iBulletType = game.GetAmmoID(iBulletType)

	if not pevAttacker or not pevAttacker:IsValid() then
		pevAttacker = owner
	end

	-- add the spray
	local vecDir = vecDirShooting + xSpread * vecRight + ySpread * vecUp
	vecDir:Normalize()

	local iPenetrationKills = 0

	--local bFirstHit = true
	local lastPlayerHit = NULL

	local tr = {}
	local traceData = {
		start = Vector(),
		endpos = Vector(),
		mask = bit.bor(CS_MASK_SHOOT, CONTENTS_HITBOX),
		filter = {owner},
		collisiongroup = COLLISION_GROUP_NONE,
		output = tr,
	}

	local waterTrace = {}
	local waterTraceData = {
		start = Vector(),
		endpos = Vector(),
		mask = bit.bor(MASK_SHOT, CONTENTS_WATER, CONTENTS_SLIME),
		filter = {owner},
		collisiongroup = COLLISION_GROUP_NONE,
		output = waterTrace,
	}

	local exitTr = {}
	local exitTrData = {
		start = Vector(),
		endpos = Vector(),
		mask = bit.bor(CS_MASK_SHOOT, CONTENTS_HITBOX),
		filter = {},
		collisiongroup = COLLISION_GROUP_NONE,
		output = exitTr,
	}

	while fCurrentDamage > 0 do
		traceData.start:Set(vecSrc)
		traceData.endpos:Set(vecSrc)
		traceData.endpos:Add(vecDir * flDistance)

		if lastPlayerHit:IsValid() then
			table.insert(traceData.filter, lastPlayerHit)
		end

		hook.Run("SWSrcPenetratationIgnoreEntities", self, owner, traceData.filter)
		hook.Run("SWCSPenetratationIgnoreEntities", self, owner, traceData.filter)

		util.TraceLine(traceData)
		-- TODO?: rayExtension = 40, ClipTraceToPlayers

		-- we didn't hit anything, stop tracing shoot
		if tr.Fraction == 1 then break end

		if lastPlayerHit:IsPlayer() then
			lastPlayerHit = tr.Entity
		elseif tr.Entity.IsSWCSShield then
			break
		end

		--bFirstHit = false

		local pSurfaceData = util.GetSurfaceData(tr.SurfaceProps)
		local iEnterMaterial = pSurfaceData and pSurfaceData.material or -1
		local matParams = SWITCH_MaterialParameters[iEnterMaterial]

		local hitGrate = bit.band(tr.Contents, CONTENTS_GRATE) ~= 0
		-- since some railings in de_inferno are CONTENTS_GRATE but CHAR_TEX_CONCRETE, we'll trust the CONTENTS_GRATE and
		-- use a high damage modifier.
		if hitGrate then
			-- If we're a concrete grate (TOOLS/TOOLSINVISIBLE texture) allow more penetrating power.
			matParams = SWITCH_MaterialParameters[MAT_GRATE]
		end

		if matParams then
			flPenetrationModifier = matParams.flPenetrationModifier
			flDamageModifier = matParams.flDamageModifier
		end

		if bDrawDebug then
			debugoverlay.Box(tr.HitPos, IMPACT_MINS, IMPACT_MAXS, flDebugTime, IMPACT_COLOR)
		end

		-- calculate the damage based on the distance the bullet travelled.
		flCurrentDistance = flCurrentDistance + tr.Fraction * flDistance
		fCurrentDamage = fCurrentDamage * math.pow(flRangeModifier, flCurrentDistance / 500)

		-- check if we reach penetration distance, no more penetrations after that
		if flCurrentDistance > flPenetrationDistance and iPenetration > 0 then
			iPenetration = 0
		end

		local iDamageType = bit.bor(DMG_BULLET, DMG_NEVERGIB)

		if bDoEffects then
			-- See if the bullet ended up underwater + started out of the water
			if bit.band(util.PointContents(tr.HitPos), bit.bor(CONTENTS_WATER, CONTENTS_SLIME)) ~= 0 then
				waterTraceData.start:Set(vecSrc)
				waterTraceData.endpos:Set(tr.HitPos)
				util.TraceLine(waterTraceData)

				if not waterTrace.AllSolid then
					local data = EffectData()
					data:SetOrigin(waterTrace.HitPos)
					data:SetNormal(waterTrace.HitNormal)
					data:SetScale(util.SharedRandom("SWSrc:FireBullets WaterSplash", 8, 12))

					if bit.band(waterTrace.Contents, CONTENTS_SLIME) ~= 0 then
						data:SetFlags(1) -- FX_WATER_IN_SLIME
					else
						data:SetFlags(0)
					end

					util.Effect("gunshotsplash", data, not game.SinglePlayer())
				end
			else
				-- Do Regular hit effects

				-- Don't decal nodraw surfaces
				if bit.band(tr.SurfaceFlags, bit.bor(SURF_SKY, SURF_NODRAW, SURF_HINT, SURF_SKIP)) == 0 then
					-- UTIL_ImpactTrace
					if tr.Fraction ~= 1 then
						local ent = tr.Entity

						local data = EffectData()
						data:SetOrigin(tr.HitPos)
						data:SetStart(tr.StartPos)
						data:SetSurfaceProp(tr.SurfaceProps)
						data:SetDamageType(iDamageType)
						data:SetHitBox(tr.HitBox)
						data:SetEntity(ent)

						if
							(CLIENT and IsFirstTimePredicted())
							and (ent:IsWorld() or (ent:IsValid() and not (ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot())))
						then
							local normal = Vector(tr.Normal)

							if tr.HitNormal.z == 0 then
								normal.z = 0
								normal:Normalize()
							end

							local planeRight = normal:Cross(-vector_up)
							local planeForward = planeRight:Cross(vector_up)

							local decalAngle = planeForward:AngleEx(vector_up)
							local decalNormal = decalAngle:Forward()

							if tr.HitNormal.z ~= 0 then
								decalNormal:Set(planeRight)
							end

							util.DecalEx(MAT_IMPACT, ent, tr.HitPos, decalNormal, color_white, 1, 1)
						end

						util.Effect("Impact_GMOD", data, not game.SinglePlayer())
					end
				end
			end
		end

		if SERVER then
			local pEntity = tr.Entity
			local bWasAlive = pEntity:Alive()

			local info = DamageInfo()
			info:SetAttacker(pevAttacker)
			info:SetInflictor(self)
			info:SetDamage(fCurrentDamage)
			info:SetDamageType(iDamageType)

			-- CalculateBulletDamageForce
			info:SetDamagePosition(tr.HitPos)
			local vecForce = Vector(vecDir)
			vecForce:Normalize()
			vecForce:Mul(game.GetAmmoForce(iBulletType))
			vecForce:Mul(phys_pushscale:GetFloat())
			info:SetDamageForce(vecForce)

			if not pEntity or not pEntity:IsValid() then
				-- makes glass breakable with no hacky workaround
				pEntity = game.GetWorld()
			end

			pEntity:DispatchTraceAttack(info, tr)

			if bWasAlive and not pEntity:Alive() and pEntity:IsPlayer() then
				iPenetrationKills = iPenetrationKills + 1
			end
		end

		-- check if bullet can penetrate another entity
		if iPenetration == 0 and not hitGrate then
			break -- no, stop
		end

		-- If we hit a grate with iPenetration == 0, stop on the next thing we hit
		if iPenetration < 0 then break end

		local penetrationEnd = Vector()

		if not TraceToExit(tr.HitPos, vecDir, penetrationEnd, 24, 128) then break end

		exitTrData.start:Set(penetrationEnd)
		exitTrData.endpos:Set(tr.HitPos)
		util.TraceLine(exitTrData)

		if exitTr.Entity ~= tr.Entity and exitTr.Entity:IsValid() then
			-- something was blocking, trace again
			table.insert(exitTrData.filter, exitTr.Entity)
			util.TraceLine(exitTrData)
		end

		pSurfaceData = util.GetSurfaceData(exitTr.SurfaceProps)
		local iExitMaterial = pSurfaceData and pSurfaceData.material or -1

		hitGrate = hitGrate and bit.band(exitTr.Contents, CONTENTS_GRATE) ~= 0

		-- if enter & exit point is wood or metal we assume this is  a hollow crate or barrel and give a penetration bonus
		if iEnterMaterial == iExitMaterial then
			if iExitMaterial == MAT_WOOD or iExitMaterial == MAT_METAL then
				flPenetrationModifier = flPenetrationModifier * 2
			end
		end

		local flTraceDistance = exitTr.HitPos:Distance(tr.HitPos)

		-- check if bullet has enough power to penetrate this distance for this material
		if flTraceDistance > (flPenetrationPower * flPenetrationModifier) then
			break -- bullet hasn't enough power to penetrate this distance
		end

		-- penetration was successful

		-- bullet did penetrate object, exit Decal
		if bDoEffects then
			-- UTIL_ImpactTrace
			if bit.band(exitTr.SurfaceFlags, bit.bor(SURF_SKY, SURF_NODRAW)) == 0 and exitTr.Fraction ~= 1 then
				local ent = exitTr.Entity

				local data = EffectData()
				data:SetOrigin(exitTr.HitPos)
				data:SetStart(exitTr.StartPos)
				data:SetSurfaceProp(exitTr.SurfaceProps)
				data:SetDamageType(iDamageType)
				data:SetHitBox(exitTr.HitBox)
				data:SetEntity(ent)

				if
					(CLIENT and IsFirstTimePredicted())
					and (ent:IsWorld() or (ent:IsValid() and not (ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot())))
				then
					local normal = Vector(exitTr.Normal)

					if exitTr.HitNormal.z == 0 then
						normal.z = 0
						normal:Normalize()
					end

					local planeRight = normal:Cross(-vector_up)
					local planeForward = planeRight:Cross(vector_up)

					local decalAngle = planeForward:AngleEx(vector_up)
					local decalNormal = decalAngle:Forward()

					if exitTr.HitNormal.z ~= 0 then
						decalNormal:Set(planeRight)
					end

					util.DecalEx(MAT_IMPACT, ent, exitTr.HitPos, decalNormal, color_white, 1, 1)
				end

				util.Effect("Impact_GMOD", data, not game.SinglePlayer())
			end
		end

		-- setup new start end parameters for successive trace
		flPenetrationPower = flPenetrationPower - (flTraceDistance / flPenetrationModifier)
		flCurrentDistance = flCurrentDistance + flTraceDistance

		vecSrc:Set(exitTr.HitPos)
		flDistance = (flDistance - flCurrentDistance) * 0.5

		-- reduce damage power each time we hit something other than a grate
		fCurrentDamage = fCurrentDamage * flDamageModifier

		-- reduce penetration counter
		iPenetration = iPenetration - 1
	end
end
