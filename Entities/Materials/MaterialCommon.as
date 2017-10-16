
// Use `.set('harvest', ..)` to
// define the materials an entity
// should yield when harvested

// It's only supposed to be set on
// the server-side. An example can
// be found in Log.as

#include "CustomBlocks.as";

namespace Material
{
  const float MERGE_RADIUS = 20.0f;

  // Client-side: Update material frame
  void updateFrame(CBlob@ this)
  {
    CSprite@ sprite = this.getSprite();
    Animation@ animation = sprite.getAnimation('default');

    if (animation is null) return;

    uint8 frames = animation.getFramesCount();
    uint16 quantity = this.getQuantity();
    uint8 index = frames * (quantity - 1) / this.maxQuantity;

    // Animation frame update
    animation.SetFrameIndex(index);

    SpriteConsts@ consts = sprite.getConsts();

    uint8 frame = animation.getFrame(index);
    Vec2f size(consts.frameWidth, consts.frameHeight);

    // Inventory icon frame update
    this.SetInventoryIcon(consts.filename, frame, size);
  }

  // Server-side: Hard merge
  void merge(CBlob@ this, CBlob@ blob)
  {
    uint16 sum = this.getQuantity();
    uint16 quantity = blob.getQuantity();

    if (sum < quantity)
    {
      // Merge into `blob`
      merge(blob, this);
      return;
    }

    sum += quantity;

    if (sum <= this.maxQuantity)
    {
      this.server_SetQuantity(sum);
      blob.server_Die();
    }
    else
    {
      // Max one out
      this.server_SetQuantity(this.maxQuantity);
      blob.server_SetQuantity(sum - this.maxQuantity);
    }
  }

  // Server-side: Attempt a merge
  bool attemptMerge(CBlob@ this, CBlob@ blob)
  {
    if (this.getName() != blob.getName()) return false;

    if (this is blob) return false;

    // Materials in-use are supposed
    // to have a fixed quantity
    if (not blob.isOnGround()) return false;

    // Same as above
    if (blob.isAttached()) return false;

    // Inventory merges are supposedly
    // handled engine-side already
    if (blob.isInInventory()) return false;

    // Full already?
    if (blob.getQuantity() >= blob.maxQuantity) return false;

    merge(blob, this);

    // Success
    return true;
  }

  // Server-side: Create a material for `this`
  void createFor(CBlob@ this, string &in name, uint16 &in quantity)
  {
    if (quantity == 0) return;

    CInventory@ inventory = this.getInventory();

    // Filling matching materials
    // inside the inventory first
    if (inventory !is null)
    {
      uint8 count = inventory.getItemsCount();

      for (uint8 i = 0; i < count; ++ i)
      {
        CBlob@ item = inventory.getItem(i);

        // Same material?
        if (name != item.getName()) continue;

        if (this is item) continue;

        uint16 current = item.getQuantity();
        uint16 space = item.maxQuantity - current;
        uint16 insert = Maths::Min(space, quantity);

        item.server_SetQuantity(current + insert);

        quantity -= insert;

        // Return if there's nothing left
        if (quantity == 0) return;
      }
    }

    Vec2f position = this.getPosition();

    while (quantity > 0)
    {
      // Uninitialized material blob
      CBlob@ item = server_CreateBlobNoInit(name);

      if (item is null) return;

      item.Tag('custom quantity');
      item.Init();

      uint16 portion = Maths::Min(quantity, item.maxQuantity);

      item.server_SetQuantity(portion);

      quantity -= portion;

      if (this.server_PutInInventory(item)) continue;

      // Wasn't possible to insert into
      // inventory. Attempt merge with
      // surrounding materials
      item.setPosition(position);

      // Full already?
      if (portion >= item.maxQuantity) continue;

      // Run once at most
      array<CBlob@> surrounding;
      CMap@ map = this.getMap();

      if (not map.getBlobsInRadius(position,
        MERGE_RADIUS, @surrounding)) return;

      // For all surrounding blobs
      for (uint16 i = 0; i < surrounding.length; ++ i)
      {
        CBlob@ blob = surrounding[i];

        // Attempt merge. Break if success
        if (attemptMerge(item, blob)) break;
      }
    }
  }

  // Server-side: Get material from a blob
  void fromBlob(CBlob@ this, CBlob@ blob, float &in damage)
  {
    if (damage <= 0.0f) return;

    // Return unless it's a harvest blob
    if (not blob.exists('harvest')) return;

    dictionary harvest;
    blob.get('harvest', harvest);

    string[]@ names = harvest.getKeys();

    // Create all harvested materials
    for (uint8 i = 0; i < names.length; ++ i)
    {
      string name = names[i];

      uint16 quantity;
      harvest.get(name, quantity);

      createFor(this, name, quantity * damage);
    }
  }

  // Server-side: Create material from a tile
  void fromTile(CBlob@ this, uint16 &in type, float &in damage)
  {
    if (damage <= 0.0f) return;

    CMap@ map = getMap();

    if (not map.isTileSolid(type)) return;

    if (map.isTileThickStone(type))
    {
      createFor(this, 'mat_stone', 6 * damage);
    }
    else if (map.isTileStone(type))
    {
      createFor(this, 'mat_stone', 4 * damage);
    }
    else if (map.isTileCastle(type))
    {
      createFor(this, 'mat_stone', damage);
    }
    else if (map.isTileWood(type))
    {
      createFor(this, 'mat_wood', damage);
    }
    else if (map.isTileGold(type))
    {
      createFor(this, 'mat_gold', 4 * damage);
    }
    else
    {
      MaterialFromCustomTile(this, type, damage);
    }
  }
}
