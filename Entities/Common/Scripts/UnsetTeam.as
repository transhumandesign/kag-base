
//unsets the team of this actor
// can be useful to prevent team damage for being an issue

void onInit(CBlob@ this)
{
	this.server_setTeamNum(-1);
	this.getCurrentScript().runFlags |= Script::remove_after_this;
}
