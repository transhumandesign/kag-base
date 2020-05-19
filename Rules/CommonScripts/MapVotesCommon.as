//-- Written by Monkey_Feats 22/2/2020 --//
#include "LoaderColors.as";

Random _random();

class MapVotesMenu
{
	MapVoteButton@ button1;
	MapVoteButton@ button2;
	MapVoteButton@ button3;

	Vec2f TL_Position;
	Vec2f BR_Pos;
	Vec2f MenuSize;

	u16[] Votes1;
	u16[] Votes2;
	u16[] Votes3;

	u8 MostVoted;
	s16 VoteTimeLeft;
	bool isSetup;

	MapVotesMenu()
	{		
		isSetup = false;

		@button1 = MapVoteButton(false);
		@button2 = MapVoteButton(true);
		@button3 = MapVoteButton(false);
	}

	void ClearVotes()
	{
		Votes1.clear();
		Votes2.clear();
		Votes3.clear();
		isSetup = false;
		VoteTimeLeft = VoteSecs;
		current_Selected = 0;
		fadeTimer = PrePostVoteSecs * getTicksASecond(); // endgame time before fading
	}

	void Refresh()
	{
		//Refresh textures and sizes
		RefreshButtons();

		//Refresh menu pos/size after getting button sizes
		Vec2f screenCenter = getDriver().getScreenDimensions()/2;
		TL_Position = screenCenter-(MenuSize/2);
		BR_Pos = screenCenter+(MenuSize/2);

		//Reposition buttons to menu
		button1.Pos.x += TL_Position.x;
		button2.Pos.x += TL_Position.x;
		button3.Pos.x += TL_Position.x;
		button1.Pos.y = button2.Pos.y = button3.Pos.y = TL_Position.y+40;

		isSetup = true;
	}

	void RefreshButtons()
	{	
		Vec2f ButtonSize;
		MenuSize.x = 30;
		MenuSize.y = 200;

		button1.RefreshButton( MenuSize.x, ButtonSize);
		MenuSize.x += ButtonSize.x+30;
		MenuSize.y = (ButtonSize.y+95) > MenuSize.y ? ButtonSize.y+95 : MenuSize.y;

		button2.RefreshRandomButton( MenuSize.x, ButtonSize);
		MenuSize.x += ButtonSize.x+30;
		MenuSize.y = (ButtonSize.y+95) > MenuSize.y ? ButtonSize.y+95 : MenuSize.y;
		
		button3.RefreshButton( MenuSize.x, ButtonSize);
		MenuSize.x += ButtonSize.x+30;
		MenuSize.y = (ButtonSize.y+95) > MenuSize.y ? ButtonSize.y+95 : MenuSize.y;
	}

	void Update(CControls@ controls, u8 &out NewSelectedNum)
	{
		if (VoteTimeLeft == VoteSecs) return; // Hack, mouseJustReleased returns true once?

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
				NewSelectedNum = 1;
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
				NewSelectedNum = 2;
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
				NewSelectedNum = 3;
				button3.State = ButtonStates::Selected;
				button1.State = button2.State = ButtonStates::None;
			}
		}
		else
		{
			NewSelectedNum = 0;
			button1.State = button1.State != ButtonStates::Selected ? ButtonStates::None : ButtonStates::Selected; 
			button2.State = button2.State != ButtonStates::Selected ? ButtonStates::None : ButtonStates::Selected;
			button3.State = button3.State != ButtonStates::Selected ? ButtonStates::None : ButtonStates::Selected;
		}
	}

	void RenderGUI()
	{
		Vec2f ScreenDim = getDriver().getScreenDimensions();

		if (fadeTimer > 0 && fadeTimer < FadeTicks)
		{
			SColor col(colors::menu_invisible_color);
			float fadeamount = 1.0 - (fadeTimer*0.01f);
			col = col.getInterpolated(colors::menu_fadeout_color, fadeamount);

			GUI::DrawRectangle(Vec2f_zero, ScreenDim, col);
		}
		else if (fadeTimer >= FadeTicks) // draw menu
		{			
			GUI::SetFont("menu");	
			GUI::DrawRectangle(Vec2f_zero, ScreenDim, colors::menu_fadeout_color);
			GUI::DrawFramedPane(TL_Position, BR_Pos);

			if (VoteTimeLeft < 1)
			{	
				string winner = "";
				switch (MostVoted)
				{
					case 1: winner = button1.shortname; break;
					case 3:	winner = button3.shortname; break;
					default: winner = "A Random Map"; break;
				}
			 	GUI::DrawText("Map Voting Has Ended.. Loading: "+ winner, TL_Position+Vec2f(22,10), color_white);
			}
			else
			{
			 	GUI::DrawText("Map Voting Ends In: "+ VoteTimeLeft, TL_Position+Vec2f(22,10), color_white);
			}

			button1.RenderGUI();
			button2.RenderGUI();
			button3.RenderGUI();

			const Vec2f CountMid1 = button1.Pos+Vec2f((button1.Size.x/2)-2, button1.Size.y + 38);
			const Vec2f CountMid2 = button2.Pos+Vec2f((button2.Size.x/2)-2, button2.Size.y + 38);
			const Vec2f CountMid3 = button3.Pos+Vec2f((button3.Size.x/2)-2, button3.Size.y + 38);
			
			GUI::SetFont("AveriaSerif-Bold_22");
			GUI::DrawTextCentered(""+Votes1.length(), CountMid1, color_white);
			GUI::DrawTextCentered(""+Votes2.length(), CountMid2, color_white);
			GUI::DrawTextCentered(""+Votes3.length(), CountMid3, color_white);
		}
	}
	void RenderRaw()
	{
		if (fadeTimer >= FadeTicks)
		{
			button1.RenderRaw();
			button2.RenderRaw();
			button3.RenderRaw();
		}
	}
};

class MapVoteButton
{
	string filename;
	string shortname;
	string displayname;
	Vertex[] maptex_raw;
	Vec2f Pos;
	Vec2f Size;
	u8 tex_offsetY;
	int State;
	bool isRandomButton;

	MapVoteButton(bool _r) 
	{
		State = 0;
		isRandomButton = _r;

		if (!isRandomButton) // initilze vertices array
		{
			maptex_raw.push_back(Vertex( 0, 0, 0, 0, 0 ));
			maptex_raw.push_back(Vertex( 1, 0, 0, 1, 0 ));
			maptex_raw.push_back(Vertex( 1, 1, 0, 1, 1 ));
			maptex_raw.push_back(Vertex( 0, 1, 0, 0, 1 ));			
		}
	}

	void RefreshRandomButton( u16 MenuWidth, Vec2f &out ButtonSize)
	{
		State = 0;
		displayname = "Random Map";
		Size = Vec2f(110,100);
		ButtonSize = Size;
		Pos.x = MenuWidth;
	}

	void RefreshButton( u16 MenuWidth, Vec2f &out ButtonSize)
	{		
		State = 0;
		if(Texture::exists(shortname))
		{
			ImageData@ edit = Texture::data(shortname);

			u16 mapW = edit.width();
			u16 mapH = edit.height();

			Size = Vec2f(mapW, mapH > 100 ? mapH : 100);
			ButtonSize = Size;
			Pos.x = MenuWidth;
			tex_offsetY = mapH <= 100 ? (100-mapH) : 0;

			//crop names longer than the map size
			Vec2f dim;			
			displayname = shortname == "test.kaggen" ? "Generated Map" : shortname;	
			GUI::SetFont("menu");
			GUI::GetTextDimensions(displayname, dim);
			if (dim.x > mapW - 10)
			{
				while (dim.x > mapW - 15)
				{
					displayname = displayname.substr(0,displayname.length()-1);
					GUI::GetTextDimensions(displayname, dim);
				}	
				displayname += "..";
			}

			maptex_raw[1].x = maptex_raw[2].x = mapW;
			maptex_raw[2].y = maptex_raw[3].y = mapH;
		}
	}

	bool isHovered(Vec2f mousepos)
	{
		Vec2f tl = Pos;
		Vec2f br = Pos + Size;
		if (mousepos.x > tl.x && mousepos.y > tl.y &&
		     mousepos.x < br.x && mousepos.y < br.y)
		{
			return true;
		}
		return false;
	}


	void RenderGUI()
	{	
		SColor col(color_white);
		switch (State)
		{
			case 1: {col = SColor(255,220,220,220);} break; //hovered
			case 2: {col = SColor(255,200,200,200);} break; //pressed
			case 3: {col = SColor(255,100,255,100);} break; //selected
			default: {col = color_white;}
		}

		const Vec2f Padding_outline = Vec2f(8,8);
		const Vec2f TL_outline = Pos-Padding_outline;
		const Vec2f BR_outline = Pos+Size+Padding_outline;
		const Vec2f Padding_window = Vec2f(4,4);
		const Vec2f TL_window = Pos-Padding_window;
		const Vec2f BR_window = Pos+Size+Padding_window;
		GUI::DrawPane(TL_outline, BR_outline, col);
		GUI::DrawWindow(TL_window, BR_window);

		const Vec2f NameMid = Pos+Vec2f((Size.x/2)-2, Size.y+16);
		GUI::DrawTextCentered(displayname, NameMid, color_white);

		if (isRandomButton)
		{
			const Vec2f IconOffset = Pos+Vec2f(24,20);
			GUI::DrawIcon( "InteractionIcons.png", 14, Vec2f(32,32), IconOffset, 1.0f, 2);
		}
	}
	void RenderRaw()
	{
		const u16[] square_IDs = {0,1,2,2,3,0};
		float[] model;

		Matrix::MakeIdentity(model);
		Matrix::SetTranslation(model, Pos.x, Pos.y+tex_offsetY, 0);
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
					editcol =  colors::minimap_open;
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
		case map_colors::interpolated_water_backwall:
		case map_colors::interpolated_water_backwall_edge:
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
	Selected
};