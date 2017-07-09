
#define SERVER_ONLY;

#include 'MaterialCommon.as';

void onInit(CBlob@ this)
{
  ScriptData@ script = this.getCurrentScript();
  script.runFlags |= Script::tick_not_moving;
  script.runFlags |= Script::tick_not_attached;
  script.runFlags |= Script::tick_not_ininventory;
  script.tickFrequency = 61;
}

void onTick(CBlob@ this)
{
  // Full already?
  if (this.getQuantity() >= this.maxQuantity) return;

  array<CBlob@> surrounding;
  CMap@ map = this.getMap();
  Vec2f position = this.getPosition();

  if (not map.getBlobsInRadius(position,
    Material::MERGE_RADIUS, @surrounding)) return;

  // For all surrounding blobs
  for (uint16 i = 0; i < surrounding.length; ++ i)
  {
    CBlob@ blob = surrounding[i];

    // Attempt merge. Break if success
    if (Material::attemptMerge(this, blob)) break;
  }
}
