// dedicated serverinitialize script
// use server variables in server_autoconfig.cfg
// sv_gamemode - sets game mode eg. /sv_gamemode "TDM"
// sv_mapcycle - sets map cycle eg. /sv_mapcycle "mapcycle.cfg";
// leave blank to use default map cycle in gamemode Rules folder

#include "Default/DefaultStart.as"
#include "Default/DefaultLoaders.as"

void Configure()
{
	v_driver = 0;  // disable video
	s_soundon = 0; // disable audio
}

void InitializeGame()
{
	print("Initializing Game Script");
	LoadDefaultMapLoaders();
	RunServer();
}
