
//drop a gold stack on death
void onDie(CBlob@ this)
{
	CBlob@ blob = server_CreateBlob("mat_gold", this.getTeamNum(), this.getPosition());
	if (blob !is null)
	{
		blob.server_SetQuantity(50);
	}
}