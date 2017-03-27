#include "LayerSetup.as";
#include "ProductionCommon.as";

//factory

const string texname = "Factory.png";

const u8 rotates	= 0x01;
const u8 forwards	= 0x02;
const u8 damage_an	= 0x04;

void onInit(CSprite@ this)
{
	CBlob@ blob = this.getBlob();

	const int team = blob.getTeamNum();

	//CANT BE SCRIPT GLOBAL, NEEDS TEAMNUM
	int[] wood_cog = {31};
	int[] team_cog = {30};
	int[] dark_cog = {15};
	int[] scroll_anim = {64, 65, 72};
	int[] big_gear = {6, 14};
	int[] frame = {1, 4};
	int[] box = {23, 31};
	int[] dispenser = {5, 13};

	LayerSetup[] layers =
	{
		// name,		texture, 		size,		frames,	 		 offset,	team, 	skin, 	visible, vars
		//dispenser
		makeLayerSetup("dispenser",		texname, Vec2f(16, 16),	dispenser,	  	Vec2f(11, -5),	team, 0,	true, damage_an),

		//gears layers
		makeLayerSetup("big gear",		texname, Vec2f(16, 16),  big_gear,   	Vec2f(-8, -7),  	0, 0,		true, rotates | forwards | damage_an),

		makeLayerSetup("gear 1",		texname, Vec2f(8, 8),	wood_cog,		Vec2f(8, -6), 	0, 0,		false, rotates | forwards),
		makeLayerSetup("gear 2",		texname, Vec2f(8, 8),	dark_cog,		Vec2f(2, -4),	team, 0,	false, rotates),

		makeLayerSetup("gear 3",		texname, Vec2f(8, 8),	dark_cog,		Vec2f(-12, 3),	0, 0,		true, rotates),
		makeLayerSetup("gear 4",		texname, Vec2f(8, 8),	team_cog,		Vec2f(-6, 7),	0, 0,		true, rotates | forwards),

		//frame
		makeLayerSetup("frame",			texname, Vec2f(40, 8),	frame,	   		Vec2f(0, -5),	0, 0,		true, damage_an),
		makeLayerSetup("box",			texname, Vec2f(16, 8),	box,	   		Vec2f(-10, 10),	0, 0,		true, damage_an)

	};

	//TODO: set up z etc here
	layers[0].z = 0.5f;
	layers[6].z = 10.f;
	layers[7].z = 0.5f;

	addLayersFromSetupArray(this, @layers);

	// cache indices and rot

	for (uint step = 0; step < layers.length; ++step)
	{
		LayerSetup @setup = layers[step];
		bool rot_forwards = (setup.vars & forwards != 0);
		setup.rotationCache = 3.1416f / setup.size.x * (rot_forwards ? -5.0f : 5.0f);
	}

	blob.set("layer setups", @layers);

	/* off until we find nice lighting solution
	//setup the dynamic foreground layer :)
	CSpriteLayer@ front = this.addSpriteLayer( "front layer", this.getFilename() , 48, 16, blob.getTeamNum(), blob.getSkinNum() );

	if (front !is null)
	{
		front.SetOffset(Vec2f(0,7));
		Animation@ anim = front.addAnimation( "default", 0, false );
		anim.AddFrame(6);
		front.SetRelativeZ( 1000 );
	}*/

	this.SetZ(-50);
	blob.Untag("icon layer");
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob.hasTag("production paused"))
		return;

	LayerSetup[]@ layers;
	if (!blob.get("layer setups", @layers)) return;

	const bool producing = isProducing(blob);
	const bool hasTech = blob.get_string("tech name").size() != 0;

	//s32 time = (getGameTime() + blob.getNetworkID()*31);
	f32 hp_frame_ratio = 1.0f - (blob.getHealth() / blob.getInitialHealth());
	for (uint step = 0; step < layers.length; ++step)
	{
		LayerSetup@ setup = layers[step];
		CSpriteLayer@ layer = getLayerFromSetup(this, setup);

		if (!hasTech)
		{
			if (step == 5) //HACK
			{
				layer.SetVisible(false);
				continue;
			}
		}
		else
		{
			if (!blob.hasTag("icon layer"))
			{
				AddSignLayerFrom(this, blob);
				blob.Tag("icon layer");
			}
		}
		layer.SetVisible(true);

		if (producing && setup.vars & rotates != 0)
		{
			layer.RotateBy(setup.rotationCache , Vec2f_zero);
		}
		if (setup.vars & damage_an != 0)
		{
			layer.animation.frame = hp_frame_ratio * layer.animation.getFramesCount();
		}
	}

}

void AddSignLayerFrom(CSprite@ this, CBlob@ scroll)
{
	RemoveSignLayer(this);

	CBlob@ blob = this.getBlob();

	int team = blob.getTeamNum();
	int skin = blob.getSkinNum();

	int x = 4 - XORRandom(8);
	int rot = 15 - XORRandom(30);

	CSpriteLayer@ sign = this.addSpriteLayer("sign", this.getFilename() , 32, 16, team, skin);
	{
		Animation@ anim = sign.addAnimation("default", 0, false);
		anim.AddFrame(11);
		sign.SetOffset(Vec2f(x, -12));
		sign.SetRelativeZ(1010);
		sign.RotateBy(rot, Vec2f());
	}

	CSpriteLayer@ icon = this.addSpriteLayer("icon", "/MiniIcons.png" , 16, 16, team, skin);
	if (icon !is null)
	{
		Animation@ anim = icon.addAnimation("default", 0, false);
		anim.AddFrame(scroll.inventoryIconFrame);
		icon.SetOffset(Vec2f(x, -12));
		icon.SetRelativeZ(1015);
		icon.RotateBy(rot, Vec2f());
	}
}

void RemoveSignLayer(CSprite@ this)
{
	this.RemoveSpriteLayer("sign");
	this.RemoveSpriteLayer("icon");
}


void onRender(CSprite@ this)
{
	CBlob@ localBlob = getLocalPlayerBlob();
	if (localBlob is null)
		return;

	CBlob@ blob = this.getBlob();
	Vec2f center = blob.getPosition();
	Vec2f mouseWorld = getControls().getMouseWorldPos();
	const f32 renderRadius = (blob.getRadius()) * 0.95f;
	bool mouseOnBlob = (mouseWorld - center).getLength() < renderRadius;
	if ((mouseOnBlob || (localBlob.getPosition() - center).getLength() < renderRadius) &&
	        (getHUD().hasButtons() && !getHUD().hasMenus())
	   )
	{
		if (blob.hasTag("production paused") && blob.get_string("tech name").size() > 0)
		{
			Vec2f pos2d = blob.getScreenPos();
			Vec2f upperleft(pos2d.x - 100, pos2d.y - 50.0f);
			Vec2f lowerright(pos2d.x + 100, pos2d.y);
			GUI::SetFont("menu");
			GUI::DrawText("Requires a Worker from the Hall to work here.", upperleft, lowerright, SColor(255, 240, 10, 10), false, false, true);
		}
	}  // E
}