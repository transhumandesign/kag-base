#include "TechsCommon.as";
#include "Help.as";

void onInit(CBlob@ this)
{
	this.server_setTeamNum(-1);
	//team - force blue unless special
	int team = (this.exists("team colour") ? this.get_u8("team colour") : 0);

	CSprite@ sprite = this.getSprite();
	sprite.ReloadSprite(sprite.getFilename(),				//reload sprite
	                    sprite.getConsts().frameWidth,
	                    sprite.getConsts().frameHeight,
	                    team,
	                    this.getSkinNum());

	if (this.exists("scroll name"))
		this.setInventoryName(this.get_string("scroll name"));

	if (this.exists("scroll icon"))
	{
		const u8 frame = this.get_u8("scroll icon");
		this.inventoryIconFrame = frame;
		//	this.getSprite().SetFrame( frame );
	}

	SetHelp(this, "help pickup", "", getTranslatedString("$scroll$Pick up    $KEY_C$"));

	ShopItem[]@ items;
	if (this.get(TECH_ARRAY, @items))
	{
		SetHelp(this, "help use carried", "", getTranslatedString("$scroll$Use in *first* Hall     $KEY_E$"));
	}
	else
	{
		SetHelp(this, "help use carried", "", getTranslatedString("$scroll$Use magic scroll    $KEY_E$"));
	}
}

void onSendCreateData(CBlob@ this, CBitStream@ stream)
{
	ShopSendCreateData(this, stream, TECH_ARRAY);
}

bool onReceiveCreateData(CBlob@ this, CBitStream@ stream)
{
	return ShopReceiveCreateData(this, stream, TECH_ARRAY);
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	this.server_setTeamNum(attached.getTeamNum());
}



// SPRITE


void onTick(CSprite@ this)
{
	this.SetFrameIndex(this.getBlob().inventoryIconFrame);
}
