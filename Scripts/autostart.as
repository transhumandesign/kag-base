// initialize script

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
}
