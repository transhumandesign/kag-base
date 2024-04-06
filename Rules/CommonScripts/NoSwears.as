//chat filter

#include "NoSwearsCommon.as";

void onInit(CRules@ this)
{
	InitSwearsArray();
}

bool onClientProcessChat(CRules@ this, const string &in textIn, string &out textOut, CPlayer@ player)
{
	return processSwears(textIn, textOut);
}

bool onServerProcessChat(CRules@ this, const string &in textIn, string &out textOut, CPlayer@ player)
{
	return processSwears(textIn, textOut);
}
