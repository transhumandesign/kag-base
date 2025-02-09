// DefaultGUI.as

void LoadDefaultGUI()
{
	if (v_driver > 0)
	{
		// add color tokens
		AddColorToken("$RED$", SColor(255, 105, 25, 5));
		AddColorToken("$GREEN$", SColor(255, 5, 105, 25));
		AddColorToken("$GREY$", SColor(255, 195, 195, 195));

		// add default icon tokens
		string interaction = "/GUI/InteractionIcons.png";
		AddIconToken("$NONE$", interaction, Vec2f(32, 32), 9);
		AddIconToken("$TIME$", interaction, Vec2f(32, 32), 0);
		AddIconToken("$COIN$", "Sprites/coins.png", Vec2f(16, 16), 1, Vec2f(0, -8));
		AddIconToken("$HEART$", "GUI/HeartNBubble.png", Vec2f(12, 12), 1);
		AddIconToken("$TEAMS$", "GUI/MenuItems.png", Vec2f(32, 32), 1);
		AddIconToken("$SPECTATOR$", "GUI/MenuItems.png", Vec2f(32, 32), 19);
		AddIconToken("$FLAG$", CFileMatcher("flag.png").getFirst(), Vec2f(32, 16), 0);
		AddIconToken("$DISABLED$", interaction, Vec2f(32, 32), 9, 1);
		AddIconToken("$CANCEL$", "GUI/MenuItems.png", Vec2f(32, 32), 29);
		AddIconToken("$RESEARCH$", interaction, Vec2f(32, 32), 27);
		AddIconToken("$ALERT$", interaction, Vec2f(32, 32), 10);
		AddIconToken("$down_arrow$", "GUI/ArrowDown.png", Vec2f(8, 8), 0);
		AddIconToken("$ATTACK_LEFT$", interaction, Vec2f(32, 32), 18, 1);
		AddIconToken("$ATTACK_RIGHT$", interaction, Vec2f(32, 32), 17, 1);
		AddIconToken("$ATTACK_THIS$", interaction, Vec2f(32, 32), 19, 1);
		AddIconToken("$DEFEND_LEFT$", interaction, Vec2f(32, 32), 18, 2);
		AddIconToken("$DEFEND_RIGHT$", interaction, Vec2f(32, 32), 17, 2);
		AddIconToken("$DEFEND_THIS$", interaction, Vec2f(32, 32), 19, 2);
		AddIconToken("$CLASSCHANGE$", "Rules/Tutorials/TutorialImages.png", Vec2f(32, 32), 7);
		AddIconToken("$BUILD$", interaction, Vec2f(32, 32), 15);
		AddIconToken("$STONE$", "Sprites/World.png", Vec2f(8, 8), 48);
		AddIconToken("$!!!$", "/Emoticons.png", Vec2f(22, 22), 48);

		// classes
		AddIconToken("$ARCHER$",        "ClassIcons.png",       Vec2f(16, 16), 2);
		AddIconToken("$KNIGHT$",        "ClassIcons.png",       Vec2f(16, 16), 1);
		AddIconToken("$BUILDER$",       "ClassIcons.png",       Vec2f(16, 16), 0);

		// blocks
		AddIconToken("$stone_block$", "Sprites/World.png", Vec2f(8, 8), CMap::tile_castle);
		AddIconToken("$back_stone_block$", "Sprites/World.png", Vec2f(8, 8), CMap::tile_castle_back);
		AddIconToken("$wood_block$", "Sprites/World.png", Vec2f(8, 8), CMap::tile_wood);
		AddIconToken("$back_wood_block$", "Sprites/World.png", Vec2f(8, 8), CMap::tile_wood_back);

		// SOURCE
		AddIconToken("$coin_slot$",     "CoinSlot.png",         Vec2f(16, 16), 3);
		AddIconToken("$lever$",         "Lever.png",            Vec2f(8, 16), 3);
		AddIconToken("$pressureplate$", "PressurePlate.png",    Vec2f(8, 16), 0);
		AddIconToken("$pushbutton$",    "PushButton.png",       Vec2f(8, 8), 3);

		// PASSIVE
		AddIconToken("$diode$",         "Diode.png",            Vec2f(8, 16), 3);
		AddIconToken("$elbow$",         "Elbow.png",            Vec2f(16, 16), 3);
		AddIconToken("$junction$",      "Junction.png",         Vec2f(16, 16), 3);
		AddIconToken("$inverter$",      "Inverter.png",         Vec2f(8, 16), 3);
		AddIconToken("$oscillator$",    "Oscillator.png",       Vec2f(8, 16), 7);
		AddIconToken("$magazine$",      "Magazine.png",         Vec2f(16, 16), 3);
		AddIconToken("$randomizer$",    "Randomizer.png",       Vec2f(8, 16), 7);
		AddIconToken("$resistor$",      "Resistor.png",         Vec2f(8, 16), 3);
		AddIconToken("$tee$",           "Tee.png",              Vec2f(16, 16), 3);
		AddIconToken("$toggle$",        "Toggle.png",           Vec2f(8, 16), 3);
		AddIconToken("$transistor$",    "Transistor.png",       Vec2f(16, 16), 3);
		AddIconToken("$wire$",          "Wire.png",             Vec2f(16, 16), 3);

		// LOAD
		AddIconToken("$bolter$",        "Bolter.png",           Vec2f(16, 16), 3);
		AddIconToken("$dispenser$",     "Dispenser.png",        Vec2f(16, 16), 3);
		AddIconToken("$lamp$",          "Lamp.png",             Vec2f(16, 16), 3);
		AddIconToken("$obstructor$",    "Obstructor.png",       Vec2f(8, 8), 0);
		AddIconToken("$spiker$",        "Spiker.png",           Vec2f(16, 16), 3);
		AddIconToken("$flamer$",        "Flamer.png",           Vec2f(16, 16), 3);

		// techs
		AddIconToken("$tech_stone$", "GUI/TechnologyIcons.png", Vec2f(16, 16), 16);

		// keys
		const Vec2f keyIconSize(16, 16);
		AddIconToken("$KEY_W$", "GUI/Keys.png", keyIconSize, 6);
		AddIconToken("$KEY_A$", "GUI/Keys.png", keyIconSize, 0);
		AddIconToken("$KEY_S$", "GUI/Keys.png", keyIconSize, 1);
		AddIconToken("$KEY_D$", "GUI/Keys.png", keyIconSize, 2);
		AddIconToken("$KEY_E$", "GUI/Keys.png", keyIconSize, 3);
		AddIconToken("$KEY_F$", "GUI/Keys.png", keyIconSize, 4);
		AddIconToken("$KEY_C$", "GUI/Keys.png", keyIconSize, 5);
		AddIconToken("$KEY_M$", "GUI/Keys.png", keyIconSize, 10);
		AddIconToken("$KEY_Q$", "GUI/Keys.png", keyIconSize, 7);
		AddIconToken("$LMB$", "GUI/Keys.png", keyIconSize, 8);
		AddIconToken("$RMB$", "GUI/Keys.png", keyIconSize, 9);
		AddIconToken("$KEY_SPACE$", "GUI/Keys.png", Vec2f(24, 16), 8);
		AddIconToken("$KEY_HOLD$", "GUI/Keys.png", Vec2f(24, 16), 9);
		AddIconToken("$KEY_TAP$", "GUI/Keys.png", Vec2f(24, 16), 10);
		AddIconToken("$KEY_F1$", "GUI/Keys.png", Vec2f(24, 16), 12);
		AddIconToken("$KEY_ESC$", "GUI/Keys.png", Vec2f(24, 16), 13);
		AddIconToken("$KEY_ENTER$", "GUI/Keys.png", Vec2f(24, 16), 14);

		// vehicles
		AddIconToken("$LoadAmmo$", interaction, Vec2f(16, 16), 7, 7);

		// indicators
		AddIconToken("$SmallIndicatorInactive$", "GUI/MenuItems.png", Vec2f(8, 8), 1*16+13);
		AddIconToken("$SmallIndicatorOn$", "GUI/MenuItems.png", Vec2f(8, 8), 1*16+14);
		AddIconToken("$SmallIndicatorOff$", "GUI/MenuItems.png", Vec2f(8, 8), 1*16+15);

		AddIconToken("$IndicatorInactive$", "GUI/MenuItems.png", Vec2f(16, 16), 10*8+1);
		AddIconToken("$IndicatorOff$", "GUI/MenuItems.png", Vec2f(16, 16), 11*8+0);
		AddIconToken("$IndicatorOn$", "GUI/MenuItems.png", Vec2f(16, 16), 11*8+1);
	}
}
