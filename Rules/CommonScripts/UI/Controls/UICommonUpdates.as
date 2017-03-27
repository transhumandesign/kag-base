namespace UI
{
	void NoTransitionUpdate( Proxy@ proxy  )
	{
		if (proxy.group is null){
			proxy.dead = true;
		}
		else {
			CalcControlPosition( proxy.group, proxy, proxy.control.x, proxy.control.y );

			proxy.selected = proxy.group.data.activeGroup is proxy.group && proxy.group.activeControl is proxy.control;
			proxy.caption = proxy.control.caption;
		}
	}

	void RenderCaption( Proxy@ proxy )
	{
		if(proxy.control is null) return;
		
		Vec2f dim;
		GUI::GetTextDimensions( proxy.caption, dim );
		Vec2f pos = proxy.ul;
		pos += Vec2f( proxy.align.x*(proxy.lr.x - proxy.ul.x), proxy.align.y*(proxy.lr.y - proxy.ul.y) - dim.y/2 );

		bool centered;
		if(proxy.control.vars.get("caption centered", centered) && centered)
			pos.x -= dim.x / 2;

		Vec2f offset;
		if(proxy.control.vars.get("caption offset", offset))
			pos += offset;

		bool pressed = false;
		if(proxy.control.vars.get("pressed", pressed) && pressed)
			pos.y += 1;

		SColor colour;
		if (proxy.selected) {
			if(!proxy.control.vars.get("colour selected", colour))
				if(!proxy.control.vars.get("colour", colour))
					colour = CAPTION_HOVER_COLOR;
		} else if(!proxy.control.vars.get("colour", colour))
				colour = CAPTION_COLOR;

		GUI::DrawText( proxy.caption, pos, proxy.lr, colour, false, false );
		// GUI::DrawText( proxy.caption, pos, colour );
	
		string icon;
		if(proxy.control.vars.get("icon", icon)){
			int iconFrame;
			Vec2f size;
			float scale;
			proxy.control.vars.get( "icon size", size );
			proxy.control.vars.get( "icon frame", iconFrame );
			proxy.control.vars.get( "icon scale", scale );
			scale *= getScreenHeight()/720.0;
			Vec2f iconPos = proxy.ul;
			iconPos += Vec2f( (proxy.lr.x - proxy.ul.x)*0.8 - size.x*scale, (proxy.lr.y - proxy.ul.y)/2 - size.y*scale );
			if(pressed)
				iconPos.y += 1;

			GUI::DrawIcon(icon, iconFrame, size, iconPos, scale);
		}
	}

	void DefaultProcessMouse( Proxy@ proxy, u8 state)
	{
		Control@ control = proxy.control;
		//print("processMouse control: "+control.caption+" state: "+state);
		
		// if (state == HOVER){
		// 	@control.group.activeControl = control;
		// 	control.group.selx = control.x;
		// 	control.group.sely = control.y;
		// 	//Sound::Play("menuclick");
		// }

		if (state == MouseEvent::HOVER && control.tooltip != ""){
			UpdateTooltip(control.tooltip);
		} else if (state == MouseEvent::HOLD){
			Vec2f mouse = getControls().getMouseScreenPos();
			Vec2f pos(	(mouse.x - proxy.ul.x) / (proxy.lr.x - proxy.ul.x),
						(mouse.y - proxy.ul.y) / (proxy.lr.y - proxy.ul.y));
			const bool pressed = pos.x > 0 && pos.x < 1 && pos.y > 0 && pos.y < 1;
			control.vars.set("pressed", pressed);
		} else if (state == MouseEvent::UP && control.action !is null) {
			control.vars.set("pressed", false);
			control.action(control.group, control);
			Sound::Play("menuclick");
		}
	}

	void UpdateTooltip(string tooltip)
	{
		CRules@ rules = getRules();
		Vec2f mouseNow = getControls().getMouseScreenPos();

		if (rules.exists("tooltip mousepos") && mouseNow == rules.get_Vec2f("tooltip mousepos")) {
			u8 timer = rules.get_u8("tooltip timer");
			if (timer > 25) {
				rules.set_string("tooltip text", tooltip);
			} else {
				rules.set_u8("tooltip timer", timer+1);
			}
		} else {
			rules.set_Vec2f("tooltip mousepos", mouseNow);
			rules.set_u8("tooltip timer", 0);
			rules.set_string("tooltip text", "");
		}
	}

	void UpdateGroup( Proxy@ proxy )
	{
		if (proxy.group is null){
			proxy.dead = true;
		}
		else {
			proxy.ul = getAbsolutePosition( proxy.group.upperLeft,  proxy.group.data.screenSize );
			proxy.lr = getAbsolutePosition( proxy.group.lowerRight, proxy.group.data.screenSize );
		}
	}

	void RenderGroup( Proxy@ proxy )
	{
		if (proxy.group is null) return;
		GUI::DrawRectangle( proxy.ul, proxy.lr );
	}

	void RenderTabsGroup( Proxy@ proxy )
	{
		if (proxy.group is null) return;
		Vec2f size = proxy.lr - proxy.ul;
		GUI::DrawFramedPane(proxy.ul - Vec2f(size.x*0.0, size.y*0.05), proxy.lr + Vec2f(size.x*0.0, size.y*0.05));
	}

	void RenderGroupFullscreen( Proxy@ proxy )
	{
		if (proxy.group is null) return;
		Vec2f size = proxy.group.data.screenSize;
		GUI::DrawRectangle( Vec2f_zero, size );

		Vec2f headerSize(size.x, size.y * 0.12);
		GUI::DrawSunkenPane( Vec2f_zero, headerSize );


		Vec2f dim;
		GUI::GetTextDimensions( proxy.group.name, dim );
		Vec2f pos = headerSize / 2 - dim / 2;
		//Vec2f( proxy.align.x*(proxy.lr.x - proxy.ul.x), proxy.align.y*(proxy.lr.y - proxy.ul.y) - dim.y/2 );

		GUI::DrawText( proxy.group.name, pos, CAPTION_COLOR );
	}
}