//-- Written by Monkey_Feats 22/2/2020 --//
#include "LoaderColors.as";

const uint voteWaitDuration = 5 * getTicksASecond();
const uint voteLockDuration = 3 * getTicksASecond();

// client->server request
const string voteRequestSelectMapTag = "mapvote: requestselectmap";
const string voteRequestUnselectMapTag = "mapvote: requestunselectmap";

// server->client info
const string voteInfoSelectMapTag = "mapvote: infoselectmap";
const string voteInfoUnselectMapTag = "mapvote: infounselectmap";
const string voteInfoWonMapTag = "mapvote: infowonmaptag";

// server->client sync
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

bool isMapVoteVisible()
{
	return ticksSinceGameOver() >= voteWaitDuration;
}

class MapVotesMenu
{
	MapVoteButton@[] buttons;
	MapImageVoteButton@[] imageButtons;

	Vec2f topLeftCorner;
	Vec2f bottomRightCorner;
	Vec2f menuSize;

	bool isSetup;

	u16[][] votes;
	u8 mostVoted;
	u8 selectedOption;

	Random random;

	MapVotesMenu()
	{
		isSetup = false;

		// HACK: makes it easier to figure out what needs to be attributed
		// random maps later on, but really should be figured out from the
		// button list or shouldn't be our responsibility
		imageButtons.resize(3);
		@imageButtons[0] = MapImageVoteButton();
		@imageButtons[1] = MapImageVoteButton();
		@imageButtons[2] = MapImageVoteButton();

		buttons.resize(3);
		@buttons[0] = @imageButtons[0];
		@buttons[1] = @imageButtons[1];
		@buttons[2] = @imageButtons[2];
		//@buttons[3] = MapRandomVoteButton();

		if (isServer())
		{
			random.Reset(Time());
		}

		ClearVotes();
	}

	// Returns the most voted option.
	// If there are several buttons with the highest count: Choose any of them
	// e.g. in the corner case of map1 with 5 votes and random with 5 votes,
	// we have a 50-50 chance of picking map1 and of picking a random map
	// Maybe we should select the random option instead but i don't think
	// i actually care enough
	u8 selectMostVoted()
	{
		u8[] mostVotedIdx;
		uint mostVotedCount = 0;

		for (int i = 0; i < votes.size(); ++i)
		{
			uint currentVoteCount = votes[i].size();
			if (currentVoteCount > mostVotedCount)
			{
				mostVotedIdx.clear();
				mostVotedIdx.push_back(i);
				mostVotedCount = currentVoteCount;
			}
			else if (currentVoteCount == mostVotedCount)
			{
				// note this codepath may be reached if we didn't encounter a
				// vote > 0, which is ok
				mostVotedIdx.push_back(i);
			}
		}

		return mostVotedIdx[XORRandom(mostVotedIdx.size())];
	}

	MapVoteButton@ getButton(uint index)
	{
		if (index >= buttons.size()) { return null; }
		return buttons[index];
	}

	bool screenPositionOverlaps(Vec2f pos)
	{
		return pos.x >= topLeftCorner.x
		    && pos.y >= topLeftCorner.y
			&& pos.x < bottomRightCorner.x
			&& pos.y < bottomRightCorner.y; 
	}

	void ClearVotes()
	{
		votes.clear();
		votes.resize(buttons.size());
		isSetup = false;
		selectedOption = 255;
	}

	void RemoveVotesFrom(u16 netid)
	{
		if (isMapVoteOver())
		{
			return;
		}

		for (int i = 0; i < votes.length; ++i)
		{
			int netid_idx = votes[i].find(netid);
			if (netid_idx != -1)
			{
				votes[i].removeAt(netid_idx);
			}
		}
	}

	void Refresh()
	{
		//Refresh textures and sizes
		RefreshButtons();

		//Refresh menu pos/size after getting button sizes
		Vec2f screenCenter = getDriver().getScreenDimensions()/2;
		topLeftCorner = Vec2f(screenCenter.x - menuSize.x / 2, -8);
		bottomRightCorner = Vec2f(screenCenter.x + menuSize.x / 2, -8 + menuSize.y);

		//Process button position relative to size
		for (uint i = 0; i < buttons.size(); ++i)
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

		for (uint i = 0; i < buttons.size(); ++i)
		{
			getButton(i).RefreshButton(menuSize.x, ButtonSize);

			menuSize.x += ButtonSize.x + 30;
			menuSize.y = Maths::Max(ButtonSize.y + 128, menuSize.y);
		}
	}

	void Update(CControls@ controls, u8 &out newSelectedNum)
	{
		newSelectedNum = 255;
		if (isMapVoteOver() || !isMapVoteVisible()) { return; }

		if (isClient())
		{
			Vec2f mousepos = controls.getMouseScreenPos();
			const bool mousePressed = controls.isKeyPressed(KEY_LBUTTON);
			const bool mouseJustReleased = controls.isKeyJustReleased(KEY_LBUTTON);

			for (uint i = 0; i < buttons.size(); ++i)
			{
				MapVoteButton@ button = @getButton(i);

				if (button.isHovered(mousepos))
				{
					if (button.state == ButtonStates::Selected)
					{
						continue;
					}

					if (button.state == ButtonStates::None)
					{
						button.state = ButtonStates::Hovered;
						Sound::Play("select.ogg");
					}

					if (mousePressed)
					{
						button.state = ButtonStates::Pressed;
					}
					else if (mouseJustReleased)
					{
						newSelectedNum = i;
						button.state = ButtonStates::Selected;

						// unselect rest
						for (uint j = 0; j < buttons.size(); ++j)
						{
							// don't unselect self
							if (i == j) { continue; }

							getButton(j).state = ButtonStates::None;
						}
					}
				}
				else
				{
					if (button.state != ButtonStates::Selected)
					{
						button.state = ButtonStates::None;
					}
				}
			}
		}
	}

	void Randomize()
	{
		string[] randomNames;

		string mapcycle = sv_mapcycle;
		if (mapcycle == "")
		{
			// FIXME: ???
			string mode_name = sv_gamemode;
			if (mode_name == "Team Deathmatch") mode_name = "TDM";
			mapcycle =  "Rules/"+mode_name+"/mapcycle.cfg";
		}

		ConfigFile cfg;
		bool loaded = false;
		if (CFileMatcher(mapcycle).getFirst() == mapcycle && cfg.loadFile(mapcycle)) loaded = true;
		else if (cfg.loadFile(mapcycle)) loaded = true;
		if (!loaded)
		{
			warn(mapcycle + " not found!");
			return;
		}

		string[] map_names;
		if (cfg.readIntoArray_string(map_names, "mapcycle"))
		{
			const string currentMap = getMap().getMapName();
			const int currentMapNum = map_names.find(currentMap);

			int availableMapCount = map_names.size();

			if (availableMapCount > imageButtons.size())
			{
				// remove current map from next map list
				if (currentMapNum != -1)
				{
					map_names.removeAt(currentMapNum);
				}
			}

			if (availableMapCount >= imageButtons.size())
			{
				// our map cycle size is >= the number of buttons we need to
				// fill, thus the following code is correct
				for (int i = 0; i < imageButtons.size(); ++i)
				{
					int candidateIndex = random.NextRanged(map_names.size());
					randomNames.push_back(map_names[candidateIndex]);
					map_names.removeAt(candidateIndex);
				}
			}
			else
			{
				// not enough maps for all buttons...
				// let's not overcomplicate logic
				LoadNextMap();
				return;
			}

			// scripted maps are in the format `mapscript.as (mapfile.png)`
			// see Challenge/mapcycle.png
			// extract the map name from there if that is the case.
			for (int i = 0; i < randomNames.size(); ++i)
			{
				const string name = randomNames[i];
				string lastChar = name.substr(name.size() - 1, 1);
				if (lastChar == ")")
				{
					string[] nameSegments = name.split(' (');
					string mapName = nameSegments[nameSegments.size() - 1];
					randomNames[i] = mapName.substr(0, mapName.size() - 1);
				}
			}
		}

		for (int i = 0; i < imageButtons.size(); ++i)
		{
			MapImageVoteButton@ button = @imageButtons[i];
			const string fileName = randomNames[i];
			button.filename = fileName;
			button.shortname = getFilenameWithoutExtension(getFilenameWithoutPath(fileName));
		}
	}

	void Sync(CPlayer@ targetPlayer = null)
	{
		CRules@ rules = getRules();

		CBitStream params;
		for (int i = 0; i < imageButtons.size(); ++i)
		{
			MapImageVoteButton@ button = @imageButtons[i];
			params.write_string(button.filename);
			params.write_string(button.shortname);
		}

		params.write_u8(mostVoted);

		for (int voteButtonIdx = 0; voteButtonIdx < votes.size(); ++voteButtonIdx)
		{
			params.write_u16(votes[voteButtonIdx].size());
			// FIXME: why do we even send full player lists???
			for (int i = 0; i < votes[voteButtonIdx].size(); ++i)
			{
				params.write_netid(votes[voteButtonIdx][i]);
			}
		}

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

	void ParseFromStream(CBitStream@ params)
	{
		for (int i = 0; i < imageButtons.size(); ++i)
		{
			MapImageVoteButton@ button = @imageButtons[i];
			params.saferead_string(button.filename);
			params.saferead_string(button.shortname);
		}

		params.saferead_u8(mostVoted);

		for (int voteButtonIdx = 0; voteButtonIdx < votes.size(); ++voteButtonIdx)
		{
			uint16 voteCount;
			params.saferead_u16(voteCount);

			votes[voteButtonIdx].resize(voteCount);
			for (int i = 0; i < voteCount; ++i)
			{
				params.saferead_netid(votes[voteButtonIdx][i]);
			}
		}
	}

	void RenderGUI()
	{
		Vec2f ScreenDim = getDriver().getScreenDimensions();

		const bool shouldNag = selectedOption == 255 && !isMapVoteOver();

		if (shouldNag)
		{
			// rationale for disabling: https://github.com/transhumandesign/kag-base/pull/1675
			// GUI::DrawRectangle(Vec2f_zero, ScreenDim, SColor(200, 0, 0, 0)); //end game taint screen
		}

		GUI::SetFont("menu");
		GUI::DrawFramedPane(topLeftCorner, bottomRightCorner);

		// workaround due to when the mostVoted gets synced from server
		if (ticksRemainingForMapVote() <= -1)
		{
			string winner = getButton(mostVoted).displayname;
			string text = getTranslatedString("Map Voting Has Ended.. Loading: {MAP}").replace("{MAP}", winner);
		 	GUI::DrawText(text, topLeftCorner + Vec2f(22, 16), color_white);
		}
		else
		{
			string text = getTranslatedString("Map Voting Ends In: {TIME}").replace("{TIME}", "" + (ticksRemainingForMapVote() / getTicksASecond()));
		 	GUI::DrawText(text, topLeftCorner + Vec2f(22, 16), color_white);
		}

		GUI::SetFont("AveriaSerif-Bold_22");
		for (uint i = 0; i < buttons.size(); ++i)
		{
			MapVoteButton@ button = getButton(i);
			const Vec2f countPos = button.clickableOrigin+Vec2f(button.clickableSize.x / 2, button.clickableSize.y - 24.0f);
			GUI::DrawTextCentered("" + votes[i].length(), countPos, color_white);
		}

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

		GUI::SetFont("menu");
		for (uint i = 0; i < buttons.size(); ++i)
		{
			MapVoteButton@ button = getButton(i);
			button.RenderGUI();
		}
	}

	void RenderRaw()
	{
		for (uint i = 0; i < buttons.size(); ++i)
		{
			buttons[i].RenderRaw();
		}
	}

	void Render()
	{
		RenderGUI();
		RenderRaw();
	}
};

class MapVoteButton
{
	string displayname;
	Vec2f clickableOrigin, clickableSize;
	Vec2f previewOrigin, previewSize;
	int state;

	MapVoteButton()
	{
		state = 0;
	}

	void RefreshButton( u16 MenuWidth, Vec2f &out ButtonSize)
	{
		state = 0;
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
		switch (state)
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

		GUI::SetFont("menu");
		GUI::DrawTextCentered(displayname, NameMid, color_white);
	}

	void RenderRaw() {}

	void loadMap() {}
};

string PrettifyMapName(string name)
{
	name = (name == "test.kaggen") ? "Generated Map" : name;

	string[] splitName = name.split("_");

	if (splitName.size() == 1)
	{
		// no underscore in name, nothing to do
		return splitName[0];
	}

	// transform:
	// 	Author_Blah_Blah
	// to:
	// 	Author's Blah Blah
	name = splitName[0];

	if (name.size() > 0)
	{
		if (name.substr(name.size() - 1) == "s")
		{
			// GuyWithANameThatEndOnS'
			name += "'";
		}
		else
		{
			// GuyWithSomeName's
			name += "'s";
		}
	}

	// add map name
	splitName.removeAt(0);
	name += " " + join(splitName, " ");

	return name;
}

const bool LARGE_PREVIEW_ALLOW = true;
const float LARGE_PREVIEW_ZOOM_SCALE = 3.0;

class MapImageVoteButton : MapVoteButton
{
	Vertex[] maptex_raw;
	string filename;
	string shortname;

	u16 mapW, mapH;

	MapImageVoteButton()
	{
		maptex_raw.push_back(Vertex(0, 0, 0, 0, 0));
		maptex_raw.push_back(Vertex(1, 0, 0, 1, 0));
		maptex_raw.push_back(Vertex(1, 1, 0, 1, 1));
		maptex_raw.push_back(Vertex(0, 1, 0, 0, 1));
	}

	void RefreshButton( u16 MenuWidth, Vec2f &out ButtonSize)
	{
		state = 0;
		if (Texture::exists(shortname))
		{
			ImageData@ edit = Texture::data(shortname);

			mapW = edit.width();
			mapH = edit.height();

			clickableOrigin = Vec2f(MenuWidth, 0.0f);
			previewSize = Vec2f(mapW, mapH);

			// Expand frame if the name is too long
			Vec2f dim;
			displayname = PrettifyMapName(shortname);
			GUI::SetFont("menu");
			GUI::GetTextDimensions(displayname, dim);

			clickableSize = previewSize;
			clickableSize.x = Maths::Max(dim.x, clickableSize.x);

			ButtonSize = clickableSize;

			maptex_raw[1].x = maptex_raw[2].x = mapW;
			maptex_raw[2].y = maptex_raw[3].y = mapH;
		}
	}

	bool shouldDoLargePreview()
	{
		return (
			LARGE_PREVIEW_ALLOW
			&& isHovered(getControls().getMouseScreenPos())
		);
	}

	void RenderGUI()
	{
		MapVoteButton::RenderGUI();
	}

	void RenderRaw()
	{
		const u16[] square_IDs = {0,1,2,2,3,0};
		float[] model;

		Matrix::MakeIdentity(model);
		Matrix::SetTranslation(model, previewOrigin.x, previewOrigin.y, 0);
		Render::SetModelTransform(model);
		Render::RawTrianglesIndexed(shortname, maptex_raw, square_IDs);

		// Yes, some should ideally be in RenderGUI, but we want to render text
		// over the map at the end
		if (shouldDoLargePreview())
		{
			Vec2f screenCenter = getDriver().getScreenDimensions() * 0.5;
			const float zoomScale = LARGE_PREVIEW_ZOOM_SCALE;

			Vec2f padding = Vec2f(4, 4);
			Vec2f scaledSize = Vec2f(mapW, mapH) * zoomScale + padding * 2.0;

			const Vec2f tl = screenCenter - scaledSize * 0.5;
			const Vec2f br = screenCenter + scaledSize * 0.5;

			GUI::DrawWindow(tl, br);

			Matrix::MakeIdentity(model);
			Matrix::SetScale(model, zoomScale, zoomScale, 1.0);
			Matrix::SetTranslation(
				model,
				screenCenter.x - mapW * zoomScale * 0.5,
				screenCenter.y - mapH * zoomScale * 0.5,
				0.0
			);
			Render::SetModelTransform(model);
			Render::RawTrianglesIndexed(shortname, maptex_raw, square_IDs);

			GUI::SetFont("AveriaSerif-Bold_22");
			Vec2f textDim;
			GUI::GetTextDimensions(displayname, textDim);
			Vec2f textOrigin(screenCenter.x, br.y - 4.0f);
			Vec2f textPadding(12.0, 6.0);
			GUI::DrawPane(textOrigin - textDim * 0.5 - textPadding, textOrigin + textDim * 0.5 + textPadding);
			GUI::DrawTextCentered(displayname, textOrigin, color_white);
		}
	}

	void loadMap()
	{
		LoadMap(filename);
	}
};

class MapRandomVoteButton : MapVoteButton
{
	// MapRandomVoteButton() {}

	void RefreshButton( u16 MenuWidth, Vec2f &out ButtonSize)
	{
		state = 0;
		displayname = "Random Map";
		ButtonSize = clickableSize = previewSize = Vec2f(110,100);
		clickableOrigin.x = previewOrigin.x = MenuWidth;
		clickableOrigin.y = previewOrigin.y = 0.0f;
	}

	void RenderGUI()
	{
		MapVoteButton::RenderGUI();

		const Vec2f IconOffset = previewOrigin + Vec2f(24,20);
		GUI::DrawIcon( "InteractionIcons.png", 14, Vec2f(32,32), IconOffset, 1.0f, 2);
	}

	void loadMap()
	{
		LoadNextMap();
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
		warn("mapvotes: texture creation failed, " + shortname + ", " + filename);
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

bool isMapVoteActive()
{
	MapVotesMenu@ mvm;
	return getRules().get("MapVotesMenu", @mvm)
		&& getRules().isGameOver()
		&& mvm.isSetup
		&& isClient()
		&& ticksSinceGameOver() >= 5*getTicksASecond();
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
