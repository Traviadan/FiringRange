/**
 *
 * Notes: 
 *
*/

class FRPawn extends UDKPawn
	config(Game)
	placeable;


// ---------------------- MOVEMENT
/** crouch eye height */
var float CrouchEyeHeight;

// ---------------------- INVENTORY
/** default inventory */
var array< class<Inventory> > DefaultInventory;

// ---------------------- WEAPON
/** weapon attachment class */
var repnotify class<FRWeaponAttachment> WeaponAttachmentClass;
/** weapon attachment */
var FRWeaponAttachment WeaponAttachment;

/** replication */
replication
{
	if(bNetDirty)
		WeaponAttachmentClass;
}

/** replicated event */
simulated event ReplicatedEvent(name VarName)
{
		if(VarName == 'WeaponAttachmentClass')
		{
			AttachWeapon();
			return;
		}
		else
		{
			super.ReplicatedEvent(VarName);
		}
}

/** replicated: weapon attachment changed */
simulated function AttachWeapon()
{
		// weapon attachment is new or been destroyed
		if(WeaponAttachment == none || WeaponAttachment.Class != WeaponAttachmentClass)
		{
				// detach current attachment if it exists
				if(WeaponAttachment != none)
				{
					WeaponAttachment.DetachFrom(Mesh);
					WeaponAttachment.Destroy();
				}
				
				// spawn weapon attachment
				if(WeaponAttachmentClass != none)
				{
					WeaponAttachment = Spawn(WeaponAttachmentClass, self);
					WeaponAttachment.Instigator = self;
				}
				else
				{
					// destroy weapon attachment
					WeaponAttachment = none;
				}
				
				// attach weapon attachment
				if(WeaponAttachment != none)
				{
					WeaponAttachment.AttachTo(self);
					WeaponAttachment.ChangeVisibility(false);
				}
		}
}

/** overloaded: play dying */
simulated function PlayDying(class<DamageType> DamageType, vector HitLocation)
{
	// destroy weapon attachment
	WeaponAttachmentClass = none;
	AttachWeapon();
	
	super.PlayDying(DamageType, HitLocation);
}

/** overloaded: weapon fired */
simulated function WeaponFired(Weapon InWeapon, bool bViaReplication, optional vector HitLocation)
{
	super.WeaponFired(InWeapon, bViaReplication, HitLocation);
	
		// play impact effects
		if(WeaponAttachment != none)
		{
				if(HitLocation != vect(0,0,0) && (WorldInfo.NetMode == NM_ListenServer 
					|| WorldInfo.NetMode == NM_Standalone || bViaReplication))
				{
					//PlayImpactEffects(HitLocation);
					WeaponAttachment.PlayImpactEffects(HitLocation);
				}
		}
}

/** overloaded: process view rotation */
simulated function ProcessViewRotation(float DeltaTime, out rotator out_ViewRotation, 
	out rotator out_DeltaRot)
{
		if(Weapon != none)
		{
			FRWeapon(Weapon).ProcessViewRotation(DeltaTime, out_ViewRotation, out_DeltaRot);
		}
	
	out_ViewRotation += out_DeltaRot;
	out_DeltaRot = rot(0,0,0);
	
		if(PlayerController(Controller) != none)
		{
			out_ViewRotation = PlayerController(Controller).LimitViewRotation(out_ViewRotation, 
				ViewPitchMin, ViewPitchMax);
		}
}

/** overwritten: calculate camera */
simulated function bool CalcCamera(float DeltaTime, out vector out_CamLoc, 
	out rotator out_CamRot, out float out_FOV)
{
	GetActorEyesViewPoint(out_CamLoc, out_CamRot);
	return true;
}

/** set movement physics */
function SetMovementPhysics()
{
		if(PhysicsVolume.bWaterVolume)
		{
			SetPhysics(PHYS_Swimming);
		}
		else
		{
				if(Physics != PHYS_Falling)
				{
					SetPhysics(PHYS_Falling);
				}
		}
}

/** overloaded: start crouch */
simulated event StartCrouch(float HeightAdjust)
{
	SetBaseEyeHeight();
	EyeHeight += HeightAdjust;
	CrouchMeshZOffset = HeightAdjust;
	
		if(Mesh != none)
		{
			Mesh.SetTranslation(Mesh.Translation + vect(0,0,1) * HeightAdjust);
		}
}

/** overloaded: end crouch */
simulated event EndCrouch(float HeightAdjust)
{
	SetBaseEyeHeight();
	EyeHeight -= HeightAdjust;
	CrouchMeshZOffset = 0.0;
	
		if(Mesh != none)
		{
			Mesh.SetTranslation(Mesh.Translation - vect(0,0,1) * HeightAdjust);
		}
}

/** overloaded: force crouch height */
simulated function SetBaseEyeHeight()
{
		if(!bIsCrouched)
		{
			BaseEyeHeight = default.BaseEyeHeight;
		}
		else
		{
			BaseEyeHeight = CrouchEyeHeight;
		}
}

/** overloaded: interpolate eye height */
event UpdateEyeHeight(float DeltaTime)
{
		if(bTearOff)
		{
			EyeHeight = default.BaseEyeHeight;
			bUpdateEyeHeight = false;
			return;
		}
	
	EyeHeight = FInterpTo(EyeHeight, BaseEyeHeight, DeltaTime, 10.0);
}

/** overloaded: get pawn view location */
simulated event vector GetPawnViewLocation()
{
		if(bUpdateEyeHeight)
		{
			return Location + EyeHeight * vect(0,0,1);
		}
		else
		{
			return Location + BaseEyeHeight * vect(0,0,1);
		}
}

/** overloaded: become view target and begin eye height interp */
simulated event BecomeViewTarget(PlayerController PC)
{
	super.BecomeViewTarget(PC);
	
		if(LocalPlayer(PC.Player) != none)
		{
			bUpdateEyeHeight = true;
		}
}

/** add default inventory */
function AddDefaultInventory()
{
	local class<Inventory> InvClass;
	local Inventory Inv;
	
		foreach DefaultInventory(InvClass)
		{
			Inv = FindInventoryType(InvClass);
			
				if(Inv == none)
				{
					CreateInventory(InvClass, Weapon != none);
				}
		}
}

/** current eye height */
simulated function float GetEyeHeight()
{
		if(!IsLocallyControlled())
		{
			return BaseEyeHeight;
		}
		else
		{
			return EyeHeight;
		}
}

defaultproperties
{
	InventoryManagerClass = class'FiringRange.FRInventoryManager'
	ControllerClass = none
	
	// mesh
	begin object class=SkeletalMeshComponent name=SkelMesh
		TickGroup = TG_PreAsyncWork
		BlockZeroExtent = true
		CollideActors = true
		BlockRigidBody = true
		RBChannel = RBCC_Pawn
		RBCollideWithChannels = (Default=true,Pawn=true,DeadPawn=false,BlockingVolume=true,EffectPhysics=true,FracturedMeshPart=true,SoftBody=true)
		MinDistFactorForKinematicUpdate = 0.2
		bAcceptsStaticDecals = false
		bAcceptsDynamicDecals = false
		bUpdateSkelWhenNotRendered = true
		bIgnoreControllersWhenNotRendered = true
		bTickAnimNodesWhenNotRendered = true
		bUseOnePassLightingOnTranslucency = true
		bPerBoneMotionBlur = true
		bHasPhysicsAssetInstance = true
		bOwnerNoSee = true
		bUpdateKinematicBonesFromAnimation = true
	end object
	Mesh = SkelMesh
	Components.Add(SkelMesh)
	
	// collision cylinder
	begin object name=CollisionCylinder
		CollisionHeight = +0044.000000
		CollisionRadius = +0021.000000
		BlockZeroExtent = false
	end object
	CylinderComponent = CollisionCylinder
	
	AlwaysRelevantDistanceSquared = +1960000.0
	
	// movement
	GroundSpeed = 440.0
	WalkingPct = 0.4
	CrouchedPct = 0.4
	JumpZ = 322.0
	AccelRate = 2048.0
	
	// pawn settings
	CrouchHeight = +0029.000000
	CrouchRadius = +0034.000000
	EyeHeight = +0038.000000
	CrouchEyeHeight = +0023.000000
	BaseEyeHeight = +0038.000000
	
	// settings
	bBlocksNavigation = true
	bNoEncroachCheck = true
	bCanStepUpOn = false
	bCanStrafe = true
	bCanCrouch = true
	bCanClimbLadders = true
	bCanPickupInventory = true
	bCanWalkOffLedges = true
	bCanSwim = true
	
	// camera
	ViewPitchMin = -16000
	ViewPitchMax = 14000
	
	// default inventory
	DefaultInventory(0) = class'FiringRange.FRWeapon_Pistol'
	DefaultInventory(1) = class'FiringRange.FRWeapon_Famas'

}