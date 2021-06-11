/**
 * Common bot "taunt engine"
 *
 * Attach to blob
 */


#include "EmotesCommon.as"

/**
 * Defines the possible taunt actions
 */
enum TauntActionIndex
{

	no_action = 0,

	hurt_enemy,
	kill_enemy,
	get_hurt,

	chat,
	dead
}

/**
 * A struct holding information about a bot's personality
 */
class BotPersonality
{

	/**
	 * name of the personality
	 */
	string name;

	/**
	 * chance of a taunt every event
	 */
	f32 tauntchance;

	/**
	 * the emote "strings" that the bot will use
	 * for certain events
	 */
	string[] hurt_enemy_emotes;
	string[] kill_enemy_emotes;
	string[] get_hurt_emotes;

	/**
	 * A list of taunts that the bot will use
	 * when it's winning or camping
	 */
	string[] taunts;

	/**
	 * A list of whines that the bot will use
	 * when its dead
	 */
	string[] whines;

	/**
	 * The number of ticks taken per character of
	 * taunt - used to emulate type lag
	 */
	u8 typespeed;

	/**
	 * Used to tune how talkative each personality is
	 */
	f32 talkchance;

	BotPersonality() {}

};

void onInit(CBlob@ this)
{
	//this.getCurrentScript().removeIfTag = "dead";

	this.set_u8("taunt action", no_action);
	this.set_u8("taunt delay", 0);

	/*BotPersonality[] personalities = {

	};*/

	//default personality
	BotPersonality b;
	b.name = "default";

	//emotes
	b.hurt_enemy_emotes.push_back("smile");
	b.hurt_enemy_emotes.push_back("mad");
	b.hurt_enemy_emotes.push_back("laugh");

	b.kill_enemy_emotes.push_back("laugh");

	b.get_hurt_emotes.push_back("frown");
	b.get_hurt_emotes.push_back("mad");
	b.get_hurt_emotes.push_back("attn");
	b.get_hurt_emotes.push_back("cry");

	//chats
	{
		string[] temp = { "haha!",
		                  "heheheh",
		                  "noob!",

		                  "noob!",

		                  "Your mother was a hamster!",
		                  "Your father smelt of elderberries!",
		                  "Go away or I shall taunt you a second time.",
		                  "Go and boil your bottom!"

		                };
		b.taunts = temp;
	}
	{
		string[] temp = { "heeelp!",
		                  "ouch!",
		                  "damnit!",
		                  "dangit!",
		                  "oof!",
		                  "...",
		                  "You'll be sorry!",
		                  "I'll get you!",

		                  "I'll be back",
		                  "Save me barry!",

		                  "It's just a flesh wound.",

		                  "yeargh!"
		                };
		b.whines = temp;
	}

	//meta
	b.tauntchance = 0.5f;

	b.typespeed = 3;
	b.talkchance = 0.25f;

	this.set("taunt personality", b);  //personalities[(this.getNetworkID() % personalities.length)] );
}

void onTick(CBlob@ this)
{
	if (this.getPlayer() is null)
		UpdateAction(this);
	else
		this.getCurrentScript().runFlags |= Script::remove_after_this; //not needed
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (hitterBlob.hasTag("player") && !this.hasTag("dead"))
		PromptAction(this, get_hurt, 5 + XORRandom(5));

	return damage;
}

void onHitBlob(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitBlob, u8 customData)
{
	if (hitBlob.hasTag("player") && !hitBlob.hasTag("dead"))
		PromptAction(this, hurt_enemy, 5 + XORRandom(5));
}

void PromptAction(CBlob@ this, u8 action, u8 delay)
{
	this.set_u8("taunt action", action);
	this.Sync("taunt action", true);

	this.set_u8("taunt delay", delay);
	this.Sync("taunt delay", true);
}

void UpdateAction(CBlob@ this)
{
	bool isdead = this.hasTag("dead");

	u8 action = this.get_u8("taunt action");
	if (action == no_action)
	{
		if (isdead)
		{
			DoAction(this, dead);
		}

		return;
	}

	u8 delay = this.get_u8("taunt delay");
	if (delay > 0)
	{
		delay--;
		this.set_u8("taunt delay", delay);
	}
	else
	{
		this.set_u8("taunt action", no_action);
		DoAction(this, action);

		if (this.get_u8("taunt action") == no_action && isdead)
			this.getCurrentScript().runFlags |= Script::remove_after_this;
	}
}

void DoAction(CBlob@ this, u8 action)
{
	BotPersonality@ b;
	if (!this.get("taunt personality", @b)) return;

	bool taunt = (XORRandom(1000) / 1000.0f) < b.tauntchance;
	bool chatter = (XORRandom(1000) / 1000.0f) < b.talkchance;

	switch (action)
	{
		case hurt_enemy:
			if (taunt) ChatOrEmote(this, chatter, b.hurt_enemy_emotes, b.taunts, b);
			break;

		case kill_enemy:
			ChatOrEmote(this, chatter, b.kill_enemy_emotes, b.taunts, b);
			break;

		case get_hurt:
			if (taunt) ChatOrEmote(this, chatter, b.get_hurt_emotes, b.whines, b);
			break;

		case dead:
			ChatOrEmote(this, true, b.get_hurt_emotes, b.whines, b);
			break;

		case chat:
			this.Chat(this.get_string("taunt chat"));
			set_emote(this, "");
			break;
	}

}

void ChatOrEmote(CBlob@ this, bool chatter, const string[]& emotes, const string[]& chats, BotPersonality@ b = null)
{
	if (!chatter)
	{
		set_emote(this, emotes[XORRandom(emotes.length)]);
	}
	else
	{
		if (b is null)
		{
			this.Chat(chats[XORRandom(chats.length)]);
			set_emote(this, "");
		}
		else
		{
			set_emote(this, "dots");

			string chat_text = chats[XORRandom(chats.length)];
			this.set_string("taunt chat", chat_text);

			u8 count = (Maths::Sqrt(chat_text.length) + 1) * b.typespeed;

			//print("text: \""+chat_text+"\" count: "+(count));

			PromptAction(this, chat, count);

		}
	}
}



