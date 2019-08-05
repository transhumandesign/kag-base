// Simple chat processing example.
// If the player sends a command, the server does what the command says.
// You can also modify the chat message before it is sent to clients by modifying text_out
// By the way, in case you couldn't tell, "mat" stands for "material(s)"

#include "MakeSeed.as";
#include "MakeCrate.as";
#include "MakeScroll.as";


void onInit(CRules@ this)
{
	//Magic cmds
	this.addCommandID("sendText");
}

bool onServerProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player)
{
	//--------MAKING CUSTOM COMMANDS-------//
	// Making commands is easy - Here's a template:
	//
	// print('!scroll'.getHash()+'');
	// Do this in rcon and it will give you a hash
	//
	// You can then add it into the switch case
	//
	// Switch out the "!YourCommand" with
	// your command's name (i.e., !cool)
	//
	// Then decide what you want to have
	// the command do
	//
	// Here are a few bits of code you can put in there
	// to make your command do something:
	//
	// blob.server_Hit(blob, blob.getPosition(), Vec2f(0, 0), 10.0f, 0);
	// Deals 10 damage to the player that used that command (20 hearts)
	//
	// CBlob@ b = server_CreateBlob('mat_wood', -1, pos);
	// insert your blob/the thing you want to spawn at 'mat_wood'
	//
	// player.server_setCoins(player.getCoins() + 100);
	// Adds 100 coins to the player's coins
	//
	// 
	//-----------------END-----------------//
	if(text_in.substr(0, 1) != "!"){return true;}
	// cannot do commands while dead
	if (player is null){return true;}

	CBlob@ blob = player.getBlob(); // now, when the code references "blob," it means the player who called the command

	if (blob is null){return true;}

	Vec2f pos = blob.getPosition(); // grab player position (x, y)
	int team = blob.getTeamNum(); // grab player team number (for i.e. making all flags you spawn be your team's flags)
	uint hash = text_in.getHash();// hash for quick grabs
	bool isMod = player.isMod();//isMod for quick grabs

	// commands that don't rely on sv_test being on (sv_test = 1)


	if(isMod)
	{
		switch(hash)
		{
			case -149123247://!bot
			{
				CPlayer@ bot = AddBot("Henry"); //when there are multiple "Henry" bots, they'll be differentiated by a number (i.e. Henry2)
				return true;
			}
			break;

			case -126600229://!debug
			{
				// print all blobs
				CBlob@[] all;
				getBlobs(@all);

				for (u32 i = 0; i < all.length; i++)
				{
					CBlob@ blob = all[i];
					print("[" + blob.getName() + " " + blob.getNetworkID() + "] ");
				}
				return true;
			}
			break;

			//add other mod commands

		}
	}

	if(this.gamemode_name == "Sandbox" || sv_test)
	{
		switch(hash)
		{
			case -363910328://!allmats
			{
				//wood
				CBlob@ wood = server_CreateBlob('mat_wood', -1, pos);
				wood.server_SetQuantity(500); // so I don't have to repeat the server_CreateBlob line again
				//stone
				CBlob@ stone = server_CreateBlob('mat_stone', -1, pos);
				stone.server_SetQuantity(500);
				//gold
				CBlob@ gold = server_CreateBlob('mat_gold', -1, pos);
				gold.server_SetQuantity(100);
				return true;
			}
			break;

			case -1846171922://!woodstone
			{
				server_CreateBlob('mat_wood', -1, pos);
				CBlob@ b = server_CreateBlob('mat_stone', -1, pos);
				b.server_SetQuantity(500);
				return true;
			}
			break;

			case -1769265172://!stonewood
			{
				server_CreateBlob('mat_stone', -1, pos);
				CBlob@ b = server_CreateBlob('mat_wood', -1, pos);
				b.server_SetQuantity(500);
				return true;
			}
			break;

			case 1758485793://!wood
			{
				server_CreateBlob('mat_wood', -1, pos);
				return true;
			}
			break;

			case -1382004594://!stones
			case 1339663753://!stone
			{
				server_CreateBlob('mat_stone', -1, pos);
				return true;
			}
			break;

			case 559095378://!gold
			{
				for (u8 i = 0; i < 4; i++)
				{
					server_CreateBlob('mat_gold', -1, pos);
				}
				return true;
			}
			break;

		}
	}

	if(sv_test)
	{
		switch(hash)
		{
			case -774276164://!tree
			{
				server_MakeSeed(pos, "tree_pine", 600, 1, 16);
				return true;
			}
			break;

			case -1081054362://!btree
			{
				server_MakeSeed(pos, "tree_bushy", 400, 2, 16);
				return true;
			}
			break;

			case 939993797://!allarrows
			{
				server_CreateBlob('mat_arrows', -1, pos);
				server_CreateBlob('mat_waterarrows', -1, pos);
				server_CreateBlob('mat_firearrows', -1, pos);
				server_CreateBlob('mat_bombarrows', -1, pos);
				return true;
			}
			break;

			case -686769318://!arrows
			{
				for(u8 i = 0; i < 3; i++)
				{
					server_CreateBlob('mat_arrows', -1, pos);
				}
				return true;
			}
			break;

			case 152189844://!allbombs
			{
				server_CreateBlob('mat_bombs', -1, pos);
				server_CreateBlob('mat_waterbombs', -1, pos);
				return true;
			}
			break;

			case -1700806531://!bombs
			{
				for(u8 i = 0; i < 4; i++)
				{
					server_CreateBlob('mat_bombs', -1, pos);
				}
				return true;
			}
			break;

			case -450856766://!spawnwater
			{
				if(isMod)
				{
					getMap().server_setFloodWaterWorldspace(pos, true);
				}
				else
				{
					sendText(this,"Only modded players can do this!",player, SColor(255,255,0,0));
				}
				return true;
			}
			break;

			case -1682572833://!crate
			{
				server_MakeCrate("", "", 0, team, Vec2f(pos.x, pos.y));
				sendText(this,"usage: !crate BLOBNAME [DESCRIPTION]",player, SColor(255,255,0,0));
				return true;
			}
			break;

			case -1241650850://!coins
			{
				player.server_setCoins(player.getCoins() + 100);
				return true;
			}
			break;

			case 1129563976://!coinsoverload
			case 650211307://!coinoverload
			{
				player.server_setCoins(player.getCoins() + 10000);
				return true;
			}
			break;

			case -668769255://!fishyschool
			{
				for(u8 i = 0; i < 12; i++)
				{
					server_CreateBlob('fishy', -1, pos);
				}
				return true;
			}
			break;

			case 1609496768://!chickenflock
			{
				for(u8 i = 0; i < 12; i++)
				{
					server_CreateBlob('chicken', -1, pos);
				}
				return true;
			}
			break;

			default:
			{
				string[]@ tokens = text_in.split(" ");
				if(tokens.length > 1)
				{
					uint subhash = tokens[0].getHash();

					switch(subhash)
					{
						case -1682572833://crate
						{
							int frame = tokens[1] == "catapult" ? 1 : 0;
							string description = tokens.length > 2 ? tokens[2] : tokens[1];
							server_MakeCrate(tokens[1], description, frame, -1, Vec2f(pos.x, pos.y));
							return true;
						}
						break;

						case 908577341://!team
						{
							int team = parseInt(tokens[1]);
							blob.server_setTeamNum(team);
							return true;
						}
						break;

						case -778676667://scroll
						{
							string s = tokens[1];
							for (uint i = 2; i < tokens.length; i++)
							{
								s += " " + tokens[i];
							}
							server_MakePredefinedScroll(pos, s);
							return true;
						}
						break;

						/*case -1012229516://!class
						{
							//If somebody wants to fix it go for it
							//b.SetPlayer causes a server side snapshot;
							
							string obj = tokens[1];
							CBlob@ b = server_CreateBlob(obj, team, pos);
							if (b is null || b.getName() == "")//getName is required since sometimes the blob can be null with no name
							{
								sendText(this,"Class "+text_in + " not found!",player, SColor(255,255,0,0));
								return true;
							}

							if(!b.hasScript("StandardControls.as"))
							{
								b.AddScript("StandardControls.as");
							}

							b.server_SetPlayer(player);

							blob.server_SetPlayer(null);
							blob.server_Die();

					


						}*/
					}
					return true;
				}

				string name = text_in.substr(1, text_in.size());

				CBlob@ blobAttempt = server_CreateBlob(name, team, pos);
				if (blobAttempt is null || blobAttempt.getName() == "")//getName is required since sometimes the blob can be null with no name
				{
					sendText(this,"Blob "+text_in + " not found!",player, SColor(255,255,0,0));
				}
			}
			break;
		}
	}
	return true;
}

void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
	if(cmd == this.getCommandID("sendText"))
	{
		string text = params.read_string();
		u8 alpha = params.read_u8();
		u8 red = params.read_u8();
		u8 green = params.read_u8();
		u8 blue = params.read_u8();
		SColor col = SColor(alpha,red,green,blue);
		client_AddToChat(text,col);
	}
}


void sendText(CRules@ this,string text, CPlayer@ player, SColor col)
{
	CBitStream@ bit = CBitStream();
	bit.write_string(text);
	bit.write_u8(col.getAlpha());
	bit.write_u8(col.getRed());
	bit.write_u8(col.getGreen());
	bit.write_u8(col.getBlue());
	this.SendCommand(this.getCommandID("sendText"), bit, player);
}