#define CLIENT_ONLY

void onMainMenuCreated(CRules@ this, CContextMenu@ menu)
{
	CContextMenu@ bindingsMenu = Menu::addContextMenu(menu, getTranslatedString("Bindings"));
	Menu::addContextItem(bindingsMenu, getTranslatedString("Bind Emotes"), "EmoteBinderMenu.as", "void NewEmotesMenu()");
	Menu::addContextItem(bindingsMenu, getTranslatedString("Bind Builder Blocks"), "BuilderBinderMenu.as", "void NewBuilderMenu()");
}
