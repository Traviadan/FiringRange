/**
 *
 * Notes: 
 *
*/

class FRWeapon extends UDKWeapon
	dependson(FRPlayerController)
	config(Weapon)
	abstract;

// ---------------------- MESH
/** arms mesh view offset */
var() vector ArmViewOffset;
/** arms view offset during ironsight */
var() vector IronsightViewOffset;
/** aiming mesh FOV */
var() float AimingMeshFOV;
/** default mesh FOV */
var() float DefaultMeshFOV;
/** private: current mesh fov */
var float CurrentMeshFOV;
/** private: mesh desired fov */
var float DesiredMeshFOV;

// ---------------------- ANIMATIONS
/** arm idle animations */
var(Animations) array<name> ArmIdleAnims;
/** arm equip animation */
var(Animations) name ArmEquipAnim;
/** arm fire animation */
var(Animations) name ArmFireAnim;
/** arm reload animation */
var(Animations) name ArmReloadAnim;
/** arm to aim animation */
var(Animations) name ArmAimAnim;
/** arm aim idle animation */
var(Animations) name ArmAimIdleAnim;
/** arm aim fire animation */
var(Animations) name ArmAimFireAnim;
/** arm unequip animation */
var(Animations) name ArmUnequipAnim;
/** arm moving animation */
var(Animations) name ArmMovingAnim;

// ---------------------- ANIMATION RATES
/** arm idle anim rate */
var float ArmIdleAnimRate;
/** arm equip anim rate */
var float ArmEquipAnimRate;
/** arm fire anim rate */
var float ArmFireAnimRate;
/** arm reload anim rate */
var float ArmReloadAnimRate;
/** arm to aim anim rate */
var float ArmAimAnimRate;
/** arm aim idle anim rate */
var float ArmAimIdleAnimRate;
/** arm aim fire anim rate */
var float ArmAimFireAnimRate;
/** arm unequip anim rate */
var float ArmUnequipAnimRate;
/** arm moving anim rate */
var float ArmMovingAnimRate;

// ---------------------- SOCKETS
/** firearm socket */
var(Sockets) name WeaponSocket;

// ---------------------- FIREARM
/** firearm class */
var(Firearm) class<FRFirearm> FirearmClass;
/** firearm */
var(Firearm) FRFirearm Firearm;

// ---------------------- AMMUNITION
/** magazine ammunition */
var(Ammo) int MagAmmo;
/** maximum magazine ammunition */
var(Ammo) int MaxMagAmmo;
/** maximum ammo storage */
var(Ammo) int MaxAmmoCount;
/** shot cost */
var(Ammo) array<int> ShotCost;

// ---------------------- IRONSIGHT
/** is aiming */
var bool bIsAiming;
/** aiming FOV */
var() float AimingFOV;
/** aiming delay */
var bool bAimingDelay;

// ---------------------- RECOIL
/** recoil */
var(Recoil) float Recoil;
/** max recoil */
var(Recoil) float MaxRecoil;
/** aiming recoil */
var(Recoil) float AimRecoil;
/** recoil offset to use */
var rotator RecoilOffset;
/** recoil interp speed */
var(Recoil) float RecoilInterpSpeed;
/** recoil decline offset to use */
var rotator RecoilDecline;
/** recoil decline percentage */
var(Recoil) float RecoilDeclinePct;
/** recoil decline speed */
var(Recoil) float RecoilDeclineSpeed;
/** total recoil cached */
var rotator TotalRecoil;

// ---------------------- MUZZLE FLASH
/** muzzle flash class */
var class<FRMuzzleFlash> MuzzleFlashClass;
/** muzzle flash */
var FRMuzzleFlash MuzzleFlash;

// ---------------------- WEAPON ATTACHMENT
/** attachment */
var class<FRWeaponAttachment> AttachmentClass;

// ---------------------- SOUNDS
/** firing sound */
var SoundCue FireSound;
/** equip sound */
var SoundCue EquipSound;
/** unequip sound */
var SoundCue UnequipSound;
/** empty fire sound */
var SoundCue FireEmptySound;

// ---------------------- FIRING MODES
/** firing modes */
var(Ammo) byte AllowedFireModes[3];
var(Ammo) byte WeaponFireMode;
var(Ammo) int WeaponShotCount;
var(Ammo) int BurstCount;

/** replication */
replication
{
	if(bNetOwner)
		MagAmmo;
}

/** overloaded: consume ammunition */
function ConsumeAmmo(byte FireModeNum)
{
	AddMagAmmo(-ShotCost[FireModeNum]);
}

/** add/remove magazine ammunition */
simulated function int AddMagAmmo(int Amount)
{
	MagAmmo = Clamp(MagAmmo + Amount, 0, MaxMagAmmo);
		if(MagAmmo < 0) MagAmmo = 0;
	
	return MagAmmo;
}

/** add/remove ammunition storage */
simulated function int AddStorageAmmo(int Amount)
{
	AmmoCount = Clamp(AmmoCount + Amount, 0, MaxAmmoCount);
		if(AmmoCount < 0) AmmoCount = 0;
	
	return AmmoCount;
}
 
/** overloaded: has any ammunition */
//@notes: called by GetWeaponRating and Active.BeginState
simulated function bool HasAnyAmmo()
{
	return (AmmoCount > 0 || MagAmmo > 0);
}

/** overloaded: has ammo */
//@notes: called by ShouldRefire and Active.BeginFire
simulated function bool HasAmmo(byte FireModeNum, optional int Amount)
{
		if(Amount == 0) return (MagAmmo >= ShotCost[FireModeNum]);
	
	return (MagAmmo >= Amount);
}

/** weapon has magazine ammunition */
simulated function bool HasMagazineAmmo()
{
	return (MagAmmo > 0);
}

/** weapon has storage ammunition */
simulated function bool HasStorageAmmo()
{
	return (AmmoCount > 0);
}

/** ammunition storage is maxed out */
simulated function bool AmmoMaxed()
{
	return (AmmoCount >= MaxAmmoCount);
}

/** magazine is maxed out */
simulated function bool IsMagFull()
{
	return (MagAmmo >= MaxMagAmmo);
}

/** overloaded: should refire */
simulated function bool ShouldRefire()
{
		if(!HasMagazineAmmo())
		{
			WeaponShotCount = 0;
			StopFire(CurrentFireMode);
			return false;
		}

		if(WeaponFireMode == 0)
		{
			StopFire(CurrentFireMode);
			return false;
		}
		else if(WeaponFireMode == 1)
		{
			WeaponShotCount++;

				if(WeaponShotCount < BurstCount)
				{
					return true;
				}
				else
				{
					StopFire(CurrentFireMode);
					WeaponShotCount = 0;
					return false;
				}
		}
		else if(WeaponFireMode == 2)
		{
			return StillFiring(CurrentFireMode);
		}

	StopFire(CurrentFireMode);
	WeaponShotCount = 0;
	return false;
}


/** overloaded: attach mesh */
simulated function AttachWeaponTo(SkeletalMeshComponent SkelMesh, optional name SocketName)
{
	local FRPawn P;
	
	super.AttachWeaponTo(SkelMesh, SocketName);
		
		if((Mesh != none) && !Mesh.bAttached)
		{
			AttachComponent(Mesh);
			AttachFirearm();
			SetHidden(false);
		}
		
		if(Instigator != none)
		{
			P = FRPawn(Instigator);
			
				if(Role == ROLE_Authority)
				{
						if(P.WeaponAttachmentClass != AttachmentClass)
						{
							P.WeaponAttachmentClass = AttachmentClass;
								if(WorldInfo.NetMode == NM_ListenServer || WorldInfo.NetMode == NM_Standalone 
									|| (WorldInfo.NetMode == NM_Client && Instigator.IsLocallyControlled()))
								{
									P.AttachWeapon();
								}
						}
				}
		}
}

/** attach firearm to arms */
simulated function AttachFirearm()
{
	local FRPawn P;
	
		if(Instigator != none)
		{
			P = FRPawn(Instigator);
			
				if(FirearmClass != none)
				{
					Firearm = Spawn(FirearmClass, self);
					
						if(Firearm != none)
						{
							Firearm.AttachTo(self, P);
							Firearm.ChangeVisibility(false);
						}
				}
		}
}

/** overloaded: detach arms */
simulated function DetachWeapon()
{
	local FRPawn P;
	
	super.DetachWeapon();
	
		if((Mesh != none) && Mesh.bAttached)
		{
			DetachFirearm();
			DetachComponent(Mesh);
		}
	
		if(Instigator != none)
		{
			P = FRPawn(Instigator);
			
				if(Role == ROLE_Authority && P.WeaponAttachmentClass == AttachmentClass)
				{
					P.WeaponAttachmentClass = none;
						if(Instigator.IsLocallyControlled())
						{
							P.AttachWeapon();
						}
				}
		}
	
	SetBase(none);
	SetHidden(true);
}

/** detach firearm from arms */
simulated function DetachFirearm()
{
		if(Firearm != none)
		{
				if(MuzzleFlash != none)
				{
					MuzzleFlash.DetachFrom(Firearm);
					MuzzleFlash = none;
				}
			
			Firearm.DetachFrom();
		}
}

/** overloaded: align the arm mesh player view */
simulated event SetPosition(UDKPawn Holder)
{
	local vector ViewOffset, DrawOffset;
	local rotator NewRotation;
	
		// if we're not in first person just return
		if(!Holder.IsFirstPerson()) return;
	
	// set view offset based on our arm view offset
	ViewOffset = ArmViewOffset;
	
	// calculate location and rotation
	DrawOffset.Z = FRPawn(Holder).GetEyeHeight();
	DrawOffset = DrawOffset + (ViewOffset >> Holder.Controller.Rotation);
	DrawOffset = Holder.Location + DrawOffset;
	
		if(Holder.Controller == none)
		{
			NewRotation = Holder.GetBaseAimRotation();
		}
		else
		{
			NewRotation = Holder.Controller.Rotation;
		}
	
	// set location/rotation/base
	SetLocation(DrawOffset);
	SetRotation(NewRotation);
	SetBase(Holder);
}

/** reload weapon */
simulated function ReloadWeapon()
{
		// weapon is inactive or already reloading so return
		if(IsInState('Inactive') || IsInState('WeaponReloading'))
		{
			return;
		}
		
		// if we are client replicate to the server
		if(Role < ROLE_Authority)
		{
			ServerReloadWeapon();
		}
		
		// clear idle anim timer if active
		if(IsTimerActive('PlayIdleAnimation'))
		{
			ClearTimer('PlayIdleAnimation');
		}
		
		// if we can reload
		if(CanReload())
		{
				// clear weapon raising if active
				if(IsTimerActive('TimeWeaponRaising')) ClearTimer('TimeWeaponRaising');
				
				// clear weapon lowering if active
				if(IsTimerActive('TimeWeaponLowering')) ClearTimer('TimeWeaponLowering');
			
				// playing fire anim so wait until the animation has finished
				// exit and come back to this function so below logic is performed at the right time
				if(IsPlayingAnim(ArmFireAnim))
				{
					SetTimer(GetAnimTimeLeft() + 0.01, false, 'ReloadWeapon');
					return;
				}
			
				// currently aiming so lower weapon before reloading
				if(bIsAiming)
				{
					TimeWeaponLowering();
				}
				
				// playing aim animation so wait until the animation has finished
				if(IsPlayingAnim(ArmAimAnim))
				{
					SetTimer(GetAnimTimeLeft() + 0.01, false, 'TimeReload');
				}
				else
				{
					// safe to continue
					TimeReload();
				}
		}
}

/** timer: delayed time reloading */
simulated function TimeReload()
{
	GotoState('WeaponReloading');
}

/** client to server: reload weapon */
reliable server function ServerReloadWeapon()
{
	ReloadWeapon();
}

/** can the weapon reload */
simulated function bool CanReload()
{
		// check if we have storage ammo and our mag isn't already full
		if(HasStorageAmmo() && !IsMagFull())
		{
			// can add further checks such as jumping or sprinting
			return true;
		}
		
	return false;
}

/** toggle aiming variance */
simulated function ToggleAim()
{
		if(bIsAiming)
		{
			LowerWeapon();
		}
		else
		{
			RaiseWeapon();
		}
}

/** ironsight aiming: raise weapon */
simulated function RaiseWeapon()
{

		// if inactive then just exit
		if(IsInState('Inactive'))
		{
			return;
		}
		
		// if reloading at all then delay aiming and exit
		if(IsInState('WeaponReloading') || IsTimerActive('ReloadWeapon') || IsTimerActive('TimeReload') || IsTimerActive('TimeWeaponReload'))
		{
			bAimingDelay = true;
			return;
		}
		
		// clear idle if active
		if(IsTimerActive('PlayIdleAnimation')) ClearTimer('PlayIdleAnimation');
		
		// clear raising if active
		if(IsTimerActive('TimeWeaponRaising')) ClearTimer('TimeWeaponRaising');
		
		// clear lowering if active
		if(IsTimerActive('TimeWeaponLowering')) ClearTimer('TimeWeaponLowering');
	
	// enable aiming delay, used in various checks
	bAimingDelay = true;
	
		// playing aim fire so just play idle after animation is finished
		if(IsPlayingAnim(ArmAimFireAnim))
		{
			SetTimer(GetAnimTimeLeft() + 0.01, false, 'PlayIdleAnimation');
		}
		// playing normal fire so continue after the animation is finished
		else if(IsPlayingAnim(ArmFireAnim))
		{
			SetTimer(GetAnimTimeLeft() + 0.01, false, 'TimeWeaponRaising');
		}
		// safe to just continue
		else
		{
			TimeWeaponRaising();
		}
}

/** ironsight aiming: lower weapon */
simulated function LowerWeapon()
{
		// if inactive then just exit
		if(IsInState('Inactive'))
		{
			return;
		}
		
		// if reloading at all then delay aiming and exit
		if(IsInState('WeaponReloading') || IsTimerActive('ReloadWeapon') || IsTimerActive('TimeReload') || IsTimerActive('TimeWeaponReload'))
		{
			bAimingDelay = false;
			return;
		}
	
		// clear idle animation if active
		if(IsTimerActive('PlayIdleAnimation')) ClearTimer('PlayIdleAnimation');
		
		// clear raising if active
		if(IsTimerActive('TimeWeaponRaising')) ClearTimer('TimeWeaponRaising');
		
		// clear lowering if active
		if(IsTimerActive('TimeWeaponLowering')) ClearTimer('TimeWeaponLowering');
	
	// disable aiming delay, used in various checks
	bAimingDelay = false;
	
		// playing aim fire so continue after the animation is finished
		if(IsPlayingAnim(ArmAimFireAnim))
		{
			SetTimer(GetAnimTimeLeft() + 0.01, false, 'TimeWeaponLowering');
		}
		// playing normal fire so just play idle after animation is finished
		else if(IsPlayingAnim(ArmFireAnim))
		{
			SetTimer(GetAnimTimeLeft() + 0.01, false, 'PlayIdleAnimation');
		}
		// safe to just continue
		else
		{
			TimeWeaponLowering();
		}
}

/** time weapon raising; called by RaiseWeapon */
simulated function TimeWeaponRaising()
{
	local float AimTime;
	local float TimeDiff;
	
		// if playing aim animation, grab the difference and apply to start offset
		if(IsPlayingAnim(ArmAimAnim))
		{
			// start difference to apply
			TimeDiff = GetAnimTimeLeft();
			AimTime = PlayWeaponAnim(ArmAimAnim, ArmAimAnimRate, false, , TimeDiff);
		}
		// playing aim fire so grab the time remaining
		else if(IsPlayingAnim(ArmAimFireAnim))
		{
			AimTime = GetAnimTimeLeft() + 0.01;
		}
		// safe to normally play the animation
		else
		{
			AimTime = PlayWeaponAnim(ArmAimAnim, ArmAimAnimRate, false);
		}
	
	// enable aiming
	bIsAiming = true;
	// set idle animation to aim idle animation
	ArmIdleAnims[0] = ArmAimIdleAnim;
	// set fire animation to aim fire animation
	ArmFireAnim = ArmAimFireAnim;
	// set view offset to ironsight view offset
	ArmViewOffset = IronsightViewOffset;
	// set camera field of view to aiming field of view
	SetFOV(AimingFOV);
	// set mesh field of view to aiming field of view
	SetMeshFOV(AimingMeshFOV);
	// play idle animation after aim animation finishes
	SetTimer(AimTime, false, 'PlayIdleAnimation');
}

/** time weapon lowering; called by LowerWeapon */
simulated function TimeWeaponLowering()
{
	local float AimTime;
	local float TimeDiff;
	
		// if playing aim animation, grab the difference and apply to start offset
		if(IsPlayingAnim(ArmAimAnim))
		{
			// start difference to apply
			TimeDiff = GetAnimTimeLeft();
			AimTime = PlayWeaponAnim(ArmAimAnim, -ArmAimAnimRate, false, , TimeDiff);
		}
		// safe to normally play the animation
		else
		{
			AimTime = PlayWeaponAnim(ArmAimAnim, -ArmAimAnimRate, false);
		}
	
	// disable aiming
	bIsAiming = false;
	// reset arm idle animation
	ArmIdleAnims[0] = default.ArmIdleAnims[0];
	// reset arm fire animation
	ArmFireAnim = default.ArmFireAnim;
	// reset arm view offset
	ArmViewOffset = default.ArmViewOffset;
	// reset camera field of view
	SetFOV();
	// reset mesh field of view
	SetMeshFOV(DefaultMeshFOV);
	// play idle animation after aim animation finishes
	SetTimer(Abs(AimTime), false, 'PlayIdleAnimation');
}

/** set camera field of view */
simulated function SetFOV(optional float NewFOV)
{
	local FRPlayerController PC;
	
		if((Instigator != none) && Instigator.Controller != none)
		{
			PC = FRPlayerController(Instigator.Controller);
					if(NewFOV > 0.0)
					{
						PC.StartZoomNonlinear(NewFOV, 10.0f);
					}
					else
					{
						PC.EndZoomNonlinear(10.0f);
					}
		}
}

/** set mesh field of view */
simulated function SetMeshFOV(float NewFOV, optional bool bForceFOV)
{
		if((Mesh != none) && Mesh.bAttached)
		{
			DesiredMeshFOV = NewFOV;
		}
}

/** adjust mesh field of view; called by Tick */
simulated function AdjustMeshFOV(float DeltaTime)
{
		if((Mesh != none) && Mesh.bAttached)
		{
				if(CurrentMeshFOV != DesiredMeshFOV)
				{
					CurrentMeshFOV = FInterpTo(CurrentMeshFOV, DesiredMeshFOV, DeltaTime, 10.0f);
					UDKSkeletalMeshComponent(Mesh).SetFOV(CurrentMeshFOV);
					
						if((Firearm != none) && Firearm.Mesh != none)
						{
							UDKSkeletalMeshComponent(Firearm.Mesh).SetFOV(CurrentMeshFOV);
						}
				}
		}
}

/** process view rotation; called by Pawn */
simulated function ProcessViewRotation(float DeltaTime, out rotator out_ViewRotation, 
	out rotator out_DeltaRot)
{
	local rotator DeltaRecoil;
	local float DeltaPitch, DeltaYaw;
	
		// perform recoil
		if(RecoilOffset != rot(0,0,0))
		{
			// interp recoil based on recoil offset
			DeltaRecoil.Pitch = RecoilOffset.Pitch - FInterpTo(RecoilOffset.Pitch, 0, DeltaTime, 
				RecoilInterpSpeed);
			DeltaRecoil.Yaw = RecoilOffset.Yaw - FInterpTo(RecoilOffset.Yaw, 0, DeltaTime, 
				RecoilInterpSpeed);
			
			// cache total recoil
			TotalRecoil.Pitch += DeltaRecoil.Pitch;
			
				// recoil is greater than our max recoil
				if(TotalRecoil.Pitch > MaxRecoil)
				{
						// still performing recoil
						if(DeltaRecoil.Pitch > 0)
						{
							// reduce offset as normal
							RecoilOffset -= DeltaRecoil;
							// reduce recoil but don't stop
							out_DeltaRot.Pitch += 1;
							out_DeltaRot.Yaw += DeltaRecoil.Yaw;
						}
				}
				// normal recoil
				else
				{
					RecoilDecline += DeltaRecoil;
					RecoilOffset -= DeltaRecoil;
					out_DeltaRot += DeltaRecoil;
				}
			
				// finished recoil
				if(DeltaRecoil == rot(0,0,0)) RecoilOffset = rot(0,0,0);
				
		}
		else
		{
				// recoil recovery
				if(RecoilDecline != rot(0,0,0))
				{
					// revert total recoil cache
					TotalRecoil = rot(0,0,0);
					
					// interp recoil recovery based on recoil decline
					DeltaPitch = RecoilDecline.Pitch - FInterpTo(RecoilDecline.Pitch, 0, DeltaTime, 
						RecoilDeclineSpeed);
					DeltaYaw = RecoilDecline.Yaw - FInterpTo(RecoilDecline.Yaw, 0, DeltaTime, 
						RecoilDeclineSpeed);
					
					out_DeltaRot.Pitch -= DeltaPitch * RecoilDeclinePct;
					out_DeltaRot.Yaw -= DeltaYaw * RecoilDeclinePct;

					RecoilDecline.Pitch -= DeltaPitch;
					RecoilDecline.Yaw -= DeltaYaw;
					
						// turn of recoil recovery if low enough
						if(Abs(DeltaPitch) < 1.0)
						{
							RecoilDecline = rot(0,0,0);
						}
				}
				
		}
	
	// adjust mesh field of view
	AdjustMeshFOV(DeltaTime);
}

/** overloaded: fire ammunition; called by WeaponFiring state */
simulated function FireAmmunition()
{
	super.FireAmmunition();
	
	// recoil
	SetWeaponRecoil(GetWeaponRecoil());
}

/** set recoil offset */
simulated function SetWeaponRecoil(int PitchRecoil)
{
	local int YawRecoil;
	YawRecoil = (0.5 - FRand()) * PitchRecoil;
	RecoilOffset.Pitch += PitchRecoil;
	RecoilOffset.Yaw += YawRecoil;
}

/** get weapon recoil */
simulated function int GetWeaponRecoil()
{
		if(bIsAiming)
		{
			return AimRecoil;
		}
		else
		{
			return Recoil;
		}
}

/** overloaded: time weapon equipping */
simulated function TimeWeaponEquipping()
{
	local float EquipAnimTime;
	
		// attach weapon
		if(Instigator != none)
		{
			// attach arm mesh
			AttachWeaponTo(Instigator.Mesh);
			
				// play arm equip animation
				if(ArmEquipAnim != '')
				{
					// play animation and return anim length for equip timer
					EquipAnimTime = PlayWeaponAnim(ArmEquipAnim, ArmEquipAnimRate, false);
					PlayWeaponAnim(ArmEquipAnim, ArmEquipAnimRate, false, Firearm.Mesh);
					PlayWeaponSound(EquipSound, 0.5);
					SetTimer(EquipAnimTime, false, 'WeaponEquipped');
				}
		}
}

/** overloaded: time weapon put down */
simulated function TimeWeaponPutDown()
{
	local float UnequipTime;
	
	ForceEndFire();
	bWeaponPutDown = true;
	UnequipTime = PlayWeaponAnim(ArmUnequipAnim, ArmUnequipAnimRate, false);
	PlayWeaponSound(UnequipSound, 0.5);
	SetTimer(UnequipTime, false, 'WeaponIsDown');
}

/** play weapon animation */
simulated function float PlayWeaponAnim(name AnimName, float Rate, optional bool bLooping, optional SkeletalMeshComponent SkelMesh, optional float StartTime)
{
	local AnimNodeSequence AnimNode;
	
		// get anim node sequence
		if(SkelMesh != none)
		{
			AnimNode = AnimNodeSequence(SkelMesh.Animations);
		}
		else
		{
			AnimNode = GetWeaponAnimNodeSeq();
		}
		
		// no sequence so return
		if(AnimNode == none) return 0.01;
	
		// set anim
		if(AnimNode.AnimSeq == none || AnimNode.AnimSeq.SequenceName != AnimName)
		{
			AnimNode.SetAnim(AnimName);
		}
		
		// no anim so return
		if(AnimNode.AnimSeq == none) return 0.01;
	
	// play anim
	AnimNode.PlayAnim(bLooping, Rate, StartTime);
	
	// return anim length
	return AnimNode.GetAnimPlaybackLength();
}

/** play weapon animation by duration */
simulated function PlayWeaponAnimByDuration(name AnimName, float Duration, optional bool bLooping, optional SkeletalMeshComponent SkelMesh, optional float StartTime)
{
	local float Rate;
	
		// use mesh if none passed in
		if((SkelMesh == none) && Mesh != none)
		{
			SkelMesh = SkeletalMeshComponent(Mesh);
		}
		
		// if no mesh or anim then return
		if(SkelMesh == none || AnimName == '') return;
	
	// get anim rate by duration
	Rate = SkelMesh.GetAnimRateByDuration(AnimName, Duration);
	
	// play anim by duration
	PlayWeaponAnim(AnimName, Rate, bLooping, SkelMesh, StartTime);
}

/** currently playing an animation */
simulated function bool IsPlayingAnim(name AnimName, optional bool bIsLooping, optional SkeletalMeshComponent SkelMesh)
{
	local AnimNodeSequence AnimNode;
	
		// get anim node sequence
		if(SkelMesh != none)
		{
			AnimNode = AnimNodeSequence(SkelMesh.Animations);
		}
		else
		{
			AnimNode = GetWeaponAnimNodeSeq();
		}
	
		// no sequence so return
		if(AnimNode == none) return false;
		
		// not playing, or anim name doesn't match, or is looping but the animation isn't looping
		if(!AnimNode.bPlaying || AnimNode.AnimSeq.SequenceName != AnimName || bIsLooping && !AnimNode.bLooping)
		{
			return false;
		}
	
	return true;
}

/** currently playing any animation */
simulated function bool IsPlayingAnims(optional SkeletalMeshComponent SkelMesh, optional bool bLooping)
{
	local AnimNodeSequence AnimNode;
	
		// get anim node sequence
		if(SkelMesh != none)
		{
			AnimNode = AnimNodeSequence(SkelMesh.Animations);
		}
		else
		{
			AnimNode = GetWeaponAnimNodeSeq();
		}
		
		// no sequence so return
		if(AnimNode == none) return false;
	
		// if looping then force false
		if(bLooping && AnimNode.bLooping) return false;
	
	return AnimNode.bPlaying;
}

/** get animation length */
simulated function float GetAnimLength(name AnimName, optional SkeletalMeshComponent SkelMesh)
{
	local AnimNodeSequence AnimNode;
	
		// get anim node sequence
		if(SkelMesh != none)
		{
			AnimNode = AnimNodeSequence(SkelMesh.Animations);
		}
		else
		{
			AnimNode = GetWeaponAnimNodeSeq();
		}
		
		// no sequence so return
		if(AnimNode == none) return 0.01;
		
	AnimNode.SetAnim(AnimName);
	return AnimNode.GetAnimPlaybackLength();
}

/** get animations time remaining */
simulated function float GetAnimTimeLeft(optional SkeletalMeshComponent SkelMesh)
{
	local AnimNodeSequence AnimNode;
	
		// get anim node sequence
		if(SkelMesh != none)
		{
			AnimNode = AnimNodeSequence(SkelMesh.Animations);
		}
		else
		{
			AnimNode = GetWeaponAnimNodeSeq();
		}
		
		// no sequence so return
		if(AnimNode == none) return 0.01;
		
	return AnimNode.GetTimeLeft();
}

/** overloaded: play fire effects */
simulated function PlayFireEffects(byte FireModeNum, optional vector HitLocation)
{
		if(ArmFireAnim != '')
		{
			PlayWeaponAnim(ArmFireAnim, ArmFireAnimRate, false);
			
				// fire anim was changed to aim fire so play normal fire anim for the firearm
				if(ArmFireAnim == ArmAimFireAnim)
				{
					PlayWeaponAnim(default.ArmFireAnim, ArmFireAnimRate, false, Firearm.Mesh);
				}
				else
				{
					PlayWeaponAnim(ArmFireAnim, ArmFireAnimRate, false, Firearm.Mesh);
				}
		}
	
	// play muzzle flash
	PlayMuzzleFlashEffect();
	
	// play fire sound
	PlayWeaponSound(FireSound, 1.0);
}

/** muzzle flash effect */
simulated function PlayMuzzleFlashEffect()
{
		// muzzle flash
		if(MuzzleFlashClass != none && MuzzleFlash == none)
		{
			MuzzleFlash = new(self) MuzzleFlashClass;
			MuzzleFlash.AttachTo(Firearm);
		}
	
		// activate effects
		if(MuzzleFlash != none)
		{
			MuzzleFlash.Activate();
			SetTimer(MuzzleFlash.MuzzleDuration, false, 'StopMuzzleFlashEffect');
		}
}

/** stop muzzle flash effect */
simulated function StopMuzzleFlashEffect()
{
		if(MuzzleFlash != none)
		{
			MuzzleFlash.Deactivate();
		}
}

/** play weapon sound */
simulated function PlayWeaponSound(SoundCue Sound, optional float Noise)
{
		if(Instigator == none) return;
		
		if(Sound != none)
		{
			Instigator.PlaySound(Sound, false, true);
			MakeNoise(Noise);
		}
}

/** state: active */
simulated state Active
{
		/** begin state */
		simulated function BeginState(name PrevState)
		{
				// playing any animations
				if(IsPlayingAnims())
				{
					// already playing an animation so get the time left and set the timer
					SetTimer(GetAnimTimeLeft(), false, 'PlayIdleAnimation');
				}
				else
				{
					// not playing an anim so play the idle anim
					PlayIdleAnimation();
				}
			
			super.BeginState(PrevState);
		}
		
		/** overloaded: begin fire */
		//@notes: this is overloaded to avoid firing while playing our aim animation
		simulated function BeginFire(byte FireModeNum)
		{
				if(Instigator == none || bDeleteMe) return;

				if(!HasMagazineAmmo())
				{
						if(HasAnyAmmo() && !IsReloading())
						{
							ReloadWeapon();
						}
						else
						{
								if(FireEmptySound != none)
								{
									PlayWeaponSound(FireEmptySound, 0.3);
								}
						}
				}
				else
				{
						if(!IsPlayingAnim(ArmAimAnim))
						{
							global.BeginFire(FireModeNum);

								if(PendingFire(FireModeNum) &&  HasAmmo(FireModeNum))
								{
									SendToFiringState(FireModeNum);
								}
						}
				}
		}		
		/** end state */
		simulated function EndState(name NextState)
		{
				if(IsTimerActive('PlayIdleAnimation'))
				{
					ClearTimer('PlayIdleAnimation');
				}
			
			super.EndState(NextState);
		}
		
		/** play idle animation */
		simulated function PlayIdleAnimation()
		{
			local int i;
			
				if(WorldInfo.NetMode != NM_DedicatedServer && ArmIdleAnims.Length > 0)
				{
					i = Rand(ArmIdleAnims.Length);
					PlayWeaponAnim(ArmIdleAnims[i], ArmIdleAnimRate, true);
				}
		}
		
}

/** timed weapon reloading */
simulated function TimeWeaponReload()
{
	local float ReloadAnimTime;
	
		// make sure this timer isn't already active
		if(!IsTimerActive('Reload'))
		{
			// play reload animation and get the animation length
			ReloadAnimTime = PlayWeaponAnim(ArmReloadAnim, ArmReloadAnimRate, false);
			// play reload animation on the weapon mesh as well
			PlayWeaponAnim(ArmReloadAnim, ArmReloadAnimRate, false, Firearm.Mesh);
			// set the timer based on the anim length and actually reload
			SetTimer(ReloadAnimTime, false, 'Reload');
		}
}

/** is weapon reloading */
simulated function bool IsReloading()
{
	return false;
}

/** reload */
simulated function Reload()
{
		if(CanReload())
		{
				if(IsTimerActive('Reload'))
				{
					ClearTimer('Reload');
				}
		}
}

/** state: weapon reloading */
simulated state WeaponReloading
{
		/** begin state */
		simulated function BeginState(name PrevState)
		{
				// clear idle anim timer is still active
				if(IsTimerActive('PlayIdleAnimation'))
				{
					ClearTimer('PlayIdleAnimation');
				}
				
				// playing anims except looping anims (will be our idle anim)
				if(IsPlayingAnims(, true))
				{
					SetTimer(GetAnimTimeLeft(), false, 'TimeWeaponReload');
				}
				else
				{
					TimeWeaponReload();
				}
		}
		
		/** begin fire */
		simulated function BeginFire(byte FireModeNum)
		{
			// don't allow firing
			return;
		}
		
		/** end state */
		simulated function EndState(name NextState)
		{
			// clear our timers
			ClearTimer('TimeWeaponReload');
			ClearTimer('Reload');
			
				// aiming delay, so begin raising
				if(bAimingDelay)
				{
					bAimingDelay = false;
					TimeWeaponRaising();
				}
			
		}
		
		/** is weapon reloading */
		simulated function bool IsReloading()
		{
			return true;
		}
		
		/** reload */
		simulated function Reload()
		{
			local int Ammo;
			
				if(MagAmmo < 1)
				{
					Ammo = Min(MaxMagAmmo, AmmoCount);
					AddMagAmmo(Ammo);
					AddStorageAmmo(-Ammo);
				}
				else
				{
					Ammo = Abs(MaxMagAmmo - MagAmmo);
					Ammo = Min(AmmoCount, Ammo);
					AddMagAmmo(Ammo);
					AddStorageAmmo(-Ammo);
				}
			
			// return to active state
			GotoState('Active');
		}
		
		/** toggle aim */
		simulated function ToggleAim()
		{
			bAimingDelay = !bAimingDelay;
			return;
		}
	
}

/** toggle firing mode */
reliable server function ToggleFireMode()
{
	local int i, j;

	j = WeaponFireMode;
		for(i = 0; i < 3; i++)
		{
			j++;
				if(j > 2)
				{
					j = 0;
				}

				if(AllowedFireModes[j] == 1)
				{
					WeaponFireMode = j;
					break;
				}
		}

}

defaultproperties
{
	// anim sequence
	begin object class=AnimNodeSequence name=MeshSequenceA
		bCauseActorAnimEnd = true
	end object
	
	// arms mesh
	begin object class=UDKSkeletalMeshComponent name=ArmsMeshComp
		SkeletalMesh = SkeletalMesh'Tutorials.Mesh.Char_Arms'
		AnimSets(0) = AnimSet'Tutorials.Anims.Char_Arm_Anims'
		DepthPriorityGroup = SDPG_Foreground
		bOnlyOwnerSee = true
		bOverrideAttachmentOwnerVisibility = true
		CastShadow = false
		FOV = 60.0f
		Animations = MeshSequenceA
		bPerBoneMotionBlur = true
		bAcceptsStaticDecals = false
		bAcceptsDynamicDecals = false
		bUpdateSkelWhenNotRendered = false
		bComponentUseFixedSkelBounds = true
	end object
	Mesh = ArmsMeshComp

	// ---------------------- MESH
	ArmViewOffset = (X=35.0)
	IronsightViewOffset = (X=40.0)
	DefaultMeshFOV = 60.0f
	CurrentMeshFOV = 60.0f
	DesiredMeshFOV = 60.0f
	AimingMeshFOV = 30.0f
	
	// ---------------------- ANIMATIONS
	ArmIdleAnims(0) = 1p_Idle
	ArmEquipAnim = 1p_Equip
	ArmUnequipAnim = 1p_Unequip
	ArmFireAnim = 1p_Fire
	ArmReloadAnim = 1p_Reload
	ArmAimAnim = 1p_ToAim
	ArmAimIdleAnim = 1p_AimIdle
	ArmAimFireAnim = 1p_AimFire
	ArmMovingAnim = 1p_Run
	
	// ---------------------- ANIMATION RATES
	ArmIdleAnimRate = 1.0
	ArmEquipAnimRate = 1.0
	ArmUnequipAnimRate = 1.0
	ArmFireAnimRate = 1.0
	ArmReloadAnimRate = 1.0
	ArmAimAnimRate = 1.0
	ArmAimIdleAnimRate = 1.0
	ArmAimFireAnimRate = 1.0
	ArmMovingAnimRate = 1.0
	
	// ---------------------- WEAPON SETTINGS
	bInstantHit = true
	FiringStatesArray(0) = WeaponFiring
	WeaponFireTypes(0) = EWFT_InstantHit
	ShouldFireOnRelease(0) = 0
	FireInterval(0) = 0.1
	Spread(0) = 0.05
	InstantHitDamage(0) = 10.0
	InstantHitMomentum(0) = 1.0
	InstantHitDamageTypes(0) = class'DamageType'
	
	// ---------------------- SOCKETS
	WeaponSocket = WeaponSocket
	
	// ---------------------- AMMUNITION
	MagAmmo = 15
	MaxMagAmmo = 15
	AmmoCount = 99
	MaxAmmoCount = 99
	ShotCost(0) = 1
	ShotCost(1) = 0

	// ---------------------- IRONSIGHT
	AimingFOV = 60.0f
	
	// ---------------------- SOUNDS
	FireSound = SoundCue'Tutorials.Sounds.Pistol_Fire_Cue'
	EquipSound = SoundCue'Tutorials.Sounds.Pistol_Equip_Cue'
	UnequipSound = SoundCue'Tutorials.Sounds.Pistol_Unequip_Cue'
	//FireEmptySound = SoundCue'Tutorials.Sounds.Pistol_FireEmpty_Cue'
	
	// ---------------------- RECOIL
	Recoil = 250.0
	MaxRecoil = 1000.0
	AimRecoil = 170.0
	RecoilInterpSpeed = 10.0
	RecoilDeclinePct = 1.0
	RecoilDeclineSpeed = 10.0
	
	// ---------------------- ATTACHMENT
	AttachmentClass = class'FRWeaponAttachment'
	
}