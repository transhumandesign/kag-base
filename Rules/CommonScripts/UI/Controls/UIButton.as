#include "UI.as"
#include "UICommonUpdates.as"

namespace UI
{
	namespace Button
	{
		Control@ Add( string caption, ACTION_FUNCTION@ action, string tooltip = "", const f32 Z = 1.0f )
		{
			Data@ data = getData();
			Control@ control = AddControl( caption );
			control.tooltip = tooltip;
			@control.action = action;
			@control.processMouse = DefaultProcessMouse;
			@control.proxy = AddProxy( data, Render, NoTransitionUpdate, data.activeGroup, control, Z );
			control.proxy.align.Set(0.2f, 0.5f);
			return control;
		}

		void AddIcon( string icon, Vec2f size, int iconFrame = 0, float scale = 1 )
		{
			Control@ control = getData().activeGroup.lastAddedControl;
			control.vars.set( "icon", icon );
			control.vars.set( "icon size", size );
			control.vars.set( "icon frame", iconFrame );
			control.vars.set( "icon scale", scale );
		}
	}

	namespace RadioButton
	{
		Control@ Add( string caption, ACTION_FUNCTION@ action, string radioSet, string tooltip = "", const f32 Z = 1.0f )
		{
			Control@ control = UI::Button::Add(caption, RadioAction, tooltip, Z);
			control.vars.set( "radio set", radioSet );
			control.vars.set( "action", @action );

			return control;
		}

		void RadioAction( Group@ group, Control@ control )
		{
			string radioSet;
			control.vars.get( "radio set", radioSet );
			string rulesString = "radio set " + radioSet + " selection";
			CRules@ rules = getRules();

			Control@ prev;
			if(rules.get(rulesString, @prev)){
				prev.vars.set( "sunken", false );
			}

			rules.set(rulesString, @control);
			control.vars.set( "sunken", true );

			ACTION_FUNCTION@ action;
			control.vars.get("action", @action );
			if (action !is null){
				action( group, control );
			}
		}
	}
}