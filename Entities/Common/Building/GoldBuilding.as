
#define SERVER_ONLY;

void onDie(CBlob@ this)
{
  CBlob@ blob = server_CreateBlobNoInit('mat_gold');

  if (blob !is null)
  {
    blob.Tag('custom quantity');
    blob.Init();

    blob.server_SetQuantity(50);
    blob.setPosition(this.getPosition());
  }
}
