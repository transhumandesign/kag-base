// make a crate that when unpacked become blobName
// inventoryName for GUI

shared CBlob@ server_MakeCrate(string blobName, string inventoryName, int frameIndex, int team, Vec2f pos, bool init = true)
{
	CBlob@ crate = server_CreateBlobNoInit("crate");

	if (crate !is null)
	{
		crate.server_setTeamNum(team);
		crate.setPosition(pos);
		crate.set_string("packed", blobName);
		crate.set_string("packed name", inventoryName);
		crate.set_u8("frame", frameIndex);
		if (init)
			crate.Init();
	}

	return crate;
}

shared CBlob@ server_MakeCrateOnParachute(string blobName, string inventoryName, int frameIndex, int team, Vec2f pos)
{
	CBlob@ crate = server_MakeCrate(blobName, inventoryName, frameIndex, team, pos, false);

	if (crate !is null)
	{
		crate.Tag("parachute");
		//if (blobName == "catapult" || blobName == "ballista") {
		//  crate.Tag("unpack on land");
		//}
		crate.Init();
	}

	return crate;
}

shared Vec2f getDropPosition(Vec2f drop)
{
	drop.x += -16.0f + 32.0f * 0.01f * XORRandom(100);
	drop.y = 32.0f + 8.0f * 0.01f * XORRandom(100);; // sky
	return drop;
}

shared void PackIntoCrate(CBlob@ this, int frameIndex)
{
	server_MakeCrate(this.getName(), this.getInventoryName(), frameIndex, this.getTeamNum(), this.getPosition());
	this.server_Die();
}