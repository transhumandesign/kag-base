// Draw an emoticon

#include "EmotesCommon.as";

void onInit(CBlob@ blob)
{
	blob.addCommandID("emote");

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
		if (is_emote(blob, index) && !blob.hasTag("dead") && !blob.isInInventory())
		{
			if (emote !is null)
			{
				CPlayer@ player = blob.getPlayer();
				if (player !is null && getSecurity().isPlayerIgnored(player))
				{
					// muted emote
					print("Ignored emote from " + player.getUsername());
					return;
				}

				blob.getCurrentScript().tickFrequency = 1;

				emote.SetVisible(!isMouseOverEmote(emote));
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

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("emote"))
	{
		u8 emote = params.read_u8();
		u32 emotetime = params.read_u32();
		this.set_u8("emote", emote);
		this.set_u32("emotetime", emotetime);
	}
}

void onClickedBubble(CBlob@ this, int index)
{
	set_emote(this, index);
}
