// main menu skin

namespace UI
{
	namespace Option
	{
		const int OPTION_HEIGHT = 18;

		void Render( Proxy@ proxy )
		{
			if(proxy.control is null) return;

			if (proxy.selected) {
				GUI::DrawRectangle( proxy.ul, proxy.lr, CONTROL_HOVER_COLOR );
			}

			Vec2f ul = proxy.ul;
			Vec2f lr = proxy.lr;
			
			string label = "";
			if(proxy.control.vars.get("label", label) && label != "") {
				Vec2f textDim;
				GUI::GetTextDimensions( label, textDim );
				GUI::DrawText( label, proxy.ul, proxy.selected ? CAPTION_HOVER_COLOR : CAPTION_COLOR );
				ul.y += textDim.y;
			}

			Vec2f pad(3, Maths::Max((lr.y - ul.y - 30) / 2, 3.0));
			GUI::DrawSunkenPane(ul + pad, lr - pad);

			if(proxy.selected && proxy.group.editControl is proxy.control){
				Vec2f pad2 = pad + Vec2f(2, 2);
				GUI::DrawRectangle( ul + pad2, lr - pad2, SColor(255, 125, 139, 121) );
			}

			Vec2f size = lr - ul - pad * 2;
			Vec2f square(size.y, size.y);
			GUI::DrawButton(lr - pad - square, lr - pad);
			GUI::DrawIcon("MenuArrows.png", 0, Vec2f(7, 7), lr - pad - square / 2 - Vec2f(3, 3), 0.5);
			
			//caption
			Vec2f dim;
			GUI::GetTextDimensions( proxy.caption, dim );
			Vec2f pos = ul;
			pos += Vec2f( (lr.x - ul.x)/2, (lr.y - ul.y)/2 - dim.y/2 );
			pos.x -= dim.x / 2; //center
			pos.x -= 15; //account for arrow down button
			GUI::DrawText( proxy.caption, pos, proxy.selected ? CAPTION_HOVER_COLOR : CAPTION_COLOR );
		}

		void RenderOptions( Proxy@ proxy )
		{
			//return;
			if(proxy.control is null) return;
			
			string[] options;
			proxy.control.vars.get( "options", options );
			int selected;
			proxy.control.vars.get( "selected", selected );

			GUI::DrawSunkenPane(proxy.ul, proxy.lr);
			GUI::DrawButton(proxy.ul + Vec2f(0, OPTION_HEIGHT * selected), 
							proxy.lr - Vec2f(0, OPTION_HEIGHT * (options.length - selected - 1)));

			for (uint i = 0; i < options.length; ++i)
			{
				GUI::DrawText( options[i], proxy.ul + Vec2f(6, OPTION_HEIGHT * i), i==selected ? CAPTION_HOVER_COLOR : CAPTION_COLOR );
			}
		}
	}
}