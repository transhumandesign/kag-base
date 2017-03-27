// main menu skin

namespace UI
{
	namespace Scroll
	{
		void Render( Proxy@ proxy )
		{
			if(proxy.control is null) return;

			if (proxy.selected) {
				GUI::DrawRectangle( proxy.ul, proxy.lr, CONTROL_HOVER_COLOR );
			}

			Vec2f ul = proxy.ul;
			Vec2f lr = proxy.lr;
			
			if (proxy.caption != "") {
				Vec2f textDim;
				GUI::GetTextDimensions( proxy.caption, textDim );
				GUI::DrawText( proxy.caption, proxy.ul, proxy.selected ? CAPTION_HOVER_COLOR : CAPTION_COLOR );
				ul.y += textDim.y;
			}

			Vec2f pad(3, Maths::Max((lr.y - ul.y - 30) / 2, 3.0));
			Vec2f size = lr - ul - pad * 2;
			Vec2f dim(size.y, size.y);
			//GUI::DrawPane(ul + pad, lr - pad);
			GUI::DrawRectangle(ul + pad, lr - pad);

			GUI::DrawButton(ul + pad, ul + pad + dim);
			GUI::DrawIcon("MenuArrows.png", 2, Vec2f(7, 7), ul + pad + dim / 2 - Vec2f(3, 3), 0.5);
			GUI::DrawButton(lr - pad - dim, lr - pad);
			GUI::DrawIcon("MenuArrows.png", 3, Vec2f(7, 7), lr - pad - dim / 2 - Vec2f(3, 3), 0.5);

			float value;
			proxy.control.vars.get( "value", value );
			Vec2f offset = ul + pad
				+ Vec2f(dim.x + value * (lr - pad - dim * 3 - (ul + pad)).x, 0);

			if(proxy.group.editControl is proxy.control && getGameTime() % 20 > 10)
				GUI::DrawRectangle(offset, offset + dim);
			else
				GUI::DrawButton(offset, offset + dim);
		}
	}

	namespace VerticalScrollbar
	{
		void Render( Proxy@ proxy )
		{
			if(proxy.control is null) return;

			if (proxy.selected) {
				GUI::DrawRectangle( proxy.ul, proxy.lr, CONTROL_HOVER_COLOR );
			}

			Vec2f ul = proxy.ul;
			Vec2f lr = proxy.lr;
		
			Vec2f pad(Maths::Max((lr.x - ul.x - 30) / 2, 3.0), 3);
			Vec2f size = lr - ul - pad * 2;
			Vec2f dim(size.x, size.x);
			//GUI::DrawPane(ul + pad, lr - pad);
			GUI::DrawRectangle(ul + pad, lr - pad);

			GUI::DrawButton(ul + pad, ul + pad + dim);
			GUI::DrawIcon("MenuArrows.png", 1, Vec2f(7, 7), ul + pad + dim / 2 - Vec2f(3, 3), 0.5);
			GUI::DrawButton(lr - pad - dim, lr - pad);
			GUI::DrawIcon("MenuArrows.png", 0, Vec2f(7, 7), lr - pad - dim / 2 - Vec2f(3, 3), 0.5);

			float increment;
			proxy.control.vars.get( "increment", increment );
			if (increment > 1) return;

			float value;
			proxy.control.vars.get( "value", value );
			Vec2f offset = ul + pad
				+ Vec2f(0, dim.y + value * (lr - pad - dim * 3 - (ul + pad)).y);

			if(proxy.group.editControl is proxy.control && getGameTime() % 20 > 10)
				GUI::DrawRectangle(offset, offset + dim);
			else
				GUI::DrawButton(offset, offset + dim);
		}
	}

	namespace Slider
	{
		void Render( Proxy@ proxy )
		{
			if(proxy.control is null) return;

			if (proxy.selected) {
				GUI::DrawRectangle( proxy.ul, proxy.lr, CONTROL_HOVER_COLOR );
			}

			Vec2f ul = proxy.ul;
			Vec2f lr = proxy.lr;
			
			if (proxy.caption != "") {
				Vec2f textDim;
				GUI::GetTextDimensions( proxy.caption, textDim );
				GUI::DrawText( proxy.caption, proxy.ul, proxy.selected ? CAPTION_HOVER_COLOR : CAPTION_COLOR );
				ul.y += textDim.y;
			}

			Vec2f pad(3, Maths::Max((lr.y - ul.y - 8) / 2, 3.0));
			Vec2f size = lr - ul - pad * 2;
			Vec2f dim(16, 32);
			GUI::DrawPane(ul + pad, ul + pad + size);

			Vec2f begin = ul + pad + Vec2f(dim.x, size.y/2);
			Vec2f end = ul + pad + size - Vec2f(dim.x, size.y/2);

			bool altActive = proxy.control.vars.get("alt active", altActive) && altActive; //side effects feel so exploited right now
			float value, value2;

			proxy.control.vars.get( "value", value );
			Vec2f offset = begin + (end - begin) * value;

			if(proxy.control.vars.get( "value2", value2 )){
				Vec2f offset2 = begin + (end - begin) * value2;

				GUI::DrawPane(offset - Vec2f(0, 8), offset2 + Vec2f(0, 8));
				
				if(proxy.group.editControl is proxy.control && getGameTime() % 20 > 10 && altActive)
					GUI::DrawButton(offset2 - dim/2, offset2 + dim/2);
				else
					GUI::DrawRectangle(offset2 - dim/2, offset2 + dim/2);
			}

			if(proxy.group.editControl is proxy.control && getGameTime() % 20 > 10 && !altActive)
				GUI::DrawButton(offset - dim/2, offset + dim/2);
			else
				GUI::DrawRectangle(offset - dim/2, offset + dim/2);
		}
	}
}