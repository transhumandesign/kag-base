shared bool isDifferentTeam(CBlob@ blob, CBlob@ caller)
{
	return blob.getTeamNum() != caller.getTeamNum() && blob.getTeamNum() != 255;
}

shared bool isNeutralTeam(CBlob@ blob)
{
	return blob.getTeamNum() == 255;
}