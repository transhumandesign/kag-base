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
