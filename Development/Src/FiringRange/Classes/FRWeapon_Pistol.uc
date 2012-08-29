/**
 *
 * Notes: 
 *
*/

class FRWeapon_Pistol extends FRWeapon;

defaultproperties
{
	// mesh settings
	ArmViewOffset = (X=43.0)
	IronsightViewOffset = (X=47.0)
	AimingMeshFOV = 45.0f
	
	// firearm
	FirearmClass = class'FRFirearm_Pistol'
	
	// ammunition
	MagAmmo = 15
	MaxMagAmmo = 15
	AmmoCount = 99
	MaxAmmoCount = 99
	
	// ironsight
	AimingFOV = 80.0f
	
	// muzzle flash
	MuzzleFlashClass = class'FRMuzzleFlash_Pistol'
	
	// fire modes
	AllowedFireModes(0) = 1
	AllowedFireModes(1) = 0
	AllowedFireModes(2) = 0

	WeaponFireMode = 0
}