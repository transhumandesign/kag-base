// main menu skin

namespace UI
{
	namespace Button
	{
		void Render( Proxy@ proxy )
		{
			if(proxy.control is null) return;

			Vec2f pad(3, 3);
			// Vec2f pad(0, 0);

			bool sunken = false;
			if(proxy.control.vars.exists("sunken"))
				proxy.control.vars.get("sunken", sunken);
			bool pressed = false;
			if(proxy.control.vars.exists("pressed"))
				proxy.control.vars.get("pressed", pressed);

			if (pressed) {
				GUI::DrawButtonPressed(proxy.ul + pad, proxy.lr - pad);
			} else if (sunken) {
				GUI::DrawButtonPressed(proxy.ul + pad, proxy.lr - pad);
				if(proxy.selected){
					GUI::DrawRectangle(proxy.ul + pad, proxy.lr - pad, CONTROL_HOVER_COLOR);
				}
			} else if (proxy.selected)	{
				//GUI::DrawRectangle(proxy.ul, proxy.lr, CONTROL_HOVER_COLOR);
				GUI::DrawButtonHover(proxy.ul + pad, proxy.lr - pad);
			} else {
				GUI::DrawButton(proxy.ul + pad, proxy.lr - pad);
			}

			RenderCaption(proxy);
		}
	}
}