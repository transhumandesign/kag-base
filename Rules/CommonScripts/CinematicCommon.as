enum ImportanceRank
{
	capturing_vehicle,
	lit_keg,
	player_near_tent,
	builder_near_flag,
	capturing_hall,
	missing_flag
}

f32 calculateZoomLevelH(u32 height)
{
	return 360.0f / Maths::Max(height, 1.0f);
}

f32 calculateZoomLevelW(u32 width)
{
	f32 ratio = f32(getDriver().getScreenHeight()) / f32(getDriver().getScreenWidth());
	return calculateZoomLevelH(width * ratio);
}

void calculateImportance(CBlob@[] blobs)
{
	CMap@ map = getMap();

	for (uint i = 0; i < blobs.length; i++)
	{
		CBlob@ blob = blobs[i];
		blob.set_f32("cinematic importance", -1);

		//lit keg
		if (blob.getName() == "keg" && blob.hasTag("exploding"))
		{
			//kegs about to explode are MORE important
			float fuse = Maths::Max(blob.get_s32("explosion_timer") - getGameTime(), 0) / blob.get_f32("keg_time");
			blob.set_f32("cinematic importance", ImportanceRank::lit_keg + 1 - fuse);
		}

		//missing flag
		if (blob.getName() == "ctf_flag")
		{
			CBlob@ flagbase = getBlobByNetworkID(blob.get_u16("base_id"));
			if (flagbase !is null && !blob.isAttachedTo(flagbase))
			{
				//flags about to be returned are LESS important
				float returnTime = float(blob.get_u16("return time")) / blob.get_u16("max return time");
				blob.set_f32("cinematic importance", ImportanceRank::missing_flag + 1 - returnTime);
			}
		}

		//capturing blobs
		if (blob.hasTag("under raid"))
		{
			//blobs closer to being captured are MORE important
			float capture = float(blob.get_s16("capture ticks")) / blob.get_s16("max capture ticks");

			if (blob.hasTag("vehicle") && blob.hasTag("respawn")) //ballista, warboat
			{
				blob.set_f32("cinematic importance", ImportanceRank::capturing_vehicle + 1 - capture);
			}

			if (blob.getName() == "hall")
			{
				blob.set_f32("cinematic importance", ImportanceRank::capturing_hall + 1 - capture);
			}
		}

		bool blobInLight = map.getTile(blob.getInterpolatedPosition()).light >= 0x20; //same as in MarkPlayers.as
		if (blob.hasTag("player") && blobInLight)
		{
			//player near enemy tent
			CBlob@[] blobsInRadius;
			map.getBlobsInRadius(blob.getInterpolatedPosition(), 28.0f * map.tilesize, blobsInRadius);
			for (uint j = 0; j < blobsInRadius.length; j++)
			{
				CBlob@ b = blobsInRadius[j];
				if (
					b.getName() == "tent" &&
					b.getTeamNum() != blob.getTeamNum()
				) {
					blob.set_f32("cinematic importance", ImportanceRank::player_near_tent);
					break;
				}
			}

			//builder near enemy flag base
			if (blob.getName() == "builder")
			{
				CBlob@[] blobsInRadius;
				map.getBlobsInRadius(blob.getInterpolatedPosition(), 8.0f * map.tilesize, blobsInRadius);
				for (uint j = 0; j < blobsInRadius.length; j++)
				{
					CBlob@ b = blobsInRadius[j];
					if (
						b.getName() == "flag_base" &&
						!b.hasTag("flag missing") &&
						b.getTeamNum() != blob.getTeamNum()
					) {
						blob.set_f32("cinematic importance", ImportanceRank::builder_near_flag);
						break;
					}
				}
			}
		}
	}
}

CBlob@[] sortBlobsByImportance(CBlob@[] blobs)
{
	if (blobs.length > 0)
	{
		CBlob@ temp;
		for (uint i = 0; i < blobs.length - 1; i++)
		{
			for (uint j = i + 1; j < blobs.length; j++)
			{
				if (blobs[i].get_f32("cinematic importance") < blobs[j].get_f32("cinematic importance"))
				{
					@temp = blobs[j];
					@blobs[j] = blobs[i];
					@blobs[i] = temp;
				}
			}
		}
	}
	return blobs;
}

bool focusOnBlob(CBlob@[] blobs)
{
	const float CHANGE_FOCUS_DELAY = 1.5f; //time before camera moves on from focused blob

	if (
		(blobs.length == 0 || //no blobs
		(currentTarget !is null && currentTarget.getHealth() <= 0) || //focus blob doesnt exist
		blobs[0] !is currentTarget || //higher importance blob
		blobs[0].get_f32("cinematic importance") == -1) && //no important blobs
		getGameTime() < switchTarget //wait a bit before moving to next important blob
	) {
		//stay at focus blob's position for a bit before moving on
		posTarget = currentTarget.getInterpolatedPosition();
		zoomTarget = 1.0f;
	}
	else if (
		blobs.length > 0 && //blobs exist
		blobs[0].get_f32("cinematic importance") != -1 //important blob
	) {
		//follow important blob
		posTarget = blobs[0].getInterpolatedPosition();
		zoomTarget = 1.0f;
		@currentTarget = blobs[0];
		switchTarget = getGameTime() + CHANGE_FOCUS_DELAY * getTicksASecond();
	}
	else
	{
		//no blobs
		return false;
	}

	return true;
}
