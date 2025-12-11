//for use with DefaultActorHUD.as based HUDs

#include "CTF_Common.as";

bool shouldRenderResupplyIndicator(CBlob@ blob)
{
	return ((getRules().gamemode_name == "CTF" || getRules().gamemode_name == "SmallCTF") &&
		(blob.getName() == "builder"));
}

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

bool hoverOnResupplyIcon(Vec2f icon_pos, Vec2f icon_size)
{
	Vec2f mouse_pos = getControls().getMouseScreenPos();

	return mouse_pos.x > icon_pos.x && mouse_pos.x < icon_pos.x + icon_size.x * 2
		&& mouse_pos.y > icon_pos.y && mouse_pos.y < icon_pos.y + icon_size.y * 2 + 6;
}

Vec2f getActorHUDStartPosition(CBlob@ blob, const u8 bar_width_in_slots)
{
	f32 width = bar_width_in_slots * 40.0f;
	return Vec2f(getHUDX() + 180 + 50 + 8 - width, getHUDY() - 40);
}

void DrawResupplyOnHUD(CBlob@ this, Vec2f tl)
{
	CPlayer@ p = this.getPlayer();
	if (p is null) return;
	
	string name = this.getName();

	GUI::SetFont("menu");

	string propname = getCTFTimerPropertyName(p, "builder");

	if (!getRules().exists(propname)) return;

	int wood_amount = matchtime_wood_amount;
	int stone_amount = matchtime_stone_amount;
	if (getRules().isWarmup())
	{
		wood_amount = warmup_wood_amount;
		stone_amount = warmup_stone_amount;
	}

	s32 next_items = getRules().get_s32(propname);

	u32 secs = ((next_items - 1 - getGameTime()) / getTicksASecond()) + 1;
	string units = ((secs != 1) ? " seconds" : " second");

	string resupply_available = getTranslatedString("Go to a builder shop or a respawn point to get a resupply of {WOOD} wood and {STONE} stone.")
		.replace("{WOOD}", "" + wood_amount)
		.replace("{STONE}", "" + stone_amount);

	Vec2f dim_res_av;
	GUI::GetTextDimensions(resupply_available, dim_res_av);

	string resupply_unavailable = getTranslatedString("Next resupply of {WOOD} wood and {STONE} stone in {SEC}{TIMESUFFIX}.")
		.replace("{SEC}", "" + secs)
		.replace("{TIMESUFFIX}", getTranslatedString(units))
		.replace("{WOOD}", "" + wood_amount)
		.replace("{STONE}", "" + stone_amount);

	Vec2f dim_res_unav;
	GUI::GetTextDimensions(resupply_unavailable, dim_res_unav);

	string short_secs = secs + "s";

	Vec2f icon_pos = tl;
	Vec2f icon_size = Vec2f(16, 16);

	bool hover = hoverOnResupplyIcon(icon_pos, icon_size);

	if (next_items > getGameTime())
	{
		GUI::DrawIcon("Entities/Common/GUI/ResupplyIcon.png", 0, icon_size, icon_pos, 1.0f);
		GUI::DrawTextCentered(short_secs, icon_pos + Vec2f(14, 36), color_white);

		if (hover)
		{
			GUI::DrawText(resupply_unavailable, icon_pos + Vec2f(icon_size.x * 2 - dim_res_unav.x + 8, -24), color_white);
		}
	}
	else
	{
		GUI::DrawIcon("Entities/Common/GUI/ResupplyIcon.png", 1, icon_size, icon_pos + Vec2f(0, 6), 1.0f);

		if (hover)
		{
			GUI::DrawText(resupply_available, icon_pos + Vec2f(icon_size.x * 2 - dim_res_av.x + 8, -24), color_white);
		}
	}
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
			const int quantity = inv.getCount(name);
			drawn.push_back(name);

			Vec2f iconpos = tl + Vec2f((drawn.length - 1) * 40, -6);
			iconpos.x += Maths::Clamp(16 - item.inventoryFrameDimension.x, -item.inventoryFrameDimension.x, item.inventoryFrameDimension.x);
			iconpos.y += Maths::Max(16 - item.inventoryFrameDimension.y, 0);
			GUI::DrawIcon(item.inventoryIconName, item.inventoryIconFrame, item.inventoryFrameDimension, iconpos, 1.0f, item.getTeamNum());

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

void DrawCoinsOnHUD(CBlob@ this, const int coins, Vec2f tl, const int slot)
{
	if (coins > 0)
	{
		GUI::DrawIconByName("$COIN$", tl + Vec2f(0 + slot * 40, 0));
		GUI::SetFont("menu");
		GUI::DrawText("" + coins, tl + Vec2f(4 + slot * 40 , 24), color_white);
	}
}
