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
	this.addCommandID("travel to");
	this.addCommandID("travel to client");
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
	if (cmd == this.getCommandID("travel to") && isServer())
	{
		CPlayer@ p = getNet().getActiveCommandPlayer();
		if (p is null) return;

		CBlob@ caller = p.getBlob();
		if (caller is null) return;

		u16 to_id;
		if (!params.saferead_u16(to_id)) return;

		CBlob@ tunnel = getBlobByNetworkID(to_id);
		if (tunnel is null) return;

		if (this.isOverlapping(caller))
		{
			server_Travel(this, caller, tunnel);
		}
	}
	else if (cmd == this.getCommandID("travel to client") && isClient())
	{
		u16 caller_id;
		if (!params.saferead_u16(caller_id)) return;
		CBlob@ caller = getBlobByNetworkID(caller_id);
		if (caller is null) return;

		u16 tunnel_id;
		if (!params.saferead_u16(tunnel_id)) return;
		CBlob@ tunnel = getBlobByNetworkID(tunnel_id);
		if (tunnel is null) return;

		client_Travel(this, caller, tunnel);
	}
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

// the shitty GenericButton callback
void Callback_Travel(CBlob@ this, CBlob@ caller)
{
	CBlob@[] tunnels;
	if (getTunnels(this, @tunnels))
	{
		// instant travel cause there is just one place to go
		if (tunnels.length == 1)
		{
			CBitStream params;
			params.write_u16(tunnels[0].getNetworkID());
			this.SendCommand(this.getCommandID("travel to"), params);
		}
		else
		{
			BuildTunnelsMenu(this);
		}
	}
}

// the good CGridMenu callbacks
void Callback_TravelTo(CBitStream@ params)
{
	CBlob@ caller = getLocalPlayerBlob();

	if (caller is null) return;

	u16 this_id;
	if (!params.saferead_u16(this_id)) return;

	CBlob@ this = getBlobByNetworkID(this_id);
	if (this is null) return;

	u16 to_id;
	if (!params.saferead_u16(to_id)) return;

	CBlob@ tunnel = getBlobByNetworkID(to_id);
	if (tunnel is null) return;

	if (this.isOverlapping(caller))
	{
		CBitStream params;
		params.write_u16(to_id);
		this.SendCommand(this.getCommandID("travel to"), params);

	}
	else
	{
		caller.getSprite().PlaySound("NoAmmo.ogg", 0.5);
	}
}

void Callback_TravelNone(CBitStream@ params)
{
	getHUD().ClearMenus();
}

CButton@ MakeTravelButton(CBlob@ this, CBlob@ caller, Vec2f buttonPos, const string &in label, const string &in cantTravelLabel)
{
	CBlob@[] tunnels;
	const bool gotTunnels = getTunnels(this, @tunnels);
	const bool travelAvailable = gotTunnels && isInRadius(this, caller);
	if (!travelAvailable)
		return null;

	// genericbuttons use the shitty callback
	CButton@ button = caller.CreateGenericButton(8, buttonPos, this, Callback_Travel, gotTunnels ? getTranslatedString(label) : getTranslatedString(cantTravelLabel));
	if (button !is null)
	{
		button.SetEnabled(travelAvailable);
	}
	return button;
}

void server_Travel(CBlob@ this, CBlob@ caller, CBlob@ tunnel)
{
	if (!isServer()) return;

	if (this !is null && caller !is null && tunnel !is null)
	{
		//(this should prevent travel when stunned, but actually
		// causes issues on net)
		//if (isKnockable(caller) && caller.get_u8("knocked") > 0)
		//	return;

		//dont travel if out of range
		if (!this.isOverlapping(caller))
			return;
		
		//dont travel if under raid and not ignoring raid
		if (this.hasTag("under raid") && !this.hasTag("ignore raid"))
			return;

		//dont travel if teamlocked tunnel and different team
		if (this.hasTag("teamlocked tunnel") && this.getTeamNum() != caller.getTeamNum())
			return;

		//dont travel if tunnel team has changed while tunnel menu was open
		if (this.getTeamNum() != tunnel.getTeamNum())
			return;

		//dont travel if caller is attached to something (e.g. siege)
		if (caller.isAttached())
			return;

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

		CBitStream params;
		params.write_u16(caller.getNetworkID());
		params.write_u16(tunnel.getNetworkID());
		this.SendCommand(this.getCommandID("travel to client"), params);
	}
}

void client_Travel(CBlob@ this, CBlob@ caller, CBlob@ tunnel)
{
	if (this !is null && caller !is null && tunnel !is null)
	{
		// assume destination is center bottom
		Vec2f position = tunnel.getPosition();
		position = Vec2f(position.x, position.y + tunnel.getHeight() / 2 - caller.getHeight() / 2);
		
		// apply offset (if it exists)
		if (tunnel.exists("travel offset"))
		{
			Vec2f offset = tunnel.get_Vec2f("travel offset");
			position += tunnel.isFacingLeft() ? -offset : offset;
		}

		if (caller.isMyPlayer())
		{
			caller.setPosition(position);
			caller.setVelocity(Vec2f_zero);
			Sound::Play("Travel.ogg");
		}
		else
		{
			Sound::Play("Travel.ogg", this.getPosition());
			Sound::Play("Travel.ogg", caller.getPosition());
		}
	}
}

const int BUTTON_SIZE = 2;

void BuildTunnelsMenu(CBlob@ this)
{
	CBlob@[] tunnels;
	getTunnelsForButtons(this, @tunnels);

	CGridMenu@ menu = CreateGridMenu(getDriver().getScreenCenterPos() + Vec2f(0.0f, 0.0f), this, Vec2f((tunnels.length) * BUTTON_SIZE, BUTTON_SIZE), getTranslatedString("Pick tunnel to travel"));
	if (menu !is null)
	{
		CBitStream params;
		menu.AddKeyCallback(KEY_ESCAPE, "TunnelTravel.as", "Callback_TravelNone", params);
		menu.SetDefaultCallback("TunnelTravel.as", "Callback_TravelNone", params);

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
				params.write_u16(this.getNetworkID());
				params.write_u16(tunnel.getNetworkID());
				int direction_index = getTravelDirectionIndex(this, tunnel);
				menu.AddButton(getTravelIcon(this, tunnel, direction_index), getTranslatedString(getTravelDescription(this, tunnel, direction_index)), "TunnelTravel.as", "Callback_TravelTo", Vec2f(BUTTON_SIZE, BUTTON_SIZE), params);
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