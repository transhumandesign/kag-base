#define CLIENT_ONLY

//Items to highlight.
const string[] classes = {"builder", "knight", "archer"};
const string[][] highlight_items = {
/* 0 */	{"mat_stone", "mat_wood", "mat_gold"}, //builder
/* 1 */	{"mat_bombs", "mat_waterbombs", "keg"}, //knight
/* 2 */	{"mat_arrows", "mat_firearrows", "mat_waterarrows", "mat_bombarrows"} //archer
};

//Disable highlighting for items with a map luminance lower than this
const uint map_luminance_threshold = 40;

//Update latency in ticks, optimization, should be at least 3
//This is also used as the delay before useful materials shine
const uint update_latency = 15;

//The ticks spent since pressing [C]
uint ticks_since_pressed = 0;

//Double-buffering logic
u16[] highlighted_blobs_buf1, highlighted_blobs_buf2;
u16[]@ front_buffer = @highlighted_blobs_buf1;

//Blobs being processed for the back buffer. Updated on the first update stage.
u16[] processed_blobs;

void onTick(CSprite@ sprite)
{
	CMap@ map = getMap();
	CBlob@ playerblob = sprite.getBlob();
	CPlayer@ player = playerblob.getPlayer();

	if (map is null || player is null || !player.isMyPlayer()) return;

	if (playerblob.isKeyPressed(key_pickup))
	{
		//Index of array of items to highlight.
		int class_index = classes.find(sprite.getBlob().getConfig());
		if (class_index < 0) return;

		u16[]@ back_buffer = front_buffer is @highlighted_blobs_buf1 ? @highlighted_blobs_buf2 : @highlighted_blobs_buf1;

		const u8 current_stage = ticks_since_pressed++ % update_latency;
		if (current_stage == 0)
		{
			Driver@ driver = getDriver();
			Vec2f world_lowerright = driver.getWorldPosFromScreenPos(driver.getScreenDimensions());
			Vec2f world_upperleft = driver.getWorldPosFromScreenPos(Vec2f_zero);

			CBlob@[] collected_blobs;
			map.getBlobsInBox(world_lowerright, world_upperleft, collected_blobs);
			processed_blobs.clear();
			for (uint i = 0; i < collected_blobs.length; i++)
			{
				processed_blobs.push_back(collected_blobs[i].getNetworkID());
			}
		}

		for (uint i = current_stage; i < processed_blobs.length; i += update_latency)
		{
			CBlob@ blob = getBlobByNetworkID(processed_blobs[i]);
			if (blob !is null && !blob.isInInventory() && highlight_items[class_index].find(blob.getConfig()) >= 0)
			{
				back_buffer.push_back(blob.getNetworkID());
			}
		}

		//Swap out buffers and clear the new backbuffer
		if (current_stage == update_latency - 1)
		{
			front_buffer.clear();
			@front_buffer = @back_buffer;
		}
	}
	else
	{
		ticks_since_pressed = 0;
	}
}

void onRender(CSprite@ sprite)
{
	CMap@ map = getMap();
	CPlayer@ player = sprite.getBlob().getPlayer();

	if (map is null || player is null || !player.isMyPlayer() || ticks_since_pressed <= update_latency) return;

	const float base_brightness = Maths::Abs(Maths::Sin((ticks_since_pressed - update_latency) / 20.0f));

	for (uint i = 0; i < front_buffer.length; ++i)
	{
		CBlob@ blob = getBlobByNetworkID(front_buffer[i]);

		//Check for conditions that might have been invalidated recently!
		if (blob is null || blob.isInInventory()) continue;

		const u8 map_luminance = map.getColorLight(blob.getPosition()).getLuminance();
		if (map_luminance >= map_luminance_threshold)
		{
			//Fading effect, brightness depends on the map color
			const uint effect_brightness = base_brightness * map_luminance;

			//Render the normal and light effects
			blob.RenderForHUD(Vec2f_zero, 0.0f, SColor(255, map_luminance, map_luminance, map_luminance), RenderStyle::normal);
			blob.RenderForHUD(Vec2f_zero, 0.0f, SColor(255, effect_brightness, effect_brightness, effect_brightness / 2), RenderStyle::light);
		}
	}
}
