/**
 *
 * Notes: 
 *
*/

class FRWeapon_Famas extends FRWeapon;

defaultproperties
{
	// mesh settings
	ArmViewOffset = (X=43.0)
	IronsightViewOffset = (X=47.0)
	AimingMeshFOV = 45.0f
	
	// firearm
	FirearmClass = class'FRFirearm_Famas'
	
	// ammunition
	MagAmmo = 30
	MaxMagAmmo = 30
	AmmoCount = 120
	MaxAmmoCount = 120
	
	// ironsight
	AimingFOV = 80.0f
	
	// muzzle flash
	MuzzleFlashClass = class'FRMuzzleFlash_Famas'

	// fire modes
	AllowedFireModes(0) = 1 // semi-auto
	AllowedFireModes(1) = 1 // burst
	AllowedFireModes(2) = 1 // auto

	WeaponFireMode = 2 // set to auto as default fire mode
	BurstCount = 3 // for a 3 round burst

	// ---------------------- SOUNDS
	/*
	FireSound = SoundCue'Tutorials.Sounds.Pistol_Fire_Cue'
	EquipSound = SoundCue'Tutorials.Sounds.Pistol_Equip_Cue'
	UnequipSound = SoundCue'Tutorials.Sounds.Pistol_Unequip_Cue'
	FireEmptySound = SoundCue'Tutorials.Sounds.Pistol_FireEmpty_Cue'
	*/
}