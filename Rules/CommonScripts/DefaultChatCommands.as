#include "ChatCommandManager.as"
#include "HelpCommand.as"
#include "BotCommand.as"
#include "StartCommand.as"
#include "EndCommand.as"
#include "PineTreeCommand.as"
#include "BushyTreeCommand.as"
#include "ArrowsCommand.as"
#include "AllArrowsCommand.as"
#include "BombsCommand.as"
#include "AllBombsCommand.as"
#include "WaterCommand.as"
#include "CrateCommand.as"
#include "CoinsCommand.as"
#include "FishiesCommand.as"
#include "ChickensCommand.as"
#include "AllMatsCommand.as"
#include "WoodCommand.as"
#include "StoneCommand.as"
#include "GoldCommand.as"
#include "TeamCommand.as"
#include "ScrollCommand.as"
#include "KnightCommand.as"
#include "ArcherCommand.as"
#include "BuilderCommand.as"
#include "SpawnCommand.as"

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

	//misc
	manager.RegisterCommand(WaterCommand());
	manager.RegisterCommand(CrateCommand());
	manager.RegisterCommand(ScrollCommand());
	manager.RegisterCommand(BotCommand());
	manager.RegisterCommand(SpawnCommand());
}
