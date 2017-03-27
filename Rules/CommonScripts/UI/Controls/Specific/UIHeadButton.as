#include "UI.as"
#include "UICommonUpdates.as"

namespace UI
{
	namespace HeadButton
	{
		void Add(){
			Data@ data = getData();
			Control@ control = AddControl( "" );
			@control.action = SetHead;
			@control.processMouse = DefaultProcessMouse;
			@control.proxy = AddProxy( data, Render, NoTransitionUpdate, data.activeGroup, control, 1.0 );
		}

		void SetHead( Group@ group, Control@ control ){
			cl_head = 7 * control.y + control.x + 30;
		}

		void Render( Proxy@ proxy )
		{
			if(proxy.control is null) return;
			Control@ control = proxy.control;

			if (cl_head == 30 + 7 * control.y + control.x) {
				if (proxy.selected)
					GUI::DrawButtonHover( proxy.ul, proxy.lr );
				else
					GUI::DrawButton( proxy.ul, proxy.lr );
			} else if (proxy.selected) {
				GUI::DrawRectangle( proxy.ul, proxy.lr, CONTROL_HOVER_COLOR );
			}

			int iconFrame = (7 * control.y + control.x + 15) * 8;
			if(cl_sex != 0)
				iconFrame += 4;
			if(proxy.selected && getGameTime() % 20 > 10)
				iconFrame += 1;
			
			Vec2f iconPos = proxy.ul;
			iconPos += Vec2f( (proxy.lr.x - proxy.ul.x)/2 - 16, (proxy.lr.y - proxy.ul.y)/2 - 16 );

			GUI::DrawIcon("Heads.png", iconFrame, Vec2f(16, 16), iconPos, 1.0);
		}
	}
}