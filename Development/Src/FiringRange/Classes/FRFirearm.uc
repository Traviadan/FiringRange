/**
 *
 * Notes: 
 *
*/

class FRFirearm extends Actor
	notplaceable
	abstract;

/** firearm skeletal mesh */
var SkeletalMeshComponent Mesh;

/** arms socket for firearm */
var SkeletalMeshSocket Socket;

/** attach firearm to arms */
simulated function AttachTo(FRWeapon Arms, FRPawn FRP)
{
	local SkeletalMeshComponent SkelMesh;
	
		if((Arms.Mesh != none) && Arms.Mesh.bAttached)
		{
			SkelMesh = SkeletalMeshComponent(Arms.Mesh);
			
				if(SkelMesh != none)
				{
					SetOwner(Arms);
					SetHardAttach(true);
					SetBase(Arms, , SkeletalMeshComponent(Arms.Mesh), Arms.WeaponSocket);
					Socket = SkelMesh.GetSocketByName(Arms.WeaponSocket);
					SetRelativeLocation(Socket.RelativeLocation * SkelMesh.Scale);
					SetRelativeRotation(Socket.RelativeRotation);
				}
		}
}

/** detach firearm from arms */
simulated function DetachFrom()
{
	SetOwner(none);
	SetHardAttach(false);
	SetBase(none);
	Socket = none;
	SetHidden(true);
	Destroy();
}

/** change visibility */
simulated function ChangeVisibility(bool bIsVisible)
{
	SetHidden(bIsVisible);
	
		if(Mesh != none)
		{
			Mesh.SetHidden(bIsVisible);
		}
}

defaultproperties
{
	// anim sequence
	begin object class=AnimNodeSequence name=MeshSequenceA
		bCauseActorAnimEnd = true
	end object
	
	// mesh
	begin object class=UDKSkeletalMeshComponent name=FirearmMesh
		DepthPriorityGroup = SDPG_Foreground
		Animations = MeshSequenceA
		bOnlyOwnerSee = true
		bOverrideAttachmentOwnerVisibility = true
		bUpdateSkelWhenNotRendered = true
		bAllowAmbientOcclusion = false
		FOV = 60.0f
		CastShadow = false
		bCastDynamicShadow = false
		bAcceptsDynamicDecals = false
		bPerBoneMotionBlur = true
	end object
	Mesh = FirearmMesh
	Components.Add(FirearmMesh)
	
	bStatic = false
	bCollideActors = false
	bBlockActors = false
	bWorldGeometry = false
	bCollideWorld = false
	bNoEncroachCheck = true
	bNoDelete = false
	
}
