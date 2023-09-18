#include "CTF_FlagCommon.as"

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

CBlob@[]@ buildImportanceList()
{
	// sinful spagghet code

	// we look up different types of blobs we want to pay attention to.
	// we want to keep the code relatively performant, hence
	// - we reuse the `blobs` array (easy)
	// - we avoid `getBlobs()`; use per name or per tag lookups instead

	CBlob@[] blobs;
	CBlob@[] importantBlobs;

	CMap@ map = getMap();

	{
		blobs.clear();
		getBlobsByName("keg", @blobs);
		const int blobCount = blobs.length;

		for (int i = 0; i < blobCount; ++i)
		{
			CBlob@ blob = @blobs[i];

			if (blob.hasTag("exploding"))
			{
				//kegs about to explode are MORE important
				float fuse = Maths::Max(blob.get_s32("explosion_timer") - getGameTime(), 0) / blob.get_f32("keg_time");
				blob.set_f32("cinematic importance", ImportanceRank::lit_keg + 1 - fuse);
				importantBlobs.push_back(@blob);
			}
		}
	}

	{
		blobs.clear();
		getBlobsByName("ctf_flag", @blobs);
		const int blobCount = blobs.length;

		for (int i = 0; i < blobCount; ++i)
		{
			CBlob@ blob = @blobs[i];

			if (!blob.isAttachedToPoint("FLAG"))
			{
				//flags about to be returned are LESS important
				float returnTime = float(blob.get_u16(return_prop)) / return_time;
				blob.set_f32("cinematic importance", ImportanceRank::missing_flag + 1 - returnTime);
				importantBlobs.push_back(@blob);
			}
		}
	}

	{
		blobs.clear();
		getBlobsByTag("under raid", @blobs);
		const int blobCount = blobs.length;

		for (int i = 0; i < blobCount; ++i)
		{
			CBlob@ blob = @blobs[i];

			//blobs closer to being captured are MORE important
			const s16 capture_time = blob.get_u16("capture time");

			if (capture_time <= 0)
			{
				continue;
			}

			float capture = float(blob.get_u16("capture ticks")) / capture_time;

			if (blob.hasTag("vehicle") && blob.hasTag("respawn"))
			{
				blob.set_f32("cinematic importance", ImportanceRank::capturing_vehicle + 1 - capture);
				importantBlobs.push_back(@blob);
			}
			else if (blob.getName() == "hall" || blob.getName() == "outpost")
			{
				blob.set_f32("cinematic importance", ImportanceRank::capturing_hall + 1 - capture);
				importantBlobs.push_back(@blob);
			}
		}
	}

	{
		blobs.clear();
		getBlobsByTag("player", @blobs);
		const int blobCount = blobs.length;

		for (int i = 0; i < blobCount; ++i)
		{
			CBlob@ blob = @blobs[i];
			bool importantBlob = false;

			Vec2f blobPos = blob.getInterpolatedPosition();
			bool blobInLight = map.getColorLight(blobPos).getLuminance() > 0.2f;
			if (blobInLight)
			{
				//player near enemy tent
				// currently disabled, because it produces too many false
				// positives (e.g. consider some player camping beneath an
				// enemy tent in a sky map), and it is generally not interesting
				// at a macro level

				// CBlob@[] blobsInRadius;
				// map.getBlobsInRadius(blobPos, 28.0f * map.tilesize, blobsInRadius);
				// for (uint j = 0; j < blobsInRadius.length; j++)
				// {
				// 	CBlob@ b = blobsInRadius[j];
				// 	if (
				// 		b.getName() == "tent" &&
				// 		b.getTeamNum() != blob.getTeamNum()
				// 	) {
				// 		blob.set_f32("cinematic importance", ImportanceRank::player_near_tent);
				// 		importantBlob = true;
				// 		break;
				// 	}
				// }

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

			if (importantBlob)
			{
				importantBlobs.push_back(@blob);
			}
		}
	}

	return @importantBlobs;
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
				if (getGameTime() < switchTarget && targetBlob !is null && blob !is targetBlob)
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
	CMap@ map = getMap();

	if (map !is null)
	{
		Vec2f mapDim = map.getMapDimensions();
		posTarget = mapDim / 2.0f;
		Vec2f zoomLevel = calculateZoomLevel(mapDim.x, mapDim.y);
		zoomTarget = Maths::Min(zoomLevel.x, zoomLevel.y);
		zoomTarget = Maths::Clamp(zoomTarget, 0.5f, 2.0f);
	}
}

bool cinematicEnabled = true;
bool cinematicForceDisabled = false;

void setCinematicEnabled(bool enabled)
{
	cinematicEnabled = enabled;
	SetTimeToCinematic();
}

void setCinematicForceDisabled(bool disabled)
{
	cinematicForceDisabled = disabled;
}

void SetTimeToCinematic()
{
	timeToCinematic = isCinematicEnabled() ? 0.0f : AUTO_CINEMATIC_TIME;
}

bool isCinematicEnabled()
{
	return cinematicEnabled && !cinematicForceDisabled && v_camera_cinematic;
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
