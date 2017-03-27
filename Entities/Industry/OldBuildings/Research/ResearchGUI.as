// Research GUI
// WAR script!

#include "ScrollCommon.as"
#include "WAR_Structs.as"
#include "RulesCore.as"
#include "ResearchCommon.as"

void onInit(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
}

void onRender( CSprite@ this )
{	   	
	CBlob@ localBlob = getLocalPlayerBlob();
	CBlob@ blob = this.getBlob();
	if (localBlob is null || localBlob.isKeyPressed(key_inventory) ||
		localBlob.isKeyJustPressed(key_left) || localBlob.isKeyJustPressed(key_right) || localBlob.isKeyJustPressed(key_up) ||
		localBlob.isKeyJustPressed(key_down) || localBlob.isKeyJustPressed(key_action2) || localBlob.isKeyJustPressed(key_action3))
	{
		blob.Untag("show research");
		getHUD().menuState = 0;
		return;
	}

	CBlob@ carried = localBlob.getCarriedBlob();
	if (carried !is null && carried.getName() == "scroll" && carried.hasTag("tech"))
	{
		blob.Untag("show research");
		getHUD().menuState = 0;
		return; //no special render if we're gonna stick in a scroll
	}

	Vec2f center = blob.getPosition();
	Vec2f mouseWorld = getControls().getMouseWorldPos();
	const f32 renderRadius = (blob.getRadius()) * 0.95f;
	if (blob.hasTag("show research"))
	{
		CHUD@ hud = getHUD();
		hud.menuState = 1;
		hud.disableButtonsForATick = true; // no buttons while drawing this

		Vec2f pos2d = blob.getScreenPos();	  pos2d.y += 20.0f;
		CCamera@ camera = getCamera();
		f32 zoom = camera.targetDistance;
		Vec2f size(800,480);
		Vec2f mouse = getControls().getMouseScreenPos();
		string label = "Demolition Bo Technology";
		Vec2f labeldim;
		GUI::GetTextDimensions( label , labeldim );

		int teamNum = blob.getTeamNum();

		Vec2f upperleft( pos2d.x-size.x*0.5f, pos2d.y-size.y*0.5f );
		Vec2f lowerright( pos2d.x+size.x*0.5f, pos2d.y+size.y*0.5f );
		
		GUI::DrawRectangle( upperleft, lowerright );
		GUI::SetFont("menu");
		GUI::DrawText( "Click the items you vote to research!", upperleft+Vec2f(10,10), SColor(0xffffffff) );
		GUI::DrawText( "Yellow paths show what will be researched when the match starts.", upperleft+Vec2f(10,24), SColor(0xffffc64b) );
		GUI::DrawText( "Red path items can only be bought for gold at trader.", upperleft+Vec2f(10,38), SColor(0xffff4b4b) );

		ResearchStatus@ stat;
		blob.get( "techs", @stat );	   		
		if(stat is null) return;
		
		ScrollSet@ scrolls = stat.scrolls;		
		for (uint i = 0; i < scrolls.names.length; i++)
		{
			const string defname = scrolls.names[i];
			ScrollDef@ def;
			scrolls.scrolls.get( defname, @def);
			if (def is null)
				continue;
			
			Vec2f buttonUL, buttonLR, buttonIcon;
			getButtonFromDef( def, upperleft, buttonUL, buttonLR, buttonIcon );
			Vec2f buttonSize( buttonLR.x-buttonUL.x, buttonLR.y-buttonUL.y );

			const bool hasTech = def.hasTech();
			const bool mouseHover = (mouse.x > buttonUL.x && mouse.x < buttonLR.x && mouse.y > buttonUL.y && mouse.y < buttonLR.y);

			for (uint i = 0; i < def.connections.length; i++)
			{
				const string nextName = def.connections[i];
				ScrollDef@ nextdef = getScrollDef( scrolls, nextName );
				if (nextdef is null)
					continue;
				
				const bool hasNextTech = nextdef.hasTech();

				Vec2f nextButtonUL, nextButtonLR, nextButtonIcon;
				getButtonFromDef( nextdef, upperleft, nextButtonUL, nextButtonLR, nextButtonIcon );

				Vec2f a,b;
				getArrowPositions( a, b, buttonUL, buttonLR, nextButtonUL, nextButtonLR, buttonSize );

				bool researching = stat.isResearching(nextName, defname);

				if(hasNextTech)
				{
					GUI::DrawArrow2D( a, b, SColor(255, 51, 102, 13) );

				}
				else if(researching)
				{
					GUI::DrawArrow2D( a, b, SColor(0xff9dca22) );
				}
				else 
				{
					GUI::DrawArrow2D( a, b, SColor(0xff660d0d) );
				}

				if (researching)
				{
					Vec2f abNorm = b-a;
					f32 abLen = abNorm.Normalize();
					GUI::DrawLine2D( a, a + (abNorm) * abLen * nextdef.percent, SColor(255, 51, 102, 13) );
				}
			}

			// draw 0 tech arrow
			if (def.level <= 0.0f)
			{
				bool researching = stat.isResearching(defname, defname);
				if (researching)
				{
					Vec2f a = Vec2f(upperleft.x+2, buttonUL.y+buttonSize.y/2.0f);
					Vec2f b = Vec2f(buttonUL.x, buttonUL.y+buttonSize.y/2.0f);
					GUI::DrawArrow2D( a, b, SColor(255, 66, 72, 75) );
					Vec2f abNorm = b-a;
					f32 abLen = abNorm.Normalize();
					GUI::DrawLine2D( a, a + (abNorm) * abLen * def.percent, SColor(0xff9dca22) );
				}
			}

			DrawButton( blob, def, defname, buttonUL, buttonLR, labeldim, buttonIcon, localBlob, mouseHover, false );
		
		}
	
		// draw voted path

		for (uint i = 0; i < stat.researchers.length; i++)
		{
			ResearchPoint@ p = stat.researchers[i];
			if(p is null || p.targets.length <= 0)
				continue;
			
			string current = p.target;
			for(uint j = 0; j < p.targets.length; j++)
			{
				const string next = p.targets[j];
				
				ScrollDef@ curdef;
				ScrollDef@ nextdef;
				if (scrolls.scrolls.get( current, @curdef) && curdef !is null &&
					scrolls.scrolls.get( next, @nextdef) && nextdef !is null)
				{
					Vec2f buttonUL, buttonLR, buttonIcon;
					getButtonFromDef( curdef, upperleft, buttonUL, buttonLR, buttonIcon );
					Vec2f buttonSize( buttonLR.x-buttonUL.x, buttonLR.y-buttonUL.y );

					Vec2f nextButtonUL, nextButtonLR, nextButtonIcon;
					getButtonFromDef( nextdef, upperleft, nextButtonUL, nextButtonLR, nextButtonIcon );

					Vec2f a,b;
					getArrowPositions( a, b, buttonUL, buttonLR, nextButtonUL, nextButtonLR, buttonSize );

				//	DrawButton( blob, curdef, current, buttonUL, buttonLR, labeldim, buttonIcon, localBlob, false, true );

					GUI::DrawArrow2D( a, b, SColor(0xffffc64b) );
				}
				current = next;
			}
		}
	
	}  // E
}

const int button_gapwidth = 4*30;

void getButtonFromDef( ScrollDef@ def, Vec2f upperleft, Vec2f &out ul, Vec2f &out lr, Vec2f &out iconPos )
{
	const f32 buttonsize = 50.0f;
	ul = upperleft + Vec2f( buttonsize/2.0f + 2.0f * def.level + 14.0f * 0.1f * button_gapwidth * def.level, 16.0f + buttonsize * (def.tier+1.0f) * 2.0f);
	iconPos = ul + Vec2f(10.0f,10.0f);
	lr.x = ul.x + buttonsize;
	lr.y = ul.y + buttonsize;
} 

void getArrowPositions( Vec2f &out a, Vec2f &out b, Vec2f buttonUL, Vec2f buttonLR, Vec2f nextButtonUL, Vec2f nextButtonLR, Vec2f buttonSize )
{
	const bool nextOnTheRight = nextButtonUL.x > buttonLR.x;
	const bool nextOnIsLower = nextButtonUL.y > buttonLR.y;	  
	a.x = nextOnTheRight ? buttonLR.x : buttonLR.x - buttonSize.x/2.0f;
	a.y = nextOnTheRight ? buttonUL.y + buttonSize.y/2.0f : nextOnIsLower ? buttonLR.y : buttonUL.y;
	b.x = nextOnTheRight ? nextButtonUL.x : nextButtonUL.x + buttonSize.x/2.0f;
	b.y = nextOnTheRight ? nextButtonUL.y + buttonSize.y/2.0f : nextOnIsLower ? nextButtonUL.y : nextButtonLR.y;
}

void DrawButton( CBlob@ blob, ScrollDef@ def, const string &in defname, Vec2f buttonUL, Vec2f buttonLR, Vec2f labeldim, Vec2f buttonIcon, CBlob@ localBlob, const bool mouseHover, const bool color )
{
	if (def.hasTech())
	{
		GUI::DrawButtonPressed( buttonUL, buttonLR);
	}
	else
	{
		(mouseHover && !def.researching) ? GUI::DrawButtonHover( buttonUL, buttonLR) : color ? GUI::DrawRectangle( buttonUL, buttonLR ) : GUI::DrawButton( buttonUL, buttonLR );
	}

	if(def.votes > 0 && !def.hasTech() )
	{
		GUI::DrawText( ""+def.votes, buttonUL, buttonLR, SColor(0xffffffff), true, true );
	}

	if (mouseHover)
	{
		string suffix;
		if (def.hasTech())
			suffix = " \n\n(available)";
		else if (def.researching)
			suffix = " \n\n(researching - " + uint16(def.timeSecs * (1-def.percent)) + "s)";
		else
			suffix = " \n\n(click to vote)";

		GUI::SetFont("menu");
		GUI::DrawText( def.name + suffix, Vec2f(buttonLR.x - labeldim.x/2.0f, buttonLR.y), color_white );

		if(localBlob.isKeyJustPressed(key_action1) && !def.hasTech() && !def.researching) //avoid sending pointless cmds
		{
			CBitStream params;
			params.write_string(localBlob.getPlayer().getUsername());
			params.write_string(defname);
			blob.SendCommand( blob.getCommandID(tech_vote_cmd), params );
		}
	}


	GUI::DrawIcon( "MiniIcons.png", def.scrollFrame, Vec2f(16,16), buttonIcon, 1.0f, blob.getTeamNum() );
}