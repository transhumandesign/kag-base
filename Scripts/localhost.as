// initialize script for testing mods locally
// run KAG with startup parameters to use this
// KAG.exe noautoupdate nolauncher autostart Scripts/localhost.as

// remember to set sv_gamemode in autoconfig.cfg if you're using custom Rules

#include "Default/DefaultStart.as"
#include "Default/DefaultLoaders.as"

//we can use this to set autoconfig stuff here
void Configure()
{
	s_soundon = 1; // sound on
	v_driver = 5;  // default video driver
}

void InitializeGame()
{
	print("Initializing Game Script");
	LoadDefaultMapLoaders();
	LoadDefaultMenuMusic();
	RunLocalhost();
}
