#include "UI.as"
#include "UICommonUpdates.as"

namespace UI
{
	namespace Option
	{
		funcdef int OPTION_FUNC( int );

		Control@ Add( const string &in label, OPTION_FUNC@ setFunc, string optionsString, int option, string tooltip = "" )
		{
			Data@ data = getData();
			Control@ control = AddControl( "" );
			control.tooltip = tooltip;
			@control.input = Input;
			@control.action = Action;
			@control.processMouse = ProcessMouse;
			@control.move = Move;
			control.vars.set( "set func", @setFunc );
			control.vars.set( "current option", option );
			control.vars.set( "selected", option );
			string[] options = optionsString.split("|");
			control.vars.set( "options", options );
			control.vars.set( "label", label );
			@control.proxy = AddProxy( data, Render, NoTransitionUpdate, data.activeGroup, control, 1.0f );
			
			if (option >= options.length)
				option = 0;
			control.caption = options[option];

			return control;
		}

		void Input( Control@ control, const s32 key, bool &out ok, bool &out cancel )
		{
			ok = false;
			cancel = false;
			CControls@ controls = getControls();
			const u32 time = getGameTime();
			bool dropped = hasGroup("drop down");

			u32 lastTime;
			s32 lastKey;
			control.vars.get( "last key time", lastTime);
			control.vars.get( "last key", lastKey);
			int selected;
			control.vars.get( "selected", selected );
			string[] options;
			control.vars.get( "options", options );

		//	printf("lastKey " + lastKey + " " + key);
			
			if (lastKey != key && lastKey != -1 || lastTime + 10 < time || key == MOUSE_SCROLL_UP || key == MOUSE_SCROLL_DOWN)
			{
				if (key == KEY_RETURN || key == controls.getActionKeyKey(AK_ACTION1) && key != KEY_LBUTTON){
					ok = true;
					Commit(control);
					Sound::Play("menuclick" );
					Deselect();
				}
				else if (key == KEY_ESCAPE || key == controls.getActionKeyKey(AK_ACTION2) && key != KEY_RBUTTON){
					cancel = true;
					//Sound::Play("back");
					Deselect();
				}
				else if (key == KEY_UP || key == KEY_LEFT || key == controls.getActionKeyKey(AK_MOVE_UP) 
					|| key == MOUSE_SCROLL_UP && !dropped)
				{
					if (selected > 0) {
						control.vars.set( "selected", selected - 1 );
						Sound::Play("select");
						if (!dropped) {
							Commit(control);
						}
					}
				}
				else if (key == KEY_DOWN || key == KEY_RIGHT || key == controls.getActionKeyKey(AK_MOVE_DOWN)
					|| key == MOUSE_SCROLL_DOWN && !dropped)
				{
					if (selected < options.length - 1) {
						control.vars.set( "selected", selected + 1 );
						Sound::Play("select");
						if (!dropped) {
							Commit(control);
						}
					}
				}
			}

			if (lastKey != key){
				control.vars.set( "last key", key );
				control.vars.set( "last key time", time );
			}
		}

		void Action( Group@ group, Control@ control )
		{
			@group.editControl = control;
			string[] options;
			control.vars.get( "options", options );
			int currentOption;
			control.vars.get( "current option", currentOption );
			control.vars.set( "selected", currentOption );
			control.vars.set( "last key", -1 );
			control.vars.set( "last key time", getGameTime() );

			Data@ data = getData();
			Vec2f screenSize = data.screenSize;
			Proxy@ proxy = control.proxy;

			Vec2f proxy_ul = proxy.ul;
			string label = "";
			if(proxy.control.vars.get("label", label) && label != "") {
				Vec2f textDim;
				GUI::GetTextDimensions( label, textDim );
				proxy_ul.y += textDim.y;
			}

			Vec2f pad(3, Maths::Max((proxy.lr.y - proxy_ul.y - 30) / 2, 3.0));
			Vec2f ul = proxy_ul + pad + Vec2f(0, proxy.lr.y - proxy_ul.y - pad.y*2);
			Vec2f lr = proxy.lr - pad + Vec2f(0, OPTION_HEIGHT * options.length);
			ul = getRelativePosition(ul, data.screenSize);
			lr = getRelativePosition(lr, data.screenSize);

			Group@ dropGroup = AddGroup("drop down", ul, lr);
				Grid( 1, 1 );
				AddControl("");
			dropGroup.proxy.Z = 1.5;
			data.proxies.sortAsc();
			@dropGroup.proxy.renderFunc = RenderOptions;
			@dropGroup.proxy.control = control;
			@data.activeGroup = group;
		}

		void Commit(Control@ control)
		{
			string[] options;
			int currentOption;
			int selected;
			control.vars.get( "options", options );
			control.vars.get( "current option", currentOption );
			control.vars.get( "selected", selected );

			OPTION_FUNC@ setFunc;
			control.vars.get( "set func", @setFunc );
			if (setFunc !is null){
				currentOption = setFunc( selected );

			}
			control.vars.set( "current option", currentOption );
			control.caption = options[currentOption];
		}

		void Deselect()
		{
			//print("Deselect");
			UI::Clear("drop down");
		}

		void ProcessMouse( Proxy@ proxy, u8 state)
		{
			Control@ control = proxy.control;
			//print("processMouse control: "+proxy.caption+" state: "+state);

			string[] options;
			control.vars.get( "options", options );
			if ((state == MouseEvent::HOVER || state == MouseEvent::HOLD) && proxy.caption == ""){
				Vec2f mouse = getControls().getMouseScreenPos();
				Vec2f pos(	(mouse.x - proxy.ul.x) / (proxy.lr.x - proxy.ul.x),
							(mouse.y - proxy.ul.y) / (proxy.lr.y - proxy.ul.y));
				if (pos.x > 0 && pos.x < 1 && pos.y > 0 && pos.y < 1) {
					control.vars.set( "selected", pos.y * options.length );;
				}
			}

			if (state == MouseEvent::HOVER && control.tooltip != ""){
				UpdateTooltip(control.tooltip);
			}

			if (proxy.caption == "") { //drop down proxy
				if (state == MouseEvent::UP) {
					Commit(control);
					Sound::Play("menuclick" );
					Deselect();
				}
			} else if (hasGroup("drop down")) {
				if (state == MouseEvent::UP)
					UI::Clear("drop down");
			} else if (state == MouseEvent::UP && control.action !is null) {
				Data@ data = getData();
				control.action( data.activeGroup, control);
				Sound::Play("menuclick");
			}
		}

		void Move( UI::Control@ control, const bool left )
		{
			int selected;
			control.vars.get( "selected", selected );
			string[] options;
			control.vars.get( "options", options );

			if (selected == (left ? 0 : options.length - 1)) return;
			control.vars.set( "selected", selected + (left ? -1 : 1) );
			Commit(control);
			Sound::Play("select");
		}
	}
}