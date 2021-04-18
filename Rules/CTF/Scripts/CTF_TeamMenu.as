#include "TeamMenu.as"

void onTick(CRules@ this)
{
	CPlayer@ p = getLocalPlayer();

	if (p is null || !p.isMyPlayer()) { return; }

    string propname = "ctf spawn time " + p.getUsername();
    if(this.exists(propname))
    {
        u8 spawn = this.get_u8(propname);

		CGridMenu@ changeTeamMenu = getGridMenuByName("Change team");

		// The player has the change team menu open, and is respawning.
		if (changeTeamMenu !is null and spawn < 255)
		{
			// Update the menu with the player's remaining spawn time.
			BuildTeamMenu(this, spawn);

			// The player's preference is locked in, and all team options
			// are disabled
			if (spawn < 2)
			{
				// Update ref to menu, now that it's been newly recreated
				CGridMenu@ changeTeamMenu = getGridMenuByName("Change team");
				uint buttonCount = changeTeamMenu.getButtonsCount();
				for (uint i = 0; i < buttonCount; i++)
				{
					changeTeamMenu.getButtonOfIndex(i).SetEnabled(false);
				}	
			}

			return;
		}

		// Original default behavior - close all menus during last 2s of spawn.
		if (spawn < 2)
		{
			getHUD().ClearMenus();
		}
    }

}