
void server_Pickup(CBlob@ this, CBlob@ picker, CBlob@ pickBlob)
{
	if (pickBlob is null || picker is null || pickBlob.isAttached())
		return;
	CBitStream params;
	params.write_netid(picker.getNetworkID());
	params.write_netid(pickBlob.getNetworkID());
	this.SendCommand(this.getCommandID("pickup"), params);
}

void server_PutInHeld(CBlob@ this, CBlob@ picker)
{
	if (picker is null)
		return;
	CBitStream params;
	params.write_netid(picker.getNetworkID());
	this.SendCommand(this.getCommandID("putinheld"), params);
}

void Tap(CBlob@ this)
{
	this.set_s32("tap_time", getGameTime());
}

void TapPickup(CBlob@ this)
{
	this.set_s32("tap_pickup_time", getGameTime());
}

bool isTap(CBlob@ this, int ticks = 15)
{
	return (getGameTime() - this.get_s32("tap_time") < ticks);
}

bool isTapPickup(CBlob@ this, int ticks = 15)
{
	// TODO: merge some code with the above and make it generalized to all keys if ever useful
	return (getGameTime() - this.get_s32("tap_pickup_time") < ticks);
}

void HandleButtonClickKey(CBlob@ this, AttachmentPoint@ point = null)
{
	if (getHUD().hasButtons())
	{
		if (point !is null)
		{
			if ((point.isKeyJustPressed(key_action1)) && !point.isKeyPressed(key_pickup))
			{
				ButtonOrMenuClick(this, this.getAimPos(), false, true);
				this.set_bool("release click", false);
			}
		}
		else
		{
			if ((this.isKeyJustPressed(key_action1)) && !this.isKeyPressed(key_pickup))
			{
				ButtonOrMenuClick(this, this.getAimPos(), false, true);
				this.set_bool("release click", false);
			}
		}
	}
}

bool ClickGridMenu(CBlob@ this, int button)
{
	CGridMenu @gmenu;
	CGridButton @gbutton;

	if (this.ClickGridMenu(button, gmenu, gbutton))   // button gets pressed here - thing get picked up
	{
		if (gmenu !is null)
		{
			// if (gmenu.getName() == this.getInventory().getMenuName() && gmenu.getOwner() !is null)
			{
				if (gbutton is null)    // carrying something, put it in
				{
					server_PutInHeld(this, gmenu.getOwner());
				}
				else // take something
				{
					// handled by button cmd   // hardcoded still :/
				}
			}
			return true;
		}
	}

	return false;
}

void ButtonOrMenuClick(CBlob@ this, Vec2f pos, bool clear, bool doClosestClick)
{
	if (!ClickGridMenu(this, 0))
		if (this.ClickInteractButton())
		{
			clear = false;
		}
		else if (doClosestClick)
		{
			if (this.ClickClosestInteractButton(pos, this.getRadius() * 1.0f))
			{
				this.ClearButtons();
				clear = false;
			}
		}

	if (clear)
	{
		this.ClearButtons();
		this.ClearMenus();
	}
}

bool pointInsidePolygon( Vec2f Point, Vec2f[] polygon, Vec2f polyPos, bool facingLeft )
{
	// Mirror the polygon when the blob is facing left
	if (facingLeft) 
	{
		for ( int i = 0 ; i < polygon.length ; i++ )
		{
		polygon[i].x = -polygon[i].x;
		}
	}

	double minX = polyPos.x+polygon[0].x;
	double maxX = polyPos.x+polygon[0].x;
	double minY = polyPos.y+polygon[0].y;
	double maxY = polyPos.y+polygon[0].y;

	for ( int i = 1 ; i < polygon.length ; i++ )
	{
		Vec2f q = polyPos+polygon[ i ];
		minX = Maths::Min( q.x, minX );
		maxX = Maths::Max( q.x, maxX );
		minY = Maths::Min( q.y, minY );
		maxY = Maths::Max( q.y, maxY );
	}

	if ( Point.x < minX || Point.x > maxX || Point.y < minY || Point.y > maxY )
	{
		return false;
	}

	bool inside = false;
	for ( int i = 0, j = polygon.length - 1 ; i < polygon.length ; j = i++ )
	{
		Vec2f pvi = polyPos + polygon[ i ];
		Vec2f pvj = polyPos + polygon[ j ];
		if ( ( pvi.y > Point.y ) != ( pvj.y > Point.y ) &&
			 Point.x < ( pvj.x - pvi.x ) * ( Point.y - pvi.y ) / ( pvj.y - pvi.y ) + pvi.x )
		{
			inside = !inside;
		}
	}

	return inside;
}

