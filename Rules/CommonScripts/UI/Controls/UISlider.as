#include "UI.as"
#include "UICommonUpdates.as"

namespace UI
{
	funcdef float SLIDER_FUNC( float );

	namespace Scroll
	{

		Control@ Add( const string &in caption, SLIDER_FUNC@ setFunc, float value, float increment, float multiplier, string currency = "" )
		{
			Data@ data = getData();
			Control@ control = AddControl( caption );
			@control.input = Input;
			@control.action = Action;
			@control.processMouse = ProcessMouse;
			@control.move = Move;
			control.vars.set( "set func", @setFunc );
			control.vars.set( "value", value );
			control.vars.set( "increment", increment );
			control.vars.set( "multiplier", multiplier );
			control.vars.set( "currency", currency );
			@control.proxy = AddProxy( data, Render, Update, data.activeGroup, control, 1.0f );
			return control;
		}

		void Update( Proxy@ proxy  )
		{
			NoTransitionUpdate( proxy );

			if (proxy.control !is null && proxy.control.caption != "")
			{
				float increment, value, value2, multiplier;
				string currency, caption;
				proxy.control.vars.get( "value", value );
				proxy.control.vars.get( "increment", increment );
				proxy.control.vars.get( "multiplier", multiplier );
				proxy.control.vars.get( "currency", currency );
				proxy.caption = proxy.control.caption + " " + Maths::Round(value * multiplier) + "" + currency;
				if (currency == "/"){
					proxy.caption += multiplier;
				}
				if (proxy.control.vars.get( "value2", value2 )){
					proxy.caption += " to " + Maths::Round(value2 * multiplier) + "" + currency;
				}
			}
		}

		void Input( Control@ control, const s32 key, bool &out ok, bool &out cancel )
		{
			_Input( control, key, ok, cancel, false );
		}

		void _Input( Control@ control, const s32 key, bool &out ok, bool &out cancel, bool v )
		{
			ok = false;
			cancel = false;
			CControls@ controls = getControls();
			const u32 time = getGameTime();

			u32 lastTime;
			s32 lastKey;
			control.vars.get( "last key time", lastTime);
			control.vars.get( "last key", lastKey);
			bool hasValue2 = control.vars.exists( "value2" );
			bool altActive = control.vars.get("alt active", altActive) && altActive; //side effects feel so exploited right now

		//	printf("lastKey " + lastKey + " " + key);
			
			if (lastKey != key && lastKey != -1 || lastTime + 10 < time || key == MOUSE_SCROLL_UP || key == MOUSE_SCROLL_DOWN)
			{
				if (key == KEY_RETURN || key == controls.getActionKeyKey(AK_ACTION1) && key != KEY_LBUTTON){
					if (altActive || !hasValue2) {
						ok = true;
						control.vars.set("alt active", false);
						Sound::Play("back" );
					} else {
						control.vars.set("alt active", true);
						Sound::Play("menuclick" );
					}
				}
				else if (key == KEY_ESCAPE || key == controls.getActionKeyKey(AK_ACTION2) && key != KEY_RBUTTON){
					ok = true;
					control.vars.set("alt active", false);
					Sound::Play("back" );
				}
				else if (!v && (key == KEY_LEFT || key == controls.getActionKeyKey(AK_MOVE_LEFT))
					|| v && (key == KEY_UP || key == controls.getActionKeyKey(AK_MOVE_UP))
					|| key == MOUSE_SCROLL_UP)
				{
					Move( control, true );
				}
				else if (!v && (key == KEY_RIGHT || key == controls.getActionKeyKey(AK_MOVE_RIGHT))
					|| v && (key == KEY_DOWN || key == controls.getActionKeyKey(AK_MOVE_DOWN))
					|| key == MOUSE_SCROLL_DOWN)
				{
					Move( control, false );
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
			control.vars.set( "last key", -1 );
			control.vars.set( "last key time", getGameTime() );
		}

		void ProcessMouse( Proxy@ proxy, u8 state )
		{
			Control@ control = proxy.control;
			Vec2f mouse = getControls().getMouseScreenPos();
			//print("processMouse control: "+proxy.caption+" state: "+state);

			Vec2f ul = proxy.ul;
			Vec2f lr = proxy.lr;
			
			if (proxy.control.caption != "") {
				Vec2f textDim;
				GUI::GetTextDimensions( proxy.control.caption, textDim );
				ul.y += textDim.y;
			}
			
			Vec2f pad(3, Maths::Max((lr.y - ul.y - 30) / 2, 3.0));
			Vec2f size = lr - ul - pad * 2;
			Vec2f dim(size.y, size.y);

			float value;
			proxy.control.vars.get( "value", value );
			Vec2f offset = ul + pad
				+ Vec2f(dim.x + value * (lr - pad - dim * 3 - (ul + pad)).x, 0);

			bool inY = mouse.y > ul.y + pad.y && mouse.y < ul.y + pad.y + dim.y;

			if (state == MouseEvent::DOWN){
				control.vars.delete("drag x");
				if(mouse.x > offset.x && mouse.x < offset.x + dim.x && inY){
					control.vars.set( "drag x", mouse.x - offset.x );
				}
			} else if (state == MouseEvent::HOLD){
				float dragX;
				bool exists = control.vars.get( "drag x", dragX );
				if (exists) {
					float value = ((mouse.x - dragX) - dim.x - ul.x - pad.x) 
					/ (lr - pad - dim * 3 - (ul + pad)).x;
					if (value < 0.0f)
						value = 0.0f;
					if (value > 1.0f)
						value = 1.0f;

					SLIDER_FUNC@ setFunc;
					control.vars.get("set func", @setFunc );
					if (setFunc !is null){
						value = setFunc( value );
					}

					control.vars.set( "value", value );
				}
			} else if (state == MouseEvent::UP){
				if (control.vars.exists("drag x")) {
					control.vars.delete("drag x");
				} else {
					if(mouse.x > ul.x + pad.x && mouse.x < ul.x + pad.x + dim.x && inY)
						Move(proxy.control, true);

					if(mouse.x > lr.x - pad.x - dim.x && mouse.x < lr.x - pad.x && inY)
						Move(proxy.control, false);
				}
			}
		}

		void Move( UI::Control@ control, const bool left )
		{
			bool altActive = control.vars.get("alt active", altActive) && altActive;
			bool hasValue2 = control.vars.exists( "value2" );

			string valueString = altActive ? "value2" : "value";
			string otherValueString = !altActive ? "value2" : "value";
			string funcString = altActive ? "set func2" : "set func";
			
			float increment, value, otherValue;
			control.vars.get( valueString, value );
			control.vars.get( otherValueString, otherValue );
			control.vars.get( "increment", increment );
			if ((left ? value : 1 - value) < 0.00001 || increment > 1) return;
			value += (left ? -1 : 1) * increment;
			
			value = Maths::Max(value, 0.0f);
			value = Maths::Min(value, 1.0f);

			if (altActive) {
				value = Maths::Max(value, otherValue);
			} else if(hasValue2){
				value = Maths::Min(value, otherValue);
			}

			SLIDER_FUNC@ setFunc;
			control.vars.get(funcString, @setFunc );
			if (setFunc !is null){
				value = setFunc( value );
			}

			control.vars.set( valueString, value );
			Sound::Play("select");
		}
	}

	namespace VerticalScrollbar
	{
		Control@ Add( SLIDER_FUNC@ setFunc, float value, float increment)
		{
			Data@ data = getData();
			Control@ control = AddControl( "" );
			@control.input = Input;
			@control.action = UI::Scroll::Action;
			@control.processMouse = ProcessMouse;
			@control.move = UI::Scroll::Move;
			control.vars.set( "set func", @setFunc );
			control.vars.set( "value", value );
			control.vars.set( "increment", increment );
			@control.proxy = AddProxy( data, Render, NoTransitionUpdate, data.activeGroup, control, 1.0f );
			return control;
		}

		void Input( Control@ control, const s32 key, bool &out ok, bool &out cancel )
		{
			UI::Scroll::_Input( control, key, ok, cancel, true );
		}
		
		void ProcessMouse( Proxy@ proxy, u8 state )
		{
			Control@ control = proxy.control;
			Vec2f mouse = getControls().getMouseScreenPos();
			//print("processMouse control: "+proxy.caption+" state: "+state);

			Vec2f ul = proxy.ul;
			Vec2f lr = proxy.lr;

			Vec2f pad(Maths::Max((lr.x - ul.x - 30) / 2, 3.0), 3);
			Vec2f size = lr - ul - pad * 2;
			Vec2f dim(size.x, size.x);

			float value;
			proxy.control.vars.get( "value", value );
			Vec2f offset = ul + pad
				+ Vec2f(0, dim.y + value * (lr - pad - dim * 3 - (ul + pad)).y);

			bool inX = mouse.x > ul.x + pad.x && mouse.x < ul.x + pad.x + dim.x;

			if (state == MouseEvent::DOWN){
				control.vars.delete("drag y");
				if(mouse.y > offset.y && mouse.y < offset.y + dim.y && inX){
					control.vars.set( "drag y", mouse.y - offset.y );
				}
			} else if (state == MouseEvent::HOLD){
				float dragX;
				bool exists = control.vars.get( "drag y", dragX );
				if (exists) {
					float value = ((mouse.y - dragX) - dim.y - ul.y - pad.y) 
					/ (lr - pad - dim * 3 - (ul + pad)).y;
					if (value < 0.0f)
						value = 0.0f;
					if (value > 1.0f)
						value = 1.0f;

					SLIDER_FUNC@ setFunc;
					control.vars.get("set func", @setFunc );
					if (setFunc !is null){
						value = setFunc( value );
					}

					control.vars.set( "value", value );
				}
			} else if (state == MouseEvent::UP){
				if (control.vars.exists("drag y")) {
					control.vars.delete("drag y");
				} else {
					if(mouse.y > ul.y + pad.y && mouse.y < ul.y + pad.y + dim.y && inX)
						UI::Scroll::Move(proxy.control, true);

					if(mouse.y > lr.y - pad.y - dim.y && mouse.y < lr.y - pad.y && inX)
						UI::Scroll::Move(proxy.control, false);
				}
			}
		}
	}

	namespace Slider
	{
		Control@ Add( const string &in caption, SLIDER_FUNC@ setFunc, float value, float increment, float multiplier, string currency = "" )
		{
			Data@ data = getData();
			Control@ control = UI::Scroll::Add( caption, setFunc, value, increment, multiplier, currency );
			@control.processMouse = ProcessMouse;
			@control.proxy.renderFunc = Render;
			return control;
		}

		void ProcessMouse( Proxy@ proxy, u8 state )
		{
			Control@ control = proxy.control;
			Vec2f mouse = getControls().getMouseScreenPos();
			//print("processMouse control: "+proxy.caption+" state: "+state);

			Vec2f ul = proxy.ul;
			Vec2f lr = proxy.lr;
			
			if (proxy.control.caption != "") {
				Vec2f textDim;
				GUI::GetTextDimensions( proxy.control.caption, textDim );
				ul.y += textDim.y;
			}


			Vec2f pad(3, Maths::Max((lr.y - ul.y - 8) / 2, 3.0));
			Vec2f size = lr - ul - pad * 2;
			Vec2f dim(16, 32);

			Vec2f begin = ul + pad + Vec2f(dim.x, size.y/2);
			Vec2f end = ul + pad + size - Vec2f(dim.x, size.y/2);

			float oldValue, oldValue2;
			proxy.control.vars.get( "value", oldValue );
			Vec2f offset = begin + (end - begin) * oldValue;

			bool hasValue2 = proxy.control.vars.get( "value2", oldValue2 );
			Vec2f offset2 = begin + (end - begin) * oldValue2;

			bool inY = mouse.y > offset.y - dim.y/2 && mouse.y < offset.y + dim.y/2;

			if (state == MouseEvent::DOWN){
				control.vars.delete("drag x");
				control.vars.delete("drag x2");
				if(mouse.x > offset.x - dim.x/2 && mouse.x < offset.x + dim.x/2 && inY){
					control.vars.set( "drag x", mouse.x - offset.x );
				} else if(hasValue2 && mouse.x > offset2.x - dim.x/2 && mouse.x < offset2.x + dim.x/2 && inY){
					control.vars.set( "drag x2", mouse.x - offset2.x );
				}
			} else if (state == MouseEvent::HOLD){
				float dragX, dragX2;
				if (control.vars.get( "drag x", dragX )) {
					float value = ((mouse.x - dragX) - begin.x) / (end - begin).x;
					value = Maths::Max(value, 0.0f);
					value = Maths::Min(value, 1.0f);

					if (hasValue2 && value > oldValue2) {
						control.vars.delete("drag x");
						control.vars.set("drag x2", dragX);
						value = oldValue2;
					} //else {
					SLIDER_FUNC@ setFunc;
					control.vars.get("set func", @setFunc );
					if (setFunc !is null){
						value = setFunc( value );
					}
					control.vars.set( "value", value );
					//}
				}
				if (control.vars.get( "drag x2", dragX2 )) {
					float value2 = ((mouse.x - dragX2) - begin.x) / (end - begin).x;
					value2 = Maths::Max(value2, 0.0f);
					value2 = Maths::Min(value2, 1.0f);

					if (value2 < oldValue) {
						control.vars.delete("drag x2");
						control.vars.set("drag x", dragX2);
						value2 = oldValue;
					}// else {
					SLIDER_FUNC@ setFunc2;
					control.vars.get("set func2", @setFunc2 );
					if (setFunc2 !is null){
						value2 = setFunc2( value2 );
					}
					control.vars.set( "value2", value2 );
					//}
				}
			} else if (state == MouseEvent::UP){
				if (control.vars.exists("drag x")) {
					control.vars.delete("drag x");
				} else if (control.vars.exists("drag x2")) {
					control.vars.delete("drag x2");
				} else {
					if(mouse.x > begin.x && mouse.x < offset.x - dim.x/2 && inY){
						proxy.control.vars.set("alt active", false);
						UI::Scroll::Move(proxy.control, true);
					}

					if(mouse.x > offset.x + dim.x/2 && mouse.x < (hasValue2 ? (offset.x + offset2.x) / 2 : end.x) && inY){
						proxy.control.vars.set("alt active", false);
						UI::Scroll::Move(proxy.control, false);
					}

					if(hasValue2 && mouse.x > (offset.x + offset2.x) / 2 && mouse.x < offset2.x - dim.x/2 && inY){
						proxy.control.vars.set("alt active", true);
						UI::Scroll::Move(proxy.control, true);
					}

					if(hasValue2 && mouse.x > offset2.x + dim.x/2 && mouse.x < end.x && inY){
						proxy.control.vars.set("alt active", true);
						UI::Scroll::Move(proxy.control, false);
					}
				}
			}
		}
	}

	namespace RangeSlider
	{
		Control@ Add( const string &in caption, SLIDER_FUNC@ setFunc, SLIDER_FUNC@ setFunc2, float value, float value2, float increment, float multiplier, string currency = "" )
		{
			Data@ data = getData();
			Control@ control = UI::Slider::Add( caption, setFunc, value, increment, multiplier, currency );
			control.vars.set( "set func2", @setFunc2 );
			control.vars.set( "value2", value2 );
			return control;
		}
	}
}