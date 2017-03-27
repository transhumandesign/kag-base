// main menu skin

namespace UI
{
	namespace Toggle
	{
		const int SIZE = 9;

		void Render( Proxy@ proxy )
		{
			if(proxy.control is null) return;

			if (proxy.selected){
				GUI::DrawRectangle( proxy.ul, proxy.lr, CONTROL_HOVER_COLOR );
			}

			Vec2f pos(proxy.ul.x + SIZE + 3, proxy.ul.y + (proxy.lr.y - proxy.ul.y) / 2);
			Vec2f dim(SIZE, SIZE);
			GUI::DrawSunkenPane(pos - dim, pos + dim);

			bool toggle;
			proxy.control.vars.get( "toggle", toggle );
			if(toggle)
				GUI::DrawIcon("MenuArrows.png", 4, Vec2f(7, 7), pos - Vec2f(3, 3), 0.5);

			RenderCaption(proxy);
		}
	}
}