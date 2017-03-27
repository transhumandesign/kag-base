namespace SpawnCmd
{
	enum Cmd
	{
		buildMenu = 1,
		changeClass = 2,
	}
}

void write_classchange(CBitStream@ params, u16 callerID, string config)
{
	params.write_u16(callerID);
	params.write_string(config);
}
