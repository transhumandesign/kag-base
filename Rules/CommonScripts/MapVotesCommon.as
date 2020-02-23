//-- Written by Monkey_Feats 22/2/2020 --//
#include "LoaderColors.as";

class MapVotesMenu
{
	bool isSetup;

	MapVoteButton@ button1;
	MapVoteButton@ button2;
	MapVoteButton@ button3;

	int Selected;
	int VotedCount1;
	int VotedCount2;
	int VotedCount3;
	u8 MostVoted;

	Vec2f TL_Position;
	Vec2f BR_Pos;
	Vec2f MenuSize;

	s32 VoteTimeLeft;

	MapVotesMenu()
	{
		isSetup = false;

		@button1 = MapVoteButton(false);
		@button2 = MapVoteButton(true);
		@button3 = MapVoteButton(false);
	}

	void Refresh()
	{
		VotedCount1 = VotedCount2 = VotedCount3 = 0;
		Selected = -1;

		//Refresh button names, textures and size
		RandomizeButtonNames();
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

	void RandomizeButtonNames()
	{
		string mode_name = getRules().gamemode_name;
		if (mode_name == "Team Deathmatch") mode_name = "TDM";
		string mapcycle =  "Rules/"+mode_name+"/mapcycle.cfg";

		ConfigFile cfg;	
		bool loaded = false;
		if (CFileMatcher(mapcycle).getFirst() == mapcycle && cfg.loadFile(mapcycle)) loaded = true;
		else if (cfg.loadFile(mapcycle)) loaded = true;
		if (!loaded) { warn( mapcycle+ " not found!"); return; }

		string[] map_names;
		if (cfg.readIntoArray_string(map_names, "mapcycle"))
		{
			const u16 arrayleng = map_names.length();
			const string currentMap = getMap().getMapName();
			Random _random(getGameTime());

			// randomize button 1 map name
			int count = 0;
			bool done = false;
			while (!done)
			{				
				count++;
				string temp = map_names[_random.NextRanged(arrayleng)];
				
				//test to see if the map filename is inside parentheses and cut it out
				//incase someone wants to add map votes to a gamemode that loads maps via scripts, eg. Challenge/mapcycle.cfg				 
				string temptest = temp.substr(temp.length() - 1,temp.length() - 1);
				if (temptest == ")")
				{
					string[] name = temp.split(' (');
					string mapName = name[name.length() - 1];
					temp = mapName.substr(0,mapName.length() - 1);
				}

 				//lots of cases to be sure we get the most randomization and exit safely
				if (arrayleng == 2)
				{
					button1.filename = map_names[0];
					button1.shortname = getFilenameWithoutExtension(getFilenameWithoutPath(button1.filename));
					done = true;
				}
				else if (temp != button1.filename && temp != button3.filename && temp != currentMap)
				{
					button1.filename = temp;
					button1.shortname = getFilenameWithoutExtension(getFilenameWithoutPath(temp));
					done = true;
				}
				else if (temp != button1.filename && temp != button3.filename)
				{
					button1.filename = temp;
					button1.shortname = getFilenameWithoutExtension(getFilenameWithoutPath(temp));
					done = true;
				}
				else if (temp != button3.filename)
				{
					button1.filename = temp;
					button1.shortname = getFilenameWithoutExtension(getFilenameWithoutPath(temp));
					done = true;
				}
				else if (count == arrayleng) //safely exit the loop, pure random, probably only 1 map in the pool
				{
					button1.filename = map_names[_random.NextRanged(arrayleng)];
					button1.shortname = getFilenameWithoutExtension(getFilenameWithoutPath(button1.filename));
					done = true;
				}
			}

			//randomize button 3 map name
			count = 0;
			done = false; 
			while (!done)
			{
				count++;
				string temp = map_names[_random.NextRanged(arrayleng)];

				string temptest = temp.substr(temp.length() - 1,temp.length() - 1);
				if (temptest == ")")
				{
					string[] name = temp.split(' (');
					string mapName = name[name.length() - 1];
					temp = mapName.substr(0,mapName.length() - 1);
				}

				if (arrayleng == 2)
				{
					button3.filename = map_names[1];
					button3.shortname = getFilenameWithoutExtension(getFilenameWithoutPath(button3.filename));
					done = true;
				}
				else if (temp != button3.filename && temp != button1.filename && temp != currentMap)
				{
					button3.filename = temp;
					button3.shortname = getFilenameWithoutExtension(getFilenameWithoutPath(temp));
					done = true;
				}
				else if (temp != button3.filename && temp != button1.filename)
				{
					button3.filename = temp;
					button3.shortname = getFilenameWithoutExtension(getFilenameWithoutPath(temp));
					done = true;
				}
				else if (temp != button1.filename)
				{
					button3.filename = temp;
					button3.shortname = getFilenameWithoutExtension(getFilenameWithoutPath(temp));
					done = true;
				}
				else if (count == arrayleng)
				{
					button3.filename = map_names[_random.NextRanged(arrayleng)];
					button3.shortname = getFilenameWithoutExtension(getFilenameWithoutPath(button3.filename));
					done = true;
				}
			}
		}
	}

	void RefreshButtons()
	{	
		Vec2f ButtonSize;
		MenuSize.x = 30;
		MenuSize.y = 200;

		button1.RefreshButton( MenuSize.x, ButtonSize);
		MenuSize.x += ButtonSize.x+30;
		MenuSize.y = (ButtonSize.y+100) > MenuSize.y ? ButtonSize.y+95 : MenuSize.y;

		button2.RefreshRandomButton( MenuSize.x, ButtonSize);
		MenuSize.x += ButtonSize.x+30;
		MenuSize.y = (ButtonSize.y+100) > MenuSize.y ? ButtonSize.y+95 : MenuSize.y;
		
		button3.RefreshButton( MenuSize.x, ButtonSize);
		MenuSize.x += ButtonSize.x+30;
		MenuSize.y = (ButtonSize.y+100) > MenuSize.y ? ButtonSize.y+95 : MenuSize.y;
	}

	void Update(CControls@ controls, u8 &out SelectedNum)
	{
		Vec2f mousepos = controls.getMouseScreenPos();
		const bool mousePressed = controls.isKeyPressed(KEY_LBUTTON);
		const bool mouseJustReleased = controls.isKeyJustReleased(KEY_LBUTTON);

		int hoverednum;
		if (button1.isHovered(mousepos))
		{
			if (button1.State == 3) return; 
			else button1.State = 1; 
			
			if (mousePressed) button1.State = 2;
			else if(mouseJustReleased) 
			{
				SelectedNum = 1;
				button1.State = 3;
				button2.State = button3.State = 0;
			}
		}
		else if (button2.isHovered(mousepos))
		{
			if (button2.State == 3) return; 
			else button2.State = 1; 
			
			if (mousePressed) button2.State = 2;
			else if(mouseJustReleased) 
			{
				SelectedNum = 2;
				button2.State = 3;
				button1.State = button3.State = 0;
			}
		}
		else if (button3.isHovered(mousepos))
		{
			if (button3.State == 3) return; 
			else button3.State = 1; 
			
			if (mousePressed) button3.State = 2;
			else if(mouseJustReleased) 
			{
				SelectedNum = 3;
				button3.State = 3;
				button1.State = button2.State = 0;
			}
		}
		else
		{
			SelectedNum = 0;
			button1.State = button1.State != 3 ? 0 : 3; 
			button2.State = button2.State != 3 ? 0 : 3;
			button3.State = button3.State != 3 ? 0 : 3;
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
			 	GUI::DrawText("Map Vote Has Ended.. Loading : "+winner, TL_Position+Vec2f(20,8), color_white);
			}
			else
			{
			 	GUI::DrawText("Map Vote Ends In : "+ VoteTimeLeft +" Secs", TL_Position+Vec2f(20,8), color_white);
			}
			

			const Vec2f NameMid1 = button1.Pos+Vec2f((button1.Size.x/2)-2, button1.Size.y + 36);
			const Vec2f NameMid2 = button2.Pos+Vec2f((button2.Size.x/2)-2, button2.Size.y + 36);
			const Vec2f NameMid3 = button3.Pos+Vec2f((button3.Size.x/2)-2, button3.Size.y + 36);
			
			GUI::SetFont("arial_20");
			GUI::DrawTextCentered(""+ VotedCount1, NameMid1, MostVoted == 1 ? SColor(colors::green_color) : color_white);
			GUI::DrawTextCentered(""+ VotedCount2, NameMid2, MostVoted == 2 ? SColor(colors::green_color) : color_white);
			GUI::DrawTextCentered(""+ VotedCount3, NameMid3, MostVoted == 3 ? SColor(colors::green_color) : color_white);
			
			GUI::SetFont("menu");
			button1.RenderGUI();
			button2.RenderGUI();
			button3.RenderGUI();
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
		if (getNet().isServer() && !getNet().isClient()) return; //works for local host and on dedicated

		if(!Texture::exists(shortname))
		{
			CreateMapTexture();
		}

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
			displayname = shortname;	
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

	void CreateMapTexture()
	{
		// not a perfect minimap replication, but the image is so small it's too hard to tell
		if(!Texture::createFromFile(shortname, filename))
		{
			warn("texture creation failed");
		}
		else
		{	
			const bool show_gold = getRules().get_bool("show_gold");
			ImageData@ edit = Texture::data(shortname);
			u16 minimapW = edit.width();
			u16 minimapH = edit.height();

			CFileImage image( CFileMatcher(filename).getFirst() );
			if (image.isLoaded())
			{
				while(image.nextPixel())
				{
					const int offset = image.getPixelOffset();
					const Vec2f pixelpos = image.getPixelPosition();

					const SColor PixelCol = image.readPixel();

					const SColor PixelCol_u = edit.get(pixelpos.x, pixelpos.y-1);
					const SColor PixelCol_d = edit.get(pixelpos.x, pixelpos.y+1);
					const SColor PixelCol_r = edit.get(pixelpos.x+1, pixelpos.y);
					const SColor PixelCol_l = edit.get(pixelpos.x-1, pixelpos.y);

					SColor editcol = colors::minimap_open;
					
					if ( type(PixelCol) == 0  )      			
					{
						editcol = colors::minimap_open;
					}
					else if ( type(PixelCol) == 1  )       			
	    			{				
	    				// Foreground	
						editcol = colors::minimap_solid;
						
						if ((type(PixelCol_u) != 1 ) || 
						    (type(PixelCol_l) != 1 ) ||
							(type(PixelCol_d) != 1 ) ||
						    (type(PixelCol_r) != 1 ) ) 
						{
							editcol = colors::minimap_solid_edge;
						}
					}
					else if ( show_gold && type(PixelCol) == 2 )
					{
						//Gold
						editcol = colors::minimap_gold;

						//Edge
						if (( type(PixelCol_u) != 1 && type(PixelCol_u) != 2 ) || 
							( type(PixelCol_l) != 1 && type(PixelCol_l) != 2 ) ||
						 	( type(PixelCol_d) != 1 && type(PixelCol_d) != 2 ) || 
							( type(PixelCol_r) != 1 && type(PixelCol_r) != 2 ) )
						{
							editcol = colors::minimap_gold_edge;
						}
					}										
					else if (type(PixelCol) == 3)
					{
						//Background
						editcol = colors::minimap_back;

						//Edge
						if(( type(PixelCol_u) == 0 ) || 
						   ( type(PixelCol_l) == 0 ) ||
					 	   ( type(PixelCol_d) == 0 ) || 
						   ( type(PixelCol_r) == 0 )  )
						{
							editcol = colors::minimap_back_edge;
						}
					}							
					else 
					{
						editcol = PixelCol_u;
					}

					//tint the map based on Water
					if ( PixelCol == SColor(map_colors::water_backdirt) || PixelCol == SColor(map_colors::water_air) )
					{
						//overides water backwall edge for some reason...
						editcol = editcol.getInterpolated( colors::minimap_water, 0.5f);
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

namespace colors
{
	enum color
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

		menu_invisible_color = 0x00000000,
		menu_fadeout_color	   = 0xbe000000,

		red_color	   = 0xffff0000,
		green_color	   = 0xff00ff00,
		blue_color	   = 0xff0000ff
	}
}

u8 type(SColor PixelCol)
{
	u8 type = 4;
	switch (PixelCol.color)
	{
		case map_colors::water_air:
		case 0xffa5bdc8: //sky col
		case colors::minimap_open:
		{
			 type = 0; break;
		}
		case colors::minimap_solid:
		//case colors::minimap_solid_edge: //duplicated case
		case map_colors::tile_ground: 
		case map_colors::tile_stone: 
		case map_colors::tile_thickstone: 
		case map_colors::tile_bedrock: 
		case map_colors::tile_castle: 
		case map_colors::tile_castle_moss:
		case map_colors::tile_wood:
		{
			 type = 1; break;
		}

		case colors::minimap_gold_exposed:
		case colors::minimap_gold:
		case colors::minimap_gold_edge:
		case map_colors::tile_gold:
		{
			 type = 2; break;
		} 

		case colors::minimap_back:
		case colors::minimap_back_edge:
		case map_colors::tile_ground_back:
		case map_colors::tile_castle_back: 
		case map_colors::tile_wood_back:
		case map_colors::tile_castle_back_moss:
		case map_colors::water_backdirt:
		{
			 type = 3; break;
		} 
	}
	return type;
}