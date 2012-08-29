/**
 *
 * Notes: 
 *
*/

class FRInventoryManager extends InventoryManager
	dependson(FRWeapon)
	config(Weapon);

defaultproperties
{
	PendingFire(0) = 0
	PendingFire(1) = 0
	
}