// Draw an emoticon

#include "EmotesCommon.as";

void onInit(CBlob@ blob)
{
	CSprite@ sprite = blob.getSprite();
	blob.set_u8("emote", Emotes::off);
	blob.set_u32("emotetime", 0);
	//init emote layer
	CSpriteLayer@ emote = sprite.addSpriteLayer("bubble", "Entities/Common/Emotes/Emoticons.png", 32, 32, 0, 0);

	if (emote !is null)
	{
		emote.SetOffset(Vec2f(0, -sprite.getBlob().getRadius() * 1.5f - 16));
		emote.SetRelativeZ(100.0f);
		{
			Animation@ anim = emote.addAnimation("default", 0, true);

			for (int i = 0; i < Emotes::emotes_total; i++)
			{
				anim.AddFrame(i);
			}
		}
		emote.SetVisible(false);
		emote.SetHUD(true);
	}

	AddBubblesToMenu(blob);
}



void onTick(CBlob@ blob)
{
	blob.getCurrentScript().tickFrequency = 6;
	// if (blob.exists("emote"))	 will show skull if none existant
	if (!blob.getShape().isStatic())
	{
		CSprite@ sprite = blob.getSprite();
		CSpriteLayer@ emote = sprite.getSpriteLayer("bubble");

		const u8 index = blob.get_u8("emote");
		if (is_emote(blob, index) && !blob.hasTag("dead"))
		{
			blob.getCurrentScript().tickFrequency = 1;
			if (emote !is null)
			{
				emote.SetVisible(true);
				emote.animation.frame = index;

				emote.ResetTransform();
				if (sprite.isFacingLeft())
				{
					emote.ScaleBy(Vec2f(-1.0f, 1.0f));
				}
				CCamera@ camera = getCamera();
				if (camera !is null)
				{
					f32 angle = -camera.getRotation() + blob.getAngleDegrees();
					emote.RotateBy(-angle, Vec2f(0, 20));
				}
			}
		}
		else
		{
			emote.SetVisible(false);
		}
	}
}

void onClickedBubble(CBlob@ this, int index)
{
	set_emote(this, index);
}

void AddBubblesToMenu(CBlob@ this)
{
	this.LoadBubbles("Entities/Common/Emotes/Emoticons.png");

	//for (int i = Emotes::skull; i < Emotes::cog; i++) {
	//    if (i != Emotes::pickup && i != Emotes::blank && i != Emotes::dots) {
	//        this.AddBubble( "", i );
	//    }
	//}

	this.AddBubble("", Emotes::right);

	this.AddBubble("", Emotes::cross);
	this.AddBubble("", Emotes::laugh);
	this.AddBubble("", Emotes::smile);
	this.AddBubble("", Emotes::check);
	this.AddBubble("", Emotes::troll);
	this.AddBubble("", Emotes::wat);

	this.AddBubble("", Emotes::down);

	this.AddBubble("", Emotes::derp);
	this.AddBubble("", Emotes::mad);
	this.AddBubble("", Emotes::disappoint);
	this.AddBubble("", Emotes::frown);
	this.AddBubble("", Emotes::cry);
	this.AddBubble("", Emotes::archer);
	this.AddBubble("", Emotes::knight);
	this.AddBubble("", Emotes::builder);

	this.AddBubble("", Emotes::left);

	this.AddBubble("", Emotes::sweat);
	this.AddBubble("", Emotes::heart);
	this.AddBubble("", Emotes::skull);
	this.AddBubble("", Emotes::flex);
	this.AddBubble("", Emotes::finger);
	this.AddBubble("", Emotes::thumbsdown);
	this.AddBubble("", Emotes::thumbsup);

	this.AddBubble("", Emotes::up);

	this.AddBubble("", Emotes::ladder);
	this.AddBubble("", Emotes::attn);
	this.AddBubble("", Emotes::question);
	this.AddBubble("", Emotes::fire);
	this.AddBubble("", Emotes::wall);
	this.AddBubble("", Emotes::note);

	//derp note
}
