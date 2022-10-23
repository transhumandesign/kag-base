enum ImportanceRank
{
	capturing_vehicle,
	lit_keg,
	player_near_tent,
	builder_near_flag,
	capturing_hall,
	missing_flag
}

enum ComparisonType
{
	cinematic_importance,
	x_position,
	y_position
}

Vec2f calculateZoomLevel(float width, float height)
{
	Driver@ driver = getDriver();
	float ratio = float(driver.getScreenHeight()) / float(driver.getScreenWidth());
	return Vec2f(
		360.0f / Maths::Max(width * ratio, 1.0f),
		360.0f / Maths::Max(height, 1.0f)
	);
}

void calculateZoomTarget(float distX, float distY)
{
	Vec2f zoomLevel = calculateZoomLevel(distX * 1.8f, distY * 1.8f);
	zoomTarget = Maths::Min(zoomLevel.x, zoomLevel.y);
	zoomTarget = Maths::Clamp(zoomTarget, CINEMATIC_FURTHEST_ZOOM, CINEMATIC_CLOSEST_ZOOM);
}

CBlob@[] calculateImportance(CBlob@[] blobs)
{
	CMap@ map = getMap();
	CBlob@[] filtered_blobs;

	for (uint i = 0; i < blobs.length; i++)
	{
		CBlob@ blob = blobs[i];
		blob.set_f32("cinematic importance", -1);
		bool importantBlob = false;

		//lit keg
		if (blob.getName() == "keg" && blob.hasTag("exploding"))
		{
			//kegs about to explode are MORE important
			float fuse = Maths::Max(blob.get_s32("explosion_timer") - getGameTime(), 0) / blob.get_f32("keg_time");
			blob.set_f32("cinematic importance", ImportanceRank::lit_keg + 1 - fuse);
			importantBlob = true;
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
				importantBlob = true;
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
				importantBlob = true;
			}

			if (blob.getName() == "hall")
			{
				blob.set_f32("cinematic importance", ImportanceRank::capturing_hall + 1 - capture);
				importantBlob = true;
			}
		}

		Vec2f blobPos = blob.getInterpolatedPosition();
		bool blobInLight = map.getTile(blobPos).light >= 0x20; //same as in MarkPlayers.as
		if (blob.hasTag("player") && blobInLight)
		{
			//player near enemy tent
			CBlob@[] blobsInRadius;
			map.getBlobsInRadius(blobPos, 28.0f * map.tilesize, blobsInRadius);
			for (uint j = 0; j < blobsInRadius.length; j++)
			{
				CBlob@ b = blobsInRadius[j];
				if (
					b.getName() == "tent" &&
					b.getTeamNum() != blob.getTeamNum()
				) {
					blob.set_f32("cinematic importance", ImportanceRank::player_near_tent);
					importantBlob = true;
					break;
				}
			}

			//builder near enemy flag base
			if (blob.getName() == "builder")
			{
				CBlob@[] blobsInRadius;
				map.getBlobsInRadius(blobPos, 8.0f * map.tilesize, blobsInRadius);
				for (uint j = 0; j < blobsInRadius.length; j++)
				{
					CBlob@ b = blobsInRadius[j];
					if (
						b.getName() == "flag_base" &&
						!b.hasTag("flag missing") &&
						b.getTeamNum() != blob.getTeamNum()
					) {
						blob.set_f32("cinematic importance", ImportanceRank::builder_near_flag);
						importantBlob = true;
						break;
					}
				}
			}
		}

		//add important blob to filtered list so sorting is quicker
		if (importantBlob)
		{
			filtered_blobs.push_back(blob);
		}
	}

	return filtered_blobs;
}

class CompareBase
{
	CBlob@ blob;
};

class CompareImportanceWrapper : CompareBase
{
	int opCmp(const CompareImportanceWrapper &in other)
	{
		return blob.get_f32("cinematic importance") - other.blob.get_f32("cinematic importance");
	}
};

/*class CompareXWrapper : CompareBase
{
	int opCmp(const CompareXWrapper &in other)
	{
		return blob.getPosition().x - other.blob.getPosition().x;
	}
};

class CompareYWrapper : CompareBase
{
	int opCmp(const CompareYWrapper &in other)
	{
		return blob.getPosition().y - other.blob.getPosition().y;
	}
};*/

void SortBlobsByImportance(CBlob@[]@ blobs)
{
	const int blobCount = blobs.length;
	CompareImportanceWrapper[] wrappers(blobCount);
	for (int i = 0; i < blobCount; ++i) { @wrappers[i].blob = @blobs[i]; }
	wrappers.sortDesc();
	for (int i = 0; i < blobCount; ++i) { @blobs[i] = @wrappers[i].blob; }
}

/*void SortBlobsByXPosition(CBlob@[]@ blobs)
{
	const int blobCount = blobs.length;
	CompareXWrapper[] wrappers(blobCount);
	for (int i = 0; i < blobCount; ++i) { @wrappers[i].blob = @blobs[i]; }
	wrappers.sortAsc();
	for (int i = 0; i < blobCount; ++i) { @blobs[i] = @wrappers[i].blob; }
}

void SortBlobsByYPosition(CBlob@[]@ blobs)
{
	const int blobCount = blobs.length;
	CompareYWrapper[] wrappers(blobCount);
	for (int i = 0; i < blobCount; ++i) { @wrappers[i].blob = @blobs[i]; }
	wrappers.sortAsc();
	for (int i = 0; i < blobCount; ++i) { @blobs[i] = @wrappers[i].blob; }
}*/

bool focusOnBlob(CBlob@[] blobs)
{
	const float CHANGE_FOCUS_DELAY = 1.5f; //time before camera moves on from focused blob

	CBlob@ targetBlob = getBlobByNetworkID(currentTarget);

	if (getGameTime() < switchTarget && targetBlob !is null && targetBlob.getHealth() <= 0)
	{
		//stay at focus blob's position for a bit after they die
		posTarget = targetBlob.getInterpolatedPosition();
		zoomTarget = 1.0f;
		return true;
	}
	else if (blobs.length > 0)
	{
		for (uint i = 0; i < blobs.length; i++)
		{
			CBlob@ blob = blobs[i];
			u16 networkID = blob.getNetworkID();
			@blob = getBlobByNetworkID(networkID);

			if (blob !is null)
			{
				if (getGameTime() < switchTarget && blob !is targetBlob)
				{
					//stay at focus blob's position for a bit before focusing on a more important blob
					posTarget = targetBlob.getInterpolatedPosition();
					zoomTarget = 1.0f;
				}
				else
				{
					//follow important blob
					posTarget = blob.getInterpolatedPosition();
					zoomTarget = 1.0f;
					currentTarget = blob.getNetworkID();
					switchTarget = getGameTime() + CHANGE_FOCUS_DELAY * getTicksASecond();
				}

				return true;
			}
		}
	}

	//not following an important blob
	return false;
}

void ViewEntireMap()
{
	Vec2f mapDim = getMap().getMapDimensions();
	posTarget = mapDim / 2.0f;
	Vec2f zoomLevel = calculateZoomLevel(mapDim.x, mapDim.y);
	zoomTarget = Maths::Min(zoomLevel.x, zoomLevel.y);
	zoomTarget = Maths::Clamp(zoomTarget, 0.5f, 2.0f);
}

void LoadCinematicConfig(CRules@ this)
{
	ConfigFile cfg = ConfigFile();
	if (!cfg.loadFile("../Cache/cinematic_prefs.cfg") || !cfg.exists("cinematic_enabled"))
	{
		cfg.add_bool("cinematic_enabled", true);
		cfg.saveFile("cinematic_prefs.cfg");
	}

	this.set("cinematic_cfg", cfg);
}

void setCinematicEnabled(bool enabled)
{
	ConfigFile@ cfg;
	getRules().get("cinematic_cfg", @cfg);
	cfg.add_bool("cinematic_enabled", enabled);
	cfg.saveFile("cinematic_prefs.cfg");

	SetTimeToCinematic();
}

void SetTimeToCinematic()
{
	timeToCinematic = isCinematicEnabled() ? 0.0f : AUTO_CINEMATIC_TIME;
}

bool isCinematicEnabled()
{
	ConfigFile@ cfg;
	getRules().get("cinematic_cfg", @cfg);
	if (cfg.exists("cinematic_enabled"))
	{
		return cfg.read_bool("cinematic_enabled");
	}

	LoadCinematicConfig(getRules());
	return false; 
}

bool isCinematic()
{
	return isCinematicEnabled() && canCinematic();
}

bool canCinematic()
{
	return (
		getCamera() !is null &&
		getLocalPlayerBlob() is null && getLocalPlayer() !is null
	);
}
