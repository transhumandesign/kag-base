#include "UI.as"

//skin
#include "MainButtonRender.as"
#include "MainTextInputRender.as"
#include "MainToggleRender.as"
#include "MainOptionRender.as"
#include "MainSliderRender.as"
//controls
#include "UIButton.as"
#include "UITextInput.as"
#include "UIToggle.as"
#include "UIOption.as"
#include "UISlider.as"

#include "UILabel.as"

ACTION_FUNCTION@ _backCallback = ShowMainMenu;

//---

void ShowMainMenu( UI::Group@ group, UI::Control@ control )
{
	UI::Clear();
	UI::SetFont("menu");

	UI::AddGroup("mainmenu", Vec2f(0.185,0.93), Vec2f(0.45,0.98));
		UI::Grid( 2, 1, 0.05 );
		UI::Button::Add("Chat", SelectChat);
		 UI::Button::AddIcon("MenuItems.png", Vec2f(16, 16), 39 );
		UI::Button::Add("Wiki", SelectWiki);
		 UI::Button::AddIcon("MenuItems.png", Vec2f(16, 16), 39 );

	UI::Group@ g = UI::AddGroup("mainmenu 2", Vec2f(0.65,0.32), Vec2f(1.0,1.0));
		UI::Grid( 1, 5 );
		UI::Button::Add("Solo", ShowSingleplayerMenu);
		 UI::Button::AddIcon("MenuItems.png", Vec2f(32, 32), 31 );
		UI::Button::Add("Multiplayer", ShowMultiplayerMenu);
		 UI::Button::AddIcon("MenuItems.png", Vec2f(32, 32), 27 );
		UI::Button::Add("Settings", ShowSettingsMenu);
		 UI::Button::AddIcon("MenuItems.png", Vec2f(32, 32), 26 );
		UI::AddSeparator();
		UI::Button::Add("Quit", SelectQuitGame);
		 UI::Button::AddIcon("MenuItems.png", Vec2f(32, 32), 29 );
		g.proxy.renderFunc = RenderTitleBackgound;
	UI::SetLastSelection(0);
}

void RenderTitleBackgound( UI::Proxy@ proxy )
{
	if (proxy.group is null) return;

	float scaleX = getScreenWidth() / 1280.0;
	float scaleY = getScreenHeight() / 720.0;
	GUI::DrawIcon("TitleBackground", 0, Vec2f(1280, 720), Vec2f(0, 0), scaleX/2, scaleY/2, color_white);
	GUI::DrawIcon("title", 0, Vec2f(512, 128), Vec2f(int(1280-getScreenWidth())/-2, 8));
	// print(""+(1024-getScreenWidth())/-2);
}

void SelectQuitGame( UI::Group@ group, UI::Control@ control ){
	QuitGame(); // bye bye
}
void SelectChat( UI::Group@ group, UI::Control@ control ){
	OpenWebsite("http://webchat.quakenet.org/?channels=kag&nick="+getLocalPlayer().getUsername());
}
void SelectWiki( UI::Group@ group, UI::Control@ control ){
	OpenWebsite("https://wiki.kag2d.com/wiki/Main_Page");
}

//////////////////////////////////// SOLO /////////////////////////////////////

void ShowSingleplayerMenu( UI::Group@ group, UI::Control@ control )
{
	UI::Clear();
	_backCallback = ShowMainMenu;

	UI::AddGroup("Solo 1", Vec2f(0.3,0.13), Vec2f(0.7,0.4));
		UI::Grid( 1, 1, 0.1 );
		UI::Button::Add("Tutorials", SelectTutorials);
		 UI::Button::AddIcon("MenuItems.png", Vec2f(32, 32), 17 );

	UI::AddGroup("Solo 2", Vec2f(0.1,0.4), Vec2f(0.9,0.67));
		UI::Grid( 2, 1, 0.1 );
		UI::Button::Add("Save the Princess", SelectSaveThePrincess);
		 UI::Button::AddIcon("ChallengeIcon.png", Vec2f(48, 48) );
		UI::Button::Add("Challenges", SelectChallenges);
		 UI::Button::AddIcon("MenuItems.png", Vec2f(32, 32), 18 );

	UI::AddGroup("Solo 3", Vec2f(0.3,0.67), Vec2f(0.7,0.94));
		UI::Grid( 1, 1, 0.1 );
		UI::Button::Add("Sandbox", SelectSandbox);
		 UI::Button::AddIcon("MenuItems.png", Vec2f(32, 32), 8 );

	UI::AddGroup("Solo", Vec2f(0.01,0.87), Vec2f(0.22,0.98));
		UI::Fullscreen();
		UI::Grid( 1, 1, 0 );
		UI::Button::Add("Back", _backCallback);
		 UI::Button::AddIcon("MenuItems.png", Vec2f(32, 32), 2 );
	UI::SetLastSelection();
}

void SelectTutorials( UI::Group@ group, UI::Control@ control ){
	UI::Clear();
	_backCallback = ShowSingleplayerMenu;

	UI::AddGroup("Tutorials 1", Vec2f(0.3,0.13), Vec2f(0.7,0.6));
		UI::Fullscreen();
		UI::Grid( 1, 4, 0.1 );
		UI::Button::Add("Basics", SelectBasics);
		 UI::Button::AddIcon("BrowserTabs.png", Vec2f(32, 32) );

		UI::AddSeparator();
		UI::Button::Add("Capture the Flag", SelectCTF);
		 UI::Button::AddIcon("QuickJoin.png", Vec2f(32, 32), 4 );
		UI::Button::Add("Take the Halls", SelectTTH);
		 UI::Button::AddIcon("MenuItems.png", Vec2f(32, 32), 31 );

	UI::AddGroup("Tutorials", Vec2f(0.01,0.87), Vec2f(0.22,0.98));
		UI::Fullscreen();
		UI::Grid( 1, 1, 0 );
		UI::Button::Add("Back", _backCallback);
		 UI::Button::AddIcon("MenuItems.png", Vec2f(32, 32), 2 );

	UI::SetLastSelection();
}

void SelectBasics( UI::Group@ group, UI::Control@ control ){
	RegisterFileExtensionScript("Scripts/MapLoaders/LoadChallengePNG.as", "png");
	LoadRules("Rules/Challenge/gamemode.cfg");
	sv_mapautocycle = false;
	sv_mapcycle_shuffle = false;
	LoadMapCycle("Rules/Tutorials/tutorial_maps.cfg");
	LoadNextMap();
}

void SelectCTF( UI::Group@ group, UI::Control@ control ){
	RegisterFileExtensionScript("Scripts/MapLoaders/LoadPNGMap.as", "png");
	LoadRules("Rules/CTF/gamemode.cfg");
	sv_mapautocycle = false;
	sv_mapcycle_shuffle = false;
	LoadMapCycle("Rules/Tutorials/tutorial_ctf_maps.cfg");
	LoadNextMap();
}

void SelectTTH( UI::Group@ group, UI::Control@ control ){
	RegisterFileExtensionScript("Scripts/MapLoaders/LoadWarPNG.as", "png");
	LoadRules("Rules/WAR/gamemode.cfg");
	sv_mapautocycle = false;
	sv_mapcycle_shuffle = false;
	LoadMapCycle("Rules/Tutorials/tutorial_tth_maps.cfg");
	LoadNextMap();
}

void SelectSaveThePrincess( UI::Group@ group, UI::Control@ control ){
	print("SelectSaveThePrincess: 33");
	LoadRules("Rules/Challenge/gamemode.cfg");
	sv_mapautocycle = false;
	sv_mapcycle_shuffle = false;
	LoadMapCycle(  "Rules/Challenge/princess_maps.cfg" );
	LoadNextMap();
}

void SelectChallenges( UI::Group@ group, UI::Control@ control ){
	RegisterFileExtensionScript("Scripts/MapLoaders/LoadChallengePNG.as", "png");
	LoadRules("Rules/Challenge/gamemode.cfg");
	sv_mapautocycle = false;
	sv_mapcycle_shuffle = true;
	LoadMapCycle("Rules/Challenge/mapcycle.cfg");
	LoadNextMap();
}

void SelectSandbox( UI::Group@ group, UI::Control@ control ){
	RegisterFileExtensionScript("Scripts/MapLoaders/LoadPNGMap.as", "png");
	RegisterFileExtensionScript("Scripts/MapLoaders/GenerateFromKAGGen.as", "kaggen.cfg");

	LoadRules("Rules/Sandbox/gamemode.cfg");
	LoadMapCycle("Rules/Sandbox/mapcycle.cfg");
	LoadNextMap();
}

/////////////////////////////////// MULTI /////////////////////////////////////

void ShowMultiplayerMenu( UI::Group@ group, UI::Control@ control )
{
	UI::Clear();
	_backCallback = ShowMainMenu;

	if (/**f/false/*/!Engine::isAuthenticated()/**/){
		Engine::ShowLoginWindow();
		UI::Group@ g = UI::AddGroup("titlescreen", Vec2f(0,0), Vec2f(1.0,1.0));
		g.proxy.renderFunc = RenderTitleBackgound;
		return;
	}

	UI::AddGroup("Multiplayer 1", Vec2f(0.30,0.23), Vec2f(0.72,0.81));
		UI::Grid( 1, 3 );
		UI::Button::Add("Simple join", ShowSimpleJoin);
		 UI::Button::AddIcon("MenuItems.png", Vec2f(32, 32), 30 );
		UI::Button::Add("Browse servers", ShowBrowser);
		 UI::Button::AddIcon("MenuItems.png", Vec2f(32, 32), 27 );
		UI::Button::Add("Connect to...", ShowConnectTo);
		 UI::Button::AddIcon("MenuItems.png", Vec2f(32, 32), 5 );

	UI::AddGroup("Multiplayer", Vec2f(0.01,0.87), Vec2f(0.22,0.98));
		UI::Fullscreen();
		UI::Grid( 1, 1, 0 );
		UI::Button::Add("Back", _backCallback);
		 UI::Button::AddIcon("MenuItems.png", Vec2f(32, 32), 2 );
	UI::SetLastSelection();
}

void ShowSimpleJoin( UI::Group@ group, UI::Control@ control )
{
	UI::Clear();
	_backCallback = ShowMultiplayerMenu;

	UI::Control@ c;

	UI::AddGroup("Simple join 1 label", Vec2f(0.1,0.13), Vec2f(0.9,0.2));
		UI::Grid( 1, 1 );
		UI::Background();
		@c = UI::Label::Add("Pick game size:");
		 c.proxy.align.Set(0.5f, 0.5f);
		 c.vars.set( "caption centered", true );

	UI::AddGroup("Simple join 1", Vec2f(0.04,0.21), Vec2f(0.96,0.34));
		UI::Grid( 4, 1, 0.08 );
		UI::RadioButton::Add("<8 players", null, "size");
		 UI::Button::AddIcon("QuickJoin.png", Vec2f(32, 32), 0 );
		UI::RadioButton::Add("8-20 players", null, "size");
		 UI::Button::AddIcon("QuickJoin.png", Vec2f(32, 32), 1 );
		UI::RadioButton::Add(">20 players", null, "size");
		 UI::Button::AddIcon("QuickJoin.png", Vec2f(32, 32), 2 );
		@c = UI::RadioButton::Add("Don't care", null, "size");
		 UI::Button::AddIcon("QuickJoin.png", Vec2f(32, 32), 3 );
		 c.action(c.group, c);

	UI::AddGroup("Simple join 2 label", Vec2f(0.1,0.39), Vec2f(0.9,0.46));
		UI::Grid( 1, 1 );
		UI::Background();
		@c = UI::Label::Add("Choose game mode:");
		 c.proxy.align.Set(0.5f, 0.5f);
		 c.vars.set( "caption centered", true );

	UI::AddGroup("Simple join 2", Vec2f(0.04,0.47), Vec2f(0.96,0.6));
		UI::Grid( 4, 1, 0.08 );
		@c = UI::RadioButton::Add("Capture the Flag", null, "mode");
		 c.proxy.align.Set(0.1f, 0.5f);
		 UI::Button::AddIcon("QuickJoin.png", Vec2f(32, 32), 4 );
		@c = UI::RadioButton::Add("Take the Halls", null, "mode");
		 c.proxy.align.Set(0.1f, 0.5f);
		 UI::Button::AddIcon("QuickJoin.png", Vec2f(32, 32), 5 );
		@c = UI::RadioButton::Add("Team Deathmatch", null, "mode");
		 c.proxy.align.Set(0.1f, 0.5f);
		 UI::Button::AddIcon("QuickJoin.png", Vec2f(32, 32), 6 );
		@c = UI::RadioButton::Add("Don't care", null, "mode");
		 c.action(c.group, c);
		 UI::Button::AddIcon("QuickJoin.png", Vec2f(32, 32), 3 );

	UI::AddGroup("Simple join 3", Vec2f(0.1,0.61), Vec2f(0.9,0.74));
		UI::Grid( 3, 1, 0.08 );
		UI::RadioButton::Add("Sandbox", null, "mode");
		 UI::Button::AddIcon("QuickJoin.png", Vec2f(32, 32), 8 );
		UI::RadioButton::Add("Co-op challenge", null, "mode");
		 UI::Button::AddIcon("QuickJoin.png", Vec2f(32, 32), 9 );
		UI::RadioButton::Add("Custom content", null, "mode");
		 UI::Button::AddIcon("QuickJoin.png", Vec2f(32, 32), 10 );

	UI::AddGroup("Simple join 4", Vec2f(0.5,0.78), Vec2f(0.77,0.91));
		UI::Grid( 1, 1, 0.08 );
		UI::Button::Add("Play!", SimpleJoinPlay);
		 UI::Button::AddIcon("QuickJoin.png", Vec2f(32, 32), 12 );

	UI::AddGroup("Simple join", Vec2f(0.01,0.87), Vec2f(0.22,0.98));
		UI::Fullscreen();
		UI::Grid( 1, 1, 0 );
		UI::Button::Add("Back", _backCallback);
		 UI::Button::AddIcon("MenuItems.png", Vec2f(32, 32), 2 );
	UI::SetLastSelection();
}

bool simplyJoining = false;
void SimpleJoinPlay( UI::Group@ group, UI::Control@ control )
{
	if (simplyJoining) {
		return;
	}

	simplyJoining = true;
	string gamemodeName = "";
	UI::Control@ modeControl;
	if(getRules().get("radio set mode selection", @modeControl)){
		gamemodeName = getShortGamemodeName(modeControl.caption);
	}

	getBrowser().filter =
		"/password/0/maxPlayerPercentage/0.99" +
		(modeControl.caption == "Custom content" ? "/usingMods/1" : "") +
		(gamemodeName != "" ? "/gameMode/" + gamemodeName : "");
	//print("getBrowser().filter: "+getBrowser().filter);

	getBrowser().RequestList();
}

void SimpleJoinOnRequestList( CRules@ this )
{
	this.set("OnPinged", SimpleJoinSortAndConnect);
	this.AddScript("PingServers");
}

void SimpleJoinSortAndConnect()
{
	simplyJoining = false;
	int sizeCategory = 3;
	UI::Control@ sizeControl;
	if(getRules().get("radio set size selection", @sizeControl)){

	}

	print("allServers.length: " + allServers.length);
	Server[] eligible;
	for (int i = 0; i < allServers.length; ++i)
		if (allServers[i].ping >= 0 && allServers[i].ping < 200
			&& SimpleJoinIsInRange(sizeCategory, allServers[i].currentPlayers)) {
			eligible.push_back(Server(allServers[i]));
		}

	if (eligible.length == 0) {
		MessageBox("No appropriate game found, sorry!",
			"No active, low ping game was found meeting your criteria.\nTry Adjusting the criteria, or pick a game manually through the server browser.\n\nGames with more players will usually be up the top of the browser.\n\nIf you can't find any servers, please check your internet connection!",
			true);

		return;
	}

	int tempSort = g_sort;
	g_sort = 1;
	eligible.sortDesc();
	g_sort = 0;
	eligible.sortDesc();
	g_sort = tempSort;

	for (int i = 0; i < eligible.length; ++i)
		if (eligible[i].s.currentPlayers > 0) {
			APIServer@ s = eligible[i].s;
			getNet().SafeConnect(s.serverIPv4Address +":"+ s.serverPort);
			return;
		}

	APIServer@ s = eligible[0].s;
	getNet().SafeConnect(s.serverIPv4Address +":"+ s.serverPort);
}

bool SimpleJoinIsInRange(int sizeCategory, int players)
{
	return (sizeCategory == 0 && players < 8) ||
			(sizeCategory == 1 && players >= 8 && players <= 20) ||
			(sizeCategory == 2 && players > 20) ||
			(sizeCategory == 3);
}

void ShowConnectTo( UI::Group@ group, UI::Control@ control )
{
	UI::Clear();
	_backCallback = ShowMultiplayerMenu;

	UI::AddGroup("Connect to... 1", Vec2f(0.30,0.3), Vec2f(0.72,0.7));
		UI::Grid( 1, 3 );
		UI::TextInput::Add("IP:Port", SetIP, cl_joinaddress);
		UI::TextInput::Add("Password", SetPass, cl_password);
		UI::Button::Add("Connect", ConnectTo);
		 UI::Button::AddIcon("MenuItems.png", Vec2f(32, 32), 28 );

	UI::AddGroup("Connect to...", Vec2f(0.01,0.87), Vec2f(0.22,0.98));
		UI::Fullscreen();
		UI::Grid( 1, 1, 0 );
		UI::Button::Add("Back", _backCallback);
		 UI::Button::AddIcon("MenuItems.png", Vec2f(32, 32), 2 );
	UI::SetLastSelection();
}

string SetIP( const string &in caption )
{
	return cl_joinaddress = caption;
}

string SetPass( const string &in caption )
{
	return cl_password = caption;
}

void ConnectTo( UI::Group@ group, UI::Control@ control )
{
	string[]@ split = cl_joinaddress.split(":");
	if (split.length != 2) return;

	_backCallback = ShowMainMenu;
	getNet().SafeConnect(split[0] +":" +split[1]);
	//ExitToMenu();
}

///////////////////////////////////////////////////////////////////////////////
////////////////////////////////// SETTINGS ///////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

void ShowSettingsMenu( UI::Group@ group, UI::Control@ control )
{
	UI::Clear();
	UI::AddGroup("Settings", Vec2f(0.01,0.87), Vec2f(0.22,0.98));
		UI::Fullscreen();
		UI::Grid( 1, 1, 0 );
		UI::Button::Add("Back", _backCallback);
		 UI::Button::AddIcon("MenuItems.png", Vec2f(32, 32), 2 );

	UI::AddGroup("Settings tabs", Vec2f(0.0,0.125), Vec2f(1,0.22));
		UI::Grid( 4, 1, 0.03);
		UI::TabsGroup();
		UI::Control@ playerButton =
			UI::RadioButton::Add("Player", ShowPlayerMenu, "settings");
		UI::RadioButton::Add("Input", ShowInputMenu, "settings");
		UI::RadioButton::Add("Video", ShowVideoMenu, "settings");
		UI::RadioButton::Add("Sound", ShowSoundMenu, "settings");

	playerButton.action(playerButton.group, playerButton);
	UI::SetSelection(0);

	@UI::getData().activeGroup = UI::getGroup("Settings");
}

const string PLAYER_SETTINGS_STRING = "Player settings";
const string INPUT_SETTINGS_STRING = "Input settings";
const string VIDEO_SETTINGS_STRING = "Video settings";
const string SOUND_SETTINGS_STRING = "Sound settings";

void ClearRadioGroups()
{
	UI::Clear(PLAYER_SETTINGS_STRING);
	UI::Clear("Heads label");
	UI::Clear("Heads");
	UI::Clear(INPUT_SETTINGS_STRING);
	UI::Clear(VIDEO_SETTINGS_STRING);
	UI::Clear(SOUND_SETTINGS_STRING);
}

/////////////////////////////////// PLAYER ////////////////////////////////////

#include "UIHeadButton.as"

void ShowPlayerMenu( UI::Group@ group, UI::Control@ control )
{
	ClearRadioGroups();

	UI::AddGroup(PLAYER_SETTINGS_STRING, Vec2f(0.2,0.3), Vec2f(0.6,0.9));
		UI::Grid( 1, 6 );

		UI::TextInput::Add( "Character name:", SetCharName, cl_name, "Your character's name", 20 );
		UI::TextInput::Add( "Clantag:", SetClanName, cl_clantag, "Show allegiance to a clan (if you have one)", 5 );
		UI::Option::Add( "Gender:", SetGender, "Male|Female", cl_sex, "Your character's gender" );
		UI::Toggle::Add( "Fixed camera", SetFixedCam, g_fixedcamera, "On - platform style\nOff - mouse look/Soldat style" );
		UI::Toggle::Add( "Show team-mates names", SetTeammateNames, u_shownames, "Show names on players" );
		UI::Toggle::Add( "Show chat bubbles", SetChatBubbles, cl_chatbubbles, "Show chat on players" );

	UI::AddGroup("Heads label", Vec2f(0.6,0.3), Vec2f(0.9,0.355));
		UI::Grid( 1, 1, 0 );
		UI::Label::Add( "Head:" );

	UI::AddGroup("Heads", Vec2f(0.6,0.355), Vec2f(0.9,0.9));
		UI::Grid( 7, 10, 0 );
		UI::Background();
		//UI::getData().activeGroup.proxy.renderFunc = UI::RenderGroup;

		for (int i = 0; i < 69; ++i)
			UI::HeadButton::Add();
		UI::AddSeparator();

	@UI::getData().activeGroup = group;
}

//simple setters
string SetCharName( const string &in caption )	{ return cl_name		= caption;	}
string SetClanName( const string &in caption )	{ return cl_clantag		= caption;	}
int  SetGender			( int option )			{ return cl_sex			= option;	}
bool SetFixedCam		( bool toggle )			{ return g_fixedcamera	= toggle;	}
bool SetTeammateNames	( bool toggle )			{ return u_shownames	= toggle;	}
bool SetChatBubbles		( bool toggle )			{ return cl_chatbubbles	= toggle;	}

//////////////////////////////////// VIDEO ////////////////////////////////////

void ShowVideoMenu( UI::Group@ group, UI::Control@ control )
{
	ClearRadioGroups();

	UI::AddGroup(VIDEO_SETTINGS_STRING, Vec2f(0.3,0.3), Vec2f(0.7,0.9));
		UI::Grid( 1, 5 );
		UI::Toggle::Add( "Smooth shader", SetShaders, v_postprocess, "Smooths the game screen using hq2x filter (will lower performance)" );
		UI::Toggle::Add( "Faster graphics", SetQuality, v_fastrender, "Check this if game is choppy or slow" );
		UI::Toggle::Add( "Uncap framerate", SetUncapped, v_uncapped, "Check this to have unlimited FPS (uncheck if you have slow performance!)" );
		UI::Toggle::Add( "VSync", SetVSync, v_vsync ,"Sync rendering with monitor refresh rate (prevents tearing). Requires restart" );
		UI::Toggle::Add( "Kids safe", SetKidsSafe, g_kidssafe, "Parental control - no gore" );

	@UI::getData().activeGroup = group;
}

//simple setters
bool SetShaders	( bool toggle )	{ return v_postprocess	= toggle; }
bool SetQuality	( bool toggle )	{ return v_fastrender	= toggle; }
bool SetUncapped( bool toggle )	{ return v_uncapped		= toggle; }
bool SetVSync	( bool toggle )	{ return v_vsync		= toggle; }
bool SetKidsSafe( bool toggle )	{ return g_kidssafe		= toggle; }


//////////////////////////////////// SOUND ////////////////////////////////////

void ShowSoundMenu( UI::Group@ group, UI::Control@ control )
{
	ClearRadioGroups();

	UI::AddGroup(SOUND_SETTINGS_STRING, Vec2f(0.3,0.3), Vec2f(0.7,0.9));
		UI::Grid( 1, 5 );
		UI::Scroll::Add( "Sound volume:", SetSoundVolume, s_volume, 0.05, 100, "%" );
		UI::Slider::Add( "Music volume:", SetMusicVolume, s_musicvolume, 0.05, 100, "%" );
		UI::Toggle::Add( "Game music", SetGameMusic, s_gamemusic, "Turn on/off the game music" );
		UI::Toggle::Add( "Menu music", SetMenuMusic, s_menumusic, "Turn on/off the menu music" );
		UI::Toggle::Add( "Swap audio channels", SetSwapChannels, s_swapchannels, "Check this if your sound is inverted" );

	@UI::getData().activeGroup = group;
}

bool SetGameMusic	( bool toggle ) { return s_gamemusic	= toggle;	}
bool SetMenuMusic	( bool toggle ) { return s_menumusic	= toggle;	}
bool SetEffects		( bool toggle ) { return s_effects		= toggle;	}
bool SetSwapChannels( bool toggle ) { return s_swapchannels	= toggle;	}
float SetSoundVolume( float value ) { return s_volume		= value;	}
float SetMusicVolume( float value ) { return s_musicvolume	= value;	}

//////////////////////////////////// INPUT ////////////////////////////////////

u8 selectedPlayer = 0;

#include "ActionKeys.as"

void ShowInputMenu( UI::Group@ group, UI::Control@ control )
{
	ClearRadioGroups();

	uint players = getLocalPlayersCount();
	CControls@ controls = getControls(selectedPlayer);

	UI::AddGroup(INPUT_SETTINGS_STRING, Vec2f(0.3,0.3), Vec2f(0.7,0.95));
		UI::Grid( 2, 18, 0.1 );
		if (players > 1) {
			string options = "PLAYER 1";
			for (int i = 1; i < players; ++i)
				options += "|PLAYER "+(i+1);
			UI::Option::Add( "", SetPlayer, options, selectedPlayer );
		} else
			UI::AddSeparator();
		UI::AddSeparator();

		for (int i = 0; i < actionKeyLabels.length; ++i) {
			UI::Control@ control = UI::Button::Add(controls.getActionKeyKeyName(actionKeyLabels[i].ak), ModifyKey);
			 UI::Label::Add(actionKeyLabels[i].label);
			control.proxy.align.Set(0.5f, 0.5f);
			control.vars.set( "caption centered", true );
		}

		UI::AddSeparator();
		 UI::AddSeparator();
		UI::Button::Add("Reset to defaults", SetKeyboardDefaults);
		 UI::AddSeparator();

	@UI::getData().activeGroup = group;
}

int SetPlayer( int option ) {
	selectedPlayer = option;
	ShowInputMenu(UI::getData().activeGroup, null);
	return selectedPlayer;
}

void ModifyKey( UI::Group@ group, UI::Control@ control )
{
	string label = group.controls[1][control.y].caption;
	E_ACTIONKEYS ak;
	for (int i = 0; i < actionKeyLabels.length; ++i)
		if (actionKeyLabels[i].label == label) {
			ak = actionKeyLabels[i].ak;
			break;
		}

	CRules@ rules = getRules();
	rules.set("modify key callback", BackToInputMenu );
	rules.set_u8("modify key", ak);
	rules.set_u8("selected player", selectedPlayer);

	rules.AddScript("modifykey");
}

void BackToInputMenu()
{
	ShowInputMenu(UI::getData().activeGroup, null);
}

void SetKeyboardDefaults( UI::Group@ group, UI::Control@ control )
{
	CControls@ controls = getControls( selectedPlayer );

	controls.MapActionKey( AK_MOVE_LEFT, KEY_KEY_A );
	controls.MapActionKey( AK_MOVE_RIGHT, KEY_KEY_D );
	controls.MapActionKey( AK_MOVE_UP, KEY_KEY_W );
	controls.MapActionKey( AK_MOVE_DOWN, KEY_KEY_S );
	controls.MapActionKey( AK_ACTION1, KEY_LBUTTON );
	controls.MapActionKey( AK_ACTION2, KEY_RBUTTON );
	controls.MapActionKey( AK_ACTION3, KEY_SPACE );
	controls.MapActionKey( AK_INVENTORY, KEY_KEY_F );
	controls.MapActionKey( AK_USE, KEY_KEY_E );
	controls.MapActionKey( AK_PICKUP, KEY_KEY_C );
	controls.MapActionKey( AK_ZOOMIN, MOUSE_SCROLL_UP );
	controls.MapActionKey( AK_ZOOMOUT, MOUSE_SCROLL_DOWN );
	controls.MapActionKey( AK_BUBBLES, KEY_KEY_Q );
	controls.MapActionKey( AK_MAP, KEY_KEY_M );
	controls.MapActionKey( AK_TAUNTS, KEY_KEY_V );

	BackToInputMenu();
}

///////////////////////////////////////////////////////////////////////////////
/////////////////////////////// SERVER BROWSER ////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

#include "UIServerButton.as"
#include "UIServerInfo.as"
#include "UIMapPreview.as"

string search = "";
void ShowBrowser( UI::Group@ group, UI::Control@ control )
{
	UI::Clear();
	_backCallback = ShowMultiplayerMenu;

	UI::Control@ c;

	UI::AddGroup("Server browser list", Vec2f(0.01,0.13), Vec2f(0.605,0.66));
		UI::Grid( 1, 8, 0.0 );
		for (int i = 0; i < 8; ++i)
			UI::AddSeparator();
		UI::Background();

	UI::AddGroup("Server browser list favourites", Vec2f(0.01,0.13), Vec2f(0.045,0.66));
		UI::Grid( 1, 8, 0.4 );
		for (int i = 0; i < 8; ++i)
			UI::AddSeparator();

	UI::AddGroup("Server browser scroll", Vec2f(0.605,0.13), Vec2f(0.65,0.66));
		UI::Grid( 1, 1, 0.0 );
		UI::VerticalScrollbar::Add(ScrollServers, 1, 1.1);

	UI::AddGroup("Server browser info", Vec2f(0.65,0.13), Vec2f(0.99,0.86));
		UI::Grid( 1, 1, 0.05 );
		UI::Background();
		UI::ServerInfo::Add(null);

	UI::AddGroup("Server browser map preview", Vec2f(0.65,0.18), Vec2f(0.99,0.36));
		UI::Grid( 1, 1, 0.01 );
		UI::AddSeparator();

	UI::AddGroup("Server browser m1", Vec2f(0.01,0.66), Vec2f(0.4,0.72));
		UI::Grid( 1, 1, 0.0 );
		@c = UI::TextInput::Add("", SetSearch, search, "", 0, "Instant search...");
		 c.proxy.align.Set(0.02f, 0.5f);
		 c.vars.set("caption centered", false);
		 c.input = UpdateSearch;

	UI::AddGroup("Server browser m2", Vec2f(0.4,0.66), Vec2f(0.645,0.72));
		UI::Grid( 1, 1, 0.0 );
		UI::Option::Add("", SetSort, "Player count|Ping|Game mode|Map size|Server name|Favourites only", g_sort);

	UI::AddGroup("Server browser m3", Vec2f(0.01,0.72), Vec2f(0.645,0.86));
		UI::Grid( 2, 2, 0.1 );
		UI::Background();
		@c = UI::Option::Add("Game mode:", SetGamemode, "All|Capture the Flag|Take the Halls|Team Deathmatch|Challenges", 0);
		 int option = -1;
		 string[] options;
		 c.vars.get( "options", options );
		 for (int i = 0; i < options.length; ++i)
		 	if (options[i] == g_filtermode) {
		 		option = i;
		 		break;
		 	}

		 if (option == -1) {
		 	option = options.length;
		 	options.push_back(g_filtermode);
		 }
		 c.vars.set( "current option", option );
		 c.caption = g_filtermode;

		@c = UI::Button::Add("Modded", ToggleFilterModded);
		 c.proxy.align.Set(0.3f, 0.5f);
		 UI::Button::AddIcon("MenuItems.png", Vec2f(16, 16), 81+(7+g_filtergold)%9, 0.5 );
		@c = UI::RangeSlider::Add("Players:", SetPlayersLower, SetPlayersUpper, g_filterplayerlower/100.0, g_filterplayerupper/100.0, 0.05, 100, "%");
		 c.processMouse = RangeSliderProcessMouse;
		@c = UI::Button::Add("Password", ToggleFilterPass);
		 c.proxy.align.Set(0.3f, 0.5f);
		 UI::Button::AddIcon("MenuItems.png", Vec2f(16, 16), 81+(7+g_filterpass)%9, 0.5 );

	UI::AddGroup("Server browser b1", Vec2f(0.78,0.87), Vec2f(0.99,0.98));
		UI::Grid( 1, 1, 0 );
		UI::Button::Add("Play", UI::ServerButton::PlayServer);
		 UI::Button::AddIcon("MenuItems.png", Vec2f(32, 32), 30 );

	UI::AddGroup("Server browser b2", Vec2f(0.395,0.87), Vec2f(0.605,0.98));
		UI::Grid( 1, 1, 0 );
		UI::Button::Add("Refresh", Refresh);
		 UI::Button::AddIcon("MenuItems.png", Vec2f(32, 32), 21 );

	UI::AddGroup("Server browser", Vec2f(0.01,0.87), Vec2f(0.22,0.98));
		UI::Fullscreen();
		UI::Grid( 1, 1, 0 );
		UI::Button::Add("Back", _backCallback);
		 UI::Button::AddIcon("MenuItems.png", Vec2f(32, 32), 2 );
	UI::SetLastSelection();

	SetupFilter();
	servers.clear();
	getBrowser().RequestList();
	requested = true;
}

void UpdateSearch( UI::Control@ control, const s32 key, bool &out ok, bool &out cancel ){
	UI::TextInput::Input( control, key, ok, cancel );
	CRules@ rules = getRules();
	if (key != 0) {
		rules.set_u32("search update time", getGameTime());
	} else {
		uint gameTime = getGameTime();
		uint updateTime = rules.get_u32("search update time");
		if (updateTime == 0) {
			rules.set_u32("search update time", gameTime);
			updateTime = gameTime;
		}

		if (gameTime == updateTime + 10) {
			search = control.caption;
			ApplyFilters();
			SortServers();
		}
	}
}

string getShortGamemodeName(string longName)
{
	if (longName == "Capture the Flag")
		return "CTF";
	if (longName == "Take the Halls")
		return "TTH";
	if (longName == "Challenges" || longName == "Co-op challenge")
		return "Challenge";
	if (longName == "Don't care" || longName == "Custom content")
		return "";
	return longName;
}

void SetupFilter()
{
	getBrowser().filter =
		(g_filtergold != 2 ? "/usingMods/" + g_filtergold : "") +
		(g_filterpass != 2 ? "/password/"  + g_filterpass : "") +
		(g_filtermode != "All" ? "/gameMode/"  + getShortGamemodeName(g_filtermode) : "") +
		"/minPlayerPercentage/" + (g_filterplayerlower/100.0) +
		"/maxPlayerPercentage/" + (g_filterplayerupper/100.0);
		//print("getBrowser().filter: "+getBrowser().filter);
}

class Server{
	APIServer@ s;

	Server(APIServer@ _s) {@s = _s;}
	int opCmp (const Server &in other) const {
		if (g_sort == 1) {//Ping
			return (other.s.ping+9999)%9999 > (s.ping+9999)%9999 ? 1 : ((other.s.ping+9999)%9999 < (s.ping+9999)%9999 ? -1 : 0); //-2 (not responding) becomes 9997
		} else if (g_sort == 2) {//Game mode
			return other.s.gameMode > s.gameMode ? -1 : (other.s.gameMode < s.gameMode ? 1 : 0);
		} else if (g_sort == 3) {//Map size
			return other.s.mapW > s.mapW ? -1 : (other.s.mapW < s.mapW ? 1 : 0);
		} else if (g_sort == 4) {//Server name
			return other.s.serverName > s.serverName ? 1 : (other.s.serverName < s.serverName ? -1 : 0);
		} else {//Player count or Favourites only
			return other.s.currentPlayers > s.currentPlayers ? -1 : (other.s.currentPlayers < s.currentPlayers ? 1 : 0);
		}
	}
};

APIServer@[] allServers;
Server[] servers;
bool requested = false;

void Refresh( UI::Group@ group, UI::Control@ control )
{
	if (requested) return;

	servers.clear();
	UI::Data@ data = UI::getData();
	UI::Control@ scroll = UI::getGroup(data, "Server browser scroll").controls[0][0];
	scroll.vars.set( "value", ScrollServers(-1) );
	getRules().set("radio set servers selection", null);
	SetupFilter();
	getBrowser().RequestList();

	UI::Group@ active = data.activeGroup;
	UI::Group@ info = UI::getGroup(data, "Server browser info");
	@data.activeGroup = info;
	UI::ClearGroup(info);
	UI::ServerInfo::Add(null);
	UI::Group@ map = UI::getGroup(data, "Server browser map preview");
	@data.activeGroup = map;
	UI::ClearGroup(map);
	UI::AddSeparator();
	@data.activeGroup = active;

	requested = true;
}

void OnRequestList( CRules@ this )
{
	if(UI::hasGroup("Simple join")){ // SimpleJoin hook
		SimpleJoinOnRequestList(this);
		return;
	}

	allServers.clear();
	getBrowser().getServersList(@allServers);

	ApplyFilters();
	SortServers();

	if (g_sort == 1) {
		this.set("OnPinged", SortServers);
		this.AddScript("PingServers");
	}
	requested = false;
}

void SortServers()
{
	servers.sortDesc();
	UI::Group@ group = UI::getGroup(UI::getData(), "Server browser scroll");
	if (group is null) return;
	UI::Control@ scroll = group.controls[0][0];
	scroll.vars.set( "increment", servers.length > 8 ? 1.0/(servers.length-8) : 2 );
	scroll.vars.set( "value", ScrollServers(-1) );
}

#include "Favourites.as"
void ApplyFilters()
{
	servers.clear();
	for (int i = 0; i < allServers.length; ++i)
		if ((g_sort != 5 || isFavourite(allServers[i]))
			&& (search == ""
				|| allServers[i].serverName.find(search) != -1
				|| allServers[i].description.find(search) != -1
				|| allServers[i].serverIPv4Address.find(search) != -1
				|| allServers[i].gameMode.find(search) != -1
				|| hasPlayer(allServers[i], search))) {
			servers.push_back(Server(allServers[i]));
		}
}

bool hasPlayer(APIServer@ s, string name)
{
	APIPlayer@[] players;
	getBrowser().getServerPlayers(s, @players);

	for (int i = 0; i < players.length; ++i)
		if (players[i].username == name)
			return true;

	return false;
}

float ScrollServers( float newValue )
{
	UI::Data@ data = UI::getData();
	UI::Control@ scroll = UI::getGroup(data, "Server browser scroll").controls[0][0];
	float oldValue;
	scroll.vars.get( "value", oldValue );

	bool refresh = newValue == -1;
	if(refresh) newValue = 0;
	int offset = Maths::Round(Maths::Max(servers.length-8, 0) * newValue);
	if(offset == Maths::Round((servers.length-8) * oldValue) && !refresh) return newValue;

	UI::Group@ list = UI::getGroup(data, "Server browser list");

	int sunkenIndex = -1, selectedIndex = -1;
	UI::Control@ prev;
	if(getRules().get("radio set servers selection", @prev) && prev !is null){
		prev.vars.get( "i", sunkenIndex );
	}
	if (list.activeControl !is null) {
		list.activeControl.vars.get( "i", selectedIndex );
	}

	UI::Group@ active = data.activeGroup;
	@data.activeGroup = list;
// print("ClearGroup: "+list.name);
	UI::ClearGroup(list);
	for (int i = 0; i < 8; ++i)
		if(i < servers.length)
			UI::ServerButton::Add(servers[offset + i].s, offset + i);
		else
			UI::AddSeparator();

	sunkenIndex -= offset;
	selectedIndex -= offset;
	if (sunkenIndex >= 0 && sunkenIndex < 8) {
		UI::Control@ sunken = list.controls[0][sunkenIndex];
		getRules().set("radio set servers selection", @sunken);
		sunken.vars.set( "sunken", true );
	}
	if (selectedIndex >= 0 && selectedIndex < 8) {
		UI::SetSelection(selectedIndex);
	}

	@data.activeGroup = UI::getGroup(data, "Server browser list favourites");
	UI::ClearGroup(data.activeGroup);
	for (int i = 0; i < 8; ++i)
		if(i < servers.length)
			UI::FavouriteButton::Add(servers[offset + i].s);
		else
			UI::AddSeparator();

	@data.activeGroup = active;

	return newValue;
}

bool sliderMoved = false;
void RangeSliderProcessMouse( UI::Proxy@ proxy, u8 state ){
	UI::Slider::ProcessMouse(proxy, state);
	if (state == MouseEvent::UP && sliderMoved){
		Refresh(null, null);
		sliderMoved = false;
	}
}

float SetPlayersLower( float value )
{
	g_filterplayerlower = Maths::Round(value * 100);
	sliderMoved = true;
	return value;
}

float SetPlayersUpper( float value )
{
	g_filterplayerupper = Maths::Round(value * 100);
	sliderMoved = true;
	return value;
}

int SetSort( int value )
{
	g_sort = value;
	ApplyFilters();
	SortServers();
	return value;
}

string SetSearch( const string&in value )
{
	search = value;
	ApplyFilters();
	SortServers();
	return value;
}

int SetGamemode( int option )
{
	UI::Data@ data = UI::getData();
	UI::Control@ control = UI::getGroup(data, "Server browser m3").controls[0][0];

	string[] options;
	control.vars.get( "options", options );

	g_filtermode = options[option];
	Refresh(null, null);
	return option;
}

void ToggleFilterModded( UI::Group@ group, UI::Control@ control )
{
	g_filtergold = (g_filtergold + 1) % 3;
	@UI::getData().activeGroup.lastAddedControl = control;
	UI::Button::AddIcon("MenuItems.png", Vec2f(16, 16), 81+(7+g_filtergold)%9, 0.5 ); //magical formula for {0, 1, 2} -> {88, 89, 81}
	Refresh(null, null);
}

void ToggleFilterPass( UI::Group@ group, UI::Control@ control )
{
	g_filterpass = (g_filterpass + 1) % 3;
	@UI::getData().activeGroup.lastAddedControl = control;
	UI::Button::AddIcon("MenuItems.png", Vec2f(16, 16), 81+(7+g_filterpass)%9, 0.5 );
	Refresh(null, null);
}
