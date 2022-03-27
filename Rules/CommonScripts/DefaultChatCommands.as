#include "ChatCommandManager.as"
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

void RegisterDefaultChatCommands(ChatCommandManager@ manager)
{
    manager.RegisterCommand(BotCommand());
    manager.RegisterCommand(StartCommand());
    manager.RegisterCommand(EndCommand());
    manager.RegisterCommand(PineTreeCommand());
    manager.RegisterCommand(BushyTreeCommand());
    manager.RegisterCommand(ArrowsCommand());
    manager.RegisterCommand(AllArrowsCommand());
    manager.RegisterCommand(BombsCommand());
    manager.RegisterCommand(AllBombsCommand());
    manager.RegisterCommand(WaterCommand());
    manager.RegisterCommand(CrateCommand());
    manager.RegisterCommand(CoinsCommand());
    manager.RegisterCommand(FishiesCommand());
    manager.RegisterCommand(ChickensCommand());
    manager.RegisterCommand(AllMatsCommand());
    manager.RegisterCommand(WoodCommand());
    manager.RegisterCommand(StoneCommand());
    manager.RegisterCommand(GoldCommand());
    manager.RegisterCommand(TeamCommand());
    manager.RegisterCommand(ScrollCommand());
}