AddCSLuaFile()

SWEP.Base = "weapon_swsrc_base"
DEFINE_BASECLASS(SWEP.Base)

SWEP.Category = "#spawnmenu.category.swsrc"
SWEP.SubCategory = "#spawnmenu.category.other"

SWEP.PrintName = "C4"
SWEP.Spawnable = true
SWEP.HoldType = "knife"
SWEP.WorldModel = "models/weapons/w_c4.mdl"
SWEP.ViewModel = "models/weapons/cstrike/c_c4.mdl"
SWEP.IconOverride = "vgui/achievements/win_bomb_plant"

SWEP.WeaponData = [=[WeaponData
{
	"MaxPlayerSpeed"		"250"
	"WeaponType"			"C4"
	"WeaponPrice"			"0"
	"WeaponArmorRatio"		"1.0"
	"CrosshairMinDistance"		"6"
	"CrosshairDeltaDistance"	"3"
	"Team"				"TERRORIST"
	"BuiltRightHanded" 		"0"
	"PlayerAnimationExtension"	"c4"
	"MuzzleFlashScale"		"1"

	"CanEquipWithShield"		"1"
	"AllowFlipping" 		"0"

	// Weapon characteristics:
	"Penetration"			"1"
	"Damage"			"50"
	"Range"				"4096"
	"RangeModifier"			"0.99"
	"Bullets"			"1"

	// Weapon data is loaded by both the Game and Client DLLs.
	"printname"			"#Cstrike_WPNHUD_C4"
	"viewmodel"			"models/weapons/v_c4.mdl"
	"playermodel"			"models/weapons/w_c4.mdl"
	"shieldviewmodel"		"models/weapons/v_c4.mdl"
	"anim_prefix"			"anim"
	"bucket"			"4"
	"bucket_position"		"0"

	"clip_size"			"30"

	"primary_ammo"			"None"
	"secondary_ammo"		"None"

	"weight"			"0"
	"item_flags"			"0"

	// Sounds for the weapon. There is a max of 16 sounds per category (i.e. max 16 "single_shot" sounds)
	SoundData
	{
	}

	// Weapon Sprite data is loaded by the Client DLL.
	TextureData
	{
		"weapon"
		{
				"font"		"CSweaponsSmall"
				"character"	"C"
		}
		"weapon_s"
		{
				"font"		"CSweapons"
				"character"	"C"
		}
		"ammo"
		{
				"file"		"sprites/640hud1"
				"x"		"182"
				"y"		"24"
				"width"		"26"
				"height"		"24"
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
			Mins	"-4 -8 -17"
			Maxs	"20 13 1"
		}
		World
		{
			Mins	"-3 0 -4"
			Maxs	"7 12 4"
		}
	}
}]=]

local g_bSinglePlayer = game.SinglePlayer()

local WEAPON_C4_ARM_TIME = 3
local NUM_BEEPS = 7

SWEP.m_szScreenText = ""
SWEP.m_bPlayedArmingBeeps = {}
SWEP.m_bBombPlanted = false

function SWEP:OverrideData(tbl)
	-- TODO: cvar for cs:s slots?
	tbl.Slot = 4
end

function SWEP:GetWeaponID()
	return WEAPON_C4
end

function SWEP:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:NetworkVar("Bool", "StartedArming")
	self:NetworkVar("Bool", "BombPlacedAnimation")
	self:NetworkVar("Float", "ArmedTime")
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

	if bit.band(btns, IN_ATTACK) ~= 0 then
		selfTable.PrimaryAttack(self)
	else
		selfTable.WeapoonIdle(self, selfTable)
	end
end

function SWEP:FireAnimationEvent(pos, ang, event, options, src_ent)
	local selfTable = self:GetTable()

	if event == 7001 then
		print(options)
		selfTable.m_szScreenText = options
	end

	return BaseClass.FireAnimationEvent(self, pos, ang, event, options, src_ent)
end

function SWEP:Holster(pSwitchingTo)
	local selfTable = self:GetTable()

	if selfTable.GetStartedArming(self) then
		selfTable.AbortBombPlant(self)
	end

	return BaseClass.Holster(self, pSwitchingTo)
end

function SWEP:PrimaryAttack()
	local selfTable = self:GetTable()

	local bArmingTimeSatisfied = false

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return end

	local onGround = owner:IsOnGround()
	local groundEntity = onGround and owner:GetGroundEntity() or NULL
	if groundEntity:IsValid() or groundEntity:IsWorld() then
		if
			groundEntity:IsPlayer() or
			swsrc.IsPushableEntity(groundEntity) or
			(SERVER and swsrc.IsBreakableEntity(groundEntity)) or
			swsrc.IsPushAwayEntity(groundEntity)
		then
			onGround = false
		end
	end

	if selfTable.GetStartedArming(self) == false and selfTable.m_bBombPlanted == false then
		if --[[owner m_bInBombZone and]] onGround then
			selfTable.SetStartedArming(self, true)
			selfTable.SetArmedTime(self, CurTime() + WEAPON_C4_ARM_TIME)
			selfTable.SetBombPlacedAnimation(self, false)

			if SERVER then
				for i = 1, NUM_BEEPS do
					selfTable.m_bPlayedArmingBeeps[i] = false
				end
			end

			owner:SetAnimation(PLAYER_ATTACK1)

			owner:SetSaveValue("m_flNextAttack", SERVER and 0 or CurTime())

			-- gameevent?

			selfTable.SetWeaponAnim(self, ACT_VM_PRIMARYATTACK)

			owner:DoCustomAnimEvent(PLAYERANIMEVENT_ATTACK_PRIMARY, 0)
		else
			--if not m_bInBombZone then
			--	owner:PrintMessage(HUD_PRINTCENTER, "#Cstrike_TitlesTXT_C4_Plant_At_Bomb_Spot")
			--else
			owner:PrintMessage(HUD_PRINTCENTER, "#Cstrike_TitlesTXT_C4_Plant_Must_Be_On_Ground")
			--end

			self:SetNextPrimaryFire(CurTime() + 1)
			return
		end
	else
		if not onGround --[[or m_bInBombZone]] then
			--if not m_bInBombZone then
			--	owner:PrintMessage(HUD_PRINTCENTER, "#Cstrike_TitlesTXT_C4_Arming_Cancelled")
			--else
			owner:PrintMessage(HUD_PRINTCENTER, "#Cstrike_TitlesTXT_C4_Plant_Must_Be_On_Ground")
			--end

			selfTable.AbortBombPlant(self)

			if selfTable.GetBombPlacedAnimation(self) then -- this means the placement animation is canceled
				selfTable.SetWeaponAnim(ACT_VM_DRAW)
			else
				selfTable.SetWeaponAnim(ACT_VM_IDLE)
			end

			return
		else
			if SERVER then
				selfTable.PlayArmingBeeps(self, selfTable)
			end

			if CurTime() >= selfTable.GetArmedTime(self) then -- the c4 is ready to be armed
				-- check to make sure the player is still in the bomb target area
				bArmingTimeSatisfied = true
			elseif CurTime() >= self.GetArmedTime(self) - 0.75 and not selfTable.GetBombPlacedAnimation(self) then
				-- call the c4 Placement animation
				selfTable.SetBombPlacedAnimation(self, true)
				selfTable.SetWeaponAnim(ACT_VM_SECONDARYATTACK)
			end
		end
	end

	if bArmingTimeSatisfied and selfTable.GetStartedArming(self) then
		selfTable.SetStartedArming(self, false)
		selfTable.SetArmedTime(0)

		--if m_bInBombZone then
		if SERVER then
			local pC4 = selfTable.ShootSatchelCharge(self)
			if pC4:IsValid() then
				-- SetBombSiteIndex

				local tr = util.TraceEntity({
					start = pC4:GetPos(),
					endpos = pC4:GetPos() + Vector(0, 0, -200),
					mask = MASK_SOLID,
					collisiongroup = COLLISION_GROUP_NONE,
					filter = {self},
				}, pC4)
				pC4:SetPos(tr.HitPos)

				-- pBombTarget mount target and BombPlanted input

				-- SetPlantedAfterPickup

				-- gameevents?

				-- progress bar time

				-- global m_bBombDropped = false
				-- global m_bBombPlanted = true

				-- plant sound

				owner:DropWeapon(self)
				SafeRemoveEntity(self)
			end
		end

		selfTable.m_bBombPlanted = true

		return
		--else
		--	owner:PrintMessage(HUD_PRINTCENTER, "#Cstrike_TitlesTXT_C4_Plant_At_Bomb_Spot")
		--
		--	-- gameevent?
		--	self:SetNextPrimaryFire(CurTime() + 1)
		--	return
		--end
	end

	self:SetNextPrimaryFire(CurTime() + 0.3)
	selfTable.SetWeaponIdleTime(self, CurTime() + util.SharedRandom("C4IdleTime", 10, 15))
end

function SWEP:WeaponIdle(tbl)
	local selfTable = tbl or self:GetTable()

	if selfTable.GetStartedArming(self) then
		selfTable.AbortBombPlant(self)

		local owner = selfTable.GetPlayerOwner(self)
		if owner ~= false then
			selfTable.SetWeaponAnim(self, ACT_VM_IDLE)
			owner:SetSaveValue("m_flNextAttack", SERVER and 0 or CurTime())
		end

		if selfTable.GetBombPlacedAnimation(self) then
			selfTable.SetWeaponAnim(self, ACT_VM_DRAW)
		else
			selfTable.SetWeaponAnim(self, ACT_VM_IDLE)
		end
	end
end

local m_iBeepFrames = {27, 37, 45, 51, 57, 63, 67}
local iNumArmingAnimFrames = 83
function SWEP:PlayArmingBeeps(tbl)
	local selfTable = tbl or self:GetTable()

	local flStartTime = selfTable.GetArmedTime(self) - WEAPON_C4_ARM_TIME

	local flProgress = (CurTime() - flStartTime) / (WEAPON_C4_ARM_TIME - 0.75)

	local currentFrame = math.floor(iNumArmingAnimFrames * flProgress)

	for i = 1, NUM_BEEPS do
		if currentFrame <= m_iBeepFrames[i] then
			break
		elseif not selfTable.m_bPlayedArmingBeeps[i] then
			selfTable.m_bPlayedArmingBeeps[i] = true

			local owner = selfTable.GetPlayerOwner(self)
			if not owner then break end -- cs:s really doesnt check the validity here??

			local soundPos = owner:GetPos() + Vector(0, 0, 5)
			local filter = RecipientFilter()
			filter:AddPAS(soundPos)

			filter:RemovePlayer(owner)

			for _, ply in player.Iterator() do
				if ply:IsBot() then continue end
				if ply == owner then continue end

				if ply:GetObserverMode() == OBS_MODE_IN_EYE and ply:GetObserverTarget() == owner then
					filter:RemovePlayer(ply)
				end
			end

			EmitSound("c4.click", soundPos, self:EntIndex(), CHAN_WEAPON, 1, 75, 0, 100, 1, filter)

			break
		end
	end
end

function SWEP:GetMaxSpeed()
	if self:GetStartedArming() then
		return 0
	else
		return BaseClass.GetMaxSpeed(self)
	end
end

--[[function SWEP:OwnerChanged()
	local selfTable = self:GetTable()

	BaseClass.OwnerChanged(self)

	if SERVER then
		local owner = selfTable.GetPlayerOwner()
		if not owner then return end

		-- gameevent?

		-- you have the bomb hint
		-- else #got_bomb

		-- SetBombPickupTime
	end
end--]]

function SWEP:OnDrop(owner)
	local selfTable = self:GetTable()
	--if SERVER then
	--	-- gameevent?
	--end

	if selfTable.GetStartedArming(self) then
		selfTable.AbortBombPlant(self, selfTable)
	end

	BaseClass.OnDrop(owner)
end

function SWEP:AbortBombPlant(tbl)
	local selfTable = tbl or self:GetTable()

	selfTable.SetStartedArming(self, false)

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return end

	self:SetNextPrimaryFire(CurTime() + 1)

	-- set progress bar time 0

	-- gameevent?

	owner:DoCustomAnimEvent(PLAYERANIMEVENT_CANCEL, 0)
end
