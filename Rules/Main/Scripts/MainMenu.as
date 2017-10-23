#define ALWAYS_ONRELOAD
#include "MainMenuCommon.as"
#include "Login.as"

void onInit(CRules@ this)
{
	printf("onInit");
	//setGameState( GameState::game );
	//if (!Engine::isAuthenticated()){
	//	Engine::ShowLoginWindow();
	//} else {
		ShowMainMenu( null, null );
	//}
	onReload(this);
}

void onReload(CRules@ this)
{
	printf("onReload");
	//_backCallback( null, null );

	UI::Group@ g = UI::AddGroup("titlescreen", Vec2f(0,0), Vec2f(1.0,1.0));
	@g.proxy.renderFunc = RenderTitleBackgound;
}

void onShowMenu(CRules@ this)
{
	printf("onShowMenu ");
	if(!getControls().externalControl)
		_backCallback( null, null );
}

void OnCloseMenu(CRules@ this)
{
	printf("OnCloseMenu");
	if(!getControls().externalControl)
		_backCallback( null, null );
}

void OnAuthenticationFail(CRules@ this)
{
	print("AUTH FAILED");
}

void OnAuthenticationSuccess(CRules@ this )
{
	print("AUTH SUCCESS");
	ShowMainMenu( null, null );
}

void OnOffline(CRules@ this)
{
	print("AUTH OFFLINE");
	ShowMainMenu( null, null );
}
