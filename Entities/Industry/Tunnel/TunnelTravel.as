// include file for blobs that use tunnel travel capabilities
// apply "travel tunnel" tag to use

#include "TunnelCommon.as";
#include "KnockedCommon.as";
#include "GenericButtonCommon.as";

// Wrapper class that overrides opCmp to allow sorting by position
class PositionComparableCBlobWrapper 
{
	CBlob@ blob;

	PositionComparableCBlobWrapper(CBlob@ p_blob)
	{
		@blob = p_blob;
	}

	// Compare by x-coordinate, then y-coordinate
	int opCmp(PositionComparableCBlobWrapper@ other)
	{
		int xDiff = blob.getPosition().x - other.blob.getPosition().x;
		if (xDiff != 0)
		{
			return xDiff;
		}
		return blob.getPosition().y - other.blob.getPosition().y;
	}
}

void onInit(CBlob@ this)
{
	this.addCommandID("travel");
	this.addCommandID("travel none");
	this.addCommandID("travel to");
	this.addCommandID("server travel to");
	this.Tag("travel tunnel");

	int team = this.getTeamNum();
	AddIconToken("$TRAVEL_RIGHT_"+team+"$", "GUI/InteractionIcons.png.png", Vec2f(32, 32), 17, team);
	AddIconToken("$TRAVEL_LEFT_"+team+"$", "GUI/InteractionIcons.png", Vec2f(32, 32), 18, team);
	AddIconToken("$TRAVEL_RIGHT_UP_"+team+"$", "GUI/InteractionIcons.png", Vec2f(32, 32), 6, team);
	AddIconToken("$TRAVEL_RIGHT_DOWN_"+team+"$", "GUI/InteractionIcons.png", Vec2f(32, 32), 7, team);
	AddIconToken("$TRAVEL_LEFT_UP_"+team+"$", "GUI/InteractionIcons.png", Vec2f(32, 32), 5, team);
	AddIconToken("$TRAVEL_LEFT_DOWN_"+team+"$", "GUI/InteractionIcons.png", Vec2f(32, 32), 4, team);
	AddIconToken("$TRAVEL_UP_"+team+"$", "GUI/InteractionIcons.png", Vec2f(32, 32), 16, team);
	AddIconToken("$TRAVEL_DOWN_"+team+"$", "GUI/InteractionIcons.png", Vec2f(32, 32), 19, team);

	if (!this.exists("travel button pos"))
	{
		this.set_Vec2f("travel button pos", Vec2f_zero);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	if (this.isOverlapping(caller) &&
	        this.hasTag("travel tunnel") &&
	        (!this.hasTag("teamlocked tunnel") || this.getTeamNum() == caller.getTeamNum()) &&
	        (!this.hasTag("under raid") || this.hasTag("ignore raid")) &&
	        //CANNOT travel when stunned
			!(isKnockable(caller) && isKnocked(caller))
		)
	{
		MakeTravelButton(this, caller, this.get_Vec2f("travel button pos"), "Travel", "Travel (requires Transport Tunnels)");
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	onTunnelCommand(this, cmd, params);
}

// get all team tunnels sorted by position

bool getTunnelsForButtons(CBlob@ this, CBlob@[]@ tunnels)
{
	CBlob@[] list;
	getBlobsByTag("travel tunnel", @list);

	PositionComparableCBlobWrapper@[] comparableList;
	for (uint i = 0; i < list.length; i++)
	{
		CBlob@ tunnel = list[i];
		if (tunnel.getTeamNum() == this.getTeamNum())
		{
			PositionComparableCBlobWrapper wrapper(tunnel);
			comparableList.push_back(wrapper);
		}
	}

	comparableList.sortAsc();

	for (uint i = 0; i < comparableList.length; i++)
	{
		CBlob@ tunnel = comparableList[i].blob;
		if (tunnel is this)
		{
			// Add "You are here"
			tunnels.push_back(null);
		}
		else 
		{			
			tunnels.push_back(tunnel);
		}
	}
	return tunnels.length > 0;
}

bool isInRadius(CBlob@ this, CBlob @caller)
{
	return ((this.getPosition() - caller.getPosition()).Length() < this.getRadius() * 1.01f + caller.getRadius());
}

CButton@ MakeTravelButton(CBlob@ this, CBlob@ caller, Vec2f buttonPos, const string &in label, const string &in cantTravelLabel)
{
	CBlob@[] tunnels;
	const bool gotTunnels = getTunnels(this, @tunnels);
	const bool travelAvailable = gotTunnels && isInRadius(this, caller);
	if (!travelAvailable)
		return null;
	CBitStream params;
	params.write_u16(caller.getNetworkID());
	CButton@ button = caller.CreateGenericButton(8, buttonPos, this, this.getCommandID("travel"), gotTunnels ? getTranslatedString(label) : getTranslatedString(cantTravelLabel), params);
	if (button !is null)
	{
		button.SetEnabled(travelAvailable);
	}
	return button;
}

bool doesFitAtTunnel(CBlob@ this, CBlob@ caller, CBlob@ tunnel)
{
	return true;
}

void Travel(CBlob@ this, CBlob@ caller, CBlob@ tunnel)
{
	CBlob@ thisTunnel = getBlobByNetworkID(this.getNetworkID());
	if (thisTunnel !is null && caller !is null && tunnel !is null)
	{
		//(this should prevent travel when stunned, but actually
		// causes issues on net)
		//if (isKnockable(caller) && caller.get_u8("knocked") > 0)
		//	return;

		//dont travel if tunnel team has changed while tunnel menu was open
		if (this.getTeamNum() != tunnel.getTeamNum())
			return;

		//dont travel if caller is attached to something (e.g. siege)
		if (caller.isAttached())
			return;

		Vec2f position = tunnel.getPosition();
		if (tunnel.exists("travel offset"))
		{
			Vec2f offset = tunnel.get_Vec2f("travel offset");
			position += tunnel.isFacingLeft() ? -offset : offset;
		}

		// move caller
		caller.setPosition(position);
		caller.setVelocity(Vec2f_zero);
		//caller.getShape().PutOnGround();

		if (caller.isMyPlayer())
		{
			Sound::Play("Travel.ogg");
		}
		else
		{
			Sound::Play("Travel.ogg", this.getPosition());
			Sound::Play("Travel.ogg", caller.getPosition());
		}

		//stunned on going through tunnel
		//(prevents tunnel spam and ensures traps get you)
		if (isKnockable(caller))
		{
			//if you travel, you lose invincible
			caller.Untag("invincible");
			caller.Sync("invincible", true);

			//actually do the knocking
			setKnocked(caller, 30, true);
		}
	}
}

void onTunnelCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("travel"))
	{
		const u16 callerID = params.read_u16();
		CBlob@ caller = getBlobByNetworkID(callerID);

		CBlob@[] tunnels;
		if (caller !is null && getTunnels(this, @tunnels))
		{
			// instant travel cause there is just one place to go
			if (tunnels.length == 1)
			{
				Travel(this, caller, tunnels[0]);
			}
			else
			{
				if (caller.isMyPlayer())
					BuildTunnelsMenu(this, callerID);
			}
		}
	}
	else if (cmd == this.getCommandID("travel to"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		CBlob@ tunnel = getBlobByNetworkID(params.read_u16());
		if (caller !is null && tunnel !is null
		        && (this.getPosition() - caller.getPosition()).getLength() < (this.getRadius() + caller.getRadius()) * 2.0f &&
		        doesFitAtTunnel(this, caller, tunnel))
		{
			if (getNet().isServer())
			{
				CBitStream params;
				params.write_u16(caller.getNetworkID());
				params.write_u16(tunnel.getNetworkID());
				this.SendCommand(this.getCommandID("server travel to"), params);
				Travel(this, caller, tunnel);
			}
		}
		else if (caller !is null && caller.isMyPlayer())
			caller.getSprite().PlaySound("NoAmmo.ogg", 0.5);
	}
	else if (cmd == this.getCommandID("server travel to"))
	{
		if (getNet().isClient())
		{
			CBlob@ caller = getBlobByNetworkID(params.read_u16());
			CBlob@ tunnel = getBlobByNetworkID(params.read_u16());
			Travel(this, caller, tunnel);
		}
	}
	else if (cmd == this.getCommandID("travel none"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		if (caller !is null && caller.isMyPlayer())
			getHUD().ClearMenus();
	}
}

const int BUTTON_SIZE = 2;

void BuildTunnelsMenu(CBlob@ this, const u16 callerID)
{
	CBlob@[] tunnels;
	getTunnelsForButtons(this, @tunnels);

	CGridMenu@ menu = CreateGridMenu(getDriver().getScreenCenterPos() + Vec2f(0.0f, 0.0f), this, Vec2f((tunnels.length) * BUTTON_SIZE, BUTTON_SIZE), getTranslatedString("Pick tunnel to travel"));
	if (menu !is null)
	{
		CBitStream exitParams;
		exitParams.write_netid(callerID);
		menu.AddKeyCommand(KEY_ESCAPE, this.getCommandID("travel none"), exitParams);
		menu.SetDefaultCommand(this.getCommandID("travel none"), exitParams);

		for (uint i = 0; i < tunnels.length; i++)
		{
			CBlob@ tunnel = tunnels[i];
			if (tunnel is null)
			{
				menu.AddButton("$CANCEL$", getTranslatedString("You are here"), Vec2f(BUTTON_SIZE, BUTTON_SIZE));
			}
			else
			{
				CBitStream params;
				params.write_u16(callerID);
				params.write_u16(tunnel.getNetworkID());
				int direction_index = getTravelDirectionIndex(this, tunnel);
				menu.AddButton(getTravelIcon(this, tunnel, direction_index), getTranslatedString(getTravelDescription(this, tunnel, direction_index)), this.getCommandID("travel to"), Vec2f(BUTTON_SIZE, BUTTON_SIZE), params);
			}
		}
	}
}

// returns index for 8 direction, starting from right, going counter-clockwise
int getTravelDirectionIndex(CBlob@ this, CBlob@ tunnel) {
	float angle = (tunnel.getPosition() - this.getPosition()).AngleRadians();
	angle += Maths::Pi / 8; //offset for proper rounding
	angle += 2 * Maths::Pi; //offset to ensure positiveness
	int direction_index = angle / (Maths::Pi * 2 / 8);
	direction_index = direction_index % 8; //ensure index is in bounds

	return direction_index;
}

string getTravelIcon(CBlob@ this, CBlob@ tunnel, int direction_index)
{
	if (tunnel.getName() == "war_base")
		return "$WAR_BASE$";

	int team = tunnel.getTeamNum();
	string[] directions =
	{
		"$TRAVEL_RIGHT_"+team+"$",
		"$TRAVEL_RIGHT_UP_"+team+"$",
		"$TRAVEL_UP_"+team+"$",
		"$TRAVEL_LEFT_UP_"+team+"$",
		"$TRAVEL_LEFT_"+team+"$",
		"$TRAVEL_LEFT_DOWN_"+team+"$",
		"$TRAVEL_DOWN_"+team+"$",
		"$TRAVEL_RIGHT_DOWN_"+team+"$"
	};
	if (direction_index >= 0 && direction_index < directions.length)
		return directions[direction_index];
	else
		return "$CANCEL$"; // should never happen
}

string getTravelDescription(CBlob@ this, CBlob@ tunnel, int direction_index)
{
	if (tunnel.getName() == "war_base")
		return "Return to base";

	const string[] directions =
	{
		"Travel right",
		"Travel right and up",
		"Travel up",
		"Travel left and up",
		"Travel left",
		"Travel left and down",
		"Travel down",
		"Travel right and down"
	};
	if (direction_index >= 0 && direction_index < directions.length)
		return directions[direction_index];
	else
		return "Travel"; // should never happen
}