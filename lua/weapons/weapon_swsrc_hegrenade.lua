AddCSLuaFile()

SWEP.Base = "weapon_swsrc_basegrenade"
DEFINE_BASECLASS(SWEP.Base)

SWEP.Category = "#spawnmenu.category.swsrc"
SWEP.SubCategory = "#spawnmenu.category.swsrc_grenades"

SWEP.PrintName = "HE Grenade"
SWEP.Spawnable = true
SWEP.HoldType = "grenade"
SWEP.WorldModel = "models/weapons/w_eq_fraggrenade.mdl"
SWEP.ViewModel = "models/weapons/cstrike/c_eq_fraggrenade.mdl"

--SWEP.Primary.DefaultClip = 5
--SWEP.Primary.ClipSize = -1

SWEP.WeaponData = [=[WeaponData
{
	"MaxPlayerSpeed"		"250"
	"WeaponType"			"Grenade"
	"WeaponPrice"			"300"
	"WeaponArmorRatio"		"1.475"
	"CrosshairMinDistance"		"8"
	"CrosshairDeltaDistance"	"3"
	"Team"				"ANY"
	"BuiltRightHanded"		"0"
	"PlayerAnimationExtension" 	"gren"
	"MuzzleFlashScale"		"0"
	"MuzzleFlashStyle"		"CS_MUZZLEFLASH_NONE"
	"CanEquipWithShield"		"1"
	"AddonModel"			"models/weapons/w_eq_fraggrenade_thrown.mdl"

	// Weapon characteristics:
	"Penetration"			"1"
	"Damage"			"50"
	"Range"				"4096"
	"RangeModifier"			"0.99"
	"Bullets"			"1"
	
	// Weapon data is loaded by both the Game and Client DLLs.
	"printname"			"#Cstrike_WPNHUD_HE_Grenade"
	"viewmodel"			"models/weapons/v_eq_fraggrenade.mdl"
	"playermodel"			"models/weapons/w_eq_fraggrenade.mdl"
	
	"anim_prefix"			"anim"
	"bucket"			"3"
	"bucket_position"		"1"

	"clip_size"			"-1"
	"default_clip"			"5"
	"primary_ammo"			"swsrc_hegrenade"
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
				"character"	"h" //"H"
		}
		"weapon_s"
		{	
				"font"		"CSweapons"
				"character"	"h" //"H"
		}
		"ammo"
		{
				"font"		"CSTypeDeath"
				"character"		"O"
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
			Maxs	"2 6 1"
		}
		Addon
		{
			Mins	"-3 -2 -2"
			Maxs	"2 3 5"
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
    return WEAPON_HEGRENADE
end

function SWEP:EmitGrenade(tbl)
	return ents.Create("swsrc_hegrenade_projectile")
end