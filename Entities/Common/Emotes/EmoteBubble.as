// Draw an emoticon

#include "EmotesCommon.as";

void onInit(CBlob@ blob)
{
	blob.addCommandID("emote");

	CSprite@ sprite = blob.getSprite();
	blob.set_string("emote", "");
	blob.set_u32("emotetime", 0);
	//init emote layer
	CSpriteLayer@ layer = sprite.addSpriteLayer("bubble", "Entities/Common/Emotes/Emoticons.png", 32, 32, 0, 0);
	layer.SetIgnoreParentFacing(true);
	layer.SetFacingLeft(false);

	if (layer !is null)
	{
		layer.SetOffset(Vec2f(0, -sprite.getBlob().getRadius() * 1.5f - 16));
		layer.SetRelativeZ(100.0f);
		{
			Animation@ anim = layer.addAnimation("default", 0, true);

			dictionary emotes;
			if (getRules().get("emotes", emotes))
			{
				for (int i = 0; i < emotes.getSize(); i++)
				{
					anim.AddFrame(i);
				}
			}
		}
		layer.SetVisible(false);
		layer.SetHUD(true);
	}
}

void onTick(CBlob@ blob)
{
	blob.getCurrentScript().tickFrequency = 6;
	// if (blob.exists("emote"))	 will show skull if none existant
	if (!blob.getShape().isStatic())
	{
		CSprite@ sprite = blob.getSprite();
		CSpriteLayer@ layer = sprite.getSpriteLayer("bubble");

		Emote@ emote = getEmote(blob.get_string("emote"));
		if (emote !is null && is_emote(blob) && !blob.hasTag("dead") && !blob.isInInventory())
		{
			blob.getCurrentScript().tickFrequency = 1;
			if (layer !is null)
			{
				layer.SetVisible(!isMouseOverEmote(layer));
				layer.animation.frame = emote.index;

				layer.ResetTransform();

				CCamera@ camera = getCamera();
				if (camera !is null)
				{
					f32 angle = -camera.getRotation() + blob.getAngleDegrees();
					layer.RotateBy(-angle, Vec2f(0, 20));
				}
			}
		}
		else
		{
			layer.SetVisible(false);
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("emote"))
	{
		string token = params.read_string();
		u32 emotetime = params.read_u32();
		this.set_string("emote", token);
		this.set_u32("emotetime", emotetime);
	}
}

void onClickedBubble(CBlob@ this, int index)
{
	print(""+index);
	// set_emote(this, index);
}
