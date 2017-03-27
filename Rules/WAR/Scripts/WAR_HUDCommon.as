//WAR HUD DATATYPES
//Serialised into a bitstream then read sequentially, nicer/faster than using strings too.

#include "HallCommon.as"

shared class WAR_HUD_TEAM
{
	u8 number;
	u8 halls;

	WAR_HUD_TEAM() { number = 255; halls = 0; }
	WAR_HUD_TEAM(CBitStream@ bt) { Unserialise(bt); }

	WAR_HUD_TEAM(WarTeamInfo@ info) //setup what we can from a war team info
	{
		number = info.index;
		halls = 0;
	}

	void Serialise(CBitStream@ bt)
	{
		bt.write_u8(number);
		bt.write_u8(halls);
	}

	void Unserialise(CBitStream@ bt)
	{
		number = bt.read_u8();
		halls = bt.read_u8();
	}
}

shared class WAR_HUD_HALL
{
	//attacked
	u16 blobID;
	bool under_raid;
	u8 team_num;
	u16 x;
	u16 tickets;
	u8[] factoryIcons;

	WAR_HUD_HALL() { under_raid = false; }
	WAR_HUD_HALL(CBitStream@ bt) { Unserialise(bt); }

	WAR_HUD_HALL(CBlob@ hall, WAR_HUD_TEAM[]& teams, const bool _under_raid)
	{
		blobID = hall.getNetworkID();
		under_raid = _under_raid;

		x = u16(hall.getPosition().x);
		team_num = hall.getTeamNum();
		tickets = hall.get_u16("tickets");

		for (uint i = 0; i < teams.length; ++i)
		{
			WAR_HUD_TEAM@ t = teams[i];
			if (t.number == team_num)
			{
				t.halls++;
				break;
			}
		}

		// add factories

		CBlob@[] factories;
		getFactories(hall, @factories);
		for (uint i = 0; i < factories.length; ++i)
		{
			CBlob@ factory = factories[i];
			if (factory.inventoryIconFrame > 0)
			{
				factoryIcons.push_back(factory.inventoryIconFrame);
			}
		}
	}

	void Serialise(CBitStream@ bt)
	{
		bt.write_u16(blobID);
		bt.write_u8(team_num);
		bt.write_u16(x);
		bt.write_u16(tickets);
		bt.write_bool(under_raid);
		bt.write_u8(factoryIcons.length);
		for (uint i = 0; i < factoryIcons.length; ++i)
		{
			bt.write_u8(factoryIcons[i]);
		}
	}

	void Unserialise(CBitStream@ bt)
	{
		blobID = bt.read_u16();
		team_num = bt.read_u8();
		x = bt.read_u16();
		tickets = bt.read_u16();
		under_raid = bt.read_bool();
		const u8 factoryIconsLength = bt.read_u8();
		for (uint i = 0; i < factoryIconsLength; ++i)
		{
			factoryIcons.push_back(bt.read_u8());
		}
	}

	CBlob@ getBlob() { return getBlobByNetworkID(blobID); }
}

shared class WAR_HUD
{
	//teams
	WAR_HUD_TEAM[] teams;

	//halls
	WAR_HUD_HALL[] halls;

	WAR_HUD() { }
	WAR_HUD(CBitStream@ bt) { Unserialise(bt); }

	/**
	 * generate everything we need from some war team structs
	 * and a group of hall blobs.
	 *
	 * make sure not to call this >1 time per hud object :)
	 */
	void Generate(WarTeamInfo@[] team_structs, CBlob@[] hall_blobs)
	{
		for (uint team_num = 0; team_num < team_structs.length; ++team_num)
		{
			WarTeamInfo@ team = team_structs[team_num];
			//we need to update this later with the number of halls :)
			teams.push_back(WAR_HUD_TEAM(team));
		}

		for (uint hall_num = 0; hall_num < hall_blobs.length; ++hall_num)
		{
			CBlob@ hall = hall_blobs[hall_num];
			//this will update the halls count automagically, hooray
			WAR_HUD_HALL h(hall, teams, isUnderRaid(hall));
			bool inserted = false;
			for (uint step = 0; step < halls.length; ++step)
			{
				if (halls[step].x > h.x)
				{
					halls.insert(step, h);
					inserted = true;
					break;
				}
			}
			if (!inserted)
				halls.push_back(h);
		}
	}

	//net stuff

	//TODO: saferead
	void Serialise(CBitStream@ bt)
	{
		u8 len;

		len = teams.length;
		bt.write_u8(len);
		for (uint i = 0; i < len; i++)
		{
			teams[i].Serialise(bt);
		}

		len = halls.length;
		bt.write_u8(len);
		for (uint i = 0; i < len; i++)
		{
			halls[i].Serialise(bt);
		}
	}

	//TODO: saferead
	void Unserialise(CBitStream@ bt)
	{
		u8 len;

		len = bt.read_u8();
		for (uint i = 0; i < len; i++)
		{
			teams.push_back(WAR_HUD_TEAM(bt));
		}

		len = bt.read_u8();
		for (uint i = 0; i < len; i++)
		{
			halls.push_back(WAR_HUD_HALL(bt));
		}
	}

};
