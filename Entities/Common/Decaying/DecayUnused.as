
#define SERVER_ONLY;

// Use `.set_u8("decay time", ..)` to
// define how long it takes for the
// material to disappear when unused

void onInit(CBlob@ this)
{
  this.server_SetTimeToDie(this.get_u16("decay time"));
}

void onDetach(CBlob@ this, CBlob@ blob, AttachmentPoint@ point)
{
  this.server_SetTimeToDie(this.get_u16("decay time"));
}

void onThisRemoveFromInventory(CBlob@ this, CBlob@ blob)
{
  this.server_SetTimeToDie(this.get_u16("decay time"));
}

void onAttach(CBlob@ this, CBlob@ blob, AttachmentPoint@ point)
{
  this.server_SetTimeToDie(-1);
}

void onThisAddToInventory(CBlob@ this, CBlob@ blob)
{
  this.server_SetTimeToDie(-1);
}
