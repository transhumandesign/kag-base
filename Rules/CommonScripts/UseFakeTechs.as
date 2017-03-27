
#include "Requirements_Tech.as";

void onInit(CRules@ this)
{
	RemoveFakeTechs(this);
}

void onRestart(CRules@ this)
{
	RemoveFakeTechs(this);
}
