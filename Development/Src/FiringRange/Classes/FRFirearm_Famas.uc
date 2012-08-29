/**
 *
 * Notes: 
 *
*/

class FRFirearm_Famas extends FRFirearm;

defaultproperties
{
	// firearm mesh
	begin object name=FirearmMesh
		SkeletalMesh = SkeletalMesh'Tutorials.Mesh.1p_Famas'
		AnimSets(0) = AnimSet'Tutorials.Anims.Weapon_Pistol_Anims'
	end object
	
}