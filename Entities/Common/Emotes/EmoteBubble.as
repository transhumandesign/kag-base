// Draw an emoticon

#include "EmotesCommon.as";

void onInit(CBlob@ blob)
{
	CSprite@ sprite = blob.getSprite();
	blob.set_u8("emote", Emotes::off);
	blob.set_u32("emotetime", 0);
	//init emote layer
	CSpriteLayer@ emote = sprite.addSpriteLayer("bubble", "Entities/Common/Emotes/Emoticons.png", 32, 32, 0, 0);
	emote.SetIgnoreParentFacing(true);
	emote.SetFacingLeft(false);

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

	//this.AddBubble("", Emotes::blueflag);
	//this.AddBubble("", Emotes::redflag);

	this.AddBubble("Point Right", Emotes::right);

	this.AddBubble("Laughing", Emotes::laugh);
	this.AddBubble("Smiling", Emotes::smile);
	this.AddBubble("Skull", Emotes::skull);
	this.AddBubble("Laughing Crying", Emotes::laughcry);
	this.AddBubble("Awkward Laughing", Emotes::awkward);
	this.AddBubble("Smug", Emotes::smug);
	this.AddBubble("Troll", Emotes::troll);
	//this.AddBubble("", Emotes::raised);
	this.AddBubble("What", Emotes::wat);

	this.AddBubble("Point Down", Emotes::down);

	this.AddBubble("Derp", Emotes::derp);
	this.AddBubble("Mad", Emotes::mad);
	this.AddBubble("Disappointed", Emotes::disappoint);
	this.AddBubble("Frown", Emotes::frown);
	this.AddBubble("Crying", Emotes::cry);
	this.AddBubble("Archer", Emotes::archer);
	this.AddBubble("Knight", Emotes::knight);
	this.AddBubble("Builder", Emotes::builder);

	this.AddBubble("Point left", Emotes::left);

	this.AddBubble("Heart", Emotes::heart);
	this.AddBubble("Love", Emotes::love);
	this.AddBubble("Kiss", Emotes::kiss);
	this.AddBubble("Flex", Emotes::flex);
	this.AddBubble("Rude Gesture", Emotes::finger);
	//this.AddBubble("", Emotes::drool);
	this.AddBubble("Thumbs Down", Emotes::thumbsdown);
	this.AddBubble("Thumbs Up", Emotes::thumbsup);
	this.AddBubble("OK", Emotes::okhand);

	this.AddBubble("Point Up", Emotes::up);

	this.AddBubble("Thinking", Emotes::think);
	this.AddBubble("Sweat Drop", Emotes::sweat);
	this.AddBubble("Ladder", Emotes::ladder);
	this.AddBubble("Attention", Emotes::attn);
	this.AddBubble("Question", Emotes::question);
	this.AddBubble("Fire", Emotes::fire);
	this.AddBubble("Wall", Emotes::wall);
	this.AddBubble("Musical Note", Emotes::note);

	//derp note
}
