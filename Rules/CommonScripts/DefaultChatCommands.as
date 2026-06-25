#include "ChatCommandManager.as"
#include "AnimalCommands.as"
#include "BlobCommands.as"
#include "GameStateCommands.as"
#include "MaterialCommands.as"
#include "MiscCommands.as"
#include "PlayerCommands.as"
#include "UtilityCommands.as"

//command register order is not important
//actual order in help command is based on the order of commands in ChatCommands.cfg
void RegisterDefaultChatCommands(ChatCommandManager@ manager)
{
	manager.RegisterCommand(HelpCommand());
	manager.RegisterCommand(TipCommand());

	//game state
	manager.RegisterCommand(StartCommand());
	manager.RegisterCommand(EndCommand());
	manager.RegisterCommand(NextMapCommand());
	manager.RegisterCommand(RestartMapCommand());

	//common
	manager.RegisterCommand(ClassCommand());
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
	manager.RegisterCommand(SharksCommand());
	manager.RegisterCommand(BisonCommand());

	//other
	manager.RegisterCommand(SeedCommand());
	manager.RegisterCommand(WaterCommand());
	manager.RegisterCommand(CrateCommand());
	manager.RegisterCommand(ScrollCommand());
	manager.RegisterCommand(BotCommand());
	manager.RegisterCommand(SpawnCommand());
	manager.RegisterCommand(KnightCommand());
	manager.RegisterCommand(ArcherCommand());
	manager.RegisterCommand(TimeCommand());
}
