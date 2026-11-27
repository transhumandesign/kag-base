///////////////////////////////////////////////////////////////////////////////
// gender texture and head offset handling stuff
//
//		used for the default 2-gender runner classes in conjunction with
//		runnerhead.as - has functionality for storing it inside rules
//		for simplicity
//

#include "PaletteSwap.as"
#include "PixelOffsets.as"

shared u32 FG_HEAD_COLOUR()
{
	return 0xffff00ff;
}
shared u32 BG_HEAD_COLOUR()
{
	return 0xffffff00;
}

shared class RunnerTextures
{
	PixelOffsetsCache male_offsets;
	PixelOffsetsCache female_offsets;

	string shortname;

	string male_shortname;
	string female_shortname;

	string male_filename;
	string female_filename;

	bool loaded;

	RunnerTextures(string _shortname, string texture_prefix)
	{
		loaded = false;

		shortname = _shortname;

		male_shortname = shortname+"_male";
		female_shortname = shortname+"_female";

		male_filename = texture_prefix+"Male.png";
		female_filename = texture_prefix+"Female.png";
	}

	void Load(Vec2f framesize)
	{
		if (loaded) return;

		array<SColor> col = {
			SColor(FG_HEAD_COLOUR()),
			SColor(BG_HEAD_COLOUR())
		};

		createAndLoadPixelOffsets(male_shortname, male_filename, framesize, col, @male_offsets);
		createAndLoadPixelOffsets(female_shortname, female_filename, framesize, col, @female_offsets);

		loaded = true;
	}

	void Load(CSprite@ sprite)
	{
		if (loaded) return;

		Load(_sprite_to_framesize(sprite));
	}

	//get the texture name

	string texname(u8 gender)
	{
		return gender == 0 ? male_shortname : female_shortname;
	}

	string texname(CBlob@ blob)
	{
		return texname(blob.getSexNum());
	}

	string texname(CSprite@ sprite)
	{
		return texname(sprite.getBlob());
	}

	//get the actual cached offsets

	PixelOffsetsCache@ cached_offsets(u8 gender)
	{
		return gender == 0 ? @male_offsets : @female_offsets;
	}

	PixelOffsetsCache@ cached_offsets(CBlob@ blob)
	{
		return cached_offsets(blob.getSexNum());
	}

	PixelOffsetsCache@ cached_offsets(CSprite@ sprite)
	{
		return cached_offsets(sprite.getBlob());
	}
};

string getRunnerTeamTexture(RunnerTextures@ textures, int gender, int team_num, int skin_num)
{
	if (textures is null) return "";
	return ApplyTeamTexture(textures.texname(u8(gender)), team_num, skin_num);
}

string getRunnerTextureName(CSprite@ sprite)
{
	CBlob@ b = sprite.getBlob();
	return getRunnerTeamTexture(getRunnerTextures(sprite), b.getSexNum(), b.getTeamNum(), 0);
}

void setRunnerTexture(CSprite@ sprite)
{
	string t = getRunnerTextureName(sprite);

	//only change if we need it and if it exists
	if (sprite.getTextureName() != t && t != "")
	{
		sprite.SetTexture(t);
	}
}

//call this in oninit from the script housing the object
//it'll change the texture of the sprite to the one for the right gender as well

RunnerTextures@ fetchRunnerTexture(string shortname, string texture_prefix)
{
	RunnerTextures@ tex = null;
	string rules_key = "runner_tex_"+shortname+"_"+texture_prefix;
	if (!getRules().get(rules_key, @tex) || tex is null)
	{
		getRules().set(rules_key, RunnerTextures(shortname, texture_prefix));
		//re-fetch
		return fetchRunnerTexture(shortname, texture_prefix);
	}
	return tex;
}

RunnerTextures@ addRunnerTextures(CSprite@ sprite, string shortname, string texture_prefix)
{
	//fetch it or set it up
	RunnerTextures@ tex = fetchRunnerTexture(shortname, texture_prefix);
	//load it out
	tex.Load(sprite);
	//store needed stuff in blob
	CBlob@ b = sprite.getBlob();
	b.set("runner_textures", @tex);
	b.set("head_offsets", tex.cached_offsets(sprite));
	//set the correct texture
	setRunnerTexture(sprite);
	//done
	return tex;
}

//get the textures object directly

RunnerTextures@ getRunnerTextures(CBlob@ blob)
{
	RunnerTextures@ tex = null;
	blob.get("runner_textures", @tex);
	return tex;
}

RunnerTextures@ getRunnerTextures(CSprite@ sprite)
{
	return getRunnerTextures(sprite.getBlob());
}

//ensure the right texture is used
void ensureCorrectRunnerTexture(CSprite@ sprite, string shortname, string texture_prefix)
{
	if (!isClient())
	{
		return;
	}

	RunnerTextures@ tex = getRunnerTextures(sprite);
	if (tex is null || tex.shortname != shortname)
	{
		//first time set up
		addRunnerTextures(sprite, shortname, texture_prefix);
		ensureCorrectRunnerTexture(sprite, shortname, texture_prefix);
		return;
	}
	//just set the texture
	CBlob@ b = sprite.getBlob();
	b.set("head_offsets", tex.cached_offsets(sprite));
	setRunnerTexture(sprite);
}

//get the head offset for the sprite
//specify frame < 0 for current frame
//layer out param specifies:
//		 0 : missing offset
//		 1 : fg offset
//		-1 : bg offset

Vec2f getHeadOffset(CBlob@ blob, int frame, int &out layer)
{
	CSprite@ sprite = blob.getSprite();
	PixelOffsetsCache@ offsets = null;
	blob.get("head_offsets", @offsets);
	if (offsets !is null)
	{
		if (frame < 0)
		{
			frame = sprite.getFrame();
		}

		array<Vec2f> px;

		//fg takes priority
		px = offsets.getOffsets(sprite, SColor(FG_HEAD_COLOUR()), frame);
		if (px.length > 0)
		{
			layer = 1;
			return px[0];
		}

		//check bg next
		px = offsets.getOffsets(sprite, SColor(BG_HEAD_COLOUR()), frame);
		if (px.length > 0)
		{
			layer = -1;
			return px[0];
		}

		layer = 0;
		return Vec2f(0,0);
	}
	layer = 0;
	return Vec2f(0,0);
}
