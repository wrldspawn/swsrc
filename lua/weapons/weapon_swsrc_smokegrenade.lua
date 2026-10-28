AddCSLuaFile()

SWEP.Base = "weapon_swsrc_basegrenade"
DEFINE_BASECLASS(SWEP.Base)

SWEP.Category = "#spawnmenu.category.swsrc"
SWEP.SubCategory = "#spawnmenu.category.swsrc_grenades"

SWEP.PrintName = "Smoke Grenade"
SWEP.Spawnable = true
SWEP.HoldType = "grenade"
SWEP.WorldModel = "models/weapons/w_eq_smokegrenade.mdl"
SWEP.ViewModel = "models/weapons/cstrike/c_eq_smokegrenade.mdl"

--SWEP.Primary.DefaultClip = 5
--SWEP.Primary.ClipSize = -1

SWEP.WeaponData = [=[WeaponData
{
	"MaxPlayerSpeed"		245
	"WeaponType"			"Grenade"
	"WeaponPrice"			"300"
	"WeaponArmorRatio"		"1.0"
	"CrosshairMinDistance"		"4"
	"CrosshairDeltaDistance"	"3"
	"Team"				"ANY"
	"BuiltRightHanded" 		"0"
	"PlayerAnimationExtension"	"gren"
	"MuzzleFlashScale"		"1"
	"MuzzleFlashStyle"		"CS_MUZZLEFLASH_NONE"
	"CanEquipWithShield" 		"1"
	"AddonModel"			"models/weapons/w_eq_smokegrenade_thrown.mdl"
		
	// Weapon characteristics:
	"Penetration"			"0"
	"Damage"			"50"
	"Range"				"4096"
	"RangeModifier"			"0.99"
	"Bullets"			"1"
	
	// Weapon data is loaded by both the Game and Client DLLs.
	"printname"			"#Cstrike_WPNHUD_Smoke_Grenade"
	"viewmodel"			"models/weapons/v_eq_smokegrenade.mdl"
	"playermodel"			"models/weapons/w_eq_smokegrenade.mdl"
	
	"anim_prefix"			"anim"
	"bucket"			"3"
	"bucket_position"		"3"

	"clip_size"			"-1"
	"default_clip"			"1"
	"primary_ammo"			"swsrc_smokegrenade"
	"secondary_ammo"		"None"

	"weight"			"2"
	"ITEM_FLAG_EXHAUSTIBLE"		"1"
	//"ITEM_FLAG_NOAMMOPICKUPS"	"1"

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
				"character"	"p"
		}
		"weapon_s"
		{	
				"font"		"CSweapons"
				"character"	"p"
		}
		"ammo"
		{
				"font"		"CSTypeDeath"
				"character"		"Q"
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
			Mins	"-6 -9 -15"
			Maxs	"15 11 0"
		}
		World
		{
			Mins	"-4 -1 -3"
			Maxs	"3 6 1"
		}
		Addon
		{
			Mins	"-3 -2 -3"
			Maxs	"2 2 4"
		}
	}
}]=]

function SWEP:OverrideData(tbl)
	-- TODO: cvar for cs:s slots?
	tbl.Slot = 4
    tbl.DefaultClip = 100
    tbl.ClipSize = 100
end

function SWEP:GetWeaponID()
    return WEAPON_SMOKEGRENADE
end

function SWEP:EmitGrenade(tbl)
	return ents.Create("swsrc_smokegrenade_projectile")
end