#include "ChatCommand.as"

class CoinsCommand : ChatCommand
{
	CoinsCommand()
	{
		super("coins", "Give yourself coins");
		AddAlias("money");
		SetUsage("[amount]");
		SetDebugOnly();
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
