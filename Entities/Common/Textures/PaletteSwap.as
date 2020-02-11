///////////////////////////////////////////////////////////////////////////////
// Swapping Palette Colours
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
//	bool CreatePaletteSwappedTexture(ImageData@ input, string output_name, ImageData@ palette, int palette_index)
//
//		handles recolouring a texture in one pass based on a palette texture
//
//		requires
//			input texture			- texture to be recoloured
//			output texture name		- where the coloured copy should be created
//			palette texture			- which colours to remap
//			palette index			- which changed colours to use
//
//		will exit and report failure if the texture already exists
//		you should check ahead of time and just use the existing texture
//		rather than recolouring every load
//
//		totally ignores fully transparent pixels as an optimisation
//
//		remaps the rgb of partly transparent pixels while preserving the alpha
//
//		note: this is the low-level texture creation function - see below for "easymode"
//

bool CreatePaletteSwappedTexture(ImageData@ input, string output_name, ImageData@ palette, int palette_index)
{
	//not needed on server or something went wrong with getting imagedata
	if (!getNet().isClient() || input is null || palette is null)
	{
		return false;
	}

	if (Texture::exists(output_name))
		return false;

	if (!Texture::createFromData(output_name, input))
		return false;

	//done, no colouring required
	if (palette_index == 0)
		return true;

	//read out the relevant palette colours
	array<SColor> in_colours;
	array<SColor> out_colours;
	for(int i = 0; i < palette.height(); i++)
	{
		in_colours.push_back(palette.get(0, i));
		out_colours.push_back(palette.get(palette_index, i));
	}

	//get the existing data
	ImageData@ edit = Texture::data(output_name);

	if (edit is null)
	{
		Texture::destroy(output_name);
		return false;
	}

	//do the remap
	edit.remap(in_colours, out_colours, 1, true, true);

	if (!Texture::update(output_name, edit))
	{
		Texture::destroy(output_name);
		return false;
	}

	return true;
}

///////////////////////////////////////////////////////////////////////////////
//
//	string PaletteSwapTexture(string in_tex, string palette_filename, int palette_index)
//
//		easymode palette swapping - will check for the texture ahead of time
//		and if anything goes wrong, falls back to the input texture
//
//		as long as you do it in the same order and nothing fails, these can be nested
//		for multiple remappings, but be aware that it's pretty expensive and try to do
//		things ahead of time - cost scales with texture size.

string PaletteSwapTexture(string in_tex, string palette_filename, int palette_index)
{
	//we make an extra copy - it's not great but these files are pretty small and widely reused
	string pal_name = "palette_"+palette_filename;
	if (!Texture::exists(pal_name))
	{
		Texture::createFromFile(pal_name, palette_filename);
	}

	ImageData@ palette = Texture::data(pal_name);

	if (palette is null) return in_tex;

	palette_index = Maths::Min(palette_index, palette.width() - 1);

	//digest the palette filename to include alongside, so that different pallettes
	//end up with different texture names that aren't too long
	string filename_digest = "";
	{
		int digest = palette_filename.getHash() & 0xffff;
		filename_digest = formatInt(digest, "0h", 4).substr(0,4);
	}

	string output_name = in_tex + "_p" + filename_digest + "_" + palette_index;

	//use it if it exists
	if (!Texture::exists(output_name))
	{
		if (!CreatePaletteSwappedTexture(Texture::data(in_tex), output_name, palette, palette_index))
		{
			//failure - just use the in texture
			return in_tex;
		}

		//otherwise success!
	}

	return output_name;
}

///////////////////////////////////////////////////////////////////////////////
//
//	string ApplyTeamTexture(string tex, int team, int skin)
//
//		even easier mode
//
//		knows the base files for team colouring of each
//

string ApplyTeamTexture(string tex, int team, int skin)
{
	tex = PaletteSwapTexture(tex, "TeamPalette.png", team);
	//tex = PaletteSwapTexture(tex, "SkinTones.png", skin); //TODO; this needs intervention in-engine (it recolours to index 1)
	return tex;
}
