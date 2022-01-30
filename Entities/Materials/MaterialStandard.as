
#include 'MaterialCommon.as'

// Use `.Tag('custom quantity')` to
// prevent the quantity from being
// set when initialized

// Remember to set the tag before
// initializing. It's only supposed
// to be set on the server-side. An
// example can be found in Material-
// Common.as

void onInit(CBlob@ this)
{
  this.AddScript("OffscreenThrottle.as");

  if (getNet().isServer())
  {
    this.server_setTeamNum(-1);

    if (this.hasTag('custom quantity'))
    {
      // Remove unused tag
      this.Untag('custom quantity');
    }
    else
    {
      this.server_SetQuantity(this.maxQuantity);
    }
  }

  this.Tag('material');
  this.Tag("pushedByDoor");

  this.getShape().getVars().waterDragScale = 12.f;

  if (getNet().isClient())
  {
    // Force inventory icon update
    Material::updateFrame(this);
  }
}

void onQuantityChange(CBlob@ this, int old)
{
  if (getNet().isServer())
  {
    // Kill 0-materials
    if (this.getQuantity() == 0)
    {
      this.server_Die();
      return;
    }
  }

  if (getNet().isClient())
  {
    Material::updateFrame(this);
  }
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
  if (blob.hasTag('solid')) return true;

  if (blob.getShape().isStatic()) return true;

  return false;
}
