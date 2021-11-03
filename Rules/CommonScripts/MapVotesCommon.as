//-- Written by Monkey_Feats 22/2/2020 --//
#include "LoaderColors.as";

const uint voteLockDuration = 3 * getTicksASecond();
const string voteEndTag = "mapvote: ended";
const string voteSelectMapTag = "mapvote: selectmap";
const string voteUnselectMapTag = "mapvote: unselectmap";
const string voteSyncTag = "mapvote: sync";
const string gameEndTimePointTag = "restart_rules_after_game";
const string gameRestartDelayTag = "restart_rules_after_game_time";
const string gameOverTimeTag = "game_over_time";

int ticksRemainingBeforeRestart()
{
	CRules@ rules = getRules();

	const int32 gameEndTimePoint = rules.get_s32(gameEndTimePointTag);

	return gameEndTimePoint - getGameTime();
}

int ticksSinceGameOver()
{
	CRules@ rules = getRules();
	return getGameTime() - rules.get_s32(gameOverTimeTag);
}

int ticksRemainingForMapVote()
{
	return ticksRemainingBeforeRestart() - voteLockDuration;
}

bool isMapVoteOver()
{
	return ticksRemainingForMapVote() <= 0;
}

class MapVotesMenu
{
	MapVoteButton@ button1;
	MapVoteButton@ button2;
	MapVoteButton@ button3;

	Vec2f topLeftCorner;
	Vec2f bottomRightCorner;
	Vec2f menuSize;

	bool isSetup;

	u16[] votes1;
	u16[] votes2;
	u16[] votes3;
	u8 mostVoted;
	u8 selectedOption;

	Random random;

	MapVoteButton@ getButton(uint index)
	{
		switch (index)
		{
		case 1: return @button1;
		case 2: return @button2;
		case 3: return @button3;
		}

		return null;
	}

	MapVotesMenu()
	{
		isSetup = false;

		@button1 = MapVoteButton(false);
		@button2 = MapVoteButton(true);
		@button3 = MapVoteButton(false);

		if (isServer())
		{
			random.Reset(Time());
		}
	}

	void ClearVotes()
	{
		votes1.clear();
		votes2.clear();
		votes3.clear();
		isSetup = false;
		selectedOption = 0;
	}

	void Refresh()
	{
		//Refresh textures and sizes
		RefreshButtons();

		//Refresh menu pos/size after getting button sizes
		Vec2f screenCenter = getDriver().getScreenDimensions()/2;
		topLeftCorner = Vec2f(screenCenter.x - menuSize.x / 2, 16);
		bottomRightCorner = Vec2f(screenCenter.x + menuSize.x / 2, 16 + menuSize.y);

		//Process button position relative to size
		for (uint i = 1; i <= 3; ++i)
		{
			MapVoteButton@ button = getButton(i);
			button.clickableOrigin.x += topLeftCorner.x;
			button.clickableOrigin.y += topLeftCorner.y + 30;

			button.clickableSize.y = menuSize.y - 30;

			button.previewOrigin =
				button.clickableOrigin + (Vec2f(button.clickableSize.x, menuSize.y - 80)) / 2 - button.previewSize / 2;
		}

		isSetup = true;
	}

	void RefreshButtons()
	{
		Vec2f ButtonSize;
		menuSize.x = 30;
		menuSize.y = 200;

		for (uint i = 1; i <= 3; ++i)
		{
			if (i == 2)
			{
				button2.RefreshRandomButton(menuSize.x, ButtonSize);
			}
			else
			{
				getButton(i).RefreshButton(menuSize.x, ButtonSize);
			}

			menuSize.x += ButtonSize.x + 30;
			menuSize.y = Maths::Max(ButtonSize.y + 128, menuSize.y);
		}
	}

	void Update(CControls@ controls, u8 &out newSelectedNum)
	{
		if (isMapVoteOver()) { return; }

		Vec2f mousepos = controls.getMouseScreenPos();
		const bool mousePressed = controls.isKeyPressed(KEY_LBUTTON);
		const bool mouseJustReleased = controls.isKeyJustReleased(KEY_LBUTTON);

		if (button1.isHovered(mousepos))
		{
			if (button1.State == ButtonStates::Selected) return;
			else if (button1.State == ButtonStates::None) {button1.State = ButtonStates::Hovered; Sound::Play("select.ogg");}

			if (mousePressed) button1.State = ButtonStates::Pressed;
			else if (mouseJustReleased)
			{
				newSelectedNum = 1;
				button1.State = ButtonStates::Selected;
				button2.State = button3.State = ButtonStates::None;
			}
		}
		else if (button2.isHovered(mousepos))
		{
			if (button2.State == ButtonStates::Selected) return;
			else if (button2.State == 0) {button2.State = ButtonStates::Hovered; Sound::Play("select.ogg");}

			if (mousePressed) button2.State = ButtonStates::Pressed;
			else if (mouseJustReleased)
			{
				newSelectedNum = 2;
				button2.State = ButtonStates::Selected;
				button1.State = button3.State = ButtonStates::None;
			}
		}
		else if (button3.isHovered(mousepos))
		{
			if (button3.State == ButtonStates::Selected) return;
			else if (button3.State == 0) { button3.State = ButtonStates::Hovered; Sound::Play("select.ogg"); }

			if (mousePressed) button3.State = ButtonStates::Pressed;
			else if (mouseJustReleased)
			{
				newSelectedNum = 3;
				button3.State = ButtonStates::Selected;
				button1.State = button2.State = ButtonStates::None;
			}
		}
		else
		{
			newSelectedNum = 0;
			button1.State = button1.State != ButtonStates::Selected ? ButtonStates::None : ButtonStates::Selected;
			button2.State = button2.State != ButtonStates::Selected ? ButtonStates::None : ButtonStates::Selected;
			button3.State = button3.State != ButtonStates::Selected ? ButtonStates::None : ButtonStates::Selected;
		}
	}

	void Randomize()
	{
		string map1name;
		string map3name;
		string mapcycle = sv_mapcycle;
		if (mapcycle == "")
		{
			string mode_name = sv_gamemode;
			if (mode_name == "Team Deathmatch") mode_name = "TDM";
			mapcycle =  "Rules/"+mode_name+"/mapcycle.cfg";
		}

		ConfigFile cfg;
		bool loaded = false;
		if (CFileMatcher(mapcycle).getFirst() == mapcycle && cfg.loadFile(mapcycle)) loaded = true;
		else if (cfg.loadFile(mapcycle)) loaded = true;
		if (!loaded) { warn( mapcycle+ " not found!"); return; }

		string[] map_names;
		if (cfg.readIntoArray_string(map_names, "mapcycle"))
		{
			const string currentMap = getMap().getMapName();
			const int currentMapNum = map_names.find(currentMap);

			int arrayleng = map_names.length();
			if (arrayleng > 4)
			{
				//remove the current map first
				if (currentMapNum != -1)
					map_names.removeAt(currentMapNum);

				if (map1name != currentMap)
				{ 	// remove the old button 1
					const int oldMap1Num = map_names.find(map1name);
					if (oldMap1Num != -1)
						map_names.removeAt(oldMap1Num);
				}
				else if (map3name != currentMap)
				{	// remove the old button 3
					const int oldMap3Num = map_names.find(map3name);
					if (oldMap3Num != -1)
						map_names.removeAt(oldMap3Num);
				}

				// random based on what's left
				map1name = map_names[random.NextRanged(map_names.length())];
				map_names.removeAt(map_names.find(map1name));
				map3name = map_names[random.NextRanged(map_names.length())];
			}
			else if (arrayleng >= 3)
			{
				//remove the current map
				if (currentMapNum != -1)
				map_names.removeAt(currentMapNum);
				// random based on what's left
				map1name = map_names[random.NextRanged(map_names.length())];
				map_names.removeAt(map_names.find(map1name));
				map3name = map_names[random.NextRanged(map_names.length())];
			}
			else if (arrayleng == 2)
			{
				map1name = map_names[0];
				map3name = map_names[1];
			}
			else //if (arrayleng <= 1)
			{
				LoadNextMap(); // we don't care about voting, get me out
			}

			//test to see if the map filename is inside parentheses and cut it out
			//incase someone wants to add map votes to a gamemode that loads maps via scripts, eg. Challenge/mapcycle.cfg
			string temptest = map1name.substr(map1name.length() - 1, map1name.length() - 1);
			if (temptest == ")")
			{
				string[] name = map1name.split(' (');
				string mapName = name[name.length() - 1];
				map1name = mapName.substr(0,mapName.length() - 1);
			}
			temptest = map3name.substr(map3name.length() - 1, map3name.length() - 1);
			if (temptest == ")")
			{
				string[] name = map1name.split(' (');
				string mapName = name[name.length() - 1];
				map3name = mapName.substr(0,mapName.length() - 1);
			}
		}

		button1.filename = map1name;
		button3.filename = map3name;
		button1.shortname = getFilenameWithoutExtension(getFilenameWithoutPath(button1.filename));
		button3.shortname = getFilenameWithoutExtension(getFilenameWithoutPath(button3.filename));
	}

	void Sync(CPlayer@ targetPlayer = null)
	{
		CRules@ rules = getRules();

		CBitStream params;
		params.write_string(button1.filename);
		params.write_string(button3.filename);
		params.write_string(button1.shortname);
		params.write_string(button3.shortname);
		params.write_u8(mostVoted);

		params.write_u8(votes1.length());
		params.write_u8(votes2.length());
		params.write_u8(votes3.length());

		for (uint i = 0; i < votes1.length(); i++)
		{ params.write_u16(votes1[i]); }
		for (uint i = 0; i < votes2.length(); i++)
		{ params.write_u16(votes2[i]); }
		for (uint i = 0; i < votes3.length(); i++)
		{ params.write_u16(votes3[i]); }

		if (targetPlayer is null)
		{
			// Send to everyone
			rules.SendCommand(rules.getCommandID(voteSyncTag), params);
		}
		else
		{
			rules.SendCommand(rules.getCommandID(voteSyncTag), params, @targetPlayer);
		}
	}

	void RenderGUI()
	{
		Vec2f ScreenDim = getDriver().getScreenDimensions();

		const bool shouldNag = selectedOption == 0 && !isMapVoteOver();

		if (shouldNag)
		{
			GUI::DrawRectangle(Vec2f_zero, ScreenDim, SColor(200, 0, 0, 0));
		}

		GUI::SetFont("menu");
		GUI::DrawFramedPane(topLeftCorner, bottomRightCorner);

		if (isMapVoteOver())
		{
			string winner = "";
			switch (mostVoted)
			{
				case 1: winner = button1.shortname; button1.State = ButtonStates::WonVote; break;
				case 3:	winner = button3.shortname; button3.State = ButtonStates::WonVote; break;
				default: winner = getTranslatedString("A Random Map"); button2.State = ButtonStates::WonVote; break;
			}
			string text = getTranslatedString("Map Voting Has Ended.. Loading: {MAP}").replace("{MAP}", winner);
		 	GUI::DrawText(text, topLeftCorner + Vec2f(22, 10), color_white);
		}
		else
		{
			string text = getTranslatedString("Map Voting Ends In: {TIME}").replace("{TIME}", "" + (ticksRemainingForMapVote() / getTicksASecond()));
		 	GUI::DrawText(text, topLeftCorner + Vec2f(22, 10), color_white);
		}

		for (uint i = 1; i <= 3; ++i)
		{
			MapVoteButton@ button = getButton(i);
			button.RenderGUI();
		}

		const Vec2f CountMid1 = button1.clickableOrigin+Vec2f(button1.clickableSize.x / 2, button1.clickableSize.y - 24.0f);
		const Vec2f CountMid2 = button2.clickableOrigin+Vec2f(button2.clickableSize.x / 2, button2.clickableSize.y - 24.0f);
		const Vec2f CountMid3 = button3.clickableOrigin+Vec2f(button3.clickableSize.x / 2, button3.clickableSize.y - 24.0f);

		GUI::SetFont("AveriaSerif-Bold_22");
		GUI::DrawTextCentered(""+votes1.length(), CountMid1, color_white);
		GUI::DrawTextCentered(""+votes2.length(), CountMid2, color_white);
		GUI::DrawTextCentered(""+votes3.length(), CountMid3, color_white);

		if (shouldNag)
		{
			GUI::DrawTextCentered(
				"Please vote for a map!",
				Vec2f(
					(topLeftCorner.x + bottomRightCorner.x) / 2,
					bottomRightCorner.y + 64 + Maths::Sin(getGameTime() * 0.1) * 8.0
				),
				color_white
			);
		}
	}

	void RenderRaw()
	{
		button1.RenderRaw();
		button2.RenderRaw();
		button3.RenderRaw();
	}

	void Render()
	{
		RenderGUI();
		RenderRaw();
	}
};

class MapVoteButton
{
	string filename;
	string shortname;
	string displayname;
	Vertex[] maptex_raw;
	Vec2f clickableOrigin, clickableSize;
	Vec2f previewOrigin, previewSize;
	int State;
	bool isRandomButton;

	MapVoteButton(bool _r)
	{
		State = 0;
		isRandomButton = _r;

		if (!isRandomButton)
		{
			maptex_raw.push_back(Vertex(0, 0, 0, 0, 0));
			maptex_raw.push_back(Vertex(1, 0, 0, 1, 0));
			maptex_raw.push_back(Vertex(1, 1, 0, 1, 1));
			maptex_raw.push_back(Vertex(0, 1, 0, 0, 1));
		}
	}

	void RefreshRandomButton( u16 MenuWidth, Vec2f &out ButtonSize)
	{
		State = 0;
		displayname = "Random Map";
		ButtonSize = clickableSize = previewSize = Vec2f(110,100);
		clickableOrigin.x = previewOrigin.x = MenuWidth;
		clickableOrigin.y = previewOrigin.y = 0.0f;
	}

	void RefreshButton( u16 MenuWidth, Vec2f &out ButtonSize)
	{
		State = 0;
		if (Texture::exists(shortname))
		{
			ImageData@ edit = Texture::data(shortname);

			const u16 mapW = edit.width();
			const u16 mapH = edit.height();

			clickableOrigin = Vec2f(MenuWidth, 0.0f);
			previewSize = Vec2f(mapW, mapH);

			// Expand frame if the name is too long
			Vec2f dim;
			displayname = shortname == "test.kaggen" ? "Generated Map" : shortname;
			GUI::SetFont("menu");
			GUI::GetTextDimensions(displayname, dim);

			clickableSize = previewSize;
			clickableSize.x = Maths::Max(dim.x, clickableSize.x);

			ButtonSize = clickableSize;

			maptex_raw[1].x = maptex_raw[2].x = mapW;
			maptex_raw[2].y = maptex_raw[3].y = mapH;
		}
	}

	bool isHovered(Vec2f mousepos)
	{
		Vec2f tl = clickableOrigin;
		Vec2f br = clickableOrigin + clickableSize;

		if (mousepos.x > tl.x && mousepos.y > tl.y &&
		     mousepos.x < br.x && mousepos.y < br.y)
		{
			return true;
		}
		return false;
	}

	void RenderGUI()
	{
		SColor col;
		switch (State)
		{
			case ButtonStates::Hovered: col = SColor(255, 220, 220, 220); break;
			case ButtonStates::Pressed: col = SColor(255, 200, 200, 200); break;
			case ButtonStates::Selected: col = SColor(255, 100, 255, 100); break;
			case ButtonStates::WonVote: col = SColor(255, 0, 255, 255); break;
			default: col = color_white;
		}

		const Vec2f Padding_outline = Vec2f(8,8);
		const Vec2f TL_outline = previewOrigin - Padding_outline;
		const Vec2f BR_outline = previewOrigin + previewSize + Padding_outline;
		const Vec2f Padding_window = Vec2f(4,4);
		const Vec2f TL_window = previewOrigin - Padding_window;
		const Vec2f BR_window = previewOrigin + previewSize + Padding_window;
		GUI::DrawPane(TL_outline, BR_outline, col);
		GUI::DrawWindow(TL_window, BR_window);

		const Vec2f NameMid = Vec2f(
			clickableOrigin.x + clickableSize.x / 2,
			clickableOrigin.y + clickableSize.y - 48
		);

		GUI::DrawTextCentered(displayname, NameMid, color_white);

		if (isRandomButton)
		{
			const Vec2f IconOffset = previewOrigin + Vec2f(24,20);
			GUI::DrawIcon( "InteractionIcons.png", 14, Vec2f(32,32), IconOffset, 1.0f, 2);
		}
	}

	void RenderRaw()
	{
		const u16[] square_IDs = {0,1,2,2,3,0};
		float[] model;

		Matrix::MakeIdentity(model);
		Matrix::SetTranslation(model, previewOrigin.x, previewOrigin.y, 0);
		Render::SetModelTransform(model);
		Render::RawTrianglesIndexed(shortname, maptex_raw, square_IDs);
	}
};

void CreateGenTexture(string shortname)
{
	if (!Texture::exists(shortname))
	{
		if (!Texture::createBySize(shortname, 150,100))
		{
			warn("texture creation failed");
		}
		else
		{
			ImageData@ edit = Texture::data(shortname);
			u16 mapW = edit.width();
			u16 mapH = edit.height();

			int Sine;
			for(int i = 0; i < edit.size(); i++)
			{
				edit[i] = SColor(0x00000000);
				int x = i%mapW;
				int y = i/mapW;

				Sine = Maths::Sin(x/8)*(2+XORRandom(2));

				if ( y+Sine < (mapH/2) )
				{
					edit[i] = colors::minimap_open;
					continue;
				}
				else if ( y+Sine > (mapH/2) )
				{
					edit[i] = colors::minimap_solid;
					continue;
				}
				else if ( y+Sine == (mapH/2) && x > 20 && x < mapW-20 )
				{
					edit[ i+(XORRandom(3)*mapW) ] = colors::minimap_solid;
				}
				else
				{
					edit[i] = colors::minimap_solid;
				}
			}

			if (!Texture::update(shortname, edit))
			{
				warn("texture update failed");
				return;
			}
		}
	}
}

void CreateMapTexture(string shortname, string filename)
{
	if (shortname == "test.kaggen")
	{
		CreateGenTexture(shortname);
		return;
	}

	if (!Texture::createFromFile(shortname, filename))
	{
		warn("texture creation failed, " + shortname + ", " + filename);
	}
	else
	{
		// a perfect minimap replication
		bool show_gold = getRules().get_bool("show_gold");
		ImageData@ edit = Texture::data(shortname);

		CFileImage image( CFileMatcher(filename).getFirst() );
		if (image.isLoaded())
		{
			const int h = image.getHeight();
			const int w = image.getWidth();
			while(image.nextPixel())
			{
				const int offset = image.getPixelOffset();
				const Vec2f pixelpos = image.getPixelPosition();

				const SColor PixelCol = image.readPixel();
				u8 tile = type(PixelCol, show_gold);
				SColor editcol = PixelCol;

				show_gold = true;

				///Colors
				const SColor color_minimap_open         (0xffA5BDC8);
				const SColor color_minimap_ground       (0xff844715);
				const SColor color_minimap_back         (0xff3B1406);
				const SColor color_minimap_stone        (0xff8B6849);
				const SColor color_minimap_thickstone   (0xff42484B);
				const SColor color_minimap_gold         (0xffFEA53D);
				const SColor color_minimap_bedrock      (0xff2D342D);
				const SColor color_minimap_wood         (0xffC48715);
				const SColor color_minimap_castle       (0xff637160);

				const SColor color_minimap_castle_back  (0xff313412);
				const SColor color_minimap_wood_back    (0xff552A11);

				const SColor color_minimap_water        (0xff2cafde);
				const SColor color_minimap_fire         (0xffd5543f);

				switch (PixelCol.color)
				{
					case map_colors::tile_ground:            editcol = color_minimap_ground; break;
					case map_colors::tile_ground_back:       editcol = color_minimap_back; break;
					case map_colors::tile_stone:             editcol = color_minimap_stone; break;
					case map_colors::tile_thickstone:        editcol = color_minimap_thickstone; break;
					case map_colors::tile_bedrock:           editcol = color_minimap_bedrock; break;
					case map_colors::tile_gold:              editcol = color_minimap_gold; break;
					case map_colors::tile_castle:            editcol = color_minimap_castle; break;
					case map_colors::tile_castle_back:       editcol = color_minimap_castle_back; break;
					case map_colors::tile_castle_moss:       editcol = color_minimap_castle; break; // TODO(hobey: moss
					case map_colors::tile_castle_back_moss:  editcol = color_minimap_castle_back; break; // TODO(hobey: moss
					case map_colors::tile_ladder:            editcol = color_minimap_open; break;
					case map_colors::tile_ladder_ground:     editcol = color_minimap_back; break;
					case map_colors::tile_ladder_castle:     editcol = color_minimap_castle_back; break;
					case map_colors::tile_ladder_wood:       editcol = color_minimap_wood_back; break;
					case map_colors::tile_grass:             editcol = color_minimap_open; break;
					case map_colors::tile_wood:              editcol = color_minimap_wood; break;
					case map_colors::tile_wood_back:         editcol = color_minimap_wood_back; break;
					case map_colors::water_air:              editcol = color_minimap_open; editcol = editcol.getInterpolated(color_minimap_water,0.5f); break;
					case map_colors::water_backdirt:         editcol = color_minimap_back; editcol = editcol.getInterpolated(color_minimap_water,0.5f); break;
					case map_colors::sky:                    editcol = color_minimap_open; break;
				}

				edit[offset] = editcol;
			}

			if (!Texture::update(shortname, edit))
			{
				warn("texture update failed, " + shortname + ", " + filename);
				return;
			}
		}
	}
}

SColor getMostLikelyCol(SColor tile_u, SColor tile_d, SColor tile_l, SColor tile_r, bool show_gold)
{
	if (type(tile_u, show_gold) != ColTileType::Sky)
	{
		const SColor[] neighborhood = { tile_u, tile_d, tile_l, tile_r };

		if ((neighborhood.find(map_colors::water_backdirt) != -1))
		{
			return map_colors::water_backdirt;
		}
		else if ((neighborhood.find(map_colors::water_air) != -1))
		{
			return map_colors::water_air;
		}
		else if ((neighborhood.find(map_colors::tile_castle) != -1) ||
		    (neighborhood.find(map_colors::tile_castle_back) != -1))
		{
			return map_colors::tile_castle_back;
		}
		else if ((neighborhood.find(map_colors::tile_wood) != -1) ||
		         (neighborhood.find(map_colors::tile_wood_back) != -1))
		{
			return map_colors::tile_wood_back;
		}
		else if ((neighborhood.find(map_colors::tile_ground) != -1) ||
		         (neighborhood.find(map_colors::tile_ground_back) != -1))
		{
			return map_colors::tile_ground_back;
		}
	}
	else if (type(tile_d, show_gold) != ColTileType::Solid && (tile_l == map_colors::tile_grass || tile_r == map_colors::tile_grass))
	{
		return map_colors::tile_grass;
	}

	return colors::minimap_open;
}

u8 type(SColor PixelCol, bool show_gold)
{
	switch (PixelCol.color)
	{
		case map_colors::tile_grass:
		case colors::map_skyblue:
		case colors::minimap_open:
		{
			 return ColTileType::Sky;
		}

		case colors::minimap_solid:
		case colors::minimap_gold_edge:
		case map_colors::tile_ground: //duplicate case colors::minimap_solid_edge:
		case map_colors::tile_stone:
		case map_colors::tile_thickstone:
		case map_colors::tile_bedrock:
		case map_colors::tile_castle:
		case map_colors::tile_castle_moss:
		case map_colors::tile_wood:
		{
			 return ColTileType::Solid;
		}

		case colors::minimap_gold_exposed:
		case colors::minimap_gold:
		//case colors::minimap_gold_edge:
		case map_colors::tile_gold:
		{
			 return show_gold ? ColTileType::Gold : ColTileType::Solid;
		}

		case colors::minimap_back:
		case colors::minimap_back_edge:
		case map_colors::tile_ground_back:
		case map_colors::tile_castle_back:
		case map_colors::tile_wood_back:
		case map_colors::tile_castle_back_moss:
		{
			 return ColTileType::Backwall;
		}

		case map_colors::water_air:
		case colors::interpolated_water_sky:
		{
			 return ColTileType::Sky_Water;
		}

		case map_colors::water_backdirt:
		case colors::interpolated_water_backwall:
		case colors::interpolated_water_backwall_edge:
		{
			 return ColTileType::Backwall_Water;
		}
	}
	return ColTileType::Other;
}

enum colors
{
	minimap_solid_edge   = 0xff844715,
	minimap_solid        = 0xffc4873a,
	minimap_back_edge    = 0xffc4873b, //yep, same as above *(almost, changed to prevent duplicate case)
	minimap_back         = 0xfff3ac5c,
	minimap_open         = 0xffedcca6,
	minimap_gold         = 0xffffbd34,
	minimap_gold_edge    = 0xffc56c22,
	minimap_gold_exposed = 0xfff0872c,
	minimap_water        = 0xff2cafde,
	minimap_fire         = 0xffd5543f,

	map_skyblue          = 0xffa5bdc8, //common blue sky colour used in map making

	interpolated_water_sky = 0xff8dbec2,
	interpolated_water_backwall_edge = 0xff789b8d,
	interpolated_water_backwall = 0xff90ae9d,

	menu_invisible_color = 0x00000000,
	menu_fadeout_color	   = 0xbe000000,

	red_color	   = 0xffff0000,
	green_color	   = 0xff00ff00,
	blue_color	   = 0xff0000ff
}

enum ColTileType
{
	Sky = 0,
	Sky_Water,
	Solid,
	Gold,
	Backwall,
	Backwall_Water,
	Other
};

enum ButtonStates
{
	None = 0,
	Hovered,
	Pressed,
	Selected,
	WonVote
};
