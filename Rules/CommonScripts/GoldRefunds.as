#define SERVER_ONLY

const string gold_drop_amount = "gold building amount";

void onBlobDie(CRules@ this, CBlob@ blob)
{
	if (!blob.exists(gold_drop_amount)) return;

	int drop_amount = blob.get_s32(gold_drop_amount);

	if (drop_amount == 0) return;

	CBlob@ gold = server_CreateBlobNoInit('mat_gold');

	if (gold !is null)
	{
		gold.Tag('custom quantity');
		gold.Init();

		gold.server_SetQuantity(drop_amount);
		gold.setPosition(blob.getPosition());
	}
}
