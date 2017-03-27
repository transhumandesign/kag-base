#include "MakeSign.as"

// Hook for map loader
void LoadMap()  // this isn't run on client!
{
	CRules@ rules = getRules();
	if (rules is null)
	{
		error("Something went wrong Rules is null");
	}

	rules.set_bool("singleplayer", true);
	rules.set_bool("tutorial", true);
	rules.set_string("ctfconfig", "Rules/Tutorials/ctf_tutorial_vars.cfg");

	RegisterFileExtensionScript("Scripts/MapLoaders/LoadPNGMap.as", "png");
	LoadMap(getMapInParenthesis());
}

void onInit(CMap@ this)
{
	// make signs

	createSign(Vec2f(13, 31) * this.tilesize, "Capture the Flag is the simplest game mode for beginners. The goal is to simply retrieve the enemy flag and bring it to your flag.");

	createSign(Vec2f(22, 30) * this.tilesize, "Killing enemies, building structures and generally being useful for your team will give you coins.\n\nCoins allow you to purchase ammo, weapons & tools in workshops. First thing, as an example on how it will look when you kill an enemy:\n\nKill those chicken and get their coins!\n\n$chicken$");
	createSign(Vec2f(27, 30) * this.tilesize, "Go to the Tent and switch class to BUILDER.\n\nPress $KEY_E$ while standing\n\non the Tent.\n\n\n\n$tent$\n\n\n");
	createSign(Vec2f(36, 35) * this.tilesize, "If you've switched to builder in the Tent now you can build workshops for your team.\n\n\nHold $KEY_F$ and select $building$");
	createSign(Vec2f(38, 35) * this.tilesize, "If you don't have wood:\n$Tree$\n\nChop down a tree\n\nHOLD $RMB$ and point at the tree.\n\n\n$log$\n\nChop down logs\ninto WOOD $mat_wood$\n\nHOLD $RMB$ and point at log.");
	createSign(Vec2f(45, 35) * this.tilesize, "Press $KEY_E$ on the frame\n\nto convert it to a proper workshop. Some will require additional resources, go gather them!");
	createSign(Vec2f(49, 35) * this.tilesize, "Workshops allow you to buy items in them for coins which you get for doing useful things for your team.\n\nClass workshops allow you to switch class in them.\n\nThe tunnel allows you to quickly move from place to place (at least 2 required).\n\nTry them out!\n\n\n$tunnel$\n");
	createSign(Vec2f(69, 36) * this.tilesize, "To conclude this tutorial go get the red flag and bring it back to your blue flag. \n\nPress $KEY_ESC$ to go to menu\n\nand exit after you're done.");
}
