/**
 *
 * Notes: 
 *
*/

class FRPlayerController extends UDKPlayerController
	dependson(FRPawn)
	config(Game);

// ---------------------- CAMERA ZOOM
/** zooming rate */
var float FOVLinearZoomRate;
/** zoomed rotation modifier */
var float ZoomRotationModifier;
/** non-linear zoom interpolation */
var bool bNonLinearZoomInterpolation;
/** non-linear zoom interp speed */
var float FOVNonLinearZoomInterpSpeed;

// ---------------------- CAMERA ANIMATIONS
/** camera animation is modifying FOV */
var bool bCurrentCamAnimAffectsFOV;

/* ----------------------------------- MOVEMENT ------------------------------------- */

/** overwritten: check jumping or crouching */
function CheckJumpOrDuck()
{
		if(Pawn == none) return;
		
		if(bPressedJump)
		{
			Pawn.DoJump(bUpdating);
		}
		
		if(Pawn.Physics != PHYS_Falling && Pawn.bCanCrouch)
		{
			Pawn.ShouldCrouch(bDuck != 0);
		}
}

/* ------------------------------------ WEAPONS ------------------------------------- */

/** exec: reload weapon */
simulated exec function Reload()
{
		if((Pawn == none) || Pawn.Weapon == none) return;
	
	FRWeapon(Pawn.Weapon).ReloadWeapon();
}

/** exec: raise weapon to ironsight */
simulated exec function RaiseWeapon()
{
		if((Pawn == none) || Pawn.Weapon == none) return;
	
	FRWeapon(Pawn.Weapon).RaiseWeapon();
}

/** exec: lower weapon from ironsight */
simulated exec function LowerWeapon()
{
		if((Pawn == none) || Pawn.Weapon == none) return;
	
	FRWeapon(Pawn.Weapon).LowerWeapon();
}

/** exec: toggle aiming */
simulated exec function ToggleAim()
{
		if((Pawn == none) || Pawn.Weapon == none) return;
	
	FRWeapon(Pawn.Weapon).ToggleAim();
}

/** exec: firing modes */
simulated exec function ToggleFireMode()
{
		if((Pawn == none) || Pawn.Weapon == none) return;
	FRWeapon(Pawn.Weapon).ToggleFireMode();
}

/* ---------------------------------- CAMERA ZOOM ----------------------------------- */

/** overloaded: update FOV property called by camera animations */
function OnUpdatePropertyFOVAngle()
{
	bCurrentCamAnimAffectsFOV = true;
	FOVAngle = DesiredFOV + (FOVAngle - 90.0);
}

/** overloaded: get FOV angle */
event float GetFOVAngle()
{
	return FOVAngle;
}

/** overloaded: adjust FOV called from PlayerTick */
function AdjustFOV(float DeltaTime)
{
	local float DeltaFOV;
	
		if(FOVAngle != DesiredFOV && (!bCurrentCamAnimAffectsFOV || CameraAnimPlayer.bFinished))
		{
				if(bNonlinearZoomInterpolation)
				{
					FOVAngle = FInterpTo(FOVAngle, DesiredFOV, DeltaTime, FOVNonlinearZoomInterpSpeed);
				}
				else
				{
						if(FOVLinearZoomRate > 0.0)
						{
							DeltaFOV = FOVLinearZoomRate * DeltaTime;
								if(FOVAngle > DesiredFOV)
								{
									FOVAngle = FMax(DesiredFOV, (FOVAngle - DeltaFOV));
								}
								else
								{
									FOVAngle = FMin(DesiredFOV, (FOVAngle + DeltaFOV));
								}
						}
						else
						{
							FOVAngle = DesiredFOV;
						}
				}
		}

}

/** start zoom by rate */
simulated function StartZoom(float NewDesiredFOV, float NewZoomRate)
{
	FOVLinearZoomRate = NewZoomRate;
	DesiredFOV = NewDesiredFOV;
	
	bNonlinearZoomInterpolation = false;
	FOVNonlinearZoomInterpSpeed = 0.0;
}

/** start non-linear zoom by rate */
simulated function StartZoomNonlinear(float NewDesiredFOV, float NewZoomRate)
{
	FOVNonlinearZoomInterpSpeed = NewZoomRate;
	DesiredFOV = NewDesiredFOV;
	
	bNonlinearZoomInterpolation = true;
	FOVLinearZoomRate = 0.0;
}

/** stop zoom */
simulated function StopZoom()
{
	DesiredFOV = FOVAngle;
	FOVLinearZoomRate = 0.0;
}

/** end zoom and reset FOV */
simulated function EndZoom()
{
	DesiredFOV = default.DefaultFOV;
	FOVAngle = default.DefaultFOV;
	FOVLinearZoomRate = 0.0;
	FOVNonlinearZoomInterpSpeed = 0.0;
}

/** end non-linear zoom and reset FOV */
simulated function EndZoomNonlinear(float ZoomInterpSpeed)
{
	DesiredFOV = default.DefaultFOV;
	FOVNonlinearZoomInterpSpeed = ZoomInterpSpeed;
	bNonlinearZoomInterpolation = true;
	FOVLinearZoomRate = 0.0;
}

/** replicated: end zoom */
reliable simulated client function ClientEndZoom()
{
	EndZoom();
}

/** overloaded: using first person camera: true/false */
function bool UsingFirstPersonCamera()
{
		if(PlayerCamera != none)
		{
			return (PlayerCamera.CameraStyle == 'FirstPerson');
		}

	return false;
}


/* ------------------------------- CAMERA ANIMATIONS ------------------------------ */

/** overloaded: replicated play camera animation */
unreliable client event ClientPlayCameraAnim(CameraAnim AnimToPlay, optional float Scale = 1.0, 
	optional float Rate = 1.0, optional float BlendInTime, optional float BlendOutTime, 
	optional bool bLoop, optional bool bRandomStartTime, 
	optional ECameraAnimPlaySpace Space = CAPS_CameraLocal, optional rotator CustomPlaySpace)
{
	local CameraAnimInst AnimInst;
	
	AnimInst = PlayCameraAnim(AnimToPlay, Scale, Rate, BlendInTime, BlendOutTime, bLoop, 
		bRandomStartTime);
		if(AnimInst != none && Space != CAPS_CameraLocal)
		{
			AnimInst.SetPlaySpace(Space, CustomPlaySpace);
		}
}

/** overloaded, replicated: stop camera animation */
reliable client event ClientStopCameraAnim(CameraAnim AnimToStop)
{
	StopCameraAnim(AnimToStop, true);
}

/** replicated: stop camera animation by animation instance */
reliable client event ClientStopCameraAnimInst(CameraAnimInst AnimToStop, 
	optional bool bImmediate)
{
	StopCameraAnimInst(AnimToStop, bImmediate);
}

/** play camera animation */
function CameraAnimInst PlayCameraAnim(CameraAnim AnimToPlay, optional float Scale = 1.0, 
	optional float Rate = 1.0, optional float BlendInTime, optional float BlendOutTime, 
	optional bool bLoop, optional bool bRandomStartTime, optional float Duration)
{
	local CameraAnimInst AnimInst;
	
	bCurrentCamAnimAffectsFOV = false;
	
		if(PlayerCamera != none)
		{
			AnimInst = PlayerCamera.PlayCameraAnim(AnimToPlay, Rate, Scale, BlendInTime, 
				BlendOutTime, bLoop, bRandomStartTime, Duration);
		}
		else if(CameraAnimPlayer != none)
		{
			CamOverridePostProcess = class'CameraActor'.default.CamOverridePostProcess;
			CameraAnimPlayer.Play(AnimToPlay, self, Rate, Scale, BlendInTime, BlendOutTime, 
				bLoop, false);
		}
	
	return AnimInst;
}

/** stop camera animation */
function StopCameraAnim(CameraAnim AnimToStop, optional bool bImmediate)
{
	bCurrentCamAnimAffectsFOV = false;
	
		if(PlayerCamera != none)
		{
			PlayerCamera.StopAllCameraAnimsByType(AnimToStop, bImmediate);
		}
		else if(CameraAnimPlayer != none)
		{
			CameraAnimPlayer.Stop(bImmediate);
		}
	
}

/** set camera anim strength */
function SetCameraAnimStrength(float NewStrength)
{
		if(CameraAnimPlayer != none)
		{
			CameraAnimPlayer.BasePlayScale = NewStrength;
		}
}

/** stop camera animation by anim instance */
function StopCameraAnimInst(CameraAnimInst AnimInst, optional bool bImmediate)
{
	bCurrentCamAnimAffectsFOV = false;
	
		if(PlayerCamera != none)
		{
			PlayerCamera.StopCameraAnim(AnimInst, bImmediate);
		}
}

defaultproperties
{
	CameraClass = class'FiringRange.FRCamera'
	InputClass = class'FiringRange.FRPlayerInput'
	
	FOVAngle = 90.0f
	DesiredFOV = 90.0f
	DefaultFOV = 90.0f
	bRun = 1
	
}