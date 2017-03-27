#include "UI.as"
#include "UILabel.as"
#include "UIButton.as"
#include "UICommonUpdates.as"

//int _dialogCount = 0;

namespace UI
{
	namespace Dialog
	{
		void Message( const string &in caption )
		{
			// save current selection
			Group@ oldGroup = UI::getData().activeGroup;
			Group@ group = UI::AddGroup("dialog 1", Vec2f(0.35,0.4), Vec2f(0.65,0.6));
			group.modal = true;
			group.proxy.Z = 2.0f;
			UI::Grid( 1, 2 );
			UI::Background();
			Control@ control = UI::Label::Add( caption, 3.0f );
			control.proxy.align.Set(0.5f, 0.5f);
			control.vars.set( "caption centered", true );
			Control@ ok = UI::Button::Add( "OK", Cancel, "", 3.0f );
			ok.proxy.align.Set(0.5f, 0.5f);
			ok.vars.set( "caption centered", true );
			ok.vars.set( "activeGroup", oldGroup );

			UI::SetSelection(-1);
		}

		funcdef void Input_Callback( const string &in );

		void Input( const string &in label, Input_Callback@ callback, string caption = "", 
			string tooltip = "", const uint maxChars = 0, string placeholder = "", const bool password = false )
		{
			// save current selection
			Group@ oldGroup = UI::getData().activeGroup;
			Group@ group = UI::AddGroup("dialog 1", Vec2f(0.35,0.4), Vec2f(0.65,0.6));
			group.modal = true;
			group.proxy.Z = 2.0f;
			UI::Grid( 1, 2, 0.25 );
			UI::Background();

			Control@ control = UI::TextInput::Add( label, null, caption, tooltip, maxChars, placeholder, password );
			control.proxy.align.Set(0.5f, 0.5f);
			control.proxy.Z = 3.0f;
			control.vars.set( "caption centered", true );
			UI::AddSeparator();

			Group@ group2 = UI::AddGroup("dialog 2", Vec2f(0.35,0.5), Vec2f(0.65,0.6));
			group2.modal = true;
			group2.proxy.Z = 2.0f;
			UI::Grid( 2, 1, 0.25 );

			Control@ ok = UI::Button::Add( "OK", Ok, "", 3.0f );
			ok.proxy.align.Set(0.5f, 0.5f);
			ok.vars.set( "caption centered", true );
			ok.vars.set( "activeGroup", oldGroup );
			ok.vars.set( "callback", @callback );
			ok.vars.set( "textInput", @control );

			Control@ cancel = UI::Button::Add( "Cancel", Cancel, "", 3.0f );
			cancel.proxy.align.Set(0.5f, 0.5f);
			cancel.vars.set( "caption centered", true );
			cancel.vars.set( "activeGroup", oldGroup );

			UI::SetSelection(-1);
		}

		void Cancel( UI::Group@ group, UI::Control@ control )
		{
			Group@ oldGroup;
			control.vars.get( "activeGroup", @oldGroup );
			@group.data.activeGroup = UI::getGroup( group.data, oldGroup.name ); // we get by name because somehow pointer changes (Angelscript WTF!?)
			UI::Clear( "dialog 1" );
			UI::Clear( "dialog 2" );
		}

		void Ok( UI::Group@ group, UI::Control@ control )
		{
			Cancel(group, control);

			Input_Callback@ callback;
			control.vars.get("callback", @callback );
			if (callback !is null){
				Control@ textInput;
				control.vars.get("textInput", @textInput );
				callback( textInput.caption );
			}
		}
	}
}