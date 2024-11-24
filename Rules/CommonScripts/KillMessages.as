// SHOW KILL MESSAGES ON CLIENT

#include "Hitters.as";
#include "TeamColour.as";
#include "HoverMessage.as";
#include "AssistCommon.as";

int fade_time = 300;


class KillMessage
{
	string victim;
	string victim_tag;
	string attacker;
	string attacker_tag;
	string helper;
	string helper_tag;
	int attackerteam;
	int victimteam;
	int helperteam;
	u8 hitter;
	s16 time;

	KillMessage() {}  //dont use this

	KillMessage(CPlayer@ _victim, CPlayer@ _attacker, u8 _hitter)
	{
		victim = _victim.getCharacterName();
		victim_tag = _victim.getClantag();
		victimteam = _victim.getTeamNum();

		if (_attacker !is null)
		{
			attacker = _attacker.getCharacterName();
			attacker_tag = _attacker.getClantag();
			attackerteam = _attacker.getTeamNum();
			//print("victimteam " + victimteam  + " " + (_victim.getBlob() !is null) + " attackerteam " + attackerteam + " " + (_attacker.getBlob() !is null));
		}
		else
		{
			attacker = "";
			attacker_tag = "";
			attackerteam = -1;
		}

		CPlayer@ _helper = getAssistPlayer(_victim, _attacker);
		if (_helper !is null)
		{
			helper = _helper.getCharacterName();
			helper_tag = _helper.getClantag();
			helperteam = _helper.getTeamNum();
		}
		else
		{
			helper = "";
			helper_tag = "";
			helperteam = -1;
		}

		hitter = _hitter;
		time = fade_time;
	}
};

class KillFeed
{
	KillMessage[] killMessages;

	void Update()
	{
		while (killMessages.length > 10)
		{
			killMessages.erase(0);
		}

		for (uint message_step = 0; message_step < killMessages.length; ++message_step)
		{
			KillMessage@ message = killMessages[message_step];
			message.time--;

			if (message.time == 0)
				killMessages.erase(message_step--);
		}
	}

	void Render()
	{
		const uint count = Maths::Min(10, killMessages.length);
		GUI::SetFont("menu");
		uint assists = 0;
		for (uint message_step = 0; message_step < count; ++message_step)
		{
			KillMessage@ message = killMessages[message_step];
			Vec2f dim, ul, lr;
			SColor col;
			f32 yOffset = 1.0f;

			Vec2f max_username_size;
			GUI::GetTextDimensions("####################", max_username_size);//20 chars
			Vec2f max_clantag_size;
			GUI::GetTextDimensions("##########", max_clantag_size);//10 chars
			Vec2f single_space_size;
			GUI::GetTextDimensions("#", single_space_size);//1 char


			if (message.attackerteam != -1)
			{
				//draw attacker name

				Vec2f attacker_name_size;
				GUI::GetTextDimensions(message.attacker, attacker_name_size);
				Vec2f attacker_tag_size;
				GUI::GetTextDimensions(message.attacker_tag + " ", attacker_tag_size);
				Vec2f dim(getScreenWidth() - attacker_name_size.x - max_username_size.x - max_clantag_size.x - single_space_size.x - 32, 0);
				ul.Set(dim.x, (message_step + yOffset + assists) * 16);
				col = getTeamColor(message.attackerteam);
				GUI::DrawText(message.attacker, ul, col);

				ul.x -= attacker_tag_size.x;
				col = getTeamColor(-1);
				GUI::DrawText(message.attacker_tag, ul, col);
			}

			if (message.helperteam != -1)
			{
				//draw helper name

				Vec2f helper_name_size;
				GUI::GetTextDimensions(message.helper, helper_name_size);
				Vec2f helper_tag_size;
				GUI::GetTextDimensions(message.helper_tag + " ", helper_tag_size);
				Vec2f dim(getScreenWidth() - helper_name_size.x - max_username_size.x - max_clantag_size.x - single_space_size.x - 32, 0);
				ul.Set(dim.x, (message_step + yOffset + assists + 1) * 16);
				col = getTeamColor(message.attackerteam);
				GUI::DrawText(message.helper, ul, col);

				ul.x -= helper_tag_size.x;
				col = getTeamColor(-1);
				GUI::DrawText(message.helper_tag, ul, col);

				//slight offset for kills with an assist
				yOffset += 0.5f;
			}

			//decide icon based on hitter
			string hitterIcon;

			switch (message.hitter)
			{
				case Hitters::fall:     		hitterIcon = "$killfeed_fall$"; break;
				case Hitters::fall_trampoline:  hitterIcon = "$killfeed_trampoline$"; break;
				case Hitters::drown:     		hitterIcon = "$killfeed_water$"; break;
				case Hitters::fire:
				case Hitters::burn:     		hitterIcon = "$killfeed_fire$"; break;
				case Hitters::stomp:    		hitterIcon = "$killfeed_stomp$"; break;
				case Hitters::builder:  		hitterIcon = "$killfeed_builder$"; break;
				case Hitters::spikes:  			hitterIcon = "$killfeed_spikes$"; break;
				case Hitters::sword:    		hitterIcon = "$killfeed_sword$"; break;
				case Hitters::shield:   		hitterIcon = "$killfeed_shield$"; break;
				case Hitters::bomb_arrow:		hitterIcon = "$killfeed_bombarrow$"; break;
				case Hitters::bomb:
				case Hitters::explosion:     	hitterIcon = "$killfeed_bomb$"; break;
				case Hitters::keg:     			hitterIcon = "$killfeed_keg$"; break;
				case Hitters::mine:             hitterIcon = "$killfeed_mine$"; break;
				case Hitters::mine_special:     hitterIcon = "$killfeed_mine$"; break;
				case Hitters::arrow:    		hitterIcon = "$killfeed_arrow$"; break;
				case Hitters::ballista: 		hitterIcon = "$killfeed_ballista$"; break;
				case Hitters::boulder:
				case Hitters::cata_stones:
				case Hitters::cata_boulder:  	hitterIcon = "$killfeed_boulder$"; break;
				case Hitters::drill:			hitterIcon = "$killfeed_drill$"; break;
				case Hitters::saw:				hitterIcon = "$killfeed_saw$"; break;
				case Hitters::bite:				hitterIcon = "$killfeed_shark$"; break;
				case Hitters::bison:			hitterIcon = "$killfeed_bison$"; break;

				default: 						hitterIcon = "$killfeed_fall$";
			}

			//draw hitter icon
			if (hitterIcon != "")
			{
				Vec2f dim(getScreenWidth() - max_username_size.x - max_clantag_size.x - (single_space_size.x*2) - 32, 0);
				ul.Set(dim.x, ((message_step + yOffset + assists) * 16) - 8);
				if (message.attackerteam < 0 || message.attackerteam > 6)
				{
					GUI::DrawIconByName(hitterIcon, ul, 1, 1, 7, color_white);
				}
				else
				{
					GUI::DrawIconByName(hitterIcon, ul, 1, 1, message.attackerteam, color_white);
				}
			}

			//draw victim name
			if (message.victimteam != -1)
			{
				Vec2f victim_name_size;
				GUI::GetTextDimensions(message.victim, victim_name_size);
				Vec2f victim_tag_size;
				GUI::GetTextDimensions(message.victim_tag + " ", victim_tag_size);

				Vec2f dim(getScreenWidth() - max_username_size.x - max_clantag_size.x, 0);

				ul.Set(dim.x, (message_step + yOffset + assists) * 16);
				col = getTeamColor(-1);
				GUI::DrawText(message.victim_tag, ul, col);

				ul.Set(dim.x + victim_tag_size.x, (message_step + yOffset + assists) * 16);
				col = getTeamColor(message.victimteam);
				GUI::DrawText(message.victim, ul, col);
			}

			//account for the extra height from assists
			if (message.helperteam != -1)
			{
				assists++;
			}
		}
	}

};

void Reset(CRules@ this)
{
	KillFeed feed;
	this.set("KillFeed", feed);
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void onInit(CRules@ this)
{
	Reset(this);

	this.addCommandID("killstreak message");
	this.addCommandID("interrupt message");

	AddIconToken("$killfeed_fall$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 1);
	AddIconToken("$killfeed_water$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 2);
	AddIconToken("$killfeed_fire$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 3);
	AddIconToken("$killfeed_stomp$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 4);
	AddIconToken("$killfeed_builder$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 8);
	AddIconToken("$killfeed_axe$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 9);
	AddIconToken("$killfeed_spikes$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 10);
	AddIconToken("$killfeed_boulder$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 11);
	AddIconToken("$killfeed_sword$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 12);
	AddIconToken("$killfeed_shield$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 13);
	AddIconToken("$killfeed_bomb$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 14);
	AddIconToken("$killfeed_keg$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 15);
	AddIconToken("$killfeed_mine$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 18);
	AddIconToken("$killfeed_arrow$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 16);
	AddIconToken("$killfeed_bombarrow$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 21);
	AddIconToken("$killfeed_ballista$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 17);
	AddIconToken("$killfeed_drill$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 19);
	AddIconToken("$killfeed_saw$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 20);
	AddIconToken("$killfeed_shark$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 22);
	AddIconToken("$killfeed_bison$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 23);
	AddIconToken("$killfeed_trampoline$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 24);
}

void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ killer, u8 customdata)
{
	if (victim !is null)
	{
		KillFeed@ feed;
		if (this.get("KillFeed", @feed) && feed !is null)
		{
			//Hide suicides from killfeed, during warm-up.
			if (!(killer is null && this.isWarmup()))
			{
				KillMessage message(victim, killer, customdata);
				feed.killMessages.push_back(message);
			}
		}

		// hover message

		if (killer !is null)
		{
			CBlob@ killerblob = killer.getBlob();
			CBlob@ victimblob = victim.getBlob();
			CPlayer@ helper = getAssistPlayer(victim, killer);

			bool kill = killerblob !is null && victimblob !is null && killerblob !is victimblob;
			bool assist = helper !is null && helper.isMyPlayer();

			if (kill)
			{
				if (isServer())
				{
					if (killerblob.getTeamNum() != victimblob.getTeamNum())
					{
						killer.set_u32("kill time", getGameTime());
						
						if(!killer.exists("killstreak"))
						{
							killer.set_u8("killstreak", 1);
						}
						else
						{
							killer.add_u8("killstreak", 1);
						}
					}

					if (victim.get_u8("killstreak") > 4)
					{

						uint16 victim_netid = victim.getNetworkID();
						uint16 killer_netid = killer.getNetworkID();
						uint8 kill_count = victim.get_u8("killstreak");

						CBitStream bs;
						bs.write_u16(victim_netid);
						bs.write_u16(killer_netid);
						bs.write_u8(kill_count);
						this.SendCommand(this.getCommandID("interrupt message"), bs);

						victim.set_u8("killstreak", 0);
					}
				}
				
				if (killerblob.isMyPlayer())
				{
					add_message(KillSpreeMessage(victim));
				}
			}
			else if (assist)
			{
				add_message(AssistMessage(victim));
			}
		}
	}
}

void onTick(CRules@ this)
{
	KillFeed@ feed;

	if (this.get("KillFeed", @feed) && feed !is null)
	{
		feed.Update();
	}

	if(isServer())
	{
		for(int a = 0; a < getPlayerCount(); a++) 
		{ 
			CPlayer@ player = getPlayer(a);

			if (player !is null && player.exists("killstreak"))
			{
				if (getGameTime() < player.get_u32("kill time"))
				{
					player.set_u8("killstreak", 0);
				}

				if (getGameTime() - player.get_u32("kill time") > (6 * getTicksASecond()) && player.get_u8("killstreak") > 4)
				{
					string multiKill;

					uint16 player_netid = player.getNetworkID();
					uint16 kill_count = player.get_u8("killstreak");

					CBitStream bs;
					bs.write_u16(player_netid);
					bs.write_u8(kill_count);
					this.SendCommand(this.getCommandID("killstreak message"), bs);
				
					player.set_u8("killstreak", 0);
				}
				else if (getGameTime() - player.get_u32("kill time") > (6 * 30))
				{
					player.set_u8("killstreak", 0);
				}
			}
		} 
	}
}

void onRender(CRules@ this)
{
	if (g_videorecording)
		return;

	KillFeed@ feed;

	if (this.get("KillFeed", @feed) && feed !is null)
	{
		feed.Render();
	}
}

void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
	if (isClient())
	{
		if (cmd == this.getCommandID("killstreak message"))
		{
			u16 player_netid;
			u8 kill_count;

			if (!params.saferead_u16(player_netid)
			 || !params.saferead_u8(kill_count))
			{
				print("failed to parse killstreak message payload");
				return;
			}

			CPlayer@ player = getPlayerByNetworkId(player_netid);

			if (player is null)
			{
				return;
			}

			string multiKill;

			switch (kill_count)
			{
				case 5: multiKill = "a Pentakill";
					break;
				case 6: multiKill = "a Hexakill";
					break;
				case 7: multiKill = "a Septakill";
					break;
				case 8: multiKill = "an Octakill";
					break;
				case 9: multiKill = "a Nonakill";
					break;
				case 10: multiKill = "a Decakill";
					break;
				case 11:
				case 18: multiKill = "an " + kill_count + " kill multikill";
					break;
				default: multiKill = "a " + kill_count + " kill multikill";
					break;
			}

			client_AddToChat(player.getCharacterName() + " got " + multiKill + "!", SColor(255, 180, 24, 94));
		}

		if (cmd == this.getCommandID("interrupt message"))
		{
			u16 victim_netid, killer_netid;
			u8 kill_count;

			if (!params.saferead_u16(victim_netid)
			 || !params.saferead_u16(killer_netid)
			 || !params.saferead_u8(kill_count))
			{
				print("failed to parse killstreak message payload");
				return;
			}

			CPlayer@ killer = getPlayerByNetworkId(killer_netid);
			CPlayer@ victim = getPlayerByNetworkId(victim_netid);

			if (killer is null || victim is null)
			{
				return;
			}

			string multiKill;

			switch (kill_count)
			{
				case 5: multiKill = "Pentakill";
					break;
				case 6: multiKill = "Hexakill";
					break;
				case 7: multiKill = "Septakill";
					break;
				case 8: multiKill = "Octakill";
					break;
				case 9: multiKill = "Nonakill";
					break;
				case 10: multiKill = "Decakill";
					break;
				default: multiKill = kill_count + " kill multikill";
					break;
			}

			client_AddToChat(killer.getCharacterName() + " has interrupted " + victim.getCharacterName() + "'s " + multiKill + "!", SColor(255, 180, 24, 94));
		}
	}
}
