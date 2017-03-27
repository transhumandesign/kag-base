/*
 * Use hall workers - request a worker from halls within
 * radius and attach it if able to get one
 */

#include "HallCommon.as";

void onInit(CBlob@ this)
{
	this.addCommandID(worker_in_cmd);
	this.addCommandID(worker_out_cmd);
	this.getCurrentScript().tickFrequency = 90;
}

void onTick(CBlob@ this)
{
	if (!this.hasTag(worker_tag))
	{
		CBlob@ worker = requestWorker(this, getHallsFor(this, BASE_RADIUS));
		if (worker !is null)
		{
			CBitStream params;
			params.write_u16(worker.getNetworkID());
			this.SendCommand(this.getCommandID(worker_in_cmd) , params);
		}
	}
	else
	{
		CBlob@ worker = getWorker(this);
		if (worker is null ||			//must have died
		        worker.hasTag("dead"))  	//explicitly dead
		{
			CBitStream params;
			params.write_u16(getWorkerID(this));
			this.SendCommand(this.getCommandID(worker_out_cmd) , params);

			this.Untag(worker_tag);
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID(worker_in_cmd))
	{
		//read the id of the worker getting claimed
		u16 id; if (!params.saferead_u16(id)) return;

		CBlob@ worker = getBlobByNetworkID(id);

		if (worker !is null)
		{
			attachWorker(this, worker, this.getShape().getHeight());

			this.Tag(worker_tag);
		}
	}
	else if (cmd == this.getCommandID(worker_out_cmd))
	{
		//read the id of the worker getting claimed
		u16 id; if (!params.saferead_u16(id)) return;

		CBlob@ worker = getBlobByNetworkID(id);

		if (returnWorker(this, getHallsFor(this, BASE_RADIUS), worker))
		{
			this.Untag(worker_tag);//success
		}
	}

}
