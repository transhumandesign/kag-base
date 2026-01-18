// Flag logic

#include "CTF_FlagCommon.as"
#include "CTF_Structs.as"

const u16 fast_return_speedup = 3;

void onInit(CBlob@ this)
{
	this.getShape().SetRotationsAllowed(false);

	this.getCurrentScript().tickFrequency = 5;

	//cannot fall out of map
	this.SetMapEdgeFlags(u8(CBlob::map_collide_up) |
	                     u8(CBlob::map_collide_down) |
	                     u8(CBlob::map_collide_sides));

	this.set_u16(return_prop, 0);

	this.Tag("medium weight"); //slow carrier a little

	this.addCommandID("pickup flag client");
	this.addCommandID("capture flag client");
	this.addCommandID("return flag client");

	//we actually have our own way of ignoring damage
	//but this is important for a lot of other scripts
	this.Tag("invincible");

	//special item - prioritise pickup
	this.Tag("special");

	//minimap
	this.SetMinimapOutsideBehaviour(CBlob::minimap_snap);
	this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 9, Vec2f(8, 8));

	//some legacy bug :/
	if (sv_test && this.getPosition() == Vec2f_zero)
	{
		warning("Flags spawned at (0,0), investigate!");
	}

	AddIconToken("$progress_bar$", "Entities/Special/CTF/FlagProgressBar.png", Vec2f(30, 8), 0);
	AddIconToken("$fast_return_indicator$", "Entities/Special/CTF/FlagFastReturnIndicator.png", Vec2f(18, 10), 0);
	AddIconToken("$return_indicator$", "Entities/Special/CTF/FlagTickIndicator.png", Vec2f(10, 10), 0);

	// Pickup: custom hover area
	Vec2f[] hoverPoly = 
		{ Vec2f(-2.5f, -15.0f)
		, Vec2f(-1.5f, -19.0f)
		, Vec2f(1.5f, -19.0f)
		, Vec2f(2.5f, -15.0f)
		, Vec2f(2.5f, 7.0f)
		, Vec2f(-2.5f, 7.0f)
		, Vec2f(-2.5f, -15.0f)
		};

	this.set("hover-poly", hoverPoly);
}

void onTick(CBlob@ this)
{
	u16 returncount = this.get_u16(return_prop);

	if (!this.isAttached())
	{
		CMap@ map = getMap();
		if (map !is null)
		{
			//return if flag hits void
			if (this.getPosition().y >= map.getMapDimensions().y)
			{
				returncount = return_time;
			}
		}

		if (returncount < return_time)
		{
			const u32 freq = this.getCurrentScript().tickFrequency;
			const bool fast_return = shouldFastReturn(this);
			returncount += freq * (fast_return ? fast_return_speedup : 1);
		}
	}
	
	this.set_u16(return_prop, returncount);
	//no sync - should be about the same on client
}

//sprite

void onInit(CSprite@ this)
{
	CSpriteLayer@ flag = this.addSpriteLayer("flag_layer", "/CTF_Flag.png", 32, 16, this.getBlob().getTeamNum(), this.getBlob().getSkinNum());
	if (flag !is null)
	{
		flag.SetOffset(Vec2f(15, -8));
		flag.SetRelativeZ(1.0f);
		Animation@ anim = flag.addAnimation("default", XORRandom(3) + 3, true);
		int[] frames = { 0, 2, 4, 6 };
		anim.AddFrames(frames);
	}
}

// alert and capture progress bar

void onRender(CSprite@ this)
{
	if (g_videorecording)
		return;

	CBlob@ blob = this.getBlob();
	if (blob.isAttached())
	{
		//todo: render "go to here" gui
		return;
	}

	const u16 returncount = blob.get_u16(return_prop);
	if (returncount <= 0 || returncount >= return_time)
		return;

	const f32 scalex = getDriver().getResolutionScaleFactor();
	const f32 zoom = getCamera().targetDistance * scalex;
	// adjust vertical offset depending on zoom
	Vec2f pos2d = blob.getInterpolatedScreenPos() + Vec2f(0.0f, (-blob.getHeight() - 20.0f) * zoom);

	const f32 wave = Maths::Sin(getGameTime() / 5.0f) * 5.0f - 25.0f;

	Vec2f pos = pos2d + Vec2f(-30.0f, -40.0f);
	Vec2f dimension = Vec2f(60.0f - 8.0f, 8.0f);
		
	GUI::DrawIconByName("$progress_bar$", pos);
	
	const f32 percentage = 1.0f - f32(returncount) / f32(return_time);
	Vec2f bar = Vec2f(pos.x + (dimension.x * percentage), pos.y + dimension.y);
	
	if (1.0f - f32(returncount) / f32(return_time) < 0.2f)
	{
		GUI::DrawRectangle(pos + Vec2f(4, 4), bar + Vec2f(4, 4), SColor(255, 59, 20, 6));
		GUI::DrawRectangle(pos + Vec2f(6, 6), bar + Vec2f(2, 4), SColor(255, 148, 27, 27));
		GUI::DrawRectangle(pos + Vec2f(6, 6), bar + Vec2f(2, 2), SColor(255, 183, 51, 51));
	}
	else
	{
		GUI::DrawRectangle(pos + Vec2f(4, 4), bar + Vec2f(4, 4), SColor(255, 58, 63, 21));
		GUI::DrawRectangle(pos + Vec2f(6, 6), bar + Vec2f(2, 4), SColor(255, 99, 112, 95));
		GUI::DrawRectangle(pos + Vec2f(6, 6), bar + Vec2f(2, 2), SColor(255, 125, 139, 120));
	}

	GUI::DrawIconByName("$ALERT$", Vec2f(pos2d.x - 32.0f, pos2d.y - 80.0f + wave));

	if (getGameTime() % 15 > 10)
	{
		if (!shouldFastReturn(blob))
		{
			GUI::DrawIconByName("$return_indicator$", Vec2f(pos2d.x-8.0f, pos2d.y-41.0f));
		}
		else
		{
			GUI::DrawIconByName("$fast_return_indicator$", Vec2f(pos2d.x-18.0f, pos2d.y-41.0f));
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	//ignore all damage except from special hit
	if (customData == 0xfa)
	{
		this.server_SetHealth(-1.0f);
		this.server_Die();
	}
	return 0.0f;
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return !this.isAttached() &&
	       byBlob.hasTag("player") &&
	       this.getTeamNum() != byBlob.getTeamNum() &&
	       canPickupFlag(byBlob) &&
	       this.getDistanceTo(byBlob) < 32.0f;
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null) return;

	if (!this.isAttached() &&
	    blob.hasTag("player") &&
	    this.getTeamNum() != blob.getTeamNum() &&
	    canPickupFlag(blob))
	{
		blob.server_AttachTo(this, "PICKUP");
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (!isClient()) return;

	bool needsmessage = false;
	string message = "";

	if (cmd == this.getCommandID("pickup flag client"))
	{
		u16 id;
		if (!params.saferead_u16(id)) return;

		CBlob@ blob = getBlobByNetworkID(id);
		if (blob !is null && blob.getPlayer() !is null)
		{
			needsmessage = true;
			message = "picked up by " + blob.getPlayer().getUsername() + "!";

			Sound::Play("/flag_capture.ogg");
		}
	}
	else if (cmd == this.getCommandID("capture flag client"))
	{
		u16 id;
		if (!params.saferead_u16(id)) return;

		CBlob@ blob = getBlobByNetworkID(id);
		if (blob !is null && blob.getPlayer() !is null)
		{
			needsmessage = true;
			message = "captured by " + blob.getPlayer().getUsername() + "!";

			Sound::Play("/flag_score.ogg");
		}
	}
	else if (cmd == this.getCommandID("return flag client"))
	{
		Sound::Play("/flag_return.ogg");

		needsmessage = true;

		if (shouldFastReturn(this))
			message = "returned due to teamwork!";
		else
			message = "returned!";
	}

	if (needsmessage)
	{
		CRules@ rules = getRules();
		const int team = this.getTeamNum();
		const string myTeamName = (team < rules.getTeamsCount() ? rules.getTeam(team).getName() + "'s" : "");

		client_AddToChat(myTeamName + " flag has been " + message);
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return (blob.getShape().isStatic());
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	this.set_u16(return_prop, 0);

	this.SetFacingLeft(attached.isFacingLeft());

    if (!isServer())
        return;

    if (attached.getName() != "flag_base") {
		this.Tag("has attached to player");
		this.Sync("has attached to player", true);
	}

	CRules@ rules = getRules();

	UIData@ ui;
	rules.get("uidata", @ui);

	if (ui is null)
	{
		UIData data;
		rules.set("uidata", data);
		rules.get("uidata", @ui);
	}

	const u16 id = this.getNetworkID();

	for(int i = 0; i < ui.flagIds.size(); i++)
	{
		if (ui.flagIds[i] == id)
		{
			if (attached.getName() == "flag_base")
			{
				ui.flagStates[i] = "f";
			}
			else if (attached.getTeamNum() != this.getTeamNum())
			{
				ui.flagStates[i] = "m";
			}
		}
	}

	CBitStream bt = ui.serialize();

	rules.set_CBitStream("ctf_serialised_team_hud", bt);
	rules.Sync("ctf_serialised_team_hud", true);
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint) {
    if (!isServer()) return;

	this.Untag("has attached to player");
	this.Sync("has attached to player", true);
}
