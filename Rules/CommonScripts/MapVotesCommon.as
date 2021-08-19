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
	// TODO(hobey): cleanup: make all the 1234 things arrays for readability and to reduce copy-paste error-proneness
	MapVoteButton@ button1;
	MapVoteButton@ button2;
	MapVoteButton@ button3;
	MapVoteButton@ button4;

	Vec2f topLeftCorner;
	Vec2f bottomRightCorner;
	Vec2f menuSize;

	bool isSetup;

	u16[] votes1;
	u16[] votes2;
	u16[] votes3;
	u16[] votes4;
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
		case 4: return @button4;
		}

		return null;
	}

	MapVotesMenu()
	{
		isSetup = false;

		@button1 = MapVoteButton(false);
		@button2 = MapVoteButton(false);
		@button3 = MapVoteButton(false);
		@button4 = MapVoteButton(false);

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
		votes4.clear();
		isSetup = false;
		selectedOption = 0;
	}

	void Refresh()
	{
		//Refresh textures and sizes
		RefreshButtons();

		//Refresh menu pos/size after getting button sizes
		Vec2f screenDims = getDriver().getScreenDimensions();
		topLeftCorner = Vec2f(screenDims.x - menuSize.x - 16, 16);
		bottomRightCorner = Vec2f(screenDims.x - 16, 16 + menuSize.y);

		//Process button position relative to size
		for (uint i = 1; i <= 4; ++i)
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

		for (uint i = 1; i <= 4; ++i)
		{
			getButton(i).RefreshButton(menuSize.x, ButtonSize);

			menuSize.x += ButtonSize.x + 30;
			menuSize.y = Maths::Max(ButtonSize.y + 128, menuSize.y);
		}
	}

	void Update(CControls@ controls, u8 &out newSelectedNum)
	{
		newSelectedNum = 0;
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
				button2.State = button3.State = button4.State = ButtonStates::None;
			}
		}
		else if (button2.isHovered(mousepos))
		{
			if (button2.State == ButtonStates::Selected) return;
			else if (button2.State == ButtonStates::None) {button2.State = ButtonStates::Hovered; Sound::Play("select.ogg");}

			if (mousePressed) button2.State = ButtonStates::Pressed;
			else if (mouseJustReleased)
			{
				newSelectedNum = 2;
				button2.State = ButtonStates::Selected;
				button1.State = button3.State = button4.State = ButtonStates::None;
			}
		}
		else if (button3.isHovered(mousepos))
		{
			if (button3.State == ButtonStates::Selected) return;
			else if (button3.State == ButtonStates::None) { button3.State = ButtonStates::Hovered; Sound::Play("select.ogg"); }

			if (mousePressed) button3.State = ButtonStates::Pressed;
			else if (mouseJustReleased)
			{
				newSelectedNum = 3;
				button3.State = ButtonStates::Selected;
				button1.State = button2.State = button4.State = ButtonStates::None;
			}
		}
		else if (button4.isHovered(mousepos))
		{
			if (button4.State == ButtonStates::Selected) return;
			else if (button4.State == ButtonStates::None) { button4.State = ButtonStates::Hovered; Sound::Play("select.ogg"); }

			if (mousePressed) button4.State = ButtonStates::Pressed;
			else if (mouseJustReleased)
			{
				newSelectedNum = 4;
				button4.State = ButtonStates::Selected;
				button1.State = button2.State = button3.State = ButtonStates::None;
			}
		}
		else
		{
			newSelectedNum = 0;
			button1.State = button1.State != ButtonStates::Selected ? ButtonStates::None : ButtonStates::Selected;
			button2.State = button2.State != ButtonStates::Selected ? ButtonStates::None : ButtonStates::Selected;
			button3.State = button3.State != ButtonStates::Selected ? ButtonStates::None : ButtonStates::Selected;
			button4.State = button4.State != ButtonStates::Selected ? ButtonStates::None : ButtonStates::Selected;
		}
	}

	void Randomize()
	{
		string map1name;
		string map2name;
		string map3name;
		string map4name;
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
			if (arrayleng > 8)
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
				if (map2name != currentMap)
				{   // remove the old button 2
					const int oldMap2Num = map_names.find(map2name);
					if (oldMap2Num != -1)
						map_names.removeAt(oldMap2Num);
				}
				else if (map3name != currentMap)
				{	// remove the old button 3
					const int oldMap3Num = map_names.find(map3name);
					if (oldMap3Num != -1)
						map_names.removeAt(oldMap3Num);
				}
				else if (map4name != currentMap)
				{   // remove the old button 4
					const int oldMap4Num = map_names.find(map4name);
					if (oldMap4Num != -1)
						map_names.removeAt(oldMap4Num);
				}

				// random based on what's left
				map1name = map_names[random.NextRanged(map_names.length())]; map_names.removeAt(map_names.find(map1name));
				map2name = map_names[random.NextRanged(map_names.length())]; map_names.removeAt(map_names.find(map2name));
				map3name = map_names[random.NextRanged(map_names.length())]; map_names.removeAt(map_names.find(map3name));
				map4name = map_names[random.NextRanged(map_names.length())];
			}
			else if (arrayleng >= 5)
			{
				//remove the current map
				if (currentMapNum != -1)
				map_names.removeAt(currentMapNum);
				// random based on what's left
				map1name = map_names[random.NextRanged(map_names.length())]; map_names.removeAt(map_names.find(map1name));
				map2name = map_names[random.NextRanged(map_names.length())]; map_names.removeAt(map_names.find(map2name));
				map3name = map_names[random.NextRanged(map_names.length())]; map_names.removeAt(map_names.find(map3name));
				map4name = map_names[random.NextRanged(map_names.length())];
			}
			else if (arrayleng == 4)
			{
				map1name = map_names[0];
				map2name = map_names[1];
				map3name = map_names[2];
				map4name = map_names[3];
			}
			else //if (arrayleng <= 1) // TODO(hobey): make a vote between only 2 or 3 in this case if the mapcycle only has 2 or 3 maps?
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
			temptest = map2name.substr(map2name.length() - 1, map3name.length() - 1);
			if (temptest == ")")
			{
				string[] name = map2name.split(' (');
				string mapName = name[name.length() - 1];
				map2name = mapName.substr(0,mapName.length() - 1);
			}
			temptest = map3name.substr(map3name.length() - 1, map3name.length() - 1);
			if (temptest == ")")
			{
				string[] name = map3name.split(' (');
				string mapName = name[name.length() - 1];
				map3name = mapName.substr(0,mapName.length() - 1);
			}
			temptest = map4name.substr(map4name.length() - 1, map3name.length() - 1);
			if (temptest == ")")
			{
				string[] name = map4name.split(' (');
				string mapName = name[name.length() - 1];
				map4name = mapName.substr(0,mapName.length() - 1);
			}
			
		}

		button1.filename = map1name;
		button2.filename = map2name;
		button3.filename = map3name;
		button4.filename = map4name;
		button1.shortname = getFilenameWithoutExtension(getFilenameWithoutPath(button1.filename));
		button2.shortname = getFilenameWithoutExtension(getFilenameWithoutPath(button2.filename));
		button3.shortname = getFilenameWithoutExtension(getFilenameWithoutPath(button3.filename));
		button4.shortname = getFilenameWithoutExtension(getFilenameWithoutPath(button4.filename));
	}

	void Sync(CPlayer@ targetPlayer = null)
	{
		CRules@ rules = getRules();

		CBitStream params;
		params.write_string(button1.filename);
		params.write_string(button2.filename);
		params.write_string(button3.filename);
		params.write_string(button4.filename);
		params.write_string(button1.shortname);
		params.write_string(button2.shortname);
		params.write_string(button3.shortname);
		params.write_string(button4.shortname);
		params.write_u8(mostVoted);
		// params.write_bool(was_a_tie);

		params.write_u8(votes1.length());
		params.write_u8(votes2.length());
		params.write_u8(votes3.length());
		params.write_u8(votes4.length());

		for (uint i = 0; i < votes1.length(); i++)
		{ params.write_u16(votes1[i]); }
		for (uint i = 0; i < votes2.length(); i++)
		{ params.write_u16(votes2[i]); }
		for (uint i = 0; i < votes3.length(); i++)
		{ params.write_u16(votes3[i]); }
		for (uint i = 0; i < votes4.length(); i++)
		{ params.write_u16(votes4[i]); }

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
			GUI::DrawRectangle(Vec2f_zero, ScreenDim, SColor(50, 0, 0, 0));
		}

		GUI::SetFont("menu");
		GUI::DrawFramedPane(topLeftCorner, bottomRightCorner);

		if (isMapVoteOver())
		{
			string winner = "";
			switch (mostVoted)
			{
				case 1: winner = button1.shortname; button1.State = ButtonStates::WonVote; break;
				case 2: winner = button2.shortname; button2.State = ButtonStates::WonVote; break;
				case 3: winner = button3.shortname; button3.State = ButtonStates::WonVote; break;
				case 4: winner = button4.shortname; button4.State = ButtonStates::WonVote; break;

				// NOTE(hobey): should never happen; fall back to first map
				default: winner = button1.shortname; button1.State = ButtonStates::WonVote; break;

				// default: winner = "One of the most voted maps... "; break;
			}
			GUI::DrawText("Map Voting Has Ended.. Loading: "+ winner, topLeftCorner+Vec2f(22,10), color_white);
		}
		else
		{
			GUI::DrawText(
				"Map Voting Ends In: " + ticksRemainingForMapVote() / getTicksASecond(),
				topLeftCorner+Vec2f(22,10),
				color_white
			);
		}

		for (uint i = 1; i <= 4; ++i)
		{
			MapVoteButton@ button = getButton(i);
			button.RenderGUI();
		}

		const Vec2f CountMid1 = button1.clickableOrigin+Vec2f(button1.clickableSize.x / 2, button1.clickableSize.y - 24.0f);
		const Vec2f CountMid2 = button2.clickableOrigin+Vec2f(button2.clickableSize.x / 2, button2.clickableSize.y - 24.0f);
		const Vec2f CountMid3 = button3.clickableOrigin+Vec2f(button3.clickableSize.x / 2, button3.clickableSize.y - 24.0f);
		const Vec2f CountMid4 = button4.clickableOrigin+Vec2f(button4.clickableSize.x / 2, button4.clickableSize.y - 24.0f);

		GUI::SetFont("AveriaSerif-Bold_22");
		GUI::DrawTextCentered(""+votes1.length(), CountMid1, color_white);
		GUI::DrawTextCentered(""+votes2.length(), CountMid2, color_white);
		GUI::DrawTextCentered(""+votes3.length(), CountMid3, color_white);
		GUI::DrawTextCentered(""+votes4.length(), CountMid4, color_white);

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
		button4.RenderRaw();
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
	if(!Texture::exists(shortname))
	{
		if(!Texture::createBySize(shortname, 150,100))
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

			if(!Texture::update(shortname, edit))
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

	if(!Texture::createFromFile(shortname, filename))
	{
		warn("texture creation failed");
	}
	else
	{
		// a perfect minimap replication
		const bool show_gold = getRules().get_bool("show_gold");
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
				const SColor PixelCol_u = edit.get(pixelpos.x, Maths::Min(pixelpos.y-1, h));
				const SColor PixelCol_d = edit.get(pixelpos.x, Maths::Max(pixelpos.y+1, 0));
				const SColor PixelCol_r = edit.get(Maths::Min(pixelpos.x+1, w), pixelpos.y);
				const SColor PixelCol_l = edit.get(Maths::Max(pixelpos.x-1, 0), pixelpos.y);

				u8 tile = type(PixelCol, show_gold);
				u8 tile_u = type(PixelCol_u, show_gold);
				u8 tile_l = type(PixelCol_l, show_gold);
				u8 tile_r = type(PixelCol_r, show_gold);
				u8 tile_d = type(PixelCol_d, show_gold);

				SColor editcol = PixelCol;

				if (tile == ColTileType::Other)
				{
					SColor mostlike = getMostLikelyCol(PixelCol_u, PixelCol_d, PixelCol_l, PixelCol_r, show_gold);
					tile = type(mostlike, show_gold);
				}

				if (tile == ColTileType::Solid)
    			{
    				//Foreground
					editcol = colors::minimap_solid;

					//Edge
					if ( (tile_u != ColTileType::Solid && tile_u != ColTileType::Gold) || (tile_d != ColTileType::Solid && tile_d != ColTileType::Gold) ||
						 (tile_l != ColTileType::Solid && tile_l != ColTileType::Gold) || (tile_r != ColTileType::Solid && tile_r != ColTileType::Gold) )
					{
						editcol = colors::minimap_solid_edge;
					}
					else if (tile_u == ColTileType::Gold || tile_d == ColTileType::Gold || tile_l == ColTileType::Gold || tile_r == ColTileType::Gold)
					{
						editcol = colors::minimap_gold_edge;
					}
				}
				else if ( tile == ColTileType::Backwall && PixelCol != SColor(map_colors::tile_grass) )
				{
					//Background
					editcol = colors::minimap_back;

					//Edge
					if ( tile_u == ColTileType::Sky || tile_d == ColTileType::Sky || tile_l == ColTileType::Sky || tile_r == ColTileType::Sky ||
						 tile_u == ColTileType::Sky_Water || tile_d == ColTileType::Sky_Water || tile_l == ColTileType::Sky_Water || tile_r == ColTileType::Sky_Water )
					{
						editcol = colors::minimap_back_edge;
					}
				}
				else if (tile == ColTileType::Gold)
				{
					//Gold
					editcol = colors::minimap_gold;

					//Edge
					if ( (tile_u != ColTileType::Solid && tile_u != ColTileType::Gold) || (tile_d != ColTileType::Solid && tile_d != ColTileType::Gold) ||
						 (tile_l != ColTileType::Solid && tile_l != ColTileType::Gold) || (tile_r != ColTileType::Solid && tile_r != ColTileType::Gold) )
					{
						editcol = colors::minimap_gold_exposed;
					}
				}
				else if ( tile == ColTileType::Backwall_Water )
				{
					//Background
					editcol = colors::interpolated_water_backwall;

					//Edge
					if ( tile_u == ColTileType::Sky || tile_d == ColTileType::Sky || tile_l == ColTileType::Sky || tile_r == ColTileType::Sky ||
						 tile_u == ColTileType::Sky_Water || tile_d == ColTileType::Sky_Water || tile_l == ColTileType::Sky_Water || tile_r == ColTileType::Sky_Water )
					{
						editcol = colors::interpolated_water_backwall_edge;
					}
				}
				else if (tile == ColTileType::Sky_Water)
				{   //Sky
					editcol = colors::interpolated_water_sky;
				}
				else
				{   //Sky
					editcol = colors::minimap_open;
				}

				edit[offset] = editcol;
			}

			if(!Texture::update(shortname, edit))
			{
				warn("texture update failed");
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
