include("shared.lua")

do -- crosshair
	local crosshair = GetConVar("swsrc_crosshair")
	local cl_dynamiccrosshair = GetConVar("swsrc_dynamiccrosshair")
	local cl_crosshairspreadscale = GetConVar("swsrc_crosshairspreadscale")
	local cl_crosshairscale = GetConVar("swsrc_crosshairscale")
	local cl_scalecrosshair = GetConVar("swsrc_scalecrosshair")
	local cl_crosshaircolor = GetConVar("swsrc_crosshaircolor")
	local cl_crosshairalpha = GetConVar("swsrc_crosshairalpha")
	local cl_crosshairusealpha = GetConVar("swsrc_crosshairusealpha")
	local cl_crosshairsize = GetConVar("swsrc_crosshairsize")
	local cl_crosshairthickness = GetConVar("swsrc_crosshairthickness")
	local cl_crosshairdot = GetConVar("swsrc_crosshairdot")
	local cl_crosshaircolor_r = GetConVar("swsrc_crosshaircolor_r")
	local cl_crosshaircolor_g = GetConVar("swsrc_crosshaircolor_g")
	local cl_crosshaircolor_b = GetConVar("swsrc_crosshaircolor_b")

	local weapon_debug_spread_show = GetConVar("swsrc_debug_spread_show")
	local weapon_debug_spread_gap = GetConVar("swsrc_debug_spread_gap")

	local cl_legacy_crosshair_recoil = GetConVar("swsrc_legacy_crosshair_recoil")
	local cl_legacy_crosshair_scale = GetConVar("swsrc_legacy_crosshair_scale")

	local clean_scope = GetConVar("swsrc_clean_scope")

	local SWITCH_color = {
		[0] = {50, 250, 50},
		{250, 50,  50},
		{50,  50,  250},
		{250, 250, 50},
		{50,  250, 250},
	}

	local function DrawCrosshairRect(x0, y0, x1, y1, bAdditive)
		x1 = x1 - x0
		y1 = y1 - y0

		if bAdditive then
			surface.DrawTexturedRect(x0, y0, x1, y1)
		else
			surface.DrawRect(x0, y0, x1, y1)
		end
	end

	local m_iCrosshairTextureID = surface.GetTextureID("vgui/white_additive")
	local m_iScopeArcTexture = surface.GetTextureID("sprites/scope_arc")
	local m_iScopeDustTexture = surface.GetTextureID("overlays/scope_lens")

	function SWEP:DrawScope(x, y)
		local sw, sh = ScrW(), ScrH()

		local inset = sh / 16
		local ow = (sh / 2) - inset
		local y1 = y - ow
		local y2 = y + ow
		local x1 = x - ow
		local x2 = x + ow

		local uv1 = 0.5 / 256
		local uv2 = 1 - uv1

		local vert = {}

		local xMod = sw / 2
		local yMod = sh / 2

		local iMiddleX = x --sw / 2
		local iMiddleY = y --sh / 2

		if not clean_scope:GetBool() then
			surface.SetTexture(m_iScopeDustTexture)
			surface.SetDrawColor(255, 255, 255, 255)

			vert[1] = {x = iMiddleX + xMod, y = iMiddleY + yMod, u = uv2, v = uv1}
			vert[2] = {x = iMiddleX - xMod, y = iMiddleY + yMod, u = uv1, v = uv1}
			vert[3] = {x = iMiddleX - xMod, y = iMiddleY - yMod, u = uv1, v = uv2}
			vert[4] = {x = iMiddleX + xMod, y = iMiddleY - yMod, u = uv2, v = uv2}
			surface.DrawPoly(vert)
		end

		surface.SetDrawColor(0, 0, 0, 255)

		-- Draw the reticle with primitives
		surface.DrawLine(0, y, sw, y)
		surface.DrawLine(x, 0, x, sh)

		-- Draw the outline
		surface.SetTexture(m_iScopeArcTexture)

		-- bottom right
		vert[1] = {x = x, y = y, u = uv1, v = uv1}
		vert[2] = {x = x2, y = y, u = uv2, v = uv1}
		vert[3] = {x = x2, y = y2, u = uv2, v = uv2}
		vert[4] = {x = x, y = y2, u = uv1, v = uv2}
		surface.DrawPoly(vert)

		-- top right
		vert[1] = {x = x - 1, y = y1, u = uv1, v = uv2}
		vert[2] = {x = x2, y = y1, u = uv2, v = uv2}
		vert[3] = {x = x2, y = y + 1, u = uv2, v = uv1}
		vert[4] = {x = x - 1, y = y + 1, u = uv1, v = uv1}
		surface.DrawPoly(vert)

		-- bottom left
		vert[1] = {x = x1, y = y, u = uv2, v = uv1}
		vert[2] = {x = x, y = y, u = uv1, v = uv1}
		vert[3] = {x = x, y = y2, u = uv1, v = uv2}
		vert[4] = {x = x1, y = y2, u = uv2, v = uv2}
		surface.DrawPoly(vert)

		-- top left
		vert[1] = {x = x1, y = y1, u = uv2, v = uv2}
		vert[2] = {x = x, y = y1, u = uv1, v = uv2}
		vert[3] = {x = x, y = y, u = uv1, v = uv1}
		vert[4] = {x = x1, y = y, u = uv2, v = uv1}
		surface.DrawPoly(vert)

		surface.DrawRect(0, 0, sw, y1) -- top
		surface.DrawRect(0, y2, sw, sh) -- bottom
		surface.DrawRect(0, y1, x1, sh) -- left
		surface.DrawRect(x2, y1, sw, sh) -- right
	end

	SWEP.m_iAmmoLastCheck = 0
	function SWEP:DoDrawCrosshair(x, y)
		if not crosshair:GetBool() then return end

		local selfTable = self:GetTable()

		local owner = self:GetPlayerOwner()
		if not owner then return end

		assert(owner == LocalPlayer() or LocalPlayer():GetObserverMode() == OBS_MODE_IN_EYE)

		if owner:IsWorldClicking() then
			x, y = input.GetCursorPos()
		end

		local col = cl_crosshaircolor:GetInt()
		local r, g, b = unpack(SWITCH_color[col] or SWITCH_color[0])
		if col == 5 then
			r = cl_crosshaircolor_r:GetInt()
			g = cl_crosshaircolor_g:GetInt()
			b = cl_crosshaircolor_b:GetInt()
		end

		-- if user is using nightvision, make the crosshair red.
		--if nv then r,g,b = unpack(SWITCH_color[1]) end

		local bAdditive = cl_crosshairusealpha:GetBool() -- or nv
		local alpha = math.Clamp(cl_crosshairalpha:GetInt(), 0, 255)
		surface.SetDrawColor(r, g, b, alpha)

		if not bAdditive then
			surface.SetDrawColor(r, g, b, 200)
			surface.SetTexture(m_iCrosshairTextureID)
		end

		local wdat = selfTable.CSWpnData

		if wdat.m_WeaponType == WEAPONTYPE_SNIPER_RIFLE and math.floor(owner:GetFOV()) ~= owner:GetDefaultFOV() then
			selfTable.DrawScope(self, x, y)

			return true
		end

		local bCrosshairVisible = wdat.m_WeaponType ~= WEAPONTYPE_SNIPER_RIFLE
		if not bCrosshairVisible and not weapon_debug_spread_show:GetBool() then return true end

		local fHalfFov = math.rad(math.floor(owner:GetFOV())) * 0.5

		local m_flCrosshairDistance = 0
		local iCrosshairDistance = 0
		local iBarSize = math.floor(ScreenScaleH(cl_crosshairsize:GetFloat()))
		local iBarThickness = math.max(1, math.floor(ScreenScaleH(cl_crosshairthickness:GetFloat())))

		local dynamic = cl_dynamiccrosshair:GetInt()
		local mode = selfTable.GetWeaponMode(self)
		if dynamic == 0 then
			-- static crosshair
			local fSpread = (wdat.m_fSpread[mode] + wdat.m_fInaccuracyStand[mode]) * 320 / math.tan(fHalfFov)
			iCrosshairDistance = math.max(0, math.floor(ScreenScaleH(fSpread * cl_crosshairspreadscale:GetFloat())))
		elseif dynamic == 1 then
			local fSpread = (selfTable.GetInaccuracy(self) + selfTable.GetSpread(self)) * 320 / math.tan(fHalfFov)
			iCrosshairDistance = math.max(0, math.floor(ScreenScaleH(fSpread * cl_crosshairspreadscale:GetFloat())))
		elseif dynamic == 2 or dynamic == 3 then
			local fCrosshairDistanceGoal = wdat.m_iCrosshairMinDistance

			if dynamic == 2 then
				if not owner:IsOnGround() then
					fCrosshairDistanceGoal = fCrosshairDistanceGoal * 2
				elseif owner:IsDucking() then
					fCrosshairDistanceGoal = fCrosshairDistanceGoal * 0.5
				elseif owner:GetVelocity():Length() > 100 then
					fCrosshairDistanceGoal = fCrosshairDistanceGoal * 1.5
				end
			end

			local iDeltaDistance = wdat.m_iCrosshairDeltaDistance
			if selfTable.GetShotsFired(self) > selfTable.m_iAmmoLastCheck then
				fCrosshairDistanceGoal = fCrosshairDistanceGoal + iDeltaDistance
			end

			selfTable.m_iAmmoLastCheck = selfTable.GetShotsFired(self)

			if m_flCrosshairDistance > fCrosshairDistanceGoal then
				if not cl_legacy_crosshair_recoil:GetBool() then
					-- .44888 on the next line makes the decay very close to what old method produces at 100fps.
					m_flCrosshairDistance = Lerp(math.exp(-FrameTime() / 0.44888), fCrosshairDistanceGoal, m_flCrosshairDistance)
				else
					m_flCrosshairDistance = m_flCrosshairDistance - 0.1 + m_flCrosshairDistance * 0.013
				end
			end

			m_flCrosshairDistance = math.Clamp(m_flCrosshairDistance, fCrosshairDistanceGoal, 25)

			if cl_legacy_crosshair_scale:GetBool() then
				local crosshairScale = cl_crosshairscale:GetInt()
				if crosshairScale < 1 then
					local sh = ScrH()
					if sh <= 600 then
						crosshairScale = 600
					elseif sh <= 768 then
						crosshairScale = 768
					else
						crosshairScale = 1200
					end
				end

				local scale
				if not cl_scalecrosshair:GetBool() then
					scale = 1
				else
					scale = ScrH() / crosshairScale
				end

				iCrosshairDistance = math.floor(m_flCrosshairDistance * scale)

				iBarSize = ScreenScale(5)
				iBarSize = math.max(1, math.floor(iBarSize * scale))
				iBarThickness = math.max(1, math.floor(scale + 0.5))
			else
				iCrosshairDistance = math.floor(m_flCrosshairDistance * (ScrH() / 1200))
			end
		end

		if bCrosshairVisible then
			-- draw horizontal crosshair lines
			local iInnerLeft = x - iCrosshairDistance - iBarThickness / 2
			local iInnerRight = iInnerLeft + 2 * iCrosshairDistance + iBarThickness
			local iOuterLeft = iInnerLeft - iBarSize
			local iOuterRight = iInnerRight + iBarSize
			local y0 = y - iBarThickness / 2
			local y1 = y0 + iBarThickness
			DrawCrosshairRect(iOuterLeft, y0, iInnerLeft, y1, bAdditive)
			DrawCrosshairRect(iInnerRight, y0, iOuterRight, y1, bAdditive)

			-- draw vertiocal crosshair lines
			local iInnerTop = y - iCrosshairDistance - iBarThickness / 2
			local iInnerBottom = iInnerTop + 2 * iCrosshairDistance + iBarThickness
			local iOuterTop = iInnerTop - iBarSize
			local iOuterBottom = iInnerBottom + iBarSize
			local x0 = x - iBarThickness / 2
			local x1 = x0 + iBarThickness
			DrawCrosshairRect(x0, iOuterTop, x1, iInnerTop, bAdditive)
			DrawCrosshairRect(x0, iInnerBottom, x1, iOuterBottom, bAdditive)

			-- draw dot
			if cl_crosshairdot:GetBool() then
				local x0 = x - iBarThickness / 2
				local x1 = x0 + iBarThickness
				local y0 = y - iBarThickness / 2
				local y1 = y0 + iBarThickness
				DrawCrosshairRect(x0, y0, x1, y1, bAdditive)
			end
		end

		-- show accuracy brackets
		local spreadShow = weapon_debug_spread_show:GetInt()
		if spreadShow == 1 or spreadShow == 2 then
			if spreadShow == 2 then
				local punchAngles = owner:GetViewPunchAngles()
				local vecDirShooting = Vector()
				swsrc.AngleVectors(punchAngles, vecDirShooting)

				local iOffsetX = math.floor(ScreenScaleH(vecDirShooting.y * 320 / math.tan(fHalfFov)))
				local iOffsetY = math.floor(ScreenScaleH(vecDirShooting.z * 320 / math.tan(fHalfFov)))

				x = x - iOffsetX
				y = y - iOffsetY
			end

			r, g, b = unpack(SWITCH_color[3])
			surface.SetDrawColor(r, g, b, alpha)

			local iBarThickness = math.max(1, math.floor(ScreenScaleH(cl_crosshairthickness:GetFloat())))

			local fSpreadDistance = (selfTable.GetInaccuracy(self) + selfTable.GetSpread(self)) * 320 / math.tan(fHalfFov)
			local iSpreadDistance = math.floor(ScreenScaleH(fSpreadDistance))

			-- draw vertical spread lines
			local iInnerLeft = x - iSpreadDistance
			local iInnerRight = x + iSpreadDistance
			local iOuterLeft = iInnerLeft - iBarThickness
			local iOuterRight = iInnerRight + iBarThickness
			local iInnerTop = y - iSpreadDistance
			local iInnerBottom = y + iSpreadDistance
			local iOuterTop = iInnerTop - iBarThickness
			local iOuterBottom = iInnerBottom + iBarThickness

			local iGap = math.ceil(weapon_debug_spread_gap:GetFloat() * iSpreadDistance)

			-- draw horizontal lines
			DrawCrosshairRect(iOuterLeft, iOuterTop, x - iGap, iInnerTop, bAdditive)
			DrawCrosshairRect(x + iGap, iOuterTop, iOuterRight, iInnerTop, bAdditive)
			DrawCrosshairRect(iOuterLeft, iInnerBottom, x - iGap, iOuterBottom, bAdditive)
			DrawCrosshairRect(x + iGap, iInnerBottom, iOuterRight, iOuterBottom, bAdditive)

			-- draw vertical lines
			DrawCrosshairRect(iOuterLeft, iOuterTop, iInnerLeft, y - iGap, bAdditive)
			DrawCrosshairRect(iOuterLeft, y + iGap, iInnerLeft, iOuterBottom, bAdditive)
			DrawCrosshairRect(iInnerRight, iOuterTop, iOuterRight, y - iGap, bAdditive)
			DrawCrosshairRect(iInnerRight, y + iGap, iOuterRight, iOuterBottom, bAdditive)
		end

		return true
	end
end

do -- view bob
	local bob_enabled = GetConVar("swsrc_use_headbob")
	-- shared with swcs lol cope
	local cl_bobcycle = CreateConVar("cl_bobcycle", "0.98", FCVAR_ARCHIVE, "the frequency at which the viewmodel bobs.",
		0.1,
		2.0)
	local cl_bob = CreateConVar("cl_bob", "0.002")
	local cl_bobup = CreateConVar("cl_bobup", "0.5")

	function SWEP:CalcViewmodelBob()
		local lateralBob, verticalBob = 0, 0

		local bobtime, lastbobtime, lastspeed, cycle = 0, 0, 0, 0

		local owner = self:GetPlayerOwner()

		local _bobup = cl_bobup:GetFloat()
		local _bobcycle = cl_bobcycle:GetFloat()
		if not owner or _bobcycle <= 0 or _bobup <= 0 or _bobup >= 1 then return lateralBob, verticalBob end

		local speed = owner:GetVelocity():Length2D()
		local flmaxSpeedDelta = math.max(0, (CurTime() - lastbobtime) * 320)

		speed = math.Clamp(speed, lastspeed - flmaxSpeedDelta, lastspeed + flmaxSpeedDelta)
		speed = math.Clamp(speed, -320, 320)

		lastspeed = speed

		local bob_offset = math.Remap(speed, 0, 320, 0, 1)

		bobtime = bobtime + (CurTime() - lastbobtime) * bob_offset
		lastbobtime = CurTime()

		--
		cycle = lastbobtime - math.floor(bobtime / _bobcycle) * _bobcycle
		cycle = cycle / _bobcycle

		if cycle < _bobup then
			cycle = math.pi * cycle / _bobup
		else
			cycle = math.pi + math.pi * (cycle - _bobup) / (1 - _bobup)
		end

		verticalBob = speed * 0.005
		verticalBob = verticalBob * 0.3 + verticalBob * 0.7 * math.sin(cycle)

		verticalBob = math.Clamp(verticalBob, -7, 4)

		cycle = bobtime - math.floor(bobtime / _bobcycle * 2) * _bobcycle * 2
		cycle = cycle / _bobcycle * 2

		if cycle < _bobup then
			cycle = math.pi * cycle / _bobup
		else
			cycle = math.pi + math.pi * (cycle - _bobup) / (1 - _bobup)
		end

		lateralBob = speed * 0.005
		lateralBob = lateralBob * 0.3 + lateralBob * 0.7 * math.sin(cycle)
		lateralBob = math.Clamp(lateralBob, -7, 4)

		return lateralBob, verticalBob
	end

	local VectorMA
	do
		local VECTOR = FindMetaTable("Vector")
		---@diagnostic disable: need-check-nil
		local VUnpack = VECTOR.Unpack
		local VSetUnpacked = VECTOR.SetUnpacked
		---@diagnostic enable: need-check-nil

		VectorMA = function(start, scale, dir, dest)
			local startX, startY, startZ = VUnpack(start)
			local dirX, dirY, dirZ = VUnpack(dir)

			VSetUnpacked(dest,
				startX + scale * dirX,
				startY + scale * dirY,
				startZ + scale * dirZ
			)
		end
	end

	function SWEP:AddViewmodelBob(vm, pos, ang)
		local forward = ang:Forward()
		--local right = ang:Right()

		local lateralBob, verticalBob = self:CalcViewmodelBob()

		VectorMA(pos, verticalBob * 0.4, forward, pos)

		pos.z = pos.z + verticalBob * 0.1

		ang.r = ang.r + verticalBob * 0.5
		ang.p = ang.p - verticalBob * 0.4

		ang.y = ang.y - lateralBob * 0.3

		-- VectorMA(pos, lateralBob * 0.2, right, pos)
	end

	function SWEP:CalcViewModelView(vm, _, _, pos, ang)
		if bob_enabled:GetBool() then
			self:AddViewmodelBob(vm, pos, ang)
		end

		return pos, ang
	end
end

do -- weapon selection
	local function ScreenScaleHClamped(v)
		return v * (math.min(ScrH(), 1080) / 480)
	end

	local font_CSweapons = {
		font = system.IsLinux() and "cs.ttf" or "cs",
		size = ScreenScaleHClamped(70),
		weight = 0,
		additive = true,
		antialias = true,
	}
	surface.CreateFont("CSweapons", font_CSweapons)
	font_CSweapons.blursize = ScreenScaleH(4)
	font_CSweapons.scanlines = ScreenScaleH(2)
	surface.CreateFont("CSweapons_glow", font_CSweapons)

	function SWEP:RenderTextureData(key, x, y, w, h, col, glow, lower)
		if glow == nil then glow = false end
		if lower == nil then lower = false end

		local iconDataKV = self.CSWpnData.TextureData[key]
		if not iconDataKV then return end

		local name = iconDataKV.szShortName
		local File = iconDataKV.szTextureFile
		if File and #File > 0 then
			if iconDataKV.bRenderedUsingFont then
				local character = iconDataKV.cCharacterInFont
				if lower then
					character = character:lower()
				end

				surface.SetFont(File)
				local cw, ch = surface.GetTextSize(character)
				local cx, cy = x + ((w / 2) - (cw / 2)), y + ((h / 2) - (ch / 2))
				surface.SetTextPos(cx, cy)
				surface.SetTextColor(col:Unpack())

				if glow then
					surface.SetFont(File .. "_glow")
					surface.DrawText(character)

					surface.SetFont(File)
					surface.SetTextPos(cx, cy)
				end

				surface.DrawText(character)
			else
				local material = Material(Format("%s.vmt", File))
				if not material or material:IsError() then
					--print(Format("Failed to load material for icon %s from file %s", name, File))
					return
				end

				local iconX, iconY = iconDataKV.rc.left, iconDataKV.rc.top
				local iconW, iconH = iconDataKV.rc.right, iconDataKV.rc.bottom

				local matW, matH = material:Width(), material:Height()
				local su, sv = iconX / matW, iconY / matH
				local eu, ev = (iconX + iconW) / matW, (iconY + iconH) / matH

				surface.SetDrawColor(col:Unpack())
				surface.SetMaterial(material)
				surface.DrawTexturedRectUV(x, y, w, h, su, sv, eu, ev)
			end
		else
			print(Format("No valid file or font specified for icon %s", name))
		end
	end

	SWEP.SelectionColor = Color(255, 220, 0, 255)
	local path = "resource/clientscheme.res"
	if not file.Exists(path, "MOD") then
		path = "resource/ClientScheme.res"
	end
	if file.Exists(path, "MOD") then
		local kv = swsrc.KeyValuesHelper(file.Read(path, "MOD"))
		if kv then
			local BaseSettings = kv:FindKey("basesettings")
			if BaseSettings then
				SWEP.SelectionColor = string.ToColor(BaseSettings:GetString("brightfg", "255 220 0 255"))
			end
		end
	end

	function SWEP:DrawWeaponSelection(x, y, w, h, a)
		self.SelectionColor.a = a
		self:RenderTextureData("weapon_s", x, y, w, h, self.SelectionColor, true, true)
	end
end
