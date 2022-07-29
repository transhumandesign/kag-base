// Blob script to override the pickup importance of the blob.
// This will set the sprite Z to the value of the "important-pickup" f32 blob property at init time.
// It will also try to restore the chosen Z when the blob gets detached.
//
// By default, "important-pickup" is set to 20, as a sane default for important blobs.
// Use `blob.set_f32("important-pickup", any_z_you_want);` in your onInit hook to override this value.
// A higher value means closer to the front, i.e. has a higher importance during pickup.
//
// WARNING: Make sure that this script is late in the script list.
// ImportantPickup's onInit must be executed *after* yours to assign the correct Z.

#include "StandardControlsCommon.as"

// Current baseZ ordening in the game:
// 100: door OPEN, bridge OPEN
// -50+: buildings
// -40 ladders
// relative -10: pickup behind (keg, crate)
// -25 ballista
// -20: fireplace
// -10: saw (-1,-5)
//      chest
//      mounted bow
// 10: carrying saw
//     bison
//     shark
//     bush
//     grain, flower
// 20: DEFAULT IMPORTANT
// 30: bomb arrows
// 50: workbench foreground (weird)
// 100: door CLOSED, bridge CLOSED
// 500: spike


// Add the following to the Init of the object to specify a custom hover polygon:
// Vec2f[] hoverPoly =
//   { Vec2f(-7.0f, 3.5f)
//   , Vec2f(-2.5f, -5.0f)
//   , Vec2f(1.0f, -5.0f)
//   , Vec2f(6.5f,  3.5f)
//   , Vec2f(-7.0f, 3.5f)
//   };

// this.set("hover-poly", hoverPoly);


// Overwrite importance by setting "important-pickup" in the onInit

void onInit(CBlob@ this)
{
	f32 baseZ = 20.0f;
	if (this.exists("important-pickup")) 
	{
		baseZ = this.get_f32("important-pickup");
	}

	this.getSprite().SetZ(baseZ);
	this.set_f32("important-pickup", baseZ);
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	f32 baseZ = this.get_f32("important-pickup");
	this.getSprite().SetZ(baseZ);
}

// Add ImportantPickup.as to sprite_scripts in the .ctf file, and enable g_debug to turn on rendering of 
// the hover squares
void onRender(CSprite@ this)
{
	if (g_debug == 0)
		return;

	const SColor inactive_color(0xFFAAAAAA);
	const SColor active_color(0xFFFFFFFF);

	CBlob@ blob = this.getBlob();

	Vec2f[]@ hoverPoly;
	if (blob.get("hover-poly", @hoverPoly)) {
		Vec2f[] polygon;

		if (blob.isFacingLeft()) 
		{
			Vec2f[] mirrored;
			for ( int i = 0 ; i < hoverPoly.length ; i++ )
			{
				Vec2f q = Vec2f(-hoverPoly[i].x, hoverPoly[i].y);
				mirrored.push_back(q);
			}

			polygon = mirrored;
		} 
		else 
		{
			polygon = hoverPoly;
		}


		Vec2f pos = blob.getPosition();

		for (int i = 0; i < polygon.length-1; ++i) 
		{
			GUI::DrawLine(polygon[i] + pos, polygon[i+1] + pos, active_color);
		}
	
	}
}