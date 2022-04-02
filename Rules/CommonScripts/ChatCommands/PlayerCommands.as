#include "ChatCommand.as"

class ArcherCommand : ChatCommand
{
	ArcherCommand()
	{
		super("archer", "Change class to Archer");
	}

	void Execute(string name, string[] args, CPlayer@ player)
	{
		if (!isServer()) return;

		CBlob@ blob = player.getBlob();
		if (blob is null)
		{
			server_AddToChat("Your class cannot be changed while dead or spectating", ConsoleColour::ERROR, player);
			return;
		}

		if (blob.getName() == "archer")
		{
			server_AddToChat("Your class is already Archer", ConsoleColour::ERROR, player);
			return;
		}

		CBlob@ archer = server_CreateBlob("archer", blob.getTeamNum(), blob.getPosition());
		archer.server_SetPlayer(player);
		blob.server_Die();
	}
}

class BuilderCommand : ChatCommand
{
	BuilderCommand()
	{
		super("builder", "Change class to Builder");
	}

	void Execute(string name, string[] args, CPlayer@ player)
	{
		if (!isServer()) return;

		CBlob@ blob = player.getBlob();
		if (blob is null)
		{
			server_AddToChat("Your class cannot be changed while dead or spectating", ConsoleColour::ERROR, player);
			return;
		}

		if (blob.getName() == "builder")
		{
			server_AddToChat("Your class is already Builder", ConsoleColour::ERROR, player);
			return;
		}

		CBlob@ builder = server_CreateBlob("builder", blob.getTeamNum(), blob.getPosition());
		builder.server_SetPlayer(player);
		blob.server_Die();
	}
}

class KnightCommand : ChatCommand
{
	KnightCommand()
	{
		super("knight", "Change class to Knight");
	}

	void Execute(string name, string[] args, CPlayer@ player)
	{
		if (!isServer()) return;

		CBlob@ blob = player.getBlob();
		if (blob is null)
		{
			server_AddToChat("Your class cannot be changed while dead or spectating", ConsoleColour::ERROR, player);
			return;
		}

		if (blob.getName() == "knight")
		{
			server_AddToChat("Your class is already Knight", ConsoleColour::ERROR, player);
			return;
		}

		CBlob@ knight = server_CreateBlob("knight", blob.getTeamNum(), blob.getPosition());
		knight.server_SetPlayer(player);
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

	void Execute(string name, string[] args, CPlayer@ player)
	{
		if (!isServer()) return;

		CBlob@ blob = player.getBlob();
		if (blob is null)
		{
			server_AddToChat("Team cannot be changed while dead or spectating", ConsoleColour::ERROR, player);
			return;
		}

		if (args.size() == 0)
		{
			server_AddToChat("Specify a team number to change to", ConsoleColour::ERROR, player);
			return;
		}

		int team = parseInt(args[0]);
		blob.server_setTeamNum(team);
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

	void Execute(string name, string[] args, CPlayer@ player)
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

	void Execute(string name, string[] args, CPlayer@ player)
	{
		CBlob@ blob = player.getBlob();
		if (blob is null)
		{
			if (isServer())
			{
				server_AddToChat("Your class cannot be changed while dead or spectating", ConsoleColour::ERROR, player);
			}
			return;
		}

		//i hate this but it works
		float health;
		float healthClamped;

		if (args.size() > 0)
		{
			health = healthClamped = parseFloat(args[0]);

			if (blob.getHealth() * 2 + health < 0.5f)
			{
				healthClamped = 0.125f - blob.getHealth() * 2;
			}

			if (blob.getHealth() * 2 + health > blob.getInitialHealth() * 2)
			{
				healthClamped = (blob.getInitialHealth() - blob.getHealth()) * 2;
			}
		}
		else
		{
			health = blob.getInitialHealth() * 2;
			healthClamped = (blob.getInitialHealth() - blob.getHealth()) * 2;
		}

		if (isServer())
		{
			blob.server_Heal(healthClamped);
		}

		if (isClient())
		{
			if (healthClamped == 0)
			{
				if (health == 0)
				{
					client_AddToChat("Specify a valid amount to heal", ConsoleColour::ERROR);
				}
				else if (health > 0)
				{
					client_AddToChat("You are already at full health", ConsoleColour::ERROR);
				}
				else
				{
					client_AddToChat("You are already at the lowest health", ConsoleColour::ERROR);
				}
			}
			else
			{
				CSprite@ sprite = blob.getSprite();
				if (sprite !is null)
				{
					if (health > 0)
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
