#include "UI.as"
#include "UICommonUpdates.as"

namespace UI
{
	namespace Toggle
	{
		funcdef bool TOGGLE_FUNC( bool );

		Control@ Add( const string &in caption, TOGGLE_FUNC@ setFunc, bool defaultOn, string tooltip = "" )
		{
			Data@ data = getData();
			Control@ control = AddControl( caption );
			control.tooltip = tooltip;
			@control.action = Action;
			@control.processMouse = DefaultProcessMouse;
			control.vars.set( "set func", @setFunc );
			control.vars.set( "toggle", defaultOn );
			control.vars.set( "caption offset", Vec2f(25, 0) );
			@control.proxy = AddProxy( data, Render, NoTransitionUpdate, data.activeGroup, control, 1.0f );
			return control;
		}

		void Action( Group@ group, Control@ control )
		{
			bool toggle;
			control.vars.get( "toggle", toggle );
			toggle = !toggle;

			TOGGLE_FUNC@ setFunc;
			control.vars.get("set func", @setFunc );
			if (setFunc !is null){
				toggle = setFunc( toggle );
			}

			control.vars.set( "toggle", toggle );
		}
	}
}