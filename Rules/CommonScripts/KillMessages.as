// SHOW KILL MESSAGES ON CLIENT

#include "Hitters.as";
#include "TeamColour.as";
#include "HoverMessage.as";

int fade_time = 300;


class KillMessage
{
	string victim;
	string victim_tag;
	string attacker;
	string attacker_tag;
	int attackerteam;
	int victimteam;
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
		for (uint message_step = 0; message_step < count; ++message_step)
		{
			KillMessage@ message = killMessages[message_step];
			Vec2f dim, ul, lr;
			SColor col;

			Vec2f max_username_size;
			GUI::GetTextDimensions("####################", max_username_size);//20 chars
			Vec2f max_clantag_size;
			GUI::GetTextDimensions("#####", max_clantag_size);//5 chars
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
				ul.Set(dim.x, (message_step + 1) * 16);
				col = getTeamColor(message.attackerteam);
				GUI::DrawText(message.attacker, ul, col);

				ul.x -= attacker_tag_size.x;
				col = getTeamColor(-1);
				GUI::DrawText(message.attacker_tag, ul, col);
			}

			//decide icon based on hitter
			string hitterIcon;

			switch (message.hitter)
			{
				case Hitters::fall:     		hitterIcon = "$killfeed_fall$"; break;

				case Hitters::drown:     		hitterIcon = "$killfeed_water$"; break;

				case Hitters::fire:
				case Hitters::burn:     		hitterIcon = "$killfeed_fire$"; break;

				case Hitters::stomp:    		hitterIcon = "$killfeed_stomp$"; break;

				case Hitters::builder:  		hitterIcon = "$killfeed_builder$"; break;

				case Hitters::spikes:  			hitterIcon = "$killfeed_spikes$"; break;

				case Hitters::sword:    		hitterIcon = "$killfeed_sword$"; break;

				case Hitters::shield:   		hitterIcon = "$killfeed_shield$"; break;

				case Hitters::bomb:
				case Hitters::bomb_arrow:
				case Hitters::explosion:     	hitterIcon = "$killfeed_bomb$"; break;

				case Hitters::keg:     			hitterIcon = "$killfeed_keg$"; break;

				case Hitters::mine:             hitterIcon = "$killfeed_mine$"; break;
				case Hitters::mine_special:     hitterIcon = "$killfeed_mine$"; break;

				case Hitters::arrow:    		hitterIcon = "$killfeed_arrow$"; break;

				case Hitters::ballista: 		hitterIcon = "$killfeed_ballista$"; break;

				case Hitters::boulder:
				case Hitters::cata_boulder:  	hitterIcon = "$killfeed_boulder$"; break;

				default: 						hitterIcon = "$killfeed_fall$";
			}

			//draw hitter icon
			if (hitterIcon != "")
			{
				Vec2f dim(getScreenWidth() - max_username_size.x - max_clantag_size.x - (single_space_size.x*2) - 32, 0);
				ul.Set(dim.x, ((message_step + 1) * 16) - 8);
				GUI::DrawIconByName(hitterIcon, ul);
			}

			//draw victim name
			if (message.victimteam != -1)
			{
				Vec2f victim_name_size;
				GUI::GetTextDimensions(message.victim, victim_name_size);
				Vec2f victim_tag_size;
				GUI::GetTextDimensions(message.victim_tag + " ", victim_tag_size);

				Vec2f dim(getScreenWidth() - max_username_size.x - max_clantag_size.x, 0);

				ul.Set(dim.x, (message_step + 1) * 16);
				col = getTeamColor(-1);
				GUI::DrawText(message.victim_tag, ul, col);

				ul.Set(dim.x + victim_tag_size.x, (message_step + 1) * 16);
				col = getTeamColor(message.victimteam);
				GUI::DrawText(message.victim, ul, col);
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
	AddIconToken("$killfeed_ballista$", "GUI/KillfeedIcons.png", Vec2f(32, 16), 17);
}

void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ killer, u8 customdata)
{
	if (victim !is null)
	{
		KillFeed@ feed;
		if (this.get("KillFeed", @feed) && feed !is null)
		{
			KillMessage message(victim, killer, customdata);
			feed.killMessages.push_back(message);
		}

		// hover message

		if (killer !is null)
		{
			CBlob@ killerblob = killer.getBlob();
			CBlob@ victimblob = victim.getBlob();
			if (killerblob !is null && victimblob !is null && killerblob.isMyPlayer() && killerblob !is victimblob)
			{
				HoverMessage m(1337, victimblob.getInventoryName(), 1, SColor(255, 255, 20, 20), false);
				addMessage(killerblob, m);
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
}

void onRender(CRules@ this)
{
	KillFeed@ feed;

	if (this.get("KillFeed", @feed) && feed !is null)
	{
		feed.Render();
	}
}
