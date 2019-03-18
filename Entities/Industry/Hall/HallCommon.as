
/*
 * HallCommon.as
 *
 * Set of common functionality for working with halls,
 * and particularly their delicious workers.
 */

#include "MigrantCommon.as"

//------------------------------------------------------//

const string hall_name = "hall";

const f32 BASE_RADIUS = 400.0f;
const f32 RAID_RADIUS = BASE_RADIUS * 0.25f;

const string workers_property = "hall workers";

const string worker_in_cmd = "in worker";
const string worker_out_cmd = "out worker";

const string worker_tag = "has worker";

namespace HallState
{
	enum state
	{
		normal = 0,
		raid,
		underwater,
		depleted,
		count
	};
};

//------------------------------------------------------//

/**
 * Set the worker we're using - wont work for multi-worker situations
 */
shared void setWorker(CBlob@ this, CBlob@ worker)
{
	if (worker is null)
	{
		this.set_u16("worker id", 0);
	}
	else
	{
		this.set_u16("worker id", worker.getNetworkID());
		worker.set_u16("owner id", this.getNetworkID());
	}
}

/**
 * get the ID of the worker we're using
 */
shared u16 getWorkerID(CBlob@ this)
{
	return this.get_u16("worker id");
}
/**
 * get the worker we're using
 */
shared CBlob@ getWorker(CBlob@ this)
{
	return getBlobByNetworkID(getWorkerID(this));
}

/**
 * get the ID of this workers owner
 */
shared u16 getOwnerID(CBlob@ worker)
{
	return worker.get_u16("owner id");
}
/**
 * get the owner of this worker
 */
shared CBlob@ getOwner(CBlob@ worker)
{
	return getBlobByNetworkID(getOwnerID(worker));
}


shared bool isUnderRaid(CBlob@ blob)
{
	if (blob.exists("hall state"))
		return (blob.get_u8("hall state") == HallState::raid) && blob.getTeamNum() <= 10;

	return blob.hasTag("under raid");
}

shared bool isHallDepleted(CBlob@ blob)
{
	return (blob.get_u8("hall state") == HallState::depleted);
}


/**
 * Update the workers of a given hall
 */

//------------------------------------------------------//

void updateWorkers(CBlob@ hall, bool raid = false)
{
	HallWorkerSet@ workers;
	if (!hall.get(workers_property, @workers) || workers is null) return;

	workers.under_raid = raid;
	workers.Update();
}

//------------------------------------------------------//

/**
 * Get all applicable halls for a given blob
 *
 * Useful for getting halls to request workers from,
 * or searching for a nearby spawn.
 */
CBlob@[] getHallsFor(CBlob@ this, f32 radius)
{
	int team = this.getTeamNum();
	Vec2f pos = this.getPosition();
	f32 radsquared = radius * radius;

	CBlob@[] ret;

	// we dont use radius here because there's likely to be less halls
	// than blobs per radius, and if there aren't then it wont't matter
	// cause it'll be some tiny number
	CBlob@[] blobs;
	if (getBlobsByName(hall_name, @blobs))
	{
		for (uint i = 0; i < blobs.length; ++i)
		{
			CBlob@ b = blobs[i];
			if (b.getTeamNum() == team && 		//same team
			        !isUnderRaid(b) &&			//not under raid and close enough
			        (b.getPosition() - pos).LengthSquared() < radsquared)
			{
				ret.push_back(b);
			}
		}
	}

	return ret;
}

/**
 * Request a worker from a single hall
 *
 * If you get a blob back, be sure to actually use it.
 * 		the hall will track the caller blob so it can reclaim
 * 		on death, or with returnWorker.
 * If you get a null back, the hall can't spare any workers.
 */
CBlob@ requestWorker(CBlob@ this, CBlob@ hall)
{
	HallWorkerSet@ workers;
	if (!hall.get(workers_property, @workers) || workers is null) return null;

	return workers.getAvailableWorker(this);
}

/**
 * Request a worker from an array of halls
 *
 * Same implications
 */
CBlob@ requestWorker(CBlob@ this, CBlob@[] halls)
{
	CBlob@ b = null;
	for (uint i = 0; i < halls.length; ++i)
	{
		@b = requestWorker(this, halls[i]);
		if (b !is null)
			break;
	}
	return b;
}

/**
 * Return a worker after you're done with it
 *
 * Will return true if you're returning the worker
 * 		to the correct hall
 * False otherwise.
 */
bool returnWorker(CBlob@ this, CBlob@ hall, CBlob@ worker)
{
	HallWorkerSet@ workers;
	if (!hall.get(workers_property, @workers) || workers is null) return false;

	if (!workers.returnWorker(worker)) return false;

	detachWorker(this, worker);
	setWorker(this, null);
	return true;

}

/**
 * Return a worker to an array of halls
 *
 * Same implications
 */
bool returnWorker(CBlob@ this, CBlob@[] halls, CBlob@ worker)
{
	for (uint i = 0; i < halls.length; ++i)
	{
		if (returnWorker(this, halls[i], worker)) return true;
	}
	return false;
}

/**
 * Attach a worker to this blob using a predefined attachment
 * "protocol" so no setup in config is required
 */
shared bool attachWorker(CBlob@ this, CBlob@ worker, f32 height = 0.0f, bool isOwner = false)
{
	f32 rand = XORRandom(1023) / 1023.0f;
	f32 w = height;
	Vec2f offset(w * -0.5f + w * rand, (height * 0.5f) - worker.getRadius());

	//no point setting for the owner
	// it'll have >1 worker to look after and its
	// own worker set anyway.
	worker.setPosition(this.getPosition() + offset);

	setWorker(this, worker);
	FreezeWorker(worker);
	if (!isOwner)
	{
		worker.getSprite().PlaySound("/" + getTranslatedString("MigrantSayHello"));
	}

	return true;
}

/**
 * Detach a previously attached worker from this blob
 * Automatically called when returning it
 */
shared void detachWorker(CBlob@ this, CBlob@ worker)
{
	ResetWorker(worker);
	setWorker(this, null);
}

/**
 * Anything that needs to be done
 * for workers to be reusable
 */
shared void FreezeWorker(CBlob@ worker)
{
	//static added in FakeAttach.as
	worker.set_Vec2f("attach", worker.getPosition());

	CMovement@ movement = worker.getMovement();
	movement.doTickScripts = false;

	CSprite@ sprite = worker.getSprite();
	sprite.SetZ(-40); //background

	worker.Tag("idle");
}

/**
 * Anything that needs to be done
 * for workers to be reusable
 */
shared void ResetWorker(CBlob@ worker)
{
	CShape@ shape = worker.getShape();
	shape.SetStatic(false);
	CMovement@ movement = worker.getMovement();
	movement.doTickScripts = true;

	CSprite@ sprite = worker.getSprite();
	sprite.SetZ(0); //normal

	worker.Untag("idle");
}

//------------------------------------------------------//

/**
 * An abstract representation of a worker
 * from a hall.
 *
 * You shouldn't need to modify this yourself at all.
 */

shared class HallWorker
{
	u16 blobID;
	u16 ownerID;
	u16 userID;

	u32 timer;

	/** so it's array compatible */
	HallWorker() { Setup(); }

	/**
	 * Construct a hall worker from a blob ID
	 * and an owner ID.
	 */
	HallWorker(u16 bid, u16 oid)
	{
		Setup(bid, oid, oid);
	}

	/**
	 * Construct a hall worker from an owner
	 * Automatically constructs the worker blob.
	 */
	HallWorker(CBlob@ owner)
	{
		Setup(0, owner.getNetworkID(), owner.getNetworkID());
	}

	void Setup(u16 bid = 0, u16 oid = 0, u16 uid = 0)
	{
		blobID = bid;
		ownerID = oid;
		userID = uid;

		timer = 0;
	}

	/** is this worker available for work?*/
	bool isAvailable()
	{
		if (userID != ownerID) return false;

		return !isBusy();
	}

	/** is this worker currently busy with something else? (fleeing?) */
	bool isBusy()
	{
		return (timer + 90 > getGameTime());
	}

	/** does this worker match this blob?*/
	bool isBlob(u16 id) { return blobID == id; }

	CBlob@ getBlob() { return getBlobByNetworkID(blobID); }
	CBlob@ getOwner() { return getBlobByNetworkID(ownerID); }
	CBlob@ getUser() { return getBlobByNetworkID(userID); }

	/**
	 * Set the user of this Hall worker
	 *
	 * returns false if it's being used incorrectly - you should
	 * return workers to the hall before giving them to anyone else.
	 */
	bool setUser(CBlob@ b)
	{
		bool correctUse = false;

		u16 id = b.getNetworkID();
		if ((isAvailable() && id == ownerID) ||
		        (!isAvailable() && id != ownerID))
		{
			correctUse = false;
		}

		userID = id;

		setWorker(b, getBlob());

		return correctUse;
	}

	/**
	 * Set the blob of this Hall worker
	 *
	 * kills the old blob if it exists
	 */

	void setBlob(CBlob@ b)
	{
		CBlob@ old = getBlobByNetworkID(blobID);
		if (old !is null)
			old.server_Die();

		if (b is null)
			blobID = 0;
		else
			blobID = b.getNetworkID();

		timer = getGameTime();
	}

	/**
	 * regenerate this worker if it's been killed somehow
	 */
	void RegenBlob()
	{
		CBlob@ owner = getOwner();
		if (owner !is null)
			setBlob(CreateMigant(owner.getPosition(), owner.getTeamNum()));
	}

	void Update()
	{
		CBlob@ b = getBlob();
		if (b !is null)
		{
			u8 strat = b.get_u8("strategy");
			if (strat != Strategy::idle && strat != Strategy::find_teammate)
			{
				timer = getGameTime();
			}

			if (b.hasTag("dead"))
				blobID = 0;
		}
	}

};

/**
 * A collection of abstract workers and associated
 * information from a hall.
 *
 * You shouldn't need to modify this yourself at all,
 * just update it every now and again.
 */

shared class HallWorkerSet
{
	HallWorker[] workers;
	u16 ownerID;
	u32 lastRespawnTime;

	u32 gametime; //scratch

	u8 count;
	bool under_raid;

	/** so it's array compatible, if thats ever needed.. */
	HallWorkerSet() { lastRespawnTime = 0; under_raid = false; }

	/**
	 * Construct a hall worker set from an owner
	 * Automatically constructs the workers from the
	 * migrants properties vars.
	 */
	HallWorkerSet(CBlob@ owner)
	{
		ownerID = owner.getNetworkID();
		count = owner.get_u8("migrants max");
		for (uint i = 0; i < count; ++i)
		{
			AddWorker(owner);
		}

		lastRespawnTime = 0;
		under_raid = false;
	}

	/** get the owner blob*/
	CBlob@ getOwner() { return getBlobByNetworkID(ownerID); }

	/**
	 * Get the first available worker from this worker set,
	 * and mark that worker as consumed.
	 */
	CBlob@ getAvailableWorker(CBlob@ user)
	{
		if (under_raid) return null;

		for (uint i = 0 ; i < workers.length; ++i)
		{
			HallWorker@ worker = workers[i];
			if (worker.isAvailable())
			{
				CBlob@ w = worker.getBlob();
				if (w !is null)
				{
					worker.setUser(user);
					return w;
				}
			}
		}
		return null;
	}

	/**
	 * Don't forget to return your workers - they'll be
	 * reclaimed later if you do, but it's cleaner and faster to
	 * do it yourself.
	 */
	bool returnWorker(CBlob@ worker)
	{
		if (worker is null) return false;

		u16 id = worker.getNetworkID();
		for (uint i = 0 ; i < workers.length; ++i)
		{
			HallWorker@ w = workers[i];
			if (!w.isAvailable() && w.isBlob(id))
			{
				CBlob@ owner = getOwner();
				w.setUser(owner);
				return true;
			}
		}

		return false;
	}

	/**
	 * Update this worker set, basically to maintain sanity
	 * only does anything on server
	 */
	void Update()
	{
		if (!getNet().isServer()) return;

		CBlob@ owner = getOwner();
		u8 tempcount = owner.get_u8("migrants max");
		if (tempcount > count)
		{
			count++;
			AddWorker(); //add workers as needed
		}
		else if (tempcount < count)
		{
			//TODO: remove as needed
		}

		UpdateWorkers();
	}

	/**
	 * Regenerate workers in any cases where they have died, and
	 * reclaim workers where the owner has died.
	 */
	void UpdateWorkers()
	{
		if (under_raid) return;

		CBlob@ owner = getOwner(); if (owner is null) return;
		int ownerteam = owner.getTeamNum();

		gametime = getGameTime();

		for (uint i = 0 ; i < workers.length; ++i)
		{
			HallWorker@ worker = workers[i];

			worker.Update(); //update internal stuff

			//regen
			CBlob@ b = worker.getBlob();
			if (b is null)
			{
				if (canRespawn())
				{
					lastRespawnTime = gametime;

					worker.RegenBlob();

					@b = worker.getBlob();
					if (b !is null) //regen succeeded
					{
						worker.setUser(owner);
						ResetWorker(b);
						setWorker(owner, b);
						attachWorker(owner, b, owner.getHeight(), true);
					}
				}
			}
			else
			{
				//set team -> conversion happens naturally
				b.server_setTeamNum(ownerteam);

				CBlob@ user = worker.getUser();
				//convert users if they are still around
				if (user !is null)
				{
					//not in use, not fleeing?
					if (worker.isAvailable())
					{
						//not in hall?!
						if (!b.getShape().isStatic() && !b.isOverlapping(owner) && canRespawn())
						{
							//move to hall
							attachWorker(owner, b, owner.getShape().getHeight(), true);
							lastRespawnTime = gametime;
						}
					}
					else //they have a valid non hall user
					{
						//so convert the user
						user.server_setTeamNum(ownerteam);
					}
				}
				else //user has died -> reclaim
					if (!worker.isBusy())	//fleeing, don't interrupt
					{
						worker.setUser(getOwner());
						ResetWorker(b);
						setWorker(owner, b);
					}
			}
		}
	}

	/** Add a worker to the system */
	void AddWorker(CBlob@ owner = null)
	{
		if (owner is null)
			@owner = getBlobByNetworkID(ownerID);

		HallWorker w(owner);
		workers.push_back(w);
	}

	//only respawn one per second
	bool canRespawn()
	{
		return lastRespawnTime + 30 < gametime;
	}

};


// useful for HUD

shared void getWorkers(CBlob@ hall, CBlob@[]@ workers)
{
	HallWorkerSet@ workersSet;
	if (!hall.get("hall workers", @workersSet) || workersSet is null) return;

	for (uint i = 0 ; i < workersSet.workers.length; ++i)
	{
		HallWorker@ worker = workersSet.workers[i];
		CBlob@ blob = worker.getBlob();
		workers.push_back(blob);
	}
}

shared void getFactories(CBlob@ hall, CBlob@[]@ factories)
{
	HallWorkerSet@ workersSet;
	if (!hall.get("hall workers", @workersSet) || workersSet is null) return;

	for (uint i = 0 ; i < workersSet.workers.length; ++i)
	{
		HallWorker@ worker = workersSet.workers[i];
		CBlob@ blob = worker.getUser();
		if (blob !is null && blob.getName() == "factory")
			factories.push_back(blob);
	}
}


