// Add this script to the script list of a blob to allow it to skip ticks when offscreen.
// This is useful to improve performance.
//
// This does significantly more than just not calling onTick hooks!
// Nearly _nothing_ will be done to update the blob while it is throttled.
// This should really only be used on somewhat static blobs (which, in particular, do _not_ increment a counter onTick!).
//
// NOTE: This optimization will *not* be done on servers, but it will be done in localhost.
//       This is acceptable for vanilla, but you may want to override this behavior in a mod.

#ifdef STAGING
uint32 throttleDuration(CBlob@ blob)
{
	const bool client = isClient(), server = isServer();
	const bool localhost = client && server;

	// Do not perform throttling on the server-side
	if (server && !localhost)
	{
		return 0;
	}

	// Just in case, give a few ticks for the blob to initialize
	if (blob.getTickSinceCreated() < 5)
	{
		return 0;
	}

	const float margin = 96.0f;
	if (!isPointOnScreen(blob.getPosition(), margin))
	{
		return 15;
	}

	return 0;
}

void onTick(CBlob@ blob)
{
	blob.throttleInterval = throttleDuration(blob);

	/*
	if (blob.throttleInterval != 0)
	{
		print("throttling " + blob.getName() + " for " + blob.throttleInterval);
	}
	*/
}
#endif