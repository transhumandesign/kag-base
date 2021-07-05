#define CLIENT_ONLY

CBlob@ toDrawInventory = null;

void onTick(CRules@ this) // pick which blob's inventory will be drawn_blobs only on game update
{
	CMap@ map = getMap();
	if (map is null) return;

	CPlayer@ player = getLocalPlayer();
	if (player is null) return;

	CControls@ controls = player.getControls();
	if (controls is null) return;

	Vec2f mouse_pos = controls.getMouseWorldPos();

	if (!player.isMod())
	{
		this.RemoveScript("AdminInventoryView.as");
		return;
	}

	if (player.getTeamNum() == this.getSpectatorTeamNum() && controls.isKeyPressed(KEY_LCONTROL))
	{
		CBlob@[] targets;
		f32 radius = 32.0f;

		if (map.getBlobsInRadius(mouse_pos, radius, @targets))
		{
			for (int i = 0; i < targets.length(); i++)
			{
				CBlob@ blob = targets[i];
				if (blob.getInventory() !is null)
				{
						@toDrawInventory = @blob;
						return;
				}
			}
		}	
	}

	@toDrawInventory = @null; // if we didn't get any blob, don't draw anything
}

void onRender(CRules@ this)
{
	if (toDrawInventory is null)
	{
		return;
	}
	else
	{
		DrawInventoryOfBlob(toDrawInventory);
	}
}

void DrawInventoryOfBlob(CBlob@ this)
{
	CInventory@ inv = this.getInventory();
	string[] drawn_blobs; // list of inventory blobs that we have already drawn
	Vec2f tl = this.getInterpolatedScreenPos();
	Vec2f offset (-40, -120);
	u8 j = 0;
	u8 columns = Maths::Ceil(Maths::Sqrt(inv.getItemsCount()));

	for (int i = 0; i < inv.getItemsCount(); i++)
	{
		CBlob@ item = inv.getItem(i);
		const string name = item.getName();
		
		if (drawn_blobs.find(name) == -1)
		{
			drawn_blobs.push_back(name);

			if (j % columns == 0 && j > 0)
			{
				offset.x = -40;
				offset.y += 60;
			}
			else if (j > 0) offset.x += 40;

			j++;
			Vec2f tempoffset(0,0);
			if (item.hasTag("material")) tempoffset.x = 5;

			const int quantity = this.getBlobCount(name);
			string disp = "" + quantity;

			GUI::DrawIcon(item.inventoryIconName, item.inventoryIconFrame, item.inventoryFrameDimension, tl + offset + tempoffset, 1.0f);
			GUI::SetFont("menu");
			GUI::DrawText(disp, tl + Vec2f(offset.x + 10, offset.y + 30), SColor(255, 255, 255, 255));
		}
	}
}