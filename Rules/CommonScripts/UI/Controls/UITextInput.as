#include "UI.as"
#include "UICommonUpdates.as"
#include "KeysHelper.as"

namespace UI
{
	namespace TextInput
	{
		funcdef string SET_FUNC( const string &in );

		Control@ Add( const string &in label, SET_FUNC@ setFunc, string caption = "", string tooltip = "", const uint maxChars = 0, string placeholder = "", const bool password = false )
		{
			Data@ data = getData();
			Control@ control = AddControl( caption );
			control.tooltip = tooltip;
			@control.input = Input;
			@control.action = Action;
			@control.processMouse = DefaultProcessMouse;
			control.vars.set( "set func", @setFunc );
			control.vars.set( "password", password );
			control.vars.set( "placeholder", placeholder );
			control.vars.set( "max chars", maxChars );
			control.vars.set( "label", label );
			control.vars.set( "caption centered", true );
			@control.proxy = AddProxy( data, Render, NoTransitionUpdate, data.activeGroup, control, 1.0f );
			control.proxy.align.Set(0.5f, 0.5f);
			return control;
		}

		// TextInput Proxy callbacks

		void Input( Control@ control, const s32 key, bool &out ok, bool &out cancel )
		{
			ok = false;
			cancel = false;
			CControls@ controls = getControls();
			const bool shift = (controls.isKeyPressed( KEY_LSHIFT ) || controls.isKeyPressed( KEY_RSHIFT ));
			const bool ctrl = (controls.isKeyPressed( KEY_LCONTROL ) || controls.isKeyPressed( KEY_RCONTROL ));
			const u32 time = getGameTime();
			u32 lastTime;
			s32 lastKey;
			s32 maxChars;
			control.vars.get("last key time", lastTime);
			control.vars.get("last key", lastKey);
			control.vars.get("max chars", maxChars);
			controls.externalControl = true;

		//	printf("lastKey " + lastKey + " " + key);
			
			if (lastKey != key && lastKey != -1 || lastTime + 10 < time)
			{
				if (key == KEY_RETURN || key == KEY_ESCAPE){
					ok = true;
					SET_FUNC@ setFunc;
					control.vars.get("set func", @setFunc );
					if (setFunc !is null){
						control.caption = setFunc( control.caption );
					}
					if (key == KEY_RETURN){
						Sound::Play("menuclick" );
					}
					controls.externalControl = false;
				} else if (key == KEY_BACK){
					if (!control.caption.isEmpty()){
						control.caption.resize( control.caption.length()-1 );
					}
				} else if (ctrl && key == KEY_KEY_V){
					control.caption += getFromClipboard();
				} else if (ctrl && key == KEY_KEY_C){
					CopyToClipboard(control.caption);
				} else {
					control.caption += getCharFromKey(key, shift);
				}
				
				if (maxChars != 0) {
					control.caption.resize( Maths::Min(control.caption.length(), maxChars) );
				}
			}

			if (lastKey != key){
				control.vars.set("last key", key);
				control.vars.set("last key time", time);
			}
		}

		void Action( Group@ group, Control@ control )
		{
			@group.editControl = control;
			control.vars.set("last key", -1);
			control.vars.set("last key time", getGameTime());
		}
	}
}