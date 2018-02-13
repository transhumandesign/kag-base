// by Splittingred

shared class HoverMessage
{
	uint16 merge_id;
	string name;
	int quantity;
	uint ticker;
	f32 renderticker;
	f32 xpos;
	f32 ypos;
	uint ttl;		 // time of expiry
	uint fade_ratio; // % of alpha at ttl
	SColor color;

	HoverMessage() {} // required for handles to work

	HoverMessage(uint16 _merge_id, string _name, int _quantity, SColor _color = color_white, bool singularise = true, uint _ttl = 175, uint _fade_ratio = 90)
	{
		if (_quantity >= 0 && _quantity < 2 && singularise)
		{
			_name = this.singularize(_name);
		}

		merge_id = _merge_id;
		name = _name;
		quantity = _quantity;
		ticker = 0;
		renderticker = 0.0f;
		xpos = 0.0;
		ypos = 0.0;
		ttl = _ttl;
		fade_ratio = _fade_ratio;
		color = _color;
	}

	// draw the text
	void draw(CBlob@ blob, int i)
	{
		GUI::SetFont("menu");
		string m = this.message();
		Vec2f pos = this.getPos(blob, m, i);
		SColor color = this.getColor();
		GUI::DrawText(m, pos, color);
	}

	// get message into a nice, friendly format
	string message()
	{
		//short-circuit
		if (quantity == 0)
		{
			return "";
		}

		const bool show_positive = true;
		const bool show_negative = false;
		//translate name
		string _translated_name = name;
		//(unless this is a kill message - todo: generalise this further)
		if(merge_id != 1337)
		{
			_translated_name = getTranslatedString(_translated_name);
		}
		//positive messages
		if(show_positive && quantity > 0)
		{
			return getTranslatedString("+{AMOUNT} {NAME}")
				.replace("{AMOUNT}", ""+Maths::Abs(quantity))
				.replace("{NAME}", _translated_name);
		}
		//negative messages
		else if(show_negative && quantity < 0)
		{
			return getTranslatedString("-{AMOUNT} {NAME}")
				.replace("{AMOUNT}", ""+Maths::Abs(quantity))
				.replace("{NAME}", _translated_name);
		}

		return "";
	}

	// update message on every tick
	void update()
	{
		ticker += 2;
		renderticker += 2.0f * getRenderApproximateCorrectionFactor();
	}

	// see if this message is expired, or should be removed from GUI
	bool isExpired()
	{
		return ticker > ttl;
	}

	// get the active color of the message. decrease proportionally by the fadeout ratio
	private SColor getColor()
	{
		uint alpha = Maths::Max(0, 255 * (ttl - renderticker * fade_ratio / 100.0f) / ttl);
		return SColor(alpha, color.getRed(), color.getGreen(), color.getBlue());
	}

	// get the position of the message. Store it to the object if no pos is already set. This allows us to do the
	// hovering above where it was picked effect. Finally, slowly make it rise by decreasing by a multiple of the ticker
	private Vec2f getPos(CBlob@ blob, string m, int i)
	{
		if (ypos == 0.0)
		{
			Vec2f pos2d = blob.getInterpolatedScreenPos();
			int top = pos2d.y - 2.5f * blob.getHeight() - 20.0f;
			Vec2f dim;
			GUI::GetTextDimensions(m , dim);
			dim.x = Maths::Min(dim.x, 200.0f);
			xpos = pos2d.x - dim.x / 2;
			ypos = top - 2 * dim.y - i * dim.y;
		}

		ypos -= renderticker / 40.0f;
		return Vec2f(xpos, ypos);
	}

	// Singularize, or de-pluralize, a string
	private string singularize(string str)
	{
		uint len = str.length();
		string lastChar = str.substr(len - 1);

		if (lastChar == "s")
		{
			str = str.substr(0, len - 1);
		}

		return str;
	}
};

HoverMessage@ addMessage(CBlob@ this, HoverMessage@ m)
{
	HoverMessage[]@ messages;
	if (!this.get("messages", @messages))
	{
		@messages = HoverMessage[]();
		this.set("messages", messages);
	}

	for (uint i = 0; i < messages.length; i++)
	{
		HoverMessage @message = messages[i];

		//merging messages
		if ((message.merge_id != 0 && message.merge_id == m.merge_id) ||
			message.name == m.name)
		{
			message.quantity += m.quantity;
			message.name = m.name;
			message.ticker = 0;
			message.ypos = 0.0;
			return message;
		}
	}

	this.push("messages", m);
	return m;
}
