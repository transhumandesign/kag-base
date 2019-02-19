///////////////////////////////////////////////////////////////////////////////
// pixel offset calculation
//
//		turns specific-coloured pixels in a sprite into vec2f locations,
//		which can be used for piecing together spritelayers or whatever else
//
//		doesn't recolour the offset pixels but can detect any colours with
//		non-zero alpha. Since the game only renders alpha >127, you can use
//		partially transparent offset pixels to avoid rendering, or modify
//		the texture yourself to remove the offending pixels.
//
//		the automatic behaviour of the engine-side pixel-offset management
//		is not preserved to ensure maximum flexibility going forward.
//
//		sharing between scripts is a bit trickier but it's the same as
//		with any other script object - dump it into an object or the
//		rules dictionary with get/set and be careful when retreiving it.
//
// 		the implementations spew warnings when something's wrong so
//		you should have a hard time missing it.
//

shared class OffsetCache
{
	array<array<Vec2f>> offsets;
	Vec2f framesize;
	SColor col;

	OffsetCache(ImageData@ data, SColor _col, Vec2f _framesize, int off_per_frame = 1)
	{
		Vec2f half_framesize = _framesize * 0.5;

		//in the case of missing image data
		//just use a "neutral" pixel offset
		if(data is null)
		{
			array<Vec2f> fake = {
				half_framesize
			};
			offsets.push_back(fake);
			return;
		}

		framesize = _framesize;
		col = _col;

		Vec2f texsize = Vec2f(data.width(), data.height());

		Vec2f tpos = Vec2f(0,0);
		Vec2f last_pos = Vec2f(0,0);
		int iters = 0;

		for(tpos.y = 0; tpos.y < texsize.y; tpos.y += framesize.y)
		{
			for(tpos.x = 0; tpos.x < texsize.x; tpos.x += framesize.x)
			{
				//each frame
				array<Vec2f> frame_offsets;

				Vec2f fpos = Vec2f(0,0);
				for(fpos.y = 0; fpos.y < framesize.y && frame_offsets.length < off_per_frame; fpos.y += 1)
				{
					for(fpos.x = 0; fpos.x < framesize.x && frame_offsets.length < off_per_frame; fpos.x += 1)
					{
						//each pixel
						iters++;
						Vec2f px = fpos + tpos;
						SColor cur = data.get(int(px.x), int(px.y));
						if(cur.getAlpha() != 0 &&
							cur.getRed() == col.getRed() &&
							cur.getGreen() == col.getGreen() &&
							cur.getBlue() == col.getBlue())
						{
							frame_offsets.push_back(fpos);
						}
					}
				}

				offsets.push_back(frame_offsets);
			}
		}
	}

	array<Vec2f> getOffsets(int frame)
	{
		if(frame < 0 || frame >= offsets.length)
		{
			frame = 0;
		}

		return offsets[frame];
	}

};

shared Vec2f _sprite_to_framesize(CSprite@ sprite)
{
	return Vec2f(sprite.getConsts().frameWidth, sprite.getConsts().frameHeight);
}

shared class PixelOffsets
{
	array<OffsetCache@> offsets;
	ImageData@ img;

	//create a set of pixeloffsets from a given texture
	PixelOffsets(string texname)
	{
		@img = Texture::data(texname);
	}

	//
	PixelOffsets(ImageData@ data)
	{
		@img = data;
	}

	private OffsetCache@ _buildCache(Vec2f framesize, SColor col)
	{
		OffsetCache@ off = OffsetCache(img, col, framesize);
		offsets.push_back(off);
		return off;
	}

	private OffsetCache@ _getCache(Vec2f framesize, SColor col)
	{
		for(int i = 0; i < offsets.length; i++)
		{
			if(offsets[i].framesize == framesize && offsets[i].col == col)
			{
				return @offsets[i];
			}
		}
		return null;
	}

	private OffsetCache@ _ensureCache(Vec2f framesize, SColor col)
	{
		OffsetCache@ cached = _getCache(framesize, col);
		if(cached !is null)
		{
			return cached;
		}

		return _buildCache(framesize, col);
	}

	// ensure that the offsets are calculated for a given
	// framesize and colour
	void EnsureLoaded(Vec2f framesize, SColor col)
	{
		_ensureCache(framesize, col);
	}

	// ensure that the offsets are calculated for a given
	// sprite and colour
	void EnsureLoaded(CSprite@ sprite, SColor col)
	{
		_ensureCache(_sprite_to_framesize(sprite), col);
	}

	// when you're done calculating adding offsets,
	// call this to free the unneeded pixel memory
	void FinaliseLoading()
	{
		@img = null;
	}

	// get the offsets for a given frame
	// length == 0 -> no pixel found that frame
	// offsets are in top to bottom, left to right order.
	array<Vec2f> getOffsets(Vec2f framesize, SColor col, int frame = 0)
	{
		return _ensureCache(framesize, col).getOffsets(frame);
	}

	// get the offsets for a given sprite, either
	// at a specific frame, or the current frame by default.
	array<Vec2f> getOffsets(CSprite@ sprite, SColor col, int frame = -1)
	{
		if(frame == -1)
		{
			frame = sprite.getFrameIndex();
		}

		return getOffsets(_sprite_to_framesize(sprite), col, frame);
	}

};

// get all the pixel offsets with different colours for a given texture
// expensive yo, do this once on setup and cache the result
shared PixelOffsets@ getPixelOffsetsForData(ImageData@ data, Vec2f framesize, array<SColor> col)
{
	PixelOffsets@ p = PixelOffsets(data);

	for(int i = 0; i < col.length; i++)
	{
		p.EnsureLoaded(framesize, col[i]);
	}

	p.FinaliseLoading();

	return @p;
}

// get all the pixel offsets with different colours for a given sprite (as above)
shared PixelOffsets@ getPixelOffsetsForTexture(string texname, Vec2f framesize, array<SColor> col)
{
	return getPixelOffsetsForData(Texture::data(texname), framesize, col);
}

// get all the pixel offsets with different colours for a given sprite (as above)
shared PixelOffsets@ getPixelOffsetsForSprite(CSprite@ sprite, array<SColor> col)
{
	return getPixelOffsetsForData(Texture::dataFromSprite(sprite), _sprite_to_framesize(sprite), col);
}

// helper for easy per-script (or per-game) caching of pixel offsets
// stick one of these in the global scope of the script
// use EnsureLoaded before getting the offsets (every time)
// it'll only load the texture once, all other times will hit the cache
//		- so trying to share it between differently sized or textured objects wont work
// recommended to do the loading in onInit if possible
//		- CRules onInit ideally but that makes sharing more of a pain
shared class PixelOffsetsCache {
	PixelOffsets@ cache = null;
	Vec2f _framesize = Vec2f(0,0);

	PixelOffsetsCache() {}

	void EnsureLoaded(ImageData@ image, Vec2f framesize, array<SColor> col)
	{
		if(cache !is null) return;

		_framesize = framesize;
		@cache = getPixelOffsetsForData(image, _framesize, col);
	}

	void EnsureLoaded(CSprite@ sprite, array<SColor> col)
	{
		if(cache !is null) return;

		_framesize = _sprite_to_framesize(sprite);
		@cache = getPixelOffsetsForSprite(sprite, col);
	}

	array<Vec2f> getOffsets(SColor col, int frame = 0)
	{
		if(cache is null) {
			//warn("warn: pixel offset cache used before ensured loaded");
			return array<Vec2f>();
		}
		return cache.getOffsets(_framesize, col, frame);
	}

	array<Vec2f> getOffsets(CSprite@ sprite, SColor col, int frame = -1)
	{
		if(cache is null) {
			//warn("warn: pixel offset cache used before ensured loaded");
			return array<Vec2f>();
		}
		return cache.getOffsets(sprite, col, frame);
	}
};

shared bool createAndLoadPixelOffsets(CSprite@ sprite, array<SColor> col, PixelOffsetsCache@ into)
{
	into.EnsureLoaded(sprite, col);
	return true;
}

shared bool createAndLoadPixelOffsets(string texname, string from_file, Vec2f framesize, array<SColor> col, PixelOffsetsCache@ into)
{
	if(!Texture::systemEnabled()) return false;
	if(!Texture::createFromFile(texname, from_file)) return false;

	//get data
	ImageData@ data = Texture::data(texname);
	if(data is null) return false;
	//remap
	array<SColor> clean;
	for(int i = 0; i < col.length; i++) {
		SColor c = col[i];
		c.setAlpha(1);
		clean.push_back(c);
	}
	data.remap(col, clean, 1, true, false);
	if(!Texture::update(texname, data)) {
		warn("failed to update texture "+texname+" with clean pixel offsets");
	}
	//load
	into.EnsureLoaded(data, framesize, col);
	return true;
}
