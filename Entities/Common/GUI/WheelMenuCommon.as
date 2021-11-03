namespace WheelMenu
{
	const SColor active_color(0xFFFFFFFF);
	const SColor inactive_color(0xFFAAAAAA);

	const SColor background_color(40, 0, 0, 0);

	const SColor fadeout_inner_color(30, 255, 255, 255);
	const SColor fadeout_outer_color(0, 255, 255, 255);

	const SColor pane_title_color(0xFFCCCCCC);
	const SColor pane_text_color(0xFFFFFFFF);

	const float hover_distance = 0.07f;
	const float auto_selection_distance = 0.3f;

	const Vec2f center_pane_padding(16.0f, 32);
	const Vec2f center_pane_text_margin(0.0f, 12.0f);
	const float center_pane_min_width = 128.0f;
}

// Basic text menu entry. Can be extended with inheritance; override render() for your own logic
class WheelMenuEntry
{
	// Identifier for the entry, never displayed
	string name;
	float item_distance = 0.4f;

	WheelMenuEntry(const string&in p_name)
	{
		name = p_name;
	}

	// Visual parameters
	string visible_name;

	// Other state, also useful to wheelmenu
	float angle_min, angle_max;
	Vec2f position;
	bool hovered;

	SColor get_color()
	{
		return hovered ? WheelMenu::active_color : WheelMenu::inactive_color;
	}

	void update(float angle, float step)
	{
		angle_min = angle;
		angle_max = angle + step;

		float angle_mid = (angle_min + angle_max) / 2.0f;
		float distance = getDriver().getScreenHeight() * item_distance;
		Vec2f origin = getDriver().getScreenCenterPos();

		position = origin - Vec2f(Maths::Cos(angle_mid), Maths::Sin(angle_mid)) * distance;
	}

	void render()
	{
		GUI::DrawTextCentered(visible_name, position, get_color());
	}
};

class IconWheelMenuEntry : WheelMenuEntry
{
	// Visual parameters
	string texture_name;
	int frame;
	Vec2f frame_size;
	Vec2f offset;
	float scale;

	IconWheelMenuEntry(const string&in p_name)
	{
		super(p_name);
	}

	void render() override
	{
		GUI::DrawIcon(
			texture_name,
			frame,
			frame_size,
			position + (offset - frame_size * 0.5f) * scale * 2.0f,
			scale,
			get_color()
		);
	}
};

class PickupWheelOption
{
	string name;

	// If two options are available with a different priority, regardless of score, we pick the one with the highest priority.
	uint priority;

	PickupWheelOption(const string&in p_name, uint p_priority = 0)
	{
		name = p_name;
		priority = p_priority;
	}
};

class PickupWheelMenuEntry : WheelMenuEntry
{
	// Visual parameters
	string icon_name;
	float scale;
	bool disabled;
	PickupWheelOption[] options;
	Vec2f offset;

	PickupWheelMenuEntry(const string&in p_name, const string&in p_icon_name, const string&in p_option, Vec2f p_offset = Vec2f(0, 0))
	{
		this = PickupWheelMenuEntry(p_name, p_icon_name, PickupWheelOption[](1, PickupWheelOption(p_option)), p_offset);
	}

	PickupWheelMenuEntry(const string&in p_name, const string&in p_icon_name, PickupWheelOption[] p_options, Vec2f p_offset = Vec2f(0, 0))
	{
		super(p_name);
		visible_name = p_name;
		icon_name = p_icon_name;
		options = p_options;
		scale = 1.0f;
		disabled = false;
		offset = p_offset;
		item_distance = 0.25f; // override
	}

	void render() override
	{
		if (disabled)
		{
			return;
		}

		GUI::DrawIcon(
			"InteractionIconsBackground.png",
			0,
			Vec2f(32, 32),
			position - Vec2f(32, 32)*1.5,
			1.5f
		);

		GUI::DrawIconByName(
			icon_name,
			position + offset - Vec2f(16, 16),
			scale
		);
	}
};

class WheelMenu
{
	WheelMenuEntry@[] entries;
	WheelMenuEntry@ hovered;
	string option_notice;

	WheelMenu()
	{
		option_notice = getTranslatedString("Select option");
	}

	float angle_step()
	{
		return !entries.isEmpty() ? Maths::Pi * 2.0f / float(entries.length) : 0.0f;
	}

	WheelMenuEntry@ get_entry_from_position(const Vec2f&in cursor)
	{
		if (entries.isEmpty()) return null;

		Vec2f offset = getDriver().getScreenCenterPos() - cursor;
		float angle = Maths::ATan2(offset.y, offset.x) + angle_step() / 2.0f;

		if (angle < 0.0f)
		{
			angle += 2.0f * Maths::Pi;
		}

		uint entry_id = (angle / (Maths::Pi * 2.0f)) * entries.length;

		if (entry_id >= 0 && entry_id < entries.length)
		{
			return @entries[entry_id];
		}

		return null;
	}

	bool is_cursor_in_range(const Vec2f&in cursor, float min_distance)
	{
		Vec2f offset = getDriver().getScreenCenterPos() - cursor;
		return offset.getLength() >= (getDriver().getScreenDimensions().getLength() * min_distance);
	}

	void determine_hovered()
	{
	    WheelMenuEntry@ previously_hovered = @hovered;

		@hovered = null;

		Vec2f cursor = getControls().getMouseScreenPos();

		// ignore cursor at center of the screen
		if (is_cursor_in_range(cursor, WheelMenu::hover_distance))
		{
			@hovered = get_entry_from_position(cursor);

            if (previously_hovered !is hovered)
			{
			    Sound::Play("select.ogg");
			}
		}
	}

	void update()
	{
		const float step = angle_step();

		// Modify the angle by half a step so the first item is properly aligned
		float angle = -step / 2.0f;

		for (uint i = 0; i < entries.length; ++i)
		{
			entries[i].update(angle, step);
			angle += step;
		}

		determine_hovered();
	}

	// Displays a gradient effect over the currently hovered item.
	void draw_hover_effect()
	{
		Driver@ driver = getDriver();
		Vec2f origin = driver.getScreenCenterPos();
		float ray_distance = driver.getScreenDimensions().getLength() / 2.0f;

		if (hovered !is null)
		{
			Vertex[] vertices;

			// Center vertex
			vertices.push_back(Vertex(
				driver.getWorldPosFromScreenPos(origin),
				0.0f,
				Vec2f(0.0f, 0.0f),
				WheelMenu::fadeout_inner_color
			));

			// Small angle vertex
			Vec2f min_direction(Maths::Cos(hovered.angle_min), Maths::Sin(hovered.angle_min));
			vertices.push_back(Vertex(
				driver.getWorldPosFromScreenPos(origin - min_direction * ray_distance),
				0.0f,
				Vec2f(1.0f, 0.0f),
				WheelMenu::fadeout_outer_color
			));

			// Large angle vertex
			Vec2f max_direction(Maths::Cos(hovered.angle_max), Maths::Sin(hovered.angle_max));
			vertices.push_back(Vertex(
				driver.getWorldPosFromScreenPos(origin - max_direction * ray_distance),
				0.0f,
				Vec2f(0.0f, 1.0f),
				WheelMenu::fadeout_outer_color
			));

			Render::RawTriangles("pixel", vertices);
		}
	}

	// Returns the given pane_size vector widened if necessary to fit in the text
	Vec2f extend_pane(const Vec2f&in pane_size, string text)
	{
		Vec2f text_size;
		GUI::GetTextDimensions(text, text_size);
		return Vec2f(Maths::Max(pane_size.x, text_size.x + WheelMenu::center_pane_padding.x * 2.0f), pane_size.y);
	}

	// Draws the center pane, which shows a simple title and the currently selected item name
	void draw_center_pane()
	{
		Vec2f origin = getDriver().getScreenCenterPos();

		string hover_text = (hovered !is null ? hovered.visible_name : getTranslatedString("(no selection)"));

		Vec2f pane_size(WheelMenu::center_pane_min_width, WheelMenu::center_pane_padding.y * 2.0f);
		pane_size = extend_pane(pane_size, hover_text);
		pane_size = extend_pane(pane_size, option_notice);

		GUI::DrawFramedPane(origin - pane_size / 2.0f, origin + pane_size / 2.0f);

		GUI::DrawTextCentered(option_notice, origin - WheelMenu::center_pane_text_margin, WheelMenu::pane_title_color);
		GUI::DrawTextCentered(hover_text, origin + WheelMenu::center_pane_text_margin, WheelMenu::pane_text_color);
	}

	// Render the wheel menu, including its items.
	// This has to be called from a render script, otherwise the hover effect will not work.
	void render()
	{
		GUI::DrawRectangle(Vec2f_zero, getDriver().getScreenDimensions(), WheelMenu::background_color);

		draw_hover_effect();
		draw_center_pane();

		for (int i = 0; i < entries.length; ++i)
		{
			entries[i].hovered = (entries[i] is hovered);
			entries[i].render();
		}
	}

	// Checking the user input.
	// Note that WheelMenu itself doesn't care about managing your select events.
	// 'auto_selection' determines the user input for when you want to do autoselect,
	// i.e. when hovering an option selects it automatically.
	WheelMenuEntry@ get_selected(bool auto_selection = false)
	{
	    WheelMenuEntry@ entry = null;

		if (auto_selection)
		{
			Vec2f origin = getDriver().getScreenCenterPos();

			if (is_cursor_in_range(getControls().getMouseScreenPos(), WheelMenu::auto_selection_distance))
			{
			    @entry = @hovered;
			}
		}
		else
		{
		    @entry = @hovered;
		}

        if (entry !is null)
		{
		    Sound::Play("buttonclick.ogg");
		}

        return @entry;
	}

	void add_entry(WheelMenuEntry@ entry)
	{
		entries.push_back(@entry);
	}

	void remove_entry(WheelMenuEntry@ entry)
	{
		int offset = entries.find(@entry);

		if (offset != -1)
		{
			entries.erase(offset);
		}
	}
};

string make_wheel_menu_property(const string&in name)
{
	return "wheel menu " + name;
}

void set_active_wheel_menu(WheelMenu@ menu)
{
	getRules().set("active wheel menu", @menu); // menu can be null

	if (menu !is null)
	{
		getControls().setMousePosition(getDriver().getScreenCenterPos());
	}
}

WheelMenu@ get_active_wheel_menu()
{
	WheelMenu@ menu;
	getRules().get("active wheel menu", @menu);
	return @menu;
}

WheelMenu@ get_wheel_menu(const string &in name)
{
	CRules@ rules = getRules();

	string prop = make_wheel_menu_property(name);

	WheelMenu@ menu;
	rules.get(prop, @menu);

	if (menu is null)
	{
		debug("Creating wheel menu '" + name + "'");

		WheelMenu new_menu;
		rules.set(prop, @new_menu);
		return @new_menu;
	}

	return @menu;
}

void remove_wheel_menu(const string &in name)
{
	getRules().clear(make_wheel_menu_property(name));
}
