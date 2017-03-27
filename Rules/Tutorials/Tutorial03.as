#include "ChallengesCommon.as"
#include "TutorialCommon.as"
#include "MakeSign.as"

void onInit(CMap@ this)
{
	SetupTutorial(this, "Builder basics tutorial");

	AddIconToken("$Tutorial_Catapult$", "TutorialImages.png", Vec2f(32, 32), 6);

	// make signs

	createSign(Vec2f(16, 44) * this.tilesize, "$lantern$\nPickup the lantern $KEY_C$");
	createSign(Vec2f(44, 50) * this.tilesize, "Drop is the same as pickup $KEY_C$");
	createSign(Vec2f(67, 43) * this.tilesize, "Activate/Deactivate things\n   $KEY_SPACE$\n\n\n$lantern$ On/Off");
	createSign(Vec2f(75, 42) * this.tilesize, "By the way: you can see a minimap at the top of the screen. You can hide or expand the minimap by pressing $KEY_M$");
	createSign(Vec2f(117, 49) * this.tilesize, "Switch class to BUILDER  $BUILDER$\n\nGo to Hall. HOLD $KEY_E$ and mouse over$CLASSCHANGE$");
	createSign(Vec2f(133, 49) * this.tilesize, "The passage is blocked here. As builder, dig your way through.\n\nPoint mouse at block\n\nHOLD $RMB$");
	createSign(Vec2f(142, 50) * this.tilesize, "$Tree$\n\nChop down a tree\n\nHOLD $RMB$ and point at the tree.");
	createSign(Vec2f(156, 50) * this.tilesize, "$log$\n\nChop down logs\ninto WOOD $mat_wood$\n\nHOLD $RMB$ and point at log.");
	createSign(Vec2f(161, 50) * this.tilesize, "$ladder$\n\nSelect a ladder to build.\n\nHOLD $KEY_F$ (inventory key)\n\nPut cursor over ladder and release inventory key.\n\n(you need$mat_wood$for this)");
	createSign(Vec2f(163, 50) * this.tilesize, "Place by pointing with mouse and pressing $LMB$");
	createSign(Vec2f(178, 50) * this.tilesize, "$Pick$\n\nBuild a bridge.\n\n$KEY_F$   $Swap$$Help_Block1$\n\n\nAlso try out the different blocks and see what they do.");
	createSign(Vec2f(197, 49) * this.tilesize, "Please note that when building horizontally you will reach a limit. You will need to build support from below to continue.");
	createSign(Vec2f(200, 49) * this.tilesize, "$Pick$  $BlockStone$\n\nMine some stone $RMB$");
	createSign(Vec2f(229, 49) * this.tilesize, "$catapult$\n\n\nLoad the catapult with stone.\n\n HOLD $KEY_E$ PRESS $mat_stone$");
	createSign(Vec2f(233, 49) * this.tilesize, "$Tutorial_Catapult$\n\n\nStand in the gunner position\n(where $down_arrow$is on the picture)\n\nPress $KEY_S$ to get in.\n\n\nHOLD $LMB$ to charge.\n\n\n(Driver is in the center\nTop is bowl)");
	createSign(Vec2f(264, 44) * this.tilesize, "One last thing.\n\nWhen playing multiplayer don't be afraid to ask for help\n\n$KEY_ENTER$for chat.\n\n\nAlso use emotes!\n\nHOLD $KEY_Q$");
	createSign(Vec2f(277, 44) * this.tilesize, "This concludes the basic tutorials. You'll surely learn more as you play the game.\n\nNow try the other solo modes or join multiplayer!");
}

void onTick(CMap@ this)
{
	CRules@ rules = getRules();

	// server check

	if (getNet().isServer())
	{
		Vec2f endPoint = rules.get_Vec2f("endpoint");
		CBlob@[] blobsNearEnd;
		if (this.getBlobsInRadius(endPoint, 32.0f, @blobsNearEnd))
		{
			for (uint i = 0; i < blobsNearEnd.length; i++)
			{
				CBlob @b = blobsNearEnd[i];
				if (b.getPlayer() !is null && !b.hasTag("checkpoint"))
				{
					b.Tag("checkpoint");
					checkpointCount++;

					if (checkpointCount == rules.get_u8("team 0 count")) // all players
					{
						ExitToMenu();
					}
				}
			}
		}
	}
}

void onRender(CRules@ this)
{
	RenderEndmap(this);
}