// Interface for sending Game Events through Rules to be picked
// up by other code, for eg tracking stats or giving coins for
// obscure things.

// don't forget to catch events with cmd == getGameplayEventID(this)!

enum GameplayEvent_IDs
{

	//0 is error

	GE_built_block = 1,
	GE_built_blob,

	GE_hit_vehicle,
	GE_kill_vehicle,

	GE_captured_flag,

	GE_end

};

const string game_event_id = "GameplayEvent";

// note, you can make your own events by starting from GE_end + 1
// if you only have one extension, or otherwise by deciding on your
// own event space - you have 16 bits of space there to avoid conflicts :)

shared class GameplayEvent
{

	u16 _type;
	u16 _id;
	CBitStream params;

	GameplayEvent()
	{
		_type = _id = 0;
	}

	GameplayEvent(u16 type, CPlayer@ player)
	{
		_type = type;

		if (player !is null)
		{
			_id = player.getNetworkID();
		}
		else
		{
			_id = 0xffff;
		}
	}

	GameplayEvent(CBitStream@ stream)
	{
		if (!Unserialise(stream) && sv_test)
		{
			error("failure to unserialise GameplayEvent");
		}
	}

	void Serialise(CBitStream@ stream)
	{
		stream.write_u16(_type);
		stream.write_u16(_id);
		stream.write_CBitStream(params);
	}

	bool Unserialise(CBitStream@ stream)
	{
		if (!stream.saferead_u16(_type))
		{
			warn("Error unserializing	GameplayEvent::_type");
			return false;
		}
		if (!stream.saferead_u16(_id))
		{
			warn("Error unserializing	GameplayEvent::_id");
			return false;
		}
		if (!stream.saferead_CBitStream(params))
		{
			warn("Error unserializing	GameplayEvent::params");
			return false;
		}

		//reset it here so we're good to go
		params.ResetBitIndex();

		return true;
	}

	u16 getType()
	{
		return _type;
	}

	CPlayer@ getPlayer()
	{
		if (_id == 0xffff)
			return null;

		return getPlayerByNetworkId(_id);
	}

};

// set up for game events, probably do this
// in your specific gamemode event handler

void SetupGameplayEvents(CRules@ this)
{
	this.addCommandID(game_event_id);
}

// get the ID

u8 getGameplayEventID(CRules@ this)
{
	return this.getCommandID(game_event_id);
}

// sending the game event!
// handles client/server specificity

void SendGameplayEvent(GameplayEvent@ event, bool fromServer = true)
{
	if (fromServer ? getNet().isServer() : getNet().isClient())
	{
		CBitStream stream;
		event.Serialise(stream);
		getRules().SendCommand(getGameplayEventID(getRules()), stream);
	}
}

// interface for various "native" events
// suggested to avoid mis-construction in case an interface changes
//     remember, callbacks can be awful to debug :D

//create a block event
GameplayEvent@ createBuiltBlockEvent(CPlayer@ by, u16 tile)
{
	GameplayEvent g(GE_built_block, by);
	g.params.write_u16(tile);
	return g;
}

//create a blob event
GameplayEvent@ createBuiltBlobEvent(CPlayer@ by, string name)
{
	GameplayEvent g(GE_built_blob, by);
	g.params.write_string(name);
	return g;
}

//create a vehicle damage event
GameplayEvent@ createVehicleDamageEvent(CPlayer@ by, f32 damage)
{
	GameplayEvent g(GE_hit_vehicle, by);
	g.params.write_f32(damage);
	return g;
}

//create a vehicle destroy event
GameplayEvent@ createVehicleDestroyEvent(CPlayer@ by)
{
	return GameplayEvent(GE_kill_vehicle, by);
}

//create a flag capture event
GameplayEvent@ createFlagCaptureEvent(CPlayer@ by)
{
	return GameplayEvent(GE_captured_flag, by);
}

// end GameplayEvents.as
