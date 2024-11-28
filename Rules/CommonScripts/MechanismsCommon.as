// MechanismsCommon.as

//topology directions - bitflags
const u8 TOPO_NONE      = 0;        // 0, 00000000
const u8 TOPO_UP        = 1;        // 1, 00000001
const u8 TOPO_RIGHT     = 1<<1;     // 2, 00000010
const u8 TOPO_DOWN      = 1<<2;     // 4, 00000100
const u8 TOPO_LEFT      = 1<<3;     // 8, 00001000

//topology directions - bitflags, pre-mixed
const u8 TOPO_HORI      = TOPO_LEFT | TOPO_RIGHT;
const u8 TOPO_VERT      = TOPO_UP   | TOPO_DOWN;
const u8 TOPO_CARDINAL  = TOPO_HORI | TOPO_VERT;

//get a fully formed topology direction set
u8 getTopology(bool up, bool down, bool left, bool right)
{
	return (up    ? TOPO_UP    : 0) |
           (down  ? TOPO_DOWN  : 0) |
           (left  ? TOPO_LEFT  : 0) |
           (right ? TOPO_RIGHT : 0);
}

//get topology based on fixed rotations within scope
u8 rotateTopology(u16 angle, u8 topo)
{
	if(angle == 0)
	{
		return topo;
	}
	else if(angle % 90 != 0 || angle > 270)
	{
		error(" rotateTopology("+angle+", "+topo+"), out of scope");
		return TOPO_NONE;
	}

	topo <<= (angle / 90);
	const u8 a = topo & 0x0f;
	const u8 b = (topo >> 4) & 0x0f;

	return (a | b);
}

//per tile information - bitflags
const u8 INFO_NONE      = 0;        //  0, 00000000, no special functionality, eg: wire
const u8 INFO_SOURCE    = 1;        //  1, 00000001, is a power source, eg: lever
const u8 INFO_LOAD      = 1<<1;     //  2, 00000010, can Activate and Deactivate, eg: bolter
const u8 INFO_ACTIVE    = 1<<2;     //  4, 00000100, used in conjuction with INFO_SOURCE to set active power sources, eg: lever
const u8 INFO_SPECIAL   = 1<<3;     //  8, 00001000, special functionality, called polymorphically, eg: transistor
const u8 INFO_RESIST    = 1<<4;     // 16, 00010000, halves input power, eg: resistor

//chunk sizes
const int chunk_tiles   = 8;
const int chunk_size    = chunk_tiles * chunk_tiles;

//power, distance in tilespaces
const u8 power_source   = 10;

//signal, distance in tilespaces
const u8 signal_strength = 20;

//////////////////////////////////////
// Components, the blob to grid
// interface that decides
// functionality based on it's
// sub classes
//////////////////////////////////////

class Component
{
	int x, y;

	Component() {}

	Component(const Vec2f &in POSITION)
	{
		x = POSITION.x;
		y = POSITION.y;
	}

	// INFO_LOAD member functions
	void Activate(CBlob@ this) {}
	void Deactivate(CBlob@ this) {}

	u8 Special(MapPowerGrid@ _grid, u8 _old, u8 _new)
	{
		return decayedPower(_old);
	}

	u8 decayedPower(const u8 &in OLD)
	{
		return (OLD > 0? OLD - 1 : OLD);
	}
};

Component@ getComponentByNetworkID(u16 id)
{
	CBlob@ blob = getBlobByNetworkID(id);
	if(blob is null) return null;

	Component@ component = null;
	blob.get("component", @component);

	return component;
}

/////////////////////////////////////
// Packet methods for
// sending and receiving
// information from the
// components inside the
// power grid
/////////////////////////////////////

enum packetType
{
	PACKET_START = 0,
	PACKET_ACTIVATE,
	PACKET_DEACTIVATE,
	PACKET_CHANGEFRAME,
	PACKET_CHANGEANIMATION,

	PACKET_END = 255
};

void packet_AddActivate(CBitStream@ stream, u16 id)
{
	stream.write_u8(PACKET_ACTIVATE);
	stream.write_u16(id);
}

void packet_AddDeactivate(CBitStream@ stream, u16 id)
{
	stream.write_u8(PACKET_DEACTIVATE);
	stream.write_u16(id);
}

void packet_AddChangeFrame(CBitStream@ stream, u16 id, u8 frame)
{
	stream.write_u8(PACKET_CHANGEFRAME);
	stream.write_u16(id);
	stream.write_u8(frame);
}

void packet_AddChangeAnimation(CBitStream@ stream, u16 id, string animation)
{
	stream.write_u8(PACKET_CHANGEANIMATION);
	stream.write_u16(id);
	stream.write_string(animation);
}

void packet_SendStream(CRules@ this, CBitStream@ stream)
{
	if (isServer())
	{
		stream.write_u8(PACKET_END);

		// we don't want a server->server command but we need to run the code on server
		CBitStream stream_server = stream;
		stream_server.Reset();
		packet_RecvStream(this, stream_server);

		// send to client
		this.SendCommand(this.getCommandID("mechanisms_packet_client"), stream);
	}
}

void packet_RecvStream(CRules@ this, CBitStream@ stream)
{
	u8 type;
	if(!stream.saferead_u8(type) || type != PACKET_START) return;

	while(stream.saferead_u8(type))
	{
		switch(type)
		{
			case PACKET_END:
				return;

			case PACKET_ACTIVATE:
				packet_RecActivate(stream);
				break;

			case PACKET_DEACTIVATE:
				packet_RecDeactivate(stream);
				break;

			case PACKET_CHANGEFRAME:
				packet_RecChangeFrame(stream);
				break;

			case PACKET_CHANGEANIMATION:
				packet_RecChangeAnimation(stream);
				break;

			default:
				error("unexpected power packet "+type+", abort!");
				return;
		}
	}
}

void packet_RecActivate(CBitStream@ stream)
{
	u16 id;
	if(!stream.saferead_u16(id)) return;

	CBlob@ blob = getBlobByNetworkID(id);
	if(blob is null) return;

	Component@ component = null;
	if (!blob.get("component", @component)) return;

	component.Activate(blob);
}

void packet_RecDeactivate(CBitStream@ stream)
{
	u16 id;
	if(!stream.saferead_u16(id)) return;

	CBlob@ blob = getBlobByNetworkID(id);
	if(blob is null) return;

	Component@ component = null;
	if (!blob.get("component", @component)) return;

	component.Deactivate(blob);
}

void packet_RecChangeFrame(CBitStream@ stream)
{
	u16 id;
	u8 frame;
	if(!stream.saferead_u16(id)) return;
	if(!stream.saferead_u8(frame)) return;

	CBlob@ blob = getBlobByNetworkID(id);
	if(blob is null) return;

	blob.getSprite().SetFrameIndex(frame);
}

void packet_RecChangeAnimation(CBitStream@ stream)
{
	u16 id;
	string animation;
	if(!stream.saferead_u16(id)) return;
	if(!stream.saferead_string(animation)) return;

	CBlob@ blob = getBlobByNetworkID(id);
	if(blob is null) return;

	CSprite@ sprite = blob.getSprite();
	if(sprite is null) return;

	sprite.SetAnimation(animation);
	sprite.SetFrameIndex(0);
}

//////////////////////////////////////
// Power chunk('s),
// handles one section
// of the map's power grid
//////////////////////////////////////

class MapPowerChunk
{
	//position
	int x, y;

	//not using handles for simplicity
	array<u8> power_old;
	array<u8> power_new;
	array<u8> topo_in;              // input topology
	array<u8> topo_out;             // output topology
	array<u8> info;                 // information flags
	array<u16> id;                  // network id of a load

	bool interesting;

	MapPowerGrid@ _grid;            //needs to be set by parent

	MapPowerChunk()
	{
		//init lengths to correct sizes
		for (int i = 0; i < chunk_size; i++)
		{
			power_old.push_back(0);
			power_new.push_back(0);
			topo_in.push_back(0);
			topo_out.push_back(0);
			info.push_back(0);
			id.push_back(0);
		}
		//this set true when there's something possible to update
		interesting = false;
	}

	void update()
	{
		if(!interesting) return;

		for(int i = 0; i < chunk_size; i++)
		{
			int _x = x + i % 8;
			int _y = y + i / 8;

			//cache this tile's values
			u8 t_in = topo_in[i];
			u8 t_out = topo_out[i];
			u8 t_old = power_old[i];
			u8 t_new;
			u8 t_info = info[i];

			if((t_info & INFO_SOURCE) != 0 && (t_info & INFO_ACTIVE) != 0)
			{
				t_new = power_source;
			}
			else
			{
				t_new = _grid.getInputPowerAt(_x, _y, t_in, t_old);

				if((t_info & INFO_RESIST) != 0)
				{
					t_new /= 2;
				}
			}
			power_new[i] = t_new;

			if((t_info & INFO_LOAD) != 0 && t_old != t_new)
			{
				if(id[i] == 0) continue;

				CBlob@ blob = getBlobByNetworkID(id[i]);
				if(blob is null) continue;

				if(t_old == 0 && t_new > 0)
				{
					// if positive edge
					packet_AddActivate(_grid.packet, id[i]);
				}
				else if (t_new == 0 && t_old > 0)
				{
					// else if negative edge
					packet_AddDeactivate(_grid.packet, id[i]);
				}
			}
			else if ((t_info & INFO_SPECIAL) != 0)
			{
				if (id[i] == 0) continue;

				CBlob@ blob = getBlobByNetworkID(id[i]);
				if (blob is null) continue;

				Component@ component = null;
				if (!blob.get("component", @component)) continue;

				power_new[i] = component.Special(_grid, t_old, t_new);
			}
		}
	}

	//"flip" the double buffer
	void flip()
	{
		power_old = power_new;
	}

	//check if there's any interesting topology going on in this chunk
	void checkInteresting()
	{
		interesting = false;
		for (int i = 0; i < chunk_size; i++)
		{
			if ( topo_in[i] != 0 ||
				topo_out[i] != 0 ||
				info[i] != 0 )
			{
				interesting = true;
				return;
			}
		}
	}

	//set a chunk tile's topology and id
	//also update if this chunk is interesting (needs updating) or not
	void setChunkTile(int tile, u8 input_topology, u8 output_topology, u8 info_flags, u16 blob_id = 0)
	{
		topo_in[tile] = input_topology;
		topo_out[tile] = output_topology;
		info[tile] = info_flags;
		id[tile] = blob_id;
		checkInteresting();
	}

	void render()
	{
		Driver@ driver = getDriver();

		CMap@ map = getMap();

		Vec2f topleft(x * map.tilesize, y * map.tilesize);
		Vec2f bottomright((x+chunk_tiles) * map.tilesize, (y+chunk_tiles) * map.tilesize);

		Vec2f screentopleft = driver.getScreenPosFromWorldPos(topleft);
		Vec2f screenbottomright = driver.getScreenPosFromWorldPos(bottomright);

		Vec2f _screenbottom(driver.getScreenWidth(), driver.getScreenHeight());

		bool onscreen = false;
		Vec2f _temp;

		_temp = screentopleft - _screenbottom;
		if (screentopleft.x > 0 && screentopleft.y > 0 &&
			_temp.x < 0 && _temp.y < 0)
			onscreen = true;

		_temp = screenbottomright - _screenbottom;
		if (screenbottomright.x > 0 && screenbottomright.y > 0 &&
			_temp.x < 0 && _temp.y < 0)
			onscreen = true;

		if (!onscreen)
		{
			return;
		}

		SColor col = interesting ? SColor( 100, 0, 200, 0 ) : SColor( 100, 235, 0, 0 );
		GUI::DrawRectangle( screentopleft, screenbottomright , col );

		for (int i = 0; i < chunk_size; i++)
		{
			int _x = x + i % 8;
			int _y = y + i / 8;

			topleft = Vec2f(_x * map.tilesize, _y * map.tilesize);
			bottomright = Vec2f((_x+1) * map.tilesize, (_y+1) * map.tilesize);

			screentopleft = driver.getScreenPosFromWorldPos(topleft);
			screenbottomright = driver.getScreenPosFromWorldPos(bottomright);

			if(topo_out[i] != 0 || topo_in[i] != 0 || info[i] != 0)
			{
				int log_of_old = 10 + power_old[i] * (240/power_source);
				SColor col = SColor( 100, log_of_old, log_of_old, info[i] == 0 ? 50 : 200 );
				GUI::DrawRectangle( screentopleft, screenbottomright , col );
				GUI::SetFont("menu");
				GUI::DrawText(""+power_new[i], screentopleft, SColor(255, 255, 198, 75));
			}
		}
	}
};

//////////////////////////////////////
// The power grid
// maintains the entire map's
// power grid + provides
// the public interface to
// the grid
//////////////////////////////////////

class MapPowerGrid
{
	array<MapPowerChunk> chunks;
	int chunk_count;
	int chunk_width;
	int chunk_height;
	int chunk_iter;
	CBitStream packet;

	MapPowerGrid(CMap@ map)
	{
		chunk_width = (map.tilemapwidth + chunk_tiles - 1) / chunk_tiles;
		chunk_height = (map.tilemapheight + chunk_tiles - 1) / chunk_tiles;
		chunk_count = chunk_width * chunk_height;
		chunks.resize(chunk_count);

		//tie loose ends
		for(int i = 0; i < chunk_count; i++)
		{
			chunks[i].x = (i % chunk_width) * chunk_tiles;
			chunks[i].y = (i / chunk_width) * chunk_tiles;
			@chunks[i]._grid = this;
		}

		chunk_iter = 0;
	}

	bool _get_indices(int x, int y, int &out index, int &out chunk_index)
	{
		int chunk_x = x / chunk_tiles;
		int chunk_y = y / chunk_tiles;

		//outside? nothing to query
		if (chunk_x < 0 || chunk_y < 0 ||
			chunk_x >= chunk_width || chunk_y >= chunk_height)
		{
			return false;
		}

		//translate indices
		index = chunk_x + chunk_y * chunk_width;
		chunk_index = (x % chunk_tiles) + ((y % chunk_tiles)*chunk_tiles);
		return true;
	}

	//get a handful of useful stuff
	void query(int x, int y, u8 &out input, u8 &out output, u8 &out old)
	{
		//init
		input = output = old = 0;

		//translate indices
		int index, chunk_index;
		if (!_get_indices(x, y, index, chunk_index))
			return;

		//read tile values
		input = chunks[index].topo_in[chunk_index];
		output = chunks[index].topo_out[chunk_index];
		old = chunks[index].power_old[chunk_index];
	}

	int getPowerFrom(int x, int y, u8 t_in, u8 t_old, u8 input, u8 output)
	{
		if ((t_in & input) != 0)
		{
			u8 n_in, n_out, n_old;
			query(x, y, n_in, n_out, n_old);
			if ((n_out & output) != 0 && n_old > t_old)
			{
				return n_old - 1;
			}
		}
		return 0;
	}

	int getInputPowerAt(int x, int y, u8 t_in, u8 t_old)
	{
		int power = t_old;

		int up = getPowerFrom(x, y-1, t_in, t_old, TOPO_UP, TOPO_DOWN);

		int down = getPowerFrom(x, y+1, t_in, t_old, TOPO_DOWN, TOPO_UP);

		int left = getPowerFrom(x-1, y, t_in, t_old, TOPO_LEFT, TOPO_RIGHT);

		int right = getPowerFrom(x+1, y, t_in, t_old, TOPO_RIGHT, TOPO_LEFT);

		power = Maths::Max(power-1, Maths::Max(Maths::Max(up, down),Maths::Max(left, right)));
		power = Maths::Min(power_source, power);
		power = Maths::Max(0, power);

		return power;
	}

	//get single things
	u8 getInput(int x, int y)
	{
		//translate indices
		int index, chunk_index;
		if(!_get_indices(x, y, index, chunk_index)) return 0;

		return chunks[index].topo_in[chunk_index];
	}

	u8 getOutput(int x, int y)
	{
		//translate indices
		int index, chunk_index;
		if(!_get_indices(x, y, index, chunk_index)) return 0;

		return chunks[index].topo_out[chunk_index];
	}

	u8 getInfo(int x, int y)
	{
		//translate indices
		int index, chunk_index;
		if(!_get_indices(x, y, index, chunk_index)) return 0;

		return chunks[index].info[chunk_index];
	}

	u8 getPower(int x, int y)
	{
		//translate indices
		int index, chunk_index;
		if(!_get_indices(x, y, index, chunk_index)) return 0;

		return chunks[index].power_old[chunk_index];
	}

	u16 getID(int x, int y)
	{
		//translate indices
		int index, chunk_index;
		if(!_get_indices(x, y, index, chunk_index)) return 0;

		return chunks[index].id[chunk_index];
	}

	//get input | output
	u8 getIO(int x, int y)
	{
		//translate indices
		int index, chunk_index;
		if(!_get_indices(x, y, index, chunk_index)) return 0;

		return chunks[index].topo_in[chunk_index] | chunks[index].topo_out[chunk_index];
	}

	//set single things
	void setInput(int x, int y, u8 v)
	{
		//translate indices
		int index, chunk_index;
		if(!_get_indices(x, y, index, chunk_index)) return;

		MapPowerChunk@ chunk = chunks[index];
		chunk.topo_in[chunk_index] = v;
		chunk.checkInteresting();
	}

	void setOutput(int x, int y, u8 v)
	{
		//translate indices
		int index, chunk_index;
		if(!_get_indices(x, y, index, chunk_index)) return;

		MapPowerChunk@ chunk = chunks[index];
		chunk.topo_out[chunk_index] = v;
		chunk.checkInteresting();
	}

	void setInfo(int x, int y, u8 v)
	{
		//translate indices
		int index, chunk_index;
		if(!_get_indices(x, y, index, chunk_index)) return;

		MapPowerChunk@ chunk = chunks[index];
		chunk.info[chunk_index] = v;
		chunk.checkInteresting();
	}

	void setPower(int x, int y, u8 v)
	{
		//translate indices
		int index, chunk_index;
		if(!_get_indices(x, y, index, chunk_index)) return;

		MapPowerChunk@ chunk = chunks[index];
		chunk.power_old[chunk_index] = v;
		chunk.power_new[chunk_index] = v;
		chunk.checkInteresting();
	}

	void setID(int x, int y, u16 v)
	{
		//translate indices
		int index, chunk_index;
		if(!_get_indices(x, y, index, chunk_index)) return;

		MapPowerChunk@ chunk = chunks[index];
		chunk.id[chunk_index] = v;
		chunk.checkInteresting();
	}

	//set all things
	void setAll(int x, int y, u8 input, u8 output, u8 info, u8 power, u16 id)
	{
		//translate indices
		int index, chunk_index;
		if(!_get_indices(x, y, index, chunk_index)) return;

		MapPowerChunk@ chunk = chunks[index];
		chunk.topo_in[chunk_index] = input;
		chunk.topo_out[chunk_index] = output;
		chunk.info[chunk_index] = info;
		chunk.power_old[chunk_index] = power;
		chunk.power_new[chunk_index] = power;
		chunk.id[chunk_index] = id;
		chunk.checkInteresting();
	}

	//update some or all (or none) of the chunks in the grid
	void update(int count = -1)
	{
		if(count < 0)
		{
			count = chunk_count;
		}

		// initialize packet here
		packet.Clear();
		packet.write_u8(PACKET_START);

		while(count-- > 0)
		{
			chunk_iter++;
			if(chunk_iter == chunk_count)
			{
				chunk_iter = 0;
				for(int i = 0; i < chunk_count; i++)
				{
					chunks[i].flip();
				}
			}

			// packet is updated within update(), inside our polymorphic classes
			@chunks[chunk_iter]._grid = this;
			chunks[chunk_iter].update();
		}

		// if the packet is larger than PACKET_START, send stream
		if(packet.getBytesUsed() > 1)
		{
			packet_SendStream(getRules(), packet);
		}
	}

	void render()
	{
		for (int i = 0; i < chunk_count; i++)
		{
			chunks[i].render();
		}
	}
};
