#include "MainMenuCommon.as"

void onShowMenu(CRules@ this)
{
	//ShowEscMenu( this );
	printf("OPEN MENU");
}

void OnCloseMenu(CRules@ this)
{
	UI::Clear();
	printf("CLOSE MENU");
}


void onInit(CRules@ this)
{
	printf("onInit dfsdf sd f");
}

// -- menus

void BackToEscMenu( CRules@ this, UI::Group@ group, UI::Control@ control )
{
	UI::Transition( group, Vec2f( -1.0f, 0.0f ) );
	UI::Transition( control, Vec2f( 1.0f, 0.0f ) );
	ShowEscMenu( this );
}

void ShowEscMenu( CRules@ this )
{
	@_backCallback = BackToEscMenu;

	UI::Clear();
	UI::SetFont("menu");
	UI::AddGroup("title", Vec2f(0,0), Vec2f(1.0f, 0.4) );
		UI::Grid( 1, 1 );
		UI::Image::Add("TitleScreen.png");
	UI::AddGroup("escmenu", Vec2f(0.2f,0.4), Vec2f(0.8,1));
		UI::Grid( 2, 4 );
	    UI::Button::Add("BROWSER", ShowBrowser);
	     UI::Label::Add("multiplayer servers browser");
	    UI::Button::Add("ADMIN", ShowAdminMenu);
	     UI::Label::Add("game and playre controls");
	    UI::Button::Add("SETUP", ShowSetupMenu);
	     UI::Label::Add("options tweaking");
	    UI::Button::Add("EXIT", ExitToMainMenu);
	     UI::Label::Add("exit to main menu");
		UI::Transition( Vec2f( -1.0f, 0.0f ) );
	UI::SetLastSelection(0);
}

void ShowAdminMenu( CRules@ this, UI::Group@ group, UI::Control@ control )
{
	UI::Transition( group, Vec2f( -1.0f, 0.0f ) );
	UI::Transition( control, Vec2f( 1.0f, 0.0f ) );
	UI::Clear(group.name);
	UI::AddGroup("admin", Vec2f(0.25f,0.4), Vec2f(0.75,1));
		UI::Grid( 1, 3 );
	    UI::Button::Add("Players", ExitToMainMenu);
	    UI::Button::Add("Maps", ExitToMainMenu);
	    UI::Button::Add("Back", BackToEscMenu);
		UI::Transition( Vec2f( -1.0f, 0.0f ) );
	UI::SetLastSelection();
}

void ExitToMainMenu( CRules@ this, UI::Group@ group, UI::Control@ control )
{
	CNet@ net = getNet();
	setGameState(GameState::game);	
	return net.SafeConnect("localhost:"+sv_port, "Rules/Main/gamemode.cfg");
}

