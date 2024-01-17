//chat filter

#include "NoSwearsCommon.as";

void onInit(CRules@ this)
{
	ConfigFile cfg;

	if (!cfg.loadFile("Base/Rules/CommonScripts/Swears.cfg") ||
	    !cfg.readIntoArray_string(word_replacements, "replacements"))
	{
		warning("Could not read chat filter configuration from Swears.cfg");
	}

	if (word_replacements.length % 2 != 0)
	{
		warning("Could not read chat filter configuration: Expected 'swear; replacement;' pairs, got " + word_replacements.length + " strings");
	}
}

bool onClientProcessChat(CRules@ this, const string &in textIn, string &out textOut, CPlayer@ player)
{
	return processSwears(textIn, textOut);
}

bool onServerProcessChat(CRules@ this, const string &in textIn, string &out textOut, CPlayer@ player)
{
	return processSwears(textIn, textOut);
}
