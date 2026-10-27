AddCSLuaFile()

SWEP.Base = "weapon_swsrc_base"
DEFINE_BASECLASS(SWEP.Base)

SWEP.Category = "#spawnmenu.category.swsrc"
SWEP.SubCategory = "#spawnmenu.category.other"

SWEP.PrintName = "Knife"
SWEP.Spawnable = true
SWEP.HoldType = "knife"
SWEP.WorldModel = "models/weapons/w_knife_t.mdl"
SWEP.ViewModel = "models/weapons/cstrike/c_knife_t.mdl"
SWEP.IconOverride = "vgui/achievements/kill_enemy_knife"

SWEP.WeaponData = [=[WeaponData
{
	"MaxPlayerSpeed"		"250"
	"WeaponType"			"Knife"
	"WeaponPrice"			"0"
	"WeaponArmorRatio"		"1.7"
	"CrosshairMinDistance"		"7"
	"CrosshairDeltaDistance"	"3"
	"Team"				"ANY"
	"BuiltRightHanded"		"1"
	"PlayerAnimationExtension"	"knife"
	"MuzzleFlashScale"		"0"
	"MuzzleFlashStyle"		"CS_MUZZLEFLASH_NONE"
	"CanEquipWithShield"		"1"


	// Weapon characteristics:
	"Penetration"			"1"
	"Damage"			"50"
	"Range"				"4096"
	"RangeModifier"			"0.99"
	"Bullets"			"1"

	// Weapon data is loaded by both the Game and Client DLLs.
	"printname"			"#Cstrike_WPNHUD_Knife"
	"viewmodel"			"models/weapons/v_knife_t.mdl"
	"playermodel"			"models/weapons/w_knife_t.mdl"
	"shieldviewmodel"		"models/weapons/v_shield_knife_r.mdl"
	"anim_prefix"			"anim"
	"bucket"			"2"
	"bucket_position"		"1"

	"clip_size"			"-1"
	"default_clip"			"1"
	"primary_ammo"			"None"
	"secondary_ammo"		"None"

	"weight"			"0"
	"item_flags"			"0"

	// Sounds for the weapon. There is a max of 16 sounds per category (i.e. max 16 "single_shot" sounds)
	SoundData
	{
		"reload"			"Default.Reload"
		"empty"				"Default.ClipEmpty_Rifle"
		"single_shot"		"Weapon_DEagle.Single"
	}

	// Weapon Sprite data is loaded by the Client DLL.
	TextureData
	{
		"weapon"
		{
				"font"		"CSweaponsSmall"
				"character"	"J"
		}
		"weapon_s"
		{
				"font"		"CSweapons"
				"character"	"J"
		}
		"ammo"
		{
				"file"		"sprites/a_icons1"
				"x"			"55"
				"y"			"60"
				"width"		"73"
				"height"	"15"
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
			Mins	"-2 -16 -15"
			Maxs	"18 11 5"
		}
		World
		{
			Mins	"-2 -5 -5"
			Maxs	"10 4 11"
		}
	}
}]=]

function SWEP:OverrideData(tbl)
	tbl.Primary.Automatic = true
	tbl.Secondary.Automatic = true

	-- TODO: cvar for cs:s slots?
	tbl.Slot = 0
end

function SWEP:GetWeaponID()
	return WEAPON_KNIFE
end

local HEAD_HULL_MINS = Vector(-16, -16, -18)
local HEAD_HULL_MAXS = Vector(16, 16, 18)
local VEC_DUCK_HULL_MIN = Vector(-16, -16, 0)
local VEC_DUCK_HULL_MAX = Vector(16, 16, 45)

function SWEP:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:NetworkVar("Float", "SmackTime")
	self:SetSmackTime(-1)
end

function SWEP:Deploy()
	self:EmitSound("Weapon_Knife.Deploy")

	return BaseClass.Deploy(self)
end

local function FindHullIntersection(vecSrc, tr, mins, maxs, filter)
	local distance = 1e6
	local tmpTrace = {}
	local minmaxs = {mins, maxs}
	local vecHullEnd = Vector(tr.HitPos)
	local vecEnd = Vector()

	vecHullEnd = vecSrc + ((vecHullEnd - vecSrc) * 2)
	util.TraceLine({
		start = vecSrc,
		endpos = vecHullEnd,
		mask = MASK_SOLID,
		collisiongroup = COLLISION_GROUP_NONE,
		filter = filter,
		output = tmpTrace,
	})

	if tmpTrace.Fraction < 1 then
		table.CopyFromTo(tmpTrace, tr)
		return
	end

	for i = 1, 2 do
		for j = 1, 2 do
			for k = 1, 2 do
				vecEnd.x = vecHullEnd.x + minmaxs[i].x
				vecEnd.y = vecHullEnd.y + minmaxs[j].y
				vecEnd.z = vecHullEnd.z + minmaxs[k].z

				util.TraceLine({
					start = vecSrc,
					endpos = vecEnd,
					mask = MASK_SOLID,
					collisiongroup = COLLISION_GROUP_NONE,
					filter = filter,
					output = tmpTrace,
				})

				if tmpTrace.Fraction < 1 then
					local thisDistance = tmpTrace.HitPos:Distance(vecSrc)
					if thisDistance < distance then
						distance = thisDistance
						table.CopyFromTo(tmpTrace, tr)
					end
				end
			end
		end
	end
end


function SWEP:PrimaryAttack()
	local selfTable = self:GetTable()

	local owner = selfTable.GetPlayerOwner(self)

	if owner then
		owner:LagCompensation(true)
	end

	selfTable.SwingOrStab(self, false)

	if owner then
		owner:LagCompensation(false)
	end
end

function SWEP:SecondaryAttack()
	local selfTable = self:GetTable()

	local owner = selfTable.GetPlayerOwner(self)

	if owner then
		owner:LagCompensation(true)
	end

	selfTable.SwingOrStab(self, true)

	if owner then
		owner:LagCompensation(false)
	end
end

local MAT_SLASH = Material(util.DecalMaterial("ManhackCut"))
function SWEP:Smack()
	local selfTable = self:GetTable()

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return end

	local tr = selfTable.m_trHit
	tr.Entity = selfTable.m_pTraceHitEnt
	local ent = tr.Entity

	if bit.band(tr.SurfaceFlags, SURF_SKY) ~= 0 then return end
	if tr.Fraction == 1 then return end

	if ent:IsValid() and (ent:IsPlayer() or ent:IsNPC()) then
		self:EmitSound(selfTable.m_bStab and "Weapon_Knife.Stab" or "Weapon_Knife.Hit")
	else
		self:EmitSound("Weapon_Knife.HitWall")
	end

	if IsFirstTimePredicted() then
		local data = EffectData()
		data:SetOrigin(tr.HitPos)
		data:SetStart(tr.StartPos)
		data:SetSurfaceProp(tr.SurfaceProps)
		data:SetDamageType(DMG_SLASH)
		data:SetHitBox(tr.HitBox)
		data:SetEntity(ent)
		data:SetAngles(owner:GetAngles())
		data:SetFlags(1) -- IMPACT_NODECAL

		---@type boolean | CRecipientFilter
		local filter = true
		if SERVER then
			filter = RecipientFilter()
			filter:AddPAS(tr.HitPos)
			filter:RemovePlayer(owner)
		end

		if CLIENT and (ent:IsWorld() or (ent:IsValid() and not (ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot()))) then
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

			util.DecalEx(MAT_SLASH, ent, tr.HitPos, decalNormal, color_white, 1, 1)
		end
		util.Effect("Impact_GMOD", data, true, filter)
	end
end

function SWEP:WeaponIdle()
	local selfTable = self:GetTable()

	if selfTable.GetWeaponIdleTime(self) > CurTime() then return end

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return end

	selfTable.SetWeaponIdleTime(self, CurTime() + 20)

	selfTable.SetWeaponAnim(self, ACT_VM_IDLE)
end

local function IsBSPModel(pEnt)
	local iSolid = pEnt:GetSolid()
	if iSolid == SOLID_BSP then
		return true
	end

	local model = pEnt:GetModel()

	if iSolid == SOLID_VPHYSICS and model:find("^%*(%d+)") then
		return true
	end

	return false
end

local filter_IgnoreOwner = swcs and swcs.filter_IgnoreOwner or function(owner, _) return owner end
local IGNORE_SHIELD = {"swcs_shield"}

local phys_pushscale = GetConVar("phys_pushscale")
local KnifeDamageScale = GetConVar("swsrc_knife_damage_scale")
function SWEP:SwingOrStab(bStab)
	local selfTable = self:GetTable()

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return end

	local fRange = bStab and 32 or 48

	local vForward = owner:GetAimVector():Angle()
	vForward:Normalize()
	vForward = vForward:Forward()
	local vecSrc = owner.m_vSavedShootPos or owner:GetShootPos()
	local vecEnd = vecSrc + vForward * fRange

	local filter = filter_IgnoreOwner(owner, IGNORE_SHIELD)

	local tr = util.TraceLine({
		start = vecSrc,
		endpos = vecEnd,
		mask = MASK_SOLID,
		collisiongroup = COLLISION_GROUP_NONE,
		filter = filter,
	})

	if tr.Fraction >= 1 then
		util.TraceHull({
			start = vecSrc,
			endpos = vecEnd,
			mask = MASK_SOLID,
			collisiongroup = COLLISION_GROUP_NONE,
			filter = filter,
			mins = HEAD_HULL_MINS,
			maxs = HEAD_HULL_MAXS,
			output = tr,
		})

		if tr.Fraction < 1 then
			local pHit = tr.Entity
			if pHit and not pHit:IsValid() or IsBSPModel(pHit) then
				FindHullIntersection(vecSrc, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, filter)
			end

			vecEnd = tr.HitPos
		end
	end

	local bDidHit = tr.Fraction < 1

	local bFirstSwing = self:GetNextPrimaryFire() + 0.4 < CurTime()

	local fPrimDelay, fSecDelay

	-- gmod uses PRIMARYATTACK instead of HITCENTER
	selfTable.SetWeaponAnim(self, bDidHit and ACT_VM_PRIMARYATTACK or ACT_VM_MISSCENTER)
	owner:DoAttackEvent()

	if bStab then
		local d = bDidHit and 1.1 or 1.0
		fPrimDelay = d
		fSecDelay = d
	else
		fPrimDelay = bDidHit and 0.5 or 0.4
		fSecDelay = 0.5
	end

	self:SetNextPrimaryFire(CurTime() + fPrimDelay)
	self:SetNextSecondaryFire(CurTime() + fSecDelay)
	selfTable.SetWeaponIdleTime(self, CurTime() + 2)

	if not bDidHit then
		self:EmitSound("Weapon_Knife.Slash")
	else
		if SERVER then
			local pEntity = tr.Entity

			local flDamage = 42

			if bStab then
				flDamage = 65

				if pEntity and pEntity:IsValid() and (pEntity:IsPlayer() or pEntity:IsNPC()) then
					local vTargetForawrd = pEntity:EyeAngles():Forward()

					local vecLOS = pEntity:GetPos() - owner:GetPos()
					vecLOS.z = 0
					vecLOS:Normalize()

					vTargetForawrd.z = 0
					local flDot = vecLOS:Dot(vTargetForawrd)

					if flDot > 0.8 then
						flDamage = flDamage * 3
					end
				end
			else
				if bFirstSwing then
					flDamage = 20
				else
					flDamage = 15
				end
			end

			flDamage = flDamage * (KnifeDamageScale:GetInt() / 100)

			local info = DamageInfo()
			info:SetInflictor(self)
			info:SetAttacker(owner)
			info:SetDamage(flDamage)
			info:SetDamageType(DMG_SLASH)

			local flScale = 1 / flDamage
			info:SetDamagePosition(tr.HitPos)

			local flForceScale = info:GetBaseDamage() * 300 -- ImpulseScale(75, 4)
			local vecForce = vForward * 1
			vecForce:Normalize()
			vecForce:Mul(flForceScale)
			vecForce:Mul(phys_pushscale:GetFloat())
			vecForce:Mul(flScale)
			info:SetDamageForce(vecForce)

			if not pEntity or not pEntity:IsValid() then
				-- makes glass breakable with no hacky workaround
				pEntity = game.GetWorld()
			end

			pEntity:DispatchTraceAttack(info, tr)

			--SuppressHostEvents(owner)
		end

		selfTable.m_trHit = tr
		selfTable.m_pTraceHitEnt = tr.Entity
		selfTable.m_bStab = bStab
		selfTable.SetSmackTime(self, CurTime() + (bStab and 0.2 or 0.1))
	end

	owner:SetAnimation(PLAYER_ATTACK1)
end

function SWEP:ProcessExtraActivities(tbl)
	local selfTable = tbl or self:GetTable()

	if selfTable.GetSmackTime(self) > 0 and CurTime() > selfTable.GetSmackTime(self) then
		selfTable.Smack(self)
		selfTable.SetSmackTime(self, -1)
	end
end
