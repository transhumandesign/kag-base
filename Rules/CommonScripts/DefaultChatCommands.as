#include "ChatCommandManager.as"
#include "AnimalCommands.as"
#include "BlobCommands.as"
#include "GameStateCommands.as"
#include "MaterialCommands.as"
#include "MiscCommands.as"
#include "PlayerCommands.as"
#include "UtilityCommands.as"

void RegisterDefaultChatCommands(ChatCommandManager@ manager)
{
	manager.RegisterCommand(HelpCommand());

	//game state
	manager.RegisterCommand(StartCommand());
	manager.RegisterCommand(EndCommand());

	//common
	if (manager.whitelistedClasses.size() > 0)
	{
		manager.RegisterCommand(ClassCommand());
	}
	manager.RegisterCommand(TeamCommand());
	manager.RegisterCommand(CoinsCommand());
	manager.RegisterCommand(HealCommand());

	//materials
	manager.RegisterCommand(WoodCommand());
	manager.RegisterCommand(StoneCommand());
	manager.RegisterCommand(GoldCommand());
	manager.RegisterCommand(AllMatsCommand());

	//utilities
	manager.RegisterCommand(BombsCommand());
	manager.RegisterCommand(AllBombsCommand());
	manager.RegisterCommand(ArrowsCommand());
	manager.RegisterCommand(AllArrowsCommand());

	//animals
	manager.RegisterCommand(FishiesCommand());
	manager.RegisterCommand(ChickensCommand());

	//other
	manager.RegisterCommand(TreeCommand());
	manager.RegisterCommand(WaterCommand());
	manager.RegisterCommand(CrateCommand());
	manager.RegisterCommand(ScrollCommand());
	manager.RegisterCommand(BotCommand());
	manager.RegisterCommand(SpawnCommand());
}
