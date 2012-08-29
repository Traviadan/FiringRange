/**
 *
 * Notes: 
 *
*/

class FRGame extends UDKGame
	config(Game);

/** overwritten: set the game type */
static event class<GameInfo> SetGameType(string MapName, string Options, string Portal)
{
	return class'FRGame';
}

defaultproperties
{
	bRestartLevel = false
	bDelayedStart = false
	bWaitingToStartMatch = true
	
	PlayerControllerClass = class'FiringRange.FRPlayerController'
	DefaultPawnClass = class'FiringRange.FRPawn'
	
}