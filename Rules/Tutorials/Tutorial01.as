#include "ChallengesCommon.as"
#include "TutorialCommon.as"
#include "MakeSign.as"

void onInit(CMap@ this)
{
	SetupTutorial(this, "Knight basics tutorial");

	AddIconToken("$Tutorial_Slash$", "TutorialImages.png", Vec2f(32, 32), 0);
	AddIconToken("$Tutorial_Slash2$", "TutorialImages.png", Vec2f(32, 32), 1);
	AddIconToken("$Tutorial_Glide$", "TutorialImages.png", Vec2f(32, 32), 2);

	// make signs

	createSign(Vec2f(5, 49) * this.tilesize, "Walk & Jump $KEY_A$ $KEY_W$ $KEY_D$");
	createSign(Vec2f(20, 51) * this.tilesize, "$sign$Go to the right and\n\nbe sure to read these signs.");
	//createSign( Vec2f(26, 51) * this.tilesize, "Useful tips appear in the bottom/left corner of the screen." );
	//createSign( Vec2f(30, 51) * this.tilesize, "Press $KEY_ESC$ to view menu\n\nand default keyboard controls." );
	createSign(Vec2f(44, 48) * this.tilesize, "$Jab$Practice the sword JAB\n\non the dummy.\n\nAim with mouse and tap $LMB$");
	createSign(Vec2f(75, 47) * this.tilesize, "Practice the sword SLASH.\n\nHOLD $LMB$ to draw sword\n\nuntil you see this pose$Tutorial_Slash$\n\nand RELEASE!");
	createSign(Vec2f(110, 47) * this.tilesize, "Practice the DOUBLE SLASH.\n\nHOLD $LMB$ until spark$Tutorial_Slash2$\n\n\nQuickly TAP $LMB$ 2 times!");
	createSign(Vec2f(122, 46) * this.tilesize, "Before entering this room charge your sword $Tutorial_Slash2$\n\nand then quickly\nwalk inside and slash!");
	createSign(Vec2f(134, 47) * this.tilesize, "HOLD $RMB$ to shield.\n\nUse mouse to aim shield.");
	createSign(Vec2f(163, 45) * this.tilesize, "Run at wall and hold jump to WALL RUN.\n\nHOLD $KEY_D$$KEY_W$");
	createSign(Vec2f(183, 47) * this.tilesize, "Knights can destroy wooden blocks, wooden doors and dig dirt. Point at the wall and jab it to get through $LMB$");
	createSign(Vec2f(200, 48) * this.tilesize, "Automatically pickup things used by your class.");

	{
		CBlob@ bomb = server_CreateBlob("mat_bombs", 0, Vec2f(205, 43) * this.tilesize);
		if (bomb !is null)
			bomb.server_SetTimeToDie(-1.0f);
	}
	{
		CBlob@ bomb = server_CreateBlob("mat_bombs", 0, Vec2f(207, 43) * this.tilesize);
		if (bomb !is null)
			bomb.server_SetTimeToDie(-1.0f);
	}
	{
		CBlob@ bomb = server_CreateBlob("mat_bombs", 0, Vec2f(208, 43) * this.tilesize);
		if (bomb !is null)
			bomb.server_SetTimeToDie(-1.0f);
	}

	createSign(Vec2f(216, 47) * this.tilesize, "Press $KEY_SPACE$ to light bomb\n\nAim with mouse.\n\nAgain $KEY_SPACE$ throw it.");
	createSign(Vec2f(247, 49) * this.tilesize, "Shield gliding$Tutorial_Glide$\n\n\nJump over the canyon and while in air:\nPoint your cursor upwards\nHOLD $RMB$ for shield.");
}

void onTick(CMap@ this)
{
	CheckEndmap(this);
}

void onRender(CRules@ this)
{
	RenderEndmap(this);
}