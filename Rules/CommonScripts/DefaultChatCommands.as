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
	manager.RegisterCommand(TeamCommand());
	manager.RegisterCommand(CoinsCommand());

	//classes
	manager.RegisterCommand(KnightCommand());
	manager.RegisterCommand(ArcherCommand());
	manager.RegisterCommand(BuilderCommand());

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

	//trees
	manager.RegisterCommand(PineTreeCommand());
	manager.RegisterCommand(BushyTreeCommand());

	//animals
	manager.RegisterCommand(FishiesCommand());
	manager.RegisterCommand(ChickensCommand());

	//other
	manager.RegisterCommand(WaterCommand());
	manager.RegisterCommand(CrateCommand());
	manager.RegisterCommand(ScrollCommand());
	manager.RegisterCommand(BotCommand());
	manager.RegisterCommand(SpawnCommand());
}
