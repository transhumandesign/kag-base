#include "ActionKeys.as"

u8 selectedPlayer;
int timeStart = 0;
s32 startKey;
s32 oldlastKeyPressed = 0;
funcdef void RETURN_FUNCTION();

void onInit( CRules@ this )
{
	selectedPlayer = this.get_u8("selected player");
	timeStart = getGameTime();
	CControls@ controls = getControls(selectedPlayer);
	startKey = controls.lastKeyPressed;
	printf("startKey " + controls.lastKeyPressed  );
}

void onTick( CRules@ this )
{
	// init cause onInit wont be called
	if (timeStart == 0){
		onInit( this );
	}

	CControls@ controls = getControls(selectedPlayer);
	const u32 time = getGameTime();
	getControls().externalControl = true;

	// prevent key from menu to interfere
	if (startKey == controls.lastKeyPressed)
		return;
	startKey = -1;

	// not too soon to prevent mistakes
	if (time - timeStart < 10)
		return;


	// cancel with escape
	if (controls.lastKeyPressed == KEY_ESCAPE)
	{
		Exit( this );
		return;
	}
	else if (controls.lastKeyPressed > 0) 
	{
		oldlastKeyPressed = controls.lastKeyPressed;
	}
	else
	{
		// set key on release
		if (oldlastKeyPressed > 0 && controls.lastKeyPressed == 0)
		{
			E_ACTIONKEYS ak = E_ACTIONKEYS(this.get_u8("modify key"));
			printf("SET KEY " + ak );
			controls.MapActionKey( ak, oldlastKeyPressed );
			Exit( this );
		}
		oldlastKeyPressed = 0;
	}
}

void onRender( CRules@ this )
{
	Driver@ driver = getDriver();
	Vec2f screenSize( driver.getScreenWidth(), driver.getScreenHeight() );
	const u32 time = getGameTime();
	E_ACTIONKEYS ak = E_ACTIONKEYS(this.get_u8("modify key"));

	// if (time % 15 < 6){
	// 	GUI::DrawRectangle( Vec2f(0,0), screenSize, SColor(162,0,0,0) );
	// }
	// else{
		GUI::DrawRectangle( Vec2f(0,0), screenSize, SColor(202,0,0,0) );
		string label;
		for (int i = 0; i < actionKeyLabels.length; ++i)
			if (actionKeyLabels[i].ak == ak) {
				label = actionKeyLabels[i].label;
				break;
			}
		GUI::DrawTextCentered( "Press a key for " + label + "...", screenSize*0.5f, color_white );
	// }
}


void Exit( CRules@ this )
{
	getControls().externalControl = false;
	timeStart = 0;
	this.RemoveScript("modifykey");

	RETURN_FUNCTION@ callback;
	this.get("modify key callback", @callback );
	callback();

	printf("EXIT KEY MODIFY");
}