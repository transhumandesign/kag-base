// include file for blobs that use tunnel travel capabilities
// apply "travel tunnel" tag to use

#include "TunnelCommon.as";
#include "Knocked.as";

void onInit(CBlob@ this)
{
	this.addCommandID("travel");
	this.addCommandID("travel none");
	this.addCommandID("travel to");
	this.addCommandID("server travel to");
	this.Tag("travel tunnel");

	AddIconToken("$TRAVEL_LEFT$", "GUI/MenuItems.png", Vec2f(32, 32), 23);
	AddIconToken("$TRAVEL_RIGHT$", "GUI/MenuItems.png", Vec2f(32, 32), 22);

	if (!this.exists("travel button pos"))
	{
		this.set_Vec2f("travel button pos", Vec2f_zero);
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.isOverlapping(caller) &&
	        this.hasTag("travel tunnel") &&
	        (!this.hasTag("teamlocked tunnel") || this.getTeamNum() == caller.getTeamNum()) &&
	        !this.hasTag("under raid") &&
	        //CANNOT travel when stunned
			!(isKnockable(caller) && caller.get_u8("knocked") > 0)
		)
	{
		MakeTravelButton(this, caller, this.get_Vec2f("travel button pos"), "Travel", "Travel (requires Transport Tunnels)");
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	onTunnelCommand(this, cmd, params);
}

// get all team tunnels sorted by team distance

bool getTunnelsForButtons(CBlob@ this, CBlob@[]@ tunnels)
{
	CBlob@[] list;
	getBlobsByTag("travel tunnel", @list);
	Vec2f thisPos = this.getPosition();

	// add left tunnels
	for (uint i = 0; i < list.length; i++)
	{
		CBlob@ blob = list[i];
		if (blob !is this && blob.getTeamNum() == this.getTeamNum() && blob.getPosition().x < thisPos.x)
		{
			bool added = false;
			const f32 distToBlob = (blob.getPosition() - thisPos).getLength();
			for (uint tunnelInd = 0; tunnelInd < tunnels.length; tunnelInd++)
			{
				CBlob@ tunnel = tunnels[tunnelInd];
				if ((tunnel.getPosition() - thisPos).getLength() < distToBlob)
				{
					tunnels.insert(tunnelInd, blob);
					added = true;
					break;
				}
			}
			if (!added)
				tunnels.push_back(blob);
		}
	}

	tunnels.push_back(null);	// add you are here

	// add right tunnels
	const uint tunnelIndStart = tunnels.length;

	for (uint i = 0; i < list.length; i++)
	{
		CBlob@ blob = list[i];
		if (blob !is this && blob.getTeamNum() == this.getTeamNum() && blob.getPosition().x >= thisPos.x)
		{
			bool added = false;
			const f32 distToBlob = (blob.getPosition() - thisPos).getLength();
			for (uint tunnelInd = tunnelIndStart; tunnelInd < tunnels.length; tunnelInd++)
			{
				CBlob@ tunnel = tunnels[tunnelInd];
				if ((tunnel.getPosition() - thisPos).getLength() > distToBlob)
				{
					tunnels.insert(tunnelInd, blob);
					added = true;
					break;
				}
			}
			if (!added)
				tunnels.push_back(blob);
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
	CButton@ button = caller.CreateGenericButton(8, buttonPos, this, this.getCommandID("travel"), gotTunnels ? label : cantTravelLabel, params);
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
	if (caller !is null && tunnel !is null)
	{
		//(this should prevent travel when stunned, but actually
		// causes issues on net)
		//if(isKnockable(caller) && caller.get_u8("knocked") > 0)
		//	return;

		if (caller.isAttached())   // attached - like sitting in cata? move whole cata
		{
			const int count = caller.getAttachmentPointCount();
			for (int i = 0; i < count; i++)
			{
				AttachmentPoint @ap = caller.getAttachmentPoint(i);
				CBlob@ occBlob = ap.getOccupied();
				if (occBlob !is null)
				{
					occBlob.setPosition(tunnel.getPosition());
					occBlob.setVelocity(Vec2f_zero);
					occBlob.getShape().PutOnGround();
				}
			}
		}
		// move caller
		caller.setPosition(tunnel.getPosition());
		caller.setVelocity(Vec2f_zero);
		caller.getShape().PutOnGround();

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
		if(isKnockable(caller))
		{
			//if you travel, you lose invincible
			caller.Untag("invincible");
			caller.Sync("invincible", true);

			//actually do the knocking
			SetKnocked(caller, 30, true);
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
			}
		}
		else if (caller !is null && caller.isMyPlayer())
			Sound::Play("NoAmmo.ogg");
	}
	else if (cmd == this.getCommandID("server travel to"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		CBlob@ tunnel = getBlobByNetworkID(params.read_u16());
		Travel(this, caller, tunnel);
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

	CGridMenu@ menu = CreateGridMenu(getDriver().getScreenCenterPos() + Vec2f(0.0f, 0.0f), this, Vec2f((tunnels.length) * BUTTON_SIZE, BUTTON_SIZE), "Pick tunnel to travel");
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
				menu.AddButton("$CANCEL$", "You are here", Vec2f(BUTTON_SIZE, BUTTON_SIZE));
			}
			else
			{
				CBitStream params;
				params.write_u16(callerID);
				params.write_u16(tunnel.getNetworkID());
				menu.AddButton(getTravelIcon(this, tunnel), getTravelDescription(this, tunnel), this.getCommandID("travel to"), Vec2f(BUTTON_SIZE, BUTTON_SIZE), params);
			}
		}
	}
}

string getTravelIcon(CBlob@ this, CBlob@ tunnel)
{
	if (tunnel.getName() == "war_base")
		return "$WAR_BASE$";

	if (tunnel.getPosition().x > this.getPosition().x)
		return "$TRAVEL_RIGHT$";

	return "$TRAVEL_LEFT$";
}

string getTravelDescription(CBlob@ this, CBlob@ tunnel)
{
	if (tunnel.getName() == "war_base")
		return "Return to base";

	if (tunnel.getPosition().x > this.getPosition().x)
		return "Travel right";

	return "Travel left";
}
