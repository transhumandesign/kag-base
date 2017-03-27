
namespace Hitters
{
	shared enum hits
	{
		nothing = 0,

		//env
		crush,
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
		suicide,

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
