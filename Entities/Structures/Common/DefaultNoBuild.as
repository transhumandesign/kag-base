#include "AddTilesBySector.as";

#define SERVER_ONLY

const string counter = "nobuild counter";
const string back = "background tile";
const string nobuild_extend = "nobuild extend";
const int CHECK_FREQ = 35;

void onInit(CBlob@ this)
{
	this.set_u8(counter, 1);
	this.getCurrentScript().tickFrequency = 5;
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
}

void onTick(CBlob@ this)
{
	if (this.getCurrentScript().tickFrequency != CHECK_FREQ)
	{
		u8 c = this.get_u8(counter);
		if (c > 0)
		{
			c--;
			this.set_u8(counter, c);
			return;
		}

		Vec2f ul, lr;
		Vec2f extend;
		if (this.exists(nobuild_extend))
		{
			extend = this.get_Vec2f(nobuild_extend);
		}

		this.getShape().getBoundingRect(ul, lr);

		lr += extend;
		this.getMap().server_AddSector(ul, lr, "no build", "", this.getNetworkID());
		lr -= extend;

		if (this.exists(back))
		{
			AddTilesBySector(ul, lr, "no build", this.get_TileType(back), CMap::tile_castle_back, this.hasTag("has window"));
		}
		else
		{
			this.getCurrentScript().runFlags |= Script::remove_after_this;
		}

		this.getCurrentScript().tickFrequency = CHECK_FREQ;
	}
	// check for collapse
	else if (getNet().isServer())
	{
		Vec2f ul, lr;
		this.getShape().getBoundingRect(ul, lr);

		CMap@ map = getMap();
		const f32 tilesize = map.tilesize;

		Vec2f tpos = ul;
		bool hasEmpty = false;
		while (tpos.x < lr.x)
		{
			while (tpos.y < lr.y)
			{
				if (map.getTile(tpos).type != 0)
				{
					return;

				}
				tpos.y += tilesize;
			}
			tpos.x += tilesize;
			tpos.y = ul.y;
		}

		// die because there is no back

		this.server_Hit(this, this.getPosition(), Vec2f_zero, this.getHealth() + 5.0f, 0, true);
	}
}

