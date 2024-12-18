// Storage.as

#include "GenericButtonCommon.as"

void onInit(CSprite@ this)
{
	// Building
	this.SetZ(-60); //-60 instead of -50 so sprite layers are behind ladders

	// Stone
	CSpriteLayer@ stone = this.addSpriteLayer("mat_stone", "StorageLayers.png", 24, 16);
	if (stone !is null)
	{
		{
			stone.addAnimation("default", 0, false);
			int[] frames = { 0, 5, 10 };
			stone.animation.AddFrames(frames);
		}
		stone.SetOffset(Vec2f(10.0f, -3.0f));
		stone.SetRelativeZ(1);
		stone.SetVisible(false);
	}

	// Wood
	CSpriteLayer@ wood = this.addSpriteLayer("mat_wood", "StorageLayers.png", 24, 16);
	if (wood !is null)
	{
		{
			wood.addAnimation("default", 0, false);
			int[] frames = { 1, 6, 11 };
			wood.animation.AddFrames(frames);
		}
		wood.SetOffset(Vec2f(-7.0f, -2.0f));
		wood.SetRelativeZ(1);
		wood.SetVisible(false);
	}

	// Gold
	CSpriteLayer@ gold = this.addSpriteLayer("mat_gold", "StorageLayers.png", 24, 16);
	if (gold !is null)
	{
		{
			gold.addAnimation("default", 0, false);
			int[] frames = { 2, 7, 12 };
			gold.animation.AddFrames(frames);
		}
		gold.SetOffset(Vec2f(-7.0f, -10.0f));
		gold.SetRelativeZ(1);
		gold.SetVisible(false);
	}

	// Bombs
	CSpriteLayer@ bombs = this.addSpriteLayer("mat_bombs", "StorageLayers.png", 24, 16);
	if (bombs !is null)
	{
		{
			bombs.addAnimation("default", 0, false);
			int[] frames = { 3, 8 };
			bombs.animation.AddFrames(frames);
		}
		bombs.SetOffset(Vec2f(-7.0f, 5.0f));
		bombs.SetRelativeZ(2);
		bombs.SetVisible(false);
	}

	// Rope
	CSpriteLayer@ rope = this.addSpriteLayer("rope", "StorageLayers.png", 24, 16);
	if (rope !is null)
	{
		{
			rope.addAnimation("default", 0, false);
			int[] frames = { 4 };
			rope.animation.AddFrames(frames);
		}
		rope.SetOffset(Vec2f(5.0f, -8.0f));
		rope.SetRelativeZ(2);
	}
	
	// Lantern
	CSpriteLayer@ lantern = this.addSpriteLayer("lantern", "Lantern.png", 8, 8);
	if (lantern !is null)
	{
		{
			lantern.addAnimation("default", 3, true);
			int[] frames = { 0, 1, 2 };
			lantern.animation.AddFrames(frames);
		}
		lantern.SetOffset(Vec2f(7.0f, -4.0f));
		lantern.SetRelativeZ(3);
		lantern.SetVisible(false);
	}
}

void onInit(CBlob@ this)
{
	this.set_TileType("background tile", CMap::tile_castle_back);
	this.getShape().getConsts().mapCollisions = false;
	AddIconToken("$store_inventory$", "InteractionIcons.png", Vec2f(32, 32), 28);
	this.inventoryButtonPos = Vec2f(12, 0);
	this.addCommandID("store inventory");
	this.getCurrentScript().tickFrequency = 60;
}

void onTick(CBlob@ this)
{
	PickupOverlap(this);
}

void PickupOverlap(CBlob@ this)
{
	if (!isServer()) return;

	Vec2f tl, br;
	this.getShape().getBoundingRect(tl, br);
	CBlob@[] blobs;
	getMap().getBlobsInBox(tl, br, @blobs);
	for (uint i = 0; i < blobs.length; i++)
	{
		CBlob@ blob = blobs[i];
		if (!blob.isAttached() && blob.isOnGround() && blob.hasTag("material") && blob.getName() != "mat_arrows")
		{
			this.server_PutInInventory(blob);
		}
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!canSeeButtons(this, caller)) return;

	if (caller.getTeamNum() == this.getTeamNum() && caller.isOverlapping(this))
	{
		CInventory@ inv = caller.getInventory();
		if (inv is null) return;

		if (inv.getItemsCount() > 0)
		{
			caller.CreateGenericButton("$store_inventory$", Vec2f(-6, 0), this, this.getCommandID("store inventory"), getTranslatedString("Store"));
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (!isServer()) return;
	
	if (cmd == this.getCommandID("store inventory") && isServer())
	{
		CPlayer@ p = getNet().getActiveCommandPlayer();
		if (p is null) return;
					
		CBlob@ caller = p.getBlob();
		if (caller is null) return;

		// overlap check
		if (!caller.isOverlapping(this)) return;

		// team check
		if (caller.getTeamNum() != this.getTeamNum()) return;

		CBlob@ carried = caller.getCarriedBlob();
		if (carried !is null && carried.hasTag("temp blob"))
		{
			carried.server_Die();
		}

		CInventory@ inv = caller.getInventory();
		if (inv is null) return;

		while (inv.getItemsCount() > 0)
		{
			CBlob@ item = inv.getItem(0);
			caller.server_PutOutInventory(item);
			this.server_PutInInventory(item);
		}
	}
}

void onAddToInventory(CBlob@ this, CBlob@ blob)
{
	updateLayers(this, blob);
}

void onRemoveFromInventory(CBlob@ this, CBlob@ blob)
{
	updateLayers(this, blob);
}

void updateLayers(CBlob@ this, CBlob@ blob)
{
	if (!isClient()) return;

	const string blobName = blob.getName();
	CSprite@ sprite = this.getSprite();
	CInventory@ inv = this.getInventory();
	const int blobCount = inv.getCount(blobName);
	bool visible = false;
	if (blobName == "mat_stone")
	{
		CSpriteLayer@ stone = sprite.getSpriteLayer("mat_stone");
		if (blobCount > 0)
		{
			const u8 frame = blobCount >= 200 ? 2 :
							 blobCount >= 100 ? 1 : 0;
			stone.SetFrameIndex(frame);
			visible = true;
		}

		stone.SetVisible(visible);
	}
	else if (blobName == "mat_wood")
	{
		CSpriteLayer@ wood = sprite.getSpriteLayer("mat_wood");
		if (blobCount > 0)
		{
			const u8 frame = blobCount >= 200 ? 2 :
							 blobCount >= 100 ? 1 : 0;
			wood.SetFrameIndex(frame);
			visible = true;
		}

		wood.SetVisible(visible);
	}
	else if (blobName == "mat_gold")
	{
		CSpriteLayer@ gold = sprite.getSpriteLayer("mat_gold");
		if (blobCount > 0)
		{
			const u8 frame = blobCount >= 200 ? 2 :
							 blobCount >= 100 ? 1 : 0;
			gold.SetFrameIndex(frame);
			visible = true;
		}

		gold.SetVisible(visible);
	}
	else if (blobName == "mat_bombs")
	{
		CSpriteLayer@ bombs = sprite.getSpriteLayer("mat_bombs");
		if (blobCount > 0)
		{
			const u8 frame = blobCount >= 2 ? 1 : 0;
			bombs.SetFrameIndex(frame);
			visible = true;
		}

		bombs.SetVisible(visible);
	}
	else if (blobName == "lantern")
	{
		CSpriteLayer@ lantern = sprite.getSpriteLayer("lantern");
		if (blobCount > 0)
		{
			for (int i = 0; i < inv.getItemsCount(); i++)
			{
				CBlob@ item = inv.getItem(i);
				if (item.getName() == "lantern" && item.get_bool("lantern lit"))
				{
					visible = true;
					break;
				}
			}
		}

		lantern.SetVisible(visible);
	}
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return (forBlob.getTeamNum() == this.getTeamNum() && forBlob.isOverlapping(this) && canSeeButtons(this, forBlob));
}
