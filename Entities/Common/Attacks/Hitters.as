
namespace Hitters
{
	shared enum hits
	{
		nothing = 0,

		//env
		crush = 1, //(required to be 1 for engine reasons)
		fall,
		water,      //just fire
		water_stun, //splash
		water_stun_force, //splash
		drown,
		fire,   //initial burst (should ignite things)
		burn,   //burn damage
		flying,

		//common actor
		stomp,
		suicide = 11, //(required to be 11 for engine reasons)

		//natural
		bite,

		//builders
		builder,

		//knight
		sword,
		shield,
		bomb,

		//archer
		stab,

		//arrows and similar projectiles
		arrow,
		bomb_arrow,
		ballista,

		//cata
		cata_stones,
		cata_boulder,
		boulder,

		//siege
		ram,

		// explosion
		explosion,
		keg,
		mine,
		mine_special,

		//traps
		spikes,

		//machinery
		saw,
		drill,

		//barbarian
		muscles,

		// scrolls
		suddengib
	};
}

// not keg - not blockable :)
bool isExplosionHitter(u8 type)
{
	return type == Hitters::bomb || type == Hitters::explosion || type == Hitters::mine || type == Hitters::bomb_arrow;
}

bool isWaterHitter(u8 type)
{
	return type == Hitters::water || type == Hitters::water_stun_force || type == Hitters::water_stun;
}

bool isHeldByTeammate(CBlob@ held_blob, CBlob@ hitter_blob)
{
	if (held_blob !is null && hitter_blob !is null && held_blob.isAttached())
	{
		AttachmentPoint@[] aps;
		if (held_blob.getAttachmentPoints(@aps))
		{
			for (uint i = 0; i < aps.length; i++)
			{
				AttachmentPoint@ ap = aps[i];

				CBlob@ occ = ap.getOccupied();

				//if (occ !is null)	print(ap.name + " " + occ.getName());

				if (occ !is null && occ.getTeamNum() == hitter_blob.getTeamNum()) 
				{
					return true;
				}
			}
		}
	}

	return false;
}
