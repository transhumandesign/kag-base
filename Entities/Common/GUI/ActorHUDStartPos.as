//for use with DefaultActorHUD.as based HUDs

f32 getHUDX()
{
	return getScreenWidth() / 3;
}

f32 getHUDY()
{
	return getScreenHeight();
}

// compatibility - prefer to use getHUDX() and getHUDY() as you are rendering, because resolution may dynamically change (from asu's staging build onwards)
const f32 HUD_X = getHUDX();
const f32 HUD_Y = getHUDY();

Vec2f getActorHUDStartPosition(CBlob@ blob, const u8 bar_width_in_slots)
{
	f32 width = bar_width_in_slots * 40.0f;
	return Vec2f(getHUDX() + 180 + 50 + 8 - width, getHUDY() - 40);
}

void DrawInventoryOnHUD(CBlob@ this, Vec2f tl)
{
	SColor col;
	CInventory@ inv = this.getInventory();
	string[] drawn;
	for (int i = 0; i < inv.getItemsCount(); i++)
	{
		CBlob@ item = inv.getItem(i);
		const string name = item.getName();
		if (drawn.find(name) == -1)
		{
			const int quantity = this.getBlobCount(name);
			drawn.push_back(name);

			GUI::DrawIcon(item.inventoryIconName, item.inventoryIconFrame, item.inventoryFrameDimension, tl + Vec2f(0 + (drawn.length - 1) * 40, -6), 1.0f);

			f32 ratio = float(quantity) / float(item.maxQuantity);
			col = ratio > 0.4f ? SColor(255, 255, 255, 255) :
			      ratio > 0.2f ? SColor(255, 255, 255, 128) :
			      ratio > 0.1f ? SColor(255, 255, 128, 0) : SColor(255, 255, 0, 0);

			GUI::SetFont("menu");
			Vec2f dimensions(0,0);
			string disp = "" + quantity;
			GUI::GetTextDimensions(disp, dimensions);
			GUI::DrawText(disp, tl + Vec2f(14 + (drawn.length - 1) * 40 - dimensions.x/2 , 24), col);
		}
	}
}

class Coin_Info
{
    int count, delta;
	int changed_time;
};

void DrawCoinsOnHUD(CBlob@ this, const int coins, Vec2f tl, const int slot)
{
	if (coins > 0)
	{
		GUI::DrawIconByName("$COIN$", tl + Vec2f(0 + slot * 40, 0));
		GUI::SetFont("menu");
		GUI::DrawText("" + coins, tl + Vec2f(4 + slot * 40 , 24), color_white);
	}

	if (this !is null)
	{
		CPlayer@ player = this.getPlayer();
		if (player !is null)
		{
			Coin_Info@ info;
			if (!player.exists("coin_info"))
			{
				Coin_Info coin_info;
				coin_info.count = 0;
				coin_info.delta = 0;
				coin_info.changed_time = 0;
				@info = @coin_info;
				player.set("coin_info", @info);
			}
			else
				player.get("coin_info", @info);
			if (info is null) return; // should never happen to be null

			if (info.count != coins)
			{
				if (info.delta != coins - info.count) // NOTE(hobey): coins just changed
				{
					info.changed_time = getGameTime();
					info.delta = coins - info.count;
				}
				else if (info.changed_time + 30 < getGameTime()) // NOTE(hobey): after a while, stop displaying the HUD
				{
					info.count = coins;
					info.delta = 0;
					return;
				}

				GUI::DrawIconByName("$COIN$", tl + Vec2f(0 + slot * 40, -48-24));
				GUI::SetFont("menu");
				GUI::DrawText((info.delta > 0 ? "+" : "") + info.delta, tl + Vec2f(4 + slot * 40 , -48), (info.delta > 0) ? SColor(255, 0, 255, 0) : SColor(255, 255, 0, 0));
			}
		}
	}
}
