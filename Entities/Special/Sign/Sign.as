// Sign logic

#include "Hitters.as";
#include "NoSwearsCommon.as";

namespace Sign
{
	enum State
	{
		blank = 0,
		written
	}
}

bool swearsReadIntoArray = false;

void onInit(CBlob@ this)
{
	//setup blank state
	this.set_u8("state", Sign::blank);

	if (!this.exists("text"))
	{
		this.set_string("text", "The big brown fox jumped over the shaggy chocolate."); // Should be ok even if the server and the client run it?
	}

	this.getSprite().SetAnimation("written");

	this.getCurrentScript().runFlags |= Script::tick_myplayer;
	this.getSprite().SetZ(-10.0f);
	
	// swears-related
	if (!swearsReadIntoArray)
		swearsReadIntoArray = InitSwearsArray();
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	return customData == Hitters::builder ? this.getInitialHealth() / 2 : damage;
}

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob is null) return;

	if (getHUD().menuState != 0) return;

	CBlob@ localBlob = getLocalPlayerBlob();
	Vec2f pos2d = blob.getScreenPos();

	if (localBlob is null) return;

	if (
	    ((localBlob.getPosition() - blob.getPosition()).Length() < 0.5f * (localBlob.getRadius() + blob.getRadius())) &&
	    (!getHUD().hasButtons()))
	{
		// positioning of text
		int top = pos2d.y - 2.5f * blob.getHeight() + 000.0f;
		int left = 200.0f;
		int margin = 4;
		Vec2f dim;
		string label = getTranslatedString(blob.get_string("text")).replace("\\n", "\n");;
		
		// censoring swears if necessary
		string textOut;
		processSwears(label, textOut);

		label = textOut + "\n";
		GUI::SetFont("menu");
		GUI::GetTextDimensions(label , dim);
		dim.x = Maths::Min(dim.x, 200.0f);
		dim.x += margin;
		dim.y += margin;
		dim.y *= 1.0f;
		top += dim.y;
		Vec2f upperleft(pos2d.x - dim.x / 2 - left, top - Maths::Min(int(2 * dim.y), 250));
		Vec2f lowerright(pos2d.x + dim.x / 2 - left, top - dim.y);
		GUI::DrawText(label, Vec2f(upperleft.x + margin, upperleft.y + margin + margin),
		              Vec2f(upperleft.x + margin + dim.x, upperleft.y + margin + dim.y),
		              SColor(255, 0, 0, 0), false, false, true);
	}
}
