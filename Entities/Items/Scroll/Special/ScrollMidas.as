// scroll script that builds gold into

#include "Hitters.as";

void onInit(CBlob@ this)
{
	this.addCommandID("midas");

	this.set_u32("midas_called", 0);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	CBitStream params;
	params.write_u16(caller.getNetworkID());
	caller.CreateGenericButton(11, Vec2f_zero, this, this.getCommandID("midas"), "Use this to turn all stone in the area into gold", params);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("midas"))
	{
		u32 timer = getGameTime() - this.get_u32("midas_called");
		if (timer < 30)
			return;

		this.set_u32("midas_called", getGameTime());

		bool acted = false;
		const int radius = 10;

		CMap@ map = this.getMap();

		if (map is null) return;

		Vec2f pos = this.getPosition();

		f32 radsq = radius * 8 * radius * 8;

		for (int x_step = -radius; x_step < radius; ++x_step)
		{
			for (int y_step = -radius; y_step < radius; ++y_step)
			{
				Vec2f off(x_step * map.tilesize, y_step * map.tilesize);

				if (off.LengthSquared() > radsq)
					continue;

				Vec2f tpos = pos + off;

				TileType t = map.getTile(tpos).type;
				if (map.isTileStone(t) || map.isTileThickStone(t))
				{
					map.server_SetTile(tpos, CMap::tile_gold);
					acted = true;
				}
			}
		}


		if (acted)
		{
			this.server_Die();
			Sound::Play("MagicWand.ogg", this.getPosition());
		}
	}
}
