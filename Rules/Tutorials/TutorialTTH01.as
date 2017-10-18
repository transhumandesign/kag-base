#include "MakeSign.as"

// Hook for map loader
void LoadMap()	// this isn't run on client!
{
	CRules@ rules = getRules();
	if (rules is null)
	{
		error("Something went wrong Rules is null");
	}

	rules.set_bool("singleplayer", true);
	rules.set_bool("tutorial", true);
	rules.set_string("warconfig", "Rules/Tutorials/war_tutorial_vars.cfg");

	RegisterFileExtensionScript("Scripts/MapLoaders/LoadWarPNG.as", "png");
	LoadMap(getMapInParenthesis());
}

void onInit(CMap@ this)
{
	// make signs

	createSign(Vec2f(8, 45) * this.tilesize, getTranslatedString("The goal of Take the Halls is for your team to capture all the halls on the map.\n\nYou can easily see them in the minimap on top of the screen.\n\n$KEY_M$ to toggle the\n\nminimap.")),
	createSign(Vec2f(26, 51) * this.tilesize, getTranslatedString("A white colored Hall is neutral. It belongs to the people of this land. Capture it by standing inside of it.")),
	createSign(Vec2f(51, 51) * this.tilesize, getTranslatedString("Hold $KEY_E$ and press $CLASSCHANGE$\n\nto change class to BUILDER\n\n\n$RESEARCH$\n\n\nPress this button to view your teams research tree.\n\nThe whole team can vote here on what technology they want. Not all techs can be achieved, decide wisely!")),
	createSign(Vec2f(46, 44) * this.tilesize, getTranslatedString("$crate$\n\nPress $KEY_E$ on the crate\n\n(if it has dropped from the sky) to get supply materials!")),
	createSign(Vec2f(64, 49) * this.tilesize, getTranslatedString("If you've switched to builder in the Hall now you can build workshops for your team.\n\nWorkshops are basically factories which make ammo & weapons automatically for you.\n\nGo to an empty spot.\n\nHold $KEY_F$ and select $building$.")),
	createSign(Vec2f(76, 48) * this.tilesize, getTranslatedString("After converting to a workshop you can see a worker appeared inside of it.\n$migrant$\n\n\nHe came from the hall.\n\nYou can only build as many functional workshops as there are workers in your hall.")),
	createSign(Vec2f(83, 48) * this.tilesize, getTranslatedString("Press $KEY_E$ on the frame\n\n$building$\n\nto convert it to a proper workshop. Select one (the unavailable ones are waiting for research in the hall to complete).")),
	createSign(Vec2f(86, 48) * this.tilesize, getTranslatedString("Hold $KEY_E$ on a workshop to see\n\nwhat it is producing. Green indicates it's done.\n\n\nTry out the different shops!")),
	createSign(Vec2f(102, 48) * this.tilesize, getTranslatedString("$trader$\n\n\nYou see a trader in his shop below.\n\nPress $KEY_E$ on the trader to buy.\n\nYou can buy the following:\n\nTechnology scrolls - give you quick access to a tech without the need for long research\n\nMagic scrolls - check the descriptions!\n\nExchange materials for gold and vice versa. This is useful when one of the resources is lacking on the map.")),
	createSign(Vec2f(126, 60) * this.tilesize, getTranslatedString("Dig the gold $RMB$.\n\nGet enough to buy the Scroll of Drought from the trader.\n\n$scroll$")),
	createSign(Vec2f(133, 60) * this.tilesize, getTranslatedString("$scroll$\n\nOnce you have the scroll press $KEY_E$ to use it!")),
	createSign(Vec2f(162, 55) * this.tilesize, getTranslatedString("If you have more than one hall you can quickly move between them.\n\nHold $KEY_E$ and\n\nselect the blue travel button.")),
	createSign(Vec2f(173, 55) * this.tilesize, getTranslatedString("Those are the basics you need to know about Take the Halls. The rest can be learned when playing online by observation. This game mode is simple but complexity comes from great strategy. See you on the battlefield!\n\nPress $KEY_ESC$ to get out.")),

}