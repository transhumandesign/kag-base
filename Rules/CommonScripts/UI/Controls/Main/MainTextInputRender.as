// main menu skin

namespace UI
{
	namespace TextInput
	{
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

			string caption;
			SColor colour;
			bool password;
			if (proxy.control.vars.get( "password", password ) && password){
				caption = "";
				for (uint i=0; i < proxy.control.caption.size(); i++)
					caption += "*";
			} else {
				caption = proxy.control.caption;
			}

			string placeholder;
			proxy.control.vars.get( "placeholder", placeholder );

			const bool editing = proxy.selected && proxy.group.editControl is proxy.control;
			if (!editing && caption == "") {
				caption = placeholder;
				colour = SColor(255, 159, 165, 160);
			} else {
				colour = proxy.selected ? CAPTION_HOVER_COLOR : CAPTION_COLOR;
			}

			Vec2f dim;
			GUI::GetTextDimensions( caption, dim );
			Vec2f pos = ul;
			pos += Vec2f( proxy.align.x*(lr.x - ul.x), proxy.align.y*(lr.y - ul.y) - dim.y/2 );

			bool centered;
			if(proxy.control.vars.get("caption centered", centered) && centered)
				pos.x -= dim.x / 2;

			if (editing && getGameTime() % 20 > 10){
				caption += "_";
			}

			// RenderCaption(proxy);
			GUI::DrawText( caption, pos, colour);
		}
	}
}
