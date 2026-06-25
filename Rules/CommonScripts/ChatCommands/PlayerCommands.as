#include "ChatCommand.as"

class ClassCommand : ChatCommand
{
	ClassCommand()
	{
		super("class", "Change your class");
		SetUsage("<name>");
	}

	bool canPlayerExecute(CPlayer@ player)
	{
		return (
			ChatCommand::canPlayerExecute(player) &&
			!ChatCommands::getManager().whitelistedClasses.empty()
		);
	}

	void Execute(string[] args, CPlayer@ player)
	{
		if (!isServer()) return;

		CBlob@ blob = player.getBlob();
		if (blob is null)
		{
			server_AddToChat(getTranslatedString("Your class cannot be changed while dead or spectating"), ConsoleColour::ERROR, player);
			return;
		}

		if (args.size() == 0)
		{
			string[] classes = ChatCommands::getManager().whitelistedClasses;
			server_AddToChat(getTranslatedString("Specify a class to swap to: " + join(classes, ", ")), ConsoleColour::ERROR, player);
			return;
		}

		string className = args[0];

		if (!isClassWhitelisted(className, player))
		{
			server_AddToChat(getTranslatedString("Class not found or cannot be swapped to"), ConsoleColour::ERROR, player);
			return;
		}

		if (blob.getName() == className)
		{
			server_AddToChat(getTranslatedString("You are already this class"), ConsoleColour::ERROR, player);
			return;
		}

		CBlob@ newBlob = server_CreateBlob(className, blob.getTeamNum(), blob.getPosition());
		if (newBlob is null)
		{
			server_AddToChat(getTranslatedString("Unable to change class"), ConsoleColour::ERROR, player);
			return;
		}

		newBlob.server_SetPlayer(player);
		blob.Tag("switch class");
		blob.server_SetPlayer(null);
		blob.server_Die();
	}
}

class TeamCommand : ChatCommand
{
	TeamCommand()
	{
		super("team", "Change your team");
		SetUsage("<team #>");
	}

	void Execute(string[] args, CPlayer@ player)
	{
		if (!isServer()) return;

		CBlob@ blob = player.getBlob();
		if (blob is null)
		{
			server_AddToChat(getTranslatedString("Team cannot be changed while dead or spectating"), ConsoleColour::ERROR, player);
			return;
		}

		if (args.size() == 0)
		{
			server_AddToChat(getTranslatedString("Specify a team number to change to"), ConsoleColour::ERROR, player);
			return;
		}

		int team = parseInt(args[0]);
		if (team == blob.getTeamNum())
		{
			server_AddToChat(getTranslatedString("You are already on this team"), ConsoleColour::ERROR, player);
			return;
		}

		blob.server_setTeamNum(team);
		
		// convert items in inventory
		CInventory@ inv = blob.getInventory();
		if (inv !is null)
		{
			for (int i = 0; i < inv.getItemsCount(); i++)
			{
				CBlob@ item = inv.getItem(i);
				
				if (item !is null && item.hasScript("SetTeamToCarrier.as"))
				{
					item.server_setTeamNum(team);
				}
			}
		}
		
		// convert held item
		if (blob.hasAttached())
		{
			CBlob@ heldblob = blob.getCarriedBlob();
			
			if (heldblob !is null && heldblob.hasScript("SetTeamToCarrier.as"))
			{
				heldblob.server_setTeamNum(team);
			}
		}
	}
}

class CoinsCommand : ChatCommand
{
	CoinsCommand()
	{
		super("coins", "Give yourself coins");
		AddAlias("money");
		SetUsage("[amount]");
	}

	void Execute(string[] args, CPlayer@ player)
	{
		if (isServer())
		{
			int coins = args.size() > 0 ? parseInt(args[0]) : player.getCoins() + 100;
			player.server_setCoins(coins);
		}

		if (player.isMyPlayer())
		{
			Sound::Play("snes_coin.ogg");
		}
	}
}

class HealCommand : ChatCommand
{
	HealCommand()
	{
		super("heal", "Heal yourself");
		AddAlias("health");
		SetUsage("[amount]");
	}

	void Execute(string[] args, CPlayer@ player)
	{
		CBlob@ blob = player.getBlob();
		if (blob is null)
		{
			if (isServer())
			{
				server_AddToChat(getTranslatedString("You cannot heal yourself while dead or spectating"), ConsoleColour::ERROR, player);
			}
			return;
		}

		//health calculation and processing

		// going in steps of 0.25
		float orig_health = args.size() > 0 ? parseFloat(args[0]) : blob.getInitialHealth() * 2;
		float health_to_heal = orig_health > 0 ? Maths::Floor(orig_health * 4) * 0.25 : Maths::Ceil(orig_health * 4) * 0.25; 
		bool no_change = health_to_heal == 0;
		bool healing = health_to_heal > 0;
		float possible_health_gap =  healing ? blob.getInitialHealth() * 2 - blob.getHealth() * 2 : blob.getHealth() * 2 - 0.25;

		// don't go lower than 0.25 or higher than max health
		health_to_heal = healing ? Maths::Min(health_to_heal, possible_health_gap) : Maths::Max(health_to_heal, -possible_health_gap);

		if (isServer())
		{
			blob.server_Heal(health_to_heal);
		}

		if (player.isMyPlayer())
		{
			if (health_to_heal == 0)
			{
				if (no_change)
				{
					client_AddToChat(getTranslatedString("Specify a valid amount (at least 0.25 or -0.25)"), ConsoleColour::ERROR);
				}
				else if (healing)
				{
					client_AddToChat(getTranslatedString("You are already at full health"), ConsoleColour::ERROR);
				}
				else
				{
					client_AddToChat(getTranslatedString("You are already at the lowest health"), ConsoleColour::ERROR);
				}
			}
			else
			{
				CSprite@ sprite = blob.getSprite();
				if (sprite !is null)
				{
					if (health_to_heal > 0)
					{
						sprite.PlaySound("Heart.ogg");
					}
					else
					{
						sprite.PlaySound("ArgShort.ogg", 1.0f, blob.getSexNum() == 0 ? 1.0f : 1.5f);
					}
				}
			}
		}
	}
}
