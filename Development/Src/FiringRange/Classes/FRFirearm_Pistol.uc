/**
 *
 * Notes: 
 *
*/

class FRFirearm_Pistol extends FRFirearm;

defaultproperties
{
	// firearm mesh
	begin object name=FirearmMesh
		SkeletalMesh = SkeletalMesh'Tutorials.Mesh.Weapon_Pistol'
		AnimSets(0) = AnimSet'Tutorials.Anims.Weapon_Pistol_Anims'
	end object
	
}