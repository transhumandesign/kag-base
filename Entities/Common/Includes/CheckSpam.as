bool isSpammed(const string &in blobName, Vec2f pos, int max = 6)
{
	return isMoreThanInRadius(blobName, max, pos, 140.0f);
}

bool isMoreThanInRadius(const string &in blobName, const uint maxCount, Vec2f pos, f32 radius)
{
	CBlob@[] blobsInRadius;
	uint count = 0;
	if (getMap().getBlobsInRadius(pos, radius, @blobsInRadius))
	{
		for (uint i = 0; i < blobsInRadius.length; i++)
		{
			CBlob @b = blobsInRadius[i];
			if (b.getName() == blobName)
			{
				count++;
			}
		}
	}
	return (count >= maxCount);
}