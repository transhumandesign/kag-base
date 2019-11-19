#include "Help.as"

#define CLIENT_ONLY

void onInit(CRules@ this)
{
	// knight
	AddIconToken("$Bomb$", "Entities/Characters/Knight/KnightIcons.png", Vec2f(16, 32), 0);
	AddIconToken("$WaterBomb$", "Entities/Characters/Knight/KnightIcons.png", Vec2f(16, 32), 2);
	AddIconToken("$Satchel$", "Entities/Characters/Knight/KnightIcons.png", Vec2f(16, 32), 3);
	AddIconToken("$Keg$", "Entities/Characters/Knight/KnightIcons.png", Vec2f(16, 32), 4);
	AddIconToken("$Help_Bomb1$", "Entities/Common/GUI/HelpIcons.png", Vec2f(8, 16), 30);
	AddIconToken("$Help_Bomb2$", "Entities/Common/GUI/HelpIcons.png", Vec2f(8, 16), 31);
	AddIconToken("$Swap$", "Entities/Common/GUI/HelpIcons.png", Vec2f(16, 16), 7);
	AddIconToken("$Jab$", "Entities/Common/GUI/HelpIcons.png", Vec2f(16, 16), 20);
	AddIconToken("$Slash$", "Entities/Common/GUI/HelpIcons.png", Vec2f(16, 16), 21);
	AddIconToken("$Shield$", "Entities/Common/GUI/HelpIcons.png", Vec2f(16, 16), 22);
	// archer
	AddIconToken("$Arrow$", "Entities/Characters/Archer/ArcherIcons.png", Vec2f(16, 32), 0);
	AddIconToken("$WaterArrow$", "Entities/Characters/Archer/ArcherIcons.png", Vec2f(16, 32), 1);
	AddIconToken("$FireArrow$", "Entities/Characters/Archer/ArcherIcons.png", Vec2f(16, 32), 2);
	AddIconToken("$BombArrow$", "Entities/Characters/Archer/ArcherIcons.png", Vec2f(16, 32), 3);
	AddIconToken("$Daggar$", "Entities/Common/GUI/HelpIcons.png", Vec2f(16, 16), 10);
	AddIconToken("$Help_Arrow1$", "Entities/Common/GUI/HelpIcons.png", Vec2f(8, 16), 28);
	AddIconToken("$Help_Arrow2$", "Entities/Common/GUI/HelpIcons.png", Vec2f(8, 16), 29);
	AddIconToken("$Swap$", "Entities/Common/GUI/HelpIcons.png", Vec2f(16, 16), 7);
	AddIconToken("$Grapple$", "Entities/Common/GUI/HelpIcons.png", Vec2f(16, 16), 16);
	// builder
	AddIconToken("$Build$", "Entities/Common/GUI/HelpIcons.png", Vec2f(16, 16), 11);
	AddIconToken("$Pick$", "Entities/Common/GUI/HelpIcons.png", Vec2f(16, 16), 12);
	AddIconToken("$Rotate$", "Entities/Common/GUI/HelpIcons.png", Vec2f(16, 16), 5);
	AddIconToken("$Help_Block1$", "Entities/Common/GUI/HelpIcons.png", Vec2f(8, 16), 12);
	AddIconToken("$Help_Block2$", "Entities/Common/GUI/HelpIcons.png", Vec2f(8, 16), 13);
	AddIconToken("$Swap$", "Entities/Common/GUI/HelpIcons.png", Vec2f(16, 16), 7);
	AddIconToken("$BlockStone$", "Sprites/world.png", Vec2f(8, 8), 96);

	AddIconToken("$workshop$", "Entities/Common/GUI/HelpIcons.png", Vec2f(16, 16), 2);
}

void onBlobCreated(CRules@ this, CBlob@ blob)
{
	if (!u_showtutorial)
		return;

	const string name = blob.getName();

	if (blob.hasTag("seats") && !blob.hasTag("animal"))
	{
		SetHelp(blob, "help hop", "", getTranslatedString(" $down_arrow$ Hop inside  $KEY_S$"), "", 5);
		SetHelp(blob, "help hop out", "", getTranslatedString(" Get out  $KEY_W$"), "", 4);
	}
	if (blob.hasTag("trader"))
	{
		SetHelp(blob, "help use", "", getTranslatedString("$trader$ Buy    $KEY_E$"), "", 3);
	}
	if (blob.hasTag("respawn"))
	{
		SetHelp(blob, "help use", "", getTranslatedString("$CLASSCHANGE$ Change class    $KEY_E$"), "", 3);
	}
	if (blob.hasTag("door"))
	{
		SetHelp(blob, "help rotate", "", getTranslatedString("${ITEM}$ $Rotate$ Rotate    $KEY_SPACE$").replace("{ITEM}", blob.getName()), "", 3);
	}

	switch (name.getHash())
	{
		case -792805582: // hall
		{
			SetHelp(blob, "help use", "", getTranslatedString("$CLASSCHANGE$ Change class    $KEY_E$"), "", 5);
		}
		break;

		case 916369496: // trap_block
		{
			SetHelp(blob, "help show", "builder", getTranslatedString("$trap_block$ Opens on enemy"), "", 15);
		}
		break;

		case 439106706: // spikes
		{
			SetHelp(blob, "help show", "builder", getTranslatedString("$spikes$ Retracts on enemy if on stone $STONE$"), "", 20);
		}

		case 804095823: // wooden_platform
		{
			SetHelp(blob, "help rotate", "", getTranslatedString("$wooden_platform$  $Rotate$ Rotate    $KEY_SPACE$"), "", 3);
		}

		case 6339497: // ladder
		{
			SetHelp(blob, "help rotate", "", getTranslatedString("$ladder$  $Rotate$ Rotate    $KEY_SPACE$"), "", 3);
		}

		case -1172577820: // tdm_ruins
		{
			SetHelp(blob, "help use", "", getTranslatedString("Change class    $KEY_E$"), "", 5);
		}

		case -1469294289: // lantern
		{
			SetHelp(blob, "help activate", "", getTranslatedString("$lantern$ On/Off     $KEY_SPACE$"), "");
			SetHelp(blob, "help pickup", "", getTranslatedString("$lantern$ Pick up    $KEY_C$"));
		}

		case -863144459: // satchel
		{
			SetHelp(blob, "help activate", "knight", getTranslatedString("$satchel$ Light     $KEY_SPACE$"), getTranslatedString("$satchel$ Only KNIGHT can light satchel"), 3);
			SetHelp(blob, "help throw", "knight", getTranslatedString("$satchel$ THROW!    $KEY_SPACE$"), "", 3);
		}

		case 1062293841: // log
		{
			SetHelp(blob, "help action2", "builder", getTranslatedString("$log$ Chop $mat_wood$   $RMB$"), "", 3);
		}

		case 2115365646: // keg
		{
			SetHelp(blob, "help pickup", "", getTranslatedString("$keg$Pick up    $KEY_C$"), "", 3);
			SetHelp(blob, "help activate", "knight", getTranslatedString("$keg$Light    $KEY_SPACE$"), getTranslatedString("$keg$Only KNIGHT can light keg"), 5);
			SetHelp(blob, "help throw", "", getTranslatedString("$keg$THROW!    $KEY_SPACE$"), "", 3);
		}

		case -895937135: // bomb
		{
			SetHelp(blob, "help throw", "", getTranslatedString("$mat_bombs$THROW!    $KEY_SPACE$"), "", 3);
		}

		case 392075840: // crate
		{
			SetHelp(blob, "help pickup", "", getTranslatedString("$crate$Pick up    $KEY_C$"), "", 3);
		}

		case 1106789566: // workbench
		{
			SetHelp(blob, "help use", "", getTranslatedString("$workbench$    $KEY_TAP$$KEY_E$"), "", 4);
		}

		case 1898442385: // catapult
		case -258437141: // ballista
		{
			SetHelp(blob, "help DRIVER movement", "", getTranslatedString("${VEHICLE}$Drive     $KEY_A$ $KEY_S$ $KEY_D$").replace("{VEHICLE}", blob.getName()), "", 3);
			SetHelp(blob, "help GUNNER action", "", getTranslatedString("${VEHICLE}$FIRE     $KEY_HOLD$$LMB$").replace("{VEHICLE}", blob.getName()), "", 3);
		}

		case -1071691608: // mounted_bow
		{
			SetHelp(blob, "help GUNNER action", "", getTranslatedString("${VEHICLE}$FIRE     $LMB$").replace("{VEHICLE}", blob.getName()), "", 3);
		}

		case 1028682697: // food
		{
			SetHelp(blob, "help switch", "", getTranslatedString("$food$Take out food  $KEY_HOLD$$KEY_F$"), "", 3);
		}

		case -951587406: // boulder
		{
			SetHelp(blob, "help pickup", "", getTranslatedString("$boulder$ Pick up    $KEY_C$"));
		}

		case 954139509: // building
		{
			SetHelp(blob, "help use", "", getTranslatedString("$building$Construct    $KEY_E$"), "", 3);
		}

		case -1441575328: // tent
		{
			SetHelp( blob, "help use", "", "Change class $KEY_E$", "", 5 );
		}

		case -157922210: // archershop
		case -1425345689: // boatshop
		case 391074896: // knightshop
		case -1716664852: // buildershop
		case -1501035293: // vehicleshop
		{
			SetHelp(blob, "help use", "", getTranslatedString("$building$ Press $KEY_E$"), "", 3);
		}

		case -1413381533: // ctf_flag
		{
			SetHelp( blob, "help use", "", "$ctf_flag$ Bring enemy flag to our flag to capture it", "", 5 );
		}

	}
}
