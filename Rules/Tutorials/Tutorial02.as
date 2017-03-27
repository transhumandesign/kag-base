#include "ChallengesCommon.as"
#include "TutorialCommon.as"
#include "MakeSign.as"

void onInit(CMap@ this)
{
	SetupTutorial(this, "Archer basics tutorial");

	AddIconToken("$Tutorial_Archer$", "TutorialImages.png", Vec2f(32, 32), 3);
	AddIconToken("$Tutorial_Archer2$", "TutorialImages.png", Vec2f(32, 32), 4);
	AddIconToken("$Tutorial_Grapple$", "TutorialImages.png", Vec2f(32, 32), 5);

	// make signs

	createSign(Vec2f(42, 51) * this.tilesize, "Stand on the enemy hall$hall$ to capture it.");
	createSign(Vec2f(53, 51) * this.tilesize, "Halls are respawn points and can be used to switch class.");
	createSign(Vec2f(57, 51) * this.tilesize, "In the hall switch class to ARCHER  $ARCHER$\n\nHOLD $KEY_E$ (use key).\n\nHover mouse over the$CLASSCHANGE$button and release\nthe use key.");
	createSign(Vec2f(67, 51) * this.tilesize, "As archer $Tutorial_Archer$\n\n\nAim with mouse.\n\nHOLD$LMB$ to charge\n\nRELEASE to fire arrow!");
	createSign(Vec2f(103, 51) * this.tilesize, "Use your grappling hook$Tutorial_Grapple$\n\n\nAim mouse up to catch the ceiling\n\nHOLD$RMB$\n\nSwing to the right $KEY_D$");
	createSign(Vec2f(111, 51) * this.tilesize, "Use a combination of grappling hook and wall running to get across here\n\nHOLD$RMB$\n\nHOLD jump & run $KEY_D$$KEY_W$");
	createSign(Vec2f(170, 50) * this.tilesize, "HOLD $LMB$ until spark$Tutorial_Archer2$\n\n\nThen $LMB$ again for\n\nTRIPLE SHOT! Good in close range!");
	createSign(Vec2f(175, 50) * this.tilesize, "$Tutorial_Archer2$\n\n\nPractice and then charge your shot before opening this door and TRIPLE SHOOT the knight!");
	createSign(Vec2f(213, 51) * this.tilesize, "Use your grappling hook$Tutorial_Grapple$ to swing over.\n\nHOLD$RMB$\n\nCatch the ceiling at the point where the lantern is$lantern$\n\nHOLD $KEY_D$\n\nRELEASE hook before stopping.");
}

void onTick(CMap@ this)
{
	CheckEndmap(this);
}

void onRender(CRules@ this)
{
	RenderEndmap(this);
}