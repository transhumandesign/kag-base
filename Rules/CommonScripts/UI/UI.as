#include "UICommon.as"
#include "UICommonUpdates.as"
#include "UIProxy.as"
// UI include

// TODO:
// - make virtual funcitonality for different gizmos
// - make a render object / separated from data for transitions

namespace MouseEvent {
	enum MouseEvent {
		HOVER = 0,
		DOWN,
		HOLD,
		UP,
	}
}

namespace UI
{
	// CONTROL FUNCTIONS
	funcdef void ACTION_FUNCTION( Group@, Control@ ); //main action
	funcdef void INPUT_FUNCTION( Control@, const s32, bool &out, bool &out ); // editable control process keys
	funcdef void MOUSE_FUNCTION( Proxy@, u8); //process mouse
	funcdef void MOVE_FUNCTION( Control@, const bool ); //process left/right

	shared class Control
	{
		int x;
		int y;
		string caption;
		string tooltip;
		bool selectable;
		ACTION_FUNCTION@ action;
		INPUT_FUNCTION@ input;
		MOUSE_FUNCTION@ processMouse;
		MOVE_FUNCTION@ move;
		dictionary vars;

		Group@ group;
		Proxy@ proxy;
	};

	shared class Group
	{
		Control@[][] controls;
		string name;
		Vec2f upperLeft;
		Vec2f lowerRight;
		int columns;
		int rows;
		float paddingFactor;

		// runtime
		Control@ activeControl;
		int selx, sely;
		bool modal;

		Control@ lastAddedControl;
		Control@ editControl;

		Data@ data;
		Proxy@ proxy;
	};

	shared class Data
	{
		Group@[] groups;
		bool canControl;
		bool selecting;
		Group@ activeGroup;
		Proxy@ dragProxy;

		string font;

		Proxy@[] proxies;


		// useful
		dictionary lastSelection;
		u32 holdKeyTime;

		// cache
		CRules@ rules;
		Vec2f screenSize;
	};

	Data@ getData( CRules@ rules ){
		Data@ data;
		rules.get( "ui", @data );
		return data;
	}

	Data@ getData(){
		return getData( getRules() );
	}

	void Clear()
	{
		Data@ data = getData();

		// remove proxies
		RemoveProxies( data );

		data.groups.clear();
		@data.activeGroup = null;
	}

	void Clear( string groupName )
	{
		Data@ data = getData();
		if (data is null){
			warn("UI:Clear: no data; have you added UIHooks to rules?");
			return;
		}
		for (uint groupIt = 0; groupIt < data.groups.length; groupIt++)
		{
			Group@ group = data.groups[ groupIt ];
			if (group.name == groupName){
				if (data.activeGroup is group)
					@data.activeGroup = null;

				// remove proxy
				RemoveProxies( data, group );

				data.groups.erase( groupIt );
				break;
			}
		}
	}

	bool hasGroup( string groupName )
	{
		Data@ data = getData();
		for (uint groupIt = 0; groupIt < data.groups.length; groupIt++)
		{
			Group@ group = data.groups[ groupIt ];
			if (group.name == groupName){
				return true;
			}
		}
		return false;
	}

	bool hasAnyGroup()
	{
		Data@ data = getData();
		return data.groups.length > 0;
	}

	Group@ getGroup( Data@ data, string groupName )
	{
		for (uint groupIt = 0; groupIt < data.groups.length; groupIt++)
		{
			Group@ group = data.groups[ groupIt ];
			if (group.name == groupName){
				return group;
			}
		}
		return null;
	}

	Group@ getGroup( string groupName )
	{
		return getGroup( getData(), groupName );
	}

	Group@ AddGroup( string name, Vec2f upperLeft = Vec2f(0.25f, 0.25f), Vec2f lowerRight = Vec2f(0.75f, 0.75f) )
	{
		Data@ data = getData();

		Group group;
		group.name = name;
		group.upperLeft = upperLeft;
		group.lowerRight = lowerRight;
		group.rows = group.columns = 0;
		group.selx = group.sely = 0;
		group.modal = false;
		@group.data = data;

		data.groups.push_back( group );
		@data.activeGroup = group;
		@group.proxy = AddProxy( data, null, UpdateGroup, data.activeGroup, null, 0.0f );
		//group.proxy.renderFunc = RenderGroup;

		return data.activeGroup;
	}

	Control@ AddControl( string caption )
	{
		Data@ data = getData();

		if (data.groups.length == 0){
			warn("UI: No groups found to add control");
			return null;
		}

		Group@ group = data.activeGroup;

		Control control;
		control.caption = caption;
		@control.group = group;
		control.selectable = true;

		uint x = 0, y = 0;
		Control@ last = group.lastAddedControl;
		if (last !is null) {
			uint count = last.y * group.columns + last.x + 1;
			x = count % group.columns;
			y = count / group.columns;

			if (y == group.rows) {
				warn("UI: no space on grid to add control");
				return null;
			}
		}

		@group.controls[x][y] = control;
		control.x = x;
		control.y = y;
		@group.lastAddedControl = control;

		if (group.activeControl is null){
			@group.activeControl = control;
		}
		return control;
	}

	Control@ getControlByCaption( Group@ group, string caption )
	{
		for (uint y=0; y<group.rows; y++){
			for (uint x=0; x<group.columns; x++){
				if (group.controls[x][y] !is null)
				{
					Control@ pControl = group.controls[x][y];
					if (pControl.caption == caption)
						return pControl;
				}
			}
		}
		return null;
	}

	void AddSeparator()
	{
		Control@ c = AddControl("");
		c.selectable = false;
	}

	void SetSelection( int index ) //-1 = last; -2 = none
	{
		Data@ data = getData();
		Group@ group = data.activeGroup;
		if(group is null) return;

		if (index == -1){
			for (uint y = group.rows-1; y >= 0; y--){
				for (uint x = group.columns-1; x >= 0; x--){
					if (group.controls[x][y].selectable) {
						group.selx = x;
						group.sely = y;
						@group.activeControl = getActiveControl( group );
						data.lastSelection.set(group.name, getSelectionIndex(group, x, y));
						return;
					}
				}
			}
			index = -2;
		}

		if (index == -2){
			group.selx = 0;
			group.sely = 0;
			@group.activeControl = null;
			return;
		}

		group.selx = index % group.columns;
		group.sely = index / group.columns;
		@group.activeControl = getActiveControl( group );
		data.lastSelection.set(group.name, getSelectionIndex(group, group.selx, group.sely));

	}

	int getSelectionIndex( Group@ group, int cx, int cy )
	{
		return cx + cy * group.columns;
	}

	void SetLastSelection( const int fallbackIndex = -1 )
	{
		Data@ data = getData();
		Group@ group = data.activeGroup;
		// set last remembered selection
		if (group !is null && data.lastSelection.exists(group.name)){
			int index;
			data.lastSelection.get( group.name, index );
			SetSelection( index );
		}
		else {
			SetSelection( fallbackIndex );
		}
	}

	void SetFont( string font )
	{
		Data@ data = getData();
		data.font = font;
	}

	Vec2f getAbsolutePosition( Vec2f p, Vec2f size )
	{
		return Vec2f( p.x * size.x, p.y * size.y );
	}

	Vec2f getRelativePosition( Vec2f p, Vec2f size )
	{
		return Vec2f( p.x / size.x, p.y / size.y );
	}

	void Tick( CRules@ rules )
	{
		Data@ data = getData(rules);

		UpdateControls( rules );

		// update proxies
		for (uint pIt = 0; pIt < data.proxies.length; pIt++)
		{
			Proxy@ proxy = data.proxies[ pIt ];
			// remove dead proxy
			if (proxy.dead){
				data.proxies.erase( pIt );
				if (pIt > 0)
					pIt--;
				continue;
			}
			// update proxy
			if (proxy.updateFunc !is null){
				proxy.updateFunc( proxy );
			}
		}
	}

	void Render( CRules@ rules )
	{
		Data@ data = getData(rules);
		if (data is null || data.proxies.length == 0)
			return;

		GUI::SetFont( data.font );

		// draw proxies
		for (uint pIt = 0; pIt < data.proxies.length; pIt++)
		{
			Proxy@ proxy = data.proxies[ pIt ];
			if (proxy.renderFunc !is null){
				proxy.renderFunc( proxy );
			}
		}

		DrawTooltip(rules);
	}

	void DrawTooltip( CRules@ rules )
	{
		string text = rules.get_string("tooltip text");
		if(text == "") return;

		Vec2f dim;
		GUI::GetTextDimensions(text, dim);
		Vec2f pad(4, 10);
		Vec2f pos = rules.get_Vec2f("tooltip mousepos") - Vec2f(0, dim.y + 2*pad.y + 4) + pad;
		
		Vec2f tl = pos - pad;
		Vec2f br = pos + dim + pad + Vec2f(7, 3);
		Vec2f offset;

		// ensure fit on screen
		if(0 - tl.y > 0) offset.y += 0 - tl.y;
		if(getScreenWidth() - br.x < 0) offset.x += getScreenWidth() - br.x;
		tl += offset;
		br += offset;
		pos += offset;

		GUI::DrawSunkenPane(tl, br);
		GUI::DrawText(text, pos, color_black);
	}

	Proxy@ getProxyUnderCursor()
	{
		Data@ data = getData();
		Vec2f mouse = getControls().getMouseScreenPos();

		for (int pIt = data.proxies.length-1; pIt >= 0; --pIt)
		{
			Proxy@ proxy = data.proxies[ pIt ];
			if (proxy.control !is null){
				const bool mouseHover = (mouse.x > proxy.ul.x && mouse.x < proxy.lr.x && mouse.y > proxy.ul.y && mouse.y < proxy.lr.y);
				if (mouseHover){
					return proxy;
				}
			}
		}			
		
		return null;
	}

	void UpdateControls( CRules@ rules )
	{
		Data@ data = getData(rules);
		CControls@ controls = getControls();
		const u32 time = getGameTime();

//	    if (rules.isPlayerListShowing()) huh?
//	    	return;

		const bool mouse1 = controls.isKeyPressed(KEY_LBUTTON);
		const bool mouse1JustPressed = controls.isKeyJustPressed(KEY_LBUTTON);
		const bool mouse1JustReleased = controls.isKeyJustReleased(KEY_LBUTTON);

		const bool keyLeft = controls.ActionKeyPressed(AK_MOVE_LEFT) || controls.isKeyPressed(KEY_LEFT);
		const bool keyRight = controls.ActionKeyPressed(AK_MOVE_RIGHT) || controls.isKeyPressed(KEY_RIGHT);
		const bool keyUp = controls.ActionKeyPressed(AK_MOVE_UP) || controls.isKeyPressed(KEY_UP);
		const bool keyDown = controls.ActionKeyPressed(AK_MOVE_DOWN) || controls.isKeyPressed(KEY_DOWN);
		const bool keyAction1 = (controls.ActionKeyPressed(AK_ACTION1) && !controls.isKeyPressed(KEY_LBUTTON)) || controls.isKeyJustPressed(KEY_RETURN) || controls.isKeyPressed(KEY_SPACE);
		const bool keyAction2 = (controls.ActionKeyPressed(AK_ACTION2) && !controls.isKeyPressed(KEY_RBUTTON));
		const bool anyKeyPressed = keyLeft || keyRight || keyUp || keyDown || keyAction1 || keyAction2;
		
		//TODO: esc = a2 = back


		//---- MOUSE -----
		Proxy@ proxy = getProxyUnderCursor();

				//TODO: DEBUG
				// if(controls.isKeyJustPressed(KEY_KEY_H))
				// {
				// 	print("caption: "+proxy.caption+
				// 	 " selected: "+proxy.selected+
				// 	 " tooltip: "+proxy.control.tooltip 
				// 	 );
				// }
		//HOVER
		if (!mouse1 && proxy !is null && proxy.control.processMouse !is null){
			proxy.control.processMouse(proxy, MouseEvent::HOVER);

			if (proxy.control.input !is null && (controls.lastKeyPressed == MOUSE_SCROLL_UP
				|| controls.lastKeyPressed == MOUSE_SCROLL_DOWN)) {
				bool ok, cancel;
				proxy.control.input( proxy.control, controls.lastKeyPressed, ok, cancel );
			}	
		} 
		else {
			rules.set_string("tooltip text", "");
			// SetSelection(-2);
		}

		//DOWN
		if (mouse1JustPressed) {
			@data.dragProxy = proxy;
			
			//cancel edit
			if (data.activeGroup !is null) {
				Control@ editControl = data.activeGroup.editControl;
				if (editControl !is null && editControl.input !is null
					&& (proxy is null || editControl !is proxy.control)) {
					bool ok, cancel;
					editControl.input( editControl, KEY_ESCAPE, ok, cancel );
					if (ok || cancel){
						@data.activeGroup.editControl = null;
					}
				}
			}
			
			//focus/unfocus
			if (proxy !is null && proxy.control.selectable) {
				Control@ control = proxy.control;
				@data.activeGroup = control.group;
				@control.group.activeControl = control;
				control.group.selx = control.x;
				control.group.sely = control.y;
				if (proxy.control.processMouse !is null) {
					proxy.control.processMouse(proxy, MouseEvent::DOWN);
				}
			} else {
				SetSelection(-2);
			}
		}

		//HOLD
		if ((mouse1 || mouse1JustReleased) && data.dragProxy !is null 
			&& data.dragProxy.control !is null && data.dragProxy.control.processMouse !is null) {
			data.dragProxy.control.processMouse(data.dragProxy, MouseEvent::HOLD);
		}

		//UP
		if (mouse1JustReleased) {
			if (proxy !is null && proxy is data.dragProxy && proxy.control.processMouse !is null) {
				proxy.control.processMouse(proxy, MouseEvent::UP);
			}
		}

		// continuous keys update
		
		if (anyKeyPressed && data.canControl){
			data.holdKeyTime = time;
		}

		if (anyKeyPressed && !data.canControl){
			if ((time - data.holdKeyTime) > 7){
				data.canControl = true;
				data.holdKeyTime += 2;
			}
		}

		if (!anyKeyPressed){
			data.holdKeyTime = 0;
		}

		// control
					
		if (data.canControl && data.activeGroup !is null )
		{
			Group@ group = data.activeGroup;

			if (group.editControl !is null || controls.externalControl)
			{
				// cease control until all keys unpressed after exiting from external control
				if (group.editControl is null){
					data.canControl = false;
					return;
				}

				// input box control
				if (group.editControl.input !is null){
					bool ok, cancel;
					group.editControl.input( group.editControl, controls.lastKeyPressed, ok, cancel );
					if (ok || cancel){
						@group.editControl = null;
					}
				}
			}
			else
			{
				bool listMode = data.rules.hasTag("list mode");
				listMode = false; 
				if (keyLeft){
					if (listMode && group.activeControl !is null && group.activeControl.move !is null) {
						group.activeControl.move(group.activeControl, true);
					} else {
						MoveSelection( SelectDirection::LEFT );
					}
				}
				else if (keyRight){
					if (listMode && group.activeControl !is null && group.activeControl.move !is null) {
						group.activeControl.move(group.activeControl, false);
					} else {
						MoveSelection( SelectDirection::RIGHT );
					}
				}
				else if (keyUp){
					MoveSelection( SelectDirection::UP );
				}
				else if (keyDown){
					MoveSelection( SelectDirection::DOWN );
				}

				if(keyAction1)
				{
					Click( rules, group );
					Sound::Play("menuclick");
				}
				if (data.activeGroup is null){
					printf("EXIT UI");
					return;
				}

				if (anyKeyPressed){
					data.canControl = false;
				}
			}
		}

		if (!anyKeyPressed){
			data.canControl = true;
		}

		rules.set_bool("in menu", data.groups.length > 0);
	}

	void Click( CRules@ rules, Group@ group )
	{
		CPlayer@ local = getLocalPlayer();
		Control@ control = group.activeControl;
		if(group.activeControl is null) return;

		group.data.lastSelection.set( group.name, getSelectionIndex( group, control.x, control.y ) );

		// callback first
		if (control.action !is null){
			control.action( group, control );
		}
		else { // else send command
			CBitStream params;
			params.write_netid( local.getNetworkID() );
			params.write_string( group.name );
			params.write_string( control.caption );
			rules.SendCommand( rules.getCommandID(CMD_STRING), params );
			CBlob@ localBlob = local.getBlob();
			if (localBlob !is null){
				localBlob.SendCommand( localBlob.getCommandID(CMD_STRING), params );
			}
		}
		if (g_debug==1)
			printf("CLICK [" + group.name + "] " + control.caption);
	}

	void Init( CRules@ rules )
	{
		Driver@ driver = getDriver();

		Data data;
		data.canControl = true;
		data.screenSize.Set( driver.getScreenWidth(), driver.getScreenHeight() );
		@data.rules = rules;

		rules.set("ui", @data);

		rules.addCommandID(CMD_STRING);
}

	void Init( CBlob@ blob )
	{
		blob.addCommandID(CMD_STRING);
	}

	bool ReadCommand( CBitStream@ params, CPlayer@ &out player, string &out group, string &out caption )
	{
		@player = getPlayerByNetworkId( params.read_netid() );
		group = params.read_string();
		caption = params.read_string();
		return true;
	}

	bool ReadControlCommand( CRules@ rules, u8 cmd, CBitStream@ params, CPlayer@ &out player, string &out group, string &out caption )
	{
		if (cmd == rules.getCommandID(CMD_STRING))    	{
			return ReadCommand( params, player, group, caption );
		}
		return false;
	}

	bool ReadControlCommand( CBlob@ blob, u8 cmd, CBitStream@ params, CPlayer@ &out player, string &out group, string &out caption )
	{
		if (cmd == blob.getCommandID(CMD_STRING))    	{
			return ReadCommand( params, player, group, caption );
		}
		return false;
	}

	// sort these somewhere

	void Fullscreen()
	{
		Data@ data = getData();
		data.activeGroup.proxy.renderFunc = RenderGroupFullscreen;
		data.activeGroup.proxy.Z = -1;
		data.proxies.sortAsc();
	}

	void Background()
	{
		getData().activeGroup.proxy.renderFunc = RenderGroup;
	}

	void TabsGroup()
	{
		getData().activeGroup.proxy.renderFunc = RenderTabsGroup;
	}

	void Grid( int columns, int rows, float paddingFactor = 0.37 )
	{
		Data@ data = getData();
		if (data.groups.length == 0){
			warn("UI: No groups found for grid setting");
			return;
		}

		Group@ group = data.activeGroup;
		group.columns = columns;
		group.rows = rows;
		group.paddingFactor = paddingFactor;

		group.controls.resize(columns);
		for (uint i=0; i<columns; i++){
			group.controls[i].resize(rows);
		}
	}

	void ClearGroup( Group@ group )
	{
		for (uint y=0; y<group.rows; y++){
			for (uint x=0; x<group.columns; x++){
				RemoveProxies( group.data, group.controls[x][y] );
				@group.controls[x][y] = null;
			}
		}
		group.selx = group.sely = 0;
		@group.lastAddedControl = null;
	}

} // GUI
