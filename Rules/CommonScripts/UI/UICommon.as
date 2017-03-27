
namespace SelectDirection {
	enum SelectDirection {
		LEFT,
		RIGHT,
		UP,
		DOWN,
	}
}

namespace UI
{
	const SColor CONTROL_HOVER_COLOR = SColor(66, 216, 226, 226);
	const SColor CAPTION_COLOR = SColor(255, 216, 226, 226);
	const SColor CAPTION_HOVER_COLOR = SColor(255, 255, 255, 224);

	string CMD_STRING = "control selected";

	bool isPrevPressed( CControls@ controls, Group@ group )
	{
		return controls.ActionKeyPressed(AK_MOVE_LEFT) || controls.ActionKeyPressed(AK_MOVE_UP);
	}

	bool isNextPressed( CControls@ controls, Group@ group )
	{
		return controls.ActionKeyPressed(AK_MOVE_RIGHT) || controls.ActionKeyPressed(AK_MOVE_DOWN);
	}

	Control@ getActiveControl( Group@ group )
	{
		return group.controls[ group.selx ][ group.sely ];
	}

	void MoveSelection2( u8 dir )
	{
		//if (group.modal){
		Data@ data = getData();
		Control@ control = data.activeGroup.activeControl;
		Vec2f activePos;
		if (control !is null) {
			activePos = (control.proxy.ul + control.proxy.lr)/2;
		} else {
			Vec2f relative;
			if (dir == SelectDirection::LEFT) 
				relative = Vec2f(1, 0.5);
			else if (dir == SelectDirection::RIGHT) 
				relative = Vec2f(0, 0.5);
			else if (dir == SelectDirection::UP) 
				relative = Vec2f(0.5, 1);
			else
				relative = Vec2f(0.5, 0);
			activePos = getAbsolutePosition( relative, data.screenSize );
		}

		float closestDistance = 1e12;
		Proxy@ closestProxy;
		for (int i = 0; i < data.proxies.length; ++i)
		{

			Proxy@ proxy = data.proxies[i];
			if (proxy.control is null || !proxy.control.selectable) continue;

			Vec2f pos = (proxy.ul + proxy.lr)/2;
			float x = Maths::Abs(pos.x - activePos.x);
			float y = Maths::Abs(pos.y - activePos.y);
			if (dir == SelectDirection::LEFT && activePos.x - pos.x < 0.0001) 
				x = Maths::Abs(pos.x - data.screenSize.x - activePos.x);
			else if (dir == SelectDirection::RIGHT && pos.x - activePos.x < 0.0001) 
				x = Maths::Abs(pos.x + data.screenSize.x - activePos.x);
			else if (dir == SelectDirection::UP && activePos.y - pos.y < 0.0001) 
				y = Maths::Abs(pos.y - data.screenSize.y - activePos.y);
			else if (dir == SelectDirection::DOWN && pos.y - activePos.y < 0.0001) 
				y = Maths::Abs(pos.y + data.screenSize.y - activePos.y);

			if (x > y && (dir == SelectDirection::LEFT || dir == SelectDirection::RIGHT) || 
				x < y && (dir == SelectDirection::DOWN || dir == SelectDirection::UP)) { //is in appropriate quadrant
				float distance = x + y;
				if (distance < closestDistance) {
					closestDistance = distance;
					@closestProxy = proxy;
				}
			}
		}

		@data.activeGroup = closestProxy.control.group;
		@data.activeGroup.activeControl = closestProxy.control;
		data.activeGroup.selx = closestProxy.control.x;
		data.activeGroup.sely = closestProxy.control.y;

		return;
	}

	void MoveSelection( u8 dir )
	{
		//if (group.modal){
		Data@ data = getData();
		Control@ control = data.activeGroup.activeControl;
		Vec2f relative;
		if (dir == SelectDirection::LEFT) 
			relative = Vec2f(1, 0.5);
		else if (dir == SelectDirection::RIGHT) 
			relative = Vec2f(0, 0.5);
		else if (dir == SelectDirection::UP) 
			relative = Vec2f(0.5, 1);
		else // (dir == SelectDirection::DOWN) 
			relative = Vec2f(0.5, 0);

		Vec2f activePos, activeCenter;
		if (control !is null) {
			activeCenter = (control.proxy.ul + control.proxy.lr)/2;
			Vec2f offset = Vec2f(1, 1) - relative;
			offset *= control.proxy.lr - control.proxy.ul;
			activePos = control.proxy.ul + offset;
		} else {
			activePos = activeCenter = getAbsolutePosition( relative, data.screenSize );
		}

		// print("activePos: "+activePos.x + ", "+activePos.y);
		// print("activeCenter: "+activeCenter.x + ", "+activeCenter.y);

		float closestDistance = 1e12;
		Proxy@ closestProxy;
		for (int i = 0; i < data.proxies.length; ++i)
		{
			Proxy@ proxy = data.proxies[i];
			if (proxy.control is null || !proxy.control.selectable
				|| data.activeGroup.modal && !proxy.group.modal) continue;

			Vec2f center = (proxy.ul + proxy.lr)/2;
			Vec2f ul = proxy.ul;
			Vec2f lr = proxy.lr;
			if (dir == SelectDirection::LEFT && activeCenter.x - center.x < 0.0001) {
				ul.x -= data.screenSize.x * 2;
				lr.x -= data.screenSize.x * 2;
			} else if (dir == SelectDirection::RIGHT && center.x - activeCenter.x < 0.0001) {
				ul.x += data.screenSize.x * 2;
				lr.x += data.screenSize.x * 2;
			} else if (dir == SelectDirection::UP && activeCenter.y - center.y < 0.0001) {
				ul.y -= data.screenSize.y * 2;
				lr.y -= data.screenSize.y * 2;
			} else if (dir == SelectDirection::DOWN && center.y - activeCenter.y < 0.0001) {
				ul.y += data.screenSize.y * 2;
				lr.y += data.screenSize.y * 2;
			}
			
			float distanceX;
			float distanceX1 = ul.x - activePos.x;
			float distanceX2 = lr.x - activePos.x;
			if (distanceX1 < 0) {
				if (distanceX2 < 0)
					distanceX = -distanceX2;
				else
					distanceX = 0;
			}
			else 
				distanceX = distanceX1;

			float distanceY;
			float distanceY1 = ul.y - activePos.y;
			float distanceY2 = lr.y - activePos.y;
			if (distanceY1 < 0) {
				if (distanceY2 < 0)
					distanceY = -distanceY2;
				else
					distanceY = 0;
			}
			else 
				distanceY = distanceY1;

			if (dir == SelectDirection::LEFT || dir == SelectDirection::RIGHT) {
				distanceY *= 2.5;
			} else if (dir == SelectDirection::UP || dir == SelectDirection::DOWN) {
				distanceX *= 2.5;
			}

			float distance = Maths::Sqrt(distanceX * distanceX + distanceY * distanceY);
			if (distance < closestDistance) {
				closestDistance = distance;
				@closestProxy = proxy;
			}
		}
		// print("closestDistance: "+closestDistance);

		if (closestProxy !is null) {
			@data.activeGroup = closestProxy.control.group;
			@data.activeGroup.activeControl = closestProxy.control;
			data.activeGroup.selx = closestProxy.control.x;
			data.activeGroup.sely = closestProxy.control.y;
			Sound::Play("select");
		}

		return;
	}
	
	bool hasSelectableControls( Group@ group )
	{
	   // check if has selectable
		for (uint y=0; y<group.rows; y++){
			for (uint x=0; x<group.columns; x++){
				Control@ pControl = group.controls[x][y];
				if (pControl !is null) {
					if (pControl.selectable)
						return true;
				}
			}
		}
	   return false;
	}

	bool isControlSeparator( Control@ control )
	{
		return control.caption == "";
	}
}