/* 
	quick dirty pop-up GUI with 2 buttons for the rebuild poll written by Bunnie
	can be safely removed from CTF gamemode.cfg && Base after the poll is done 
	start date: 5.11.2022
	end date: 18.11.2022
	(Need to talk to Verra about activating the poll before updating)
*/

#define CLIENT_ONLY

bool hide = true;

class PopupGUI
{
	string text1 = "A big balance update has been released recently.\n\nPlease take a moment to participate in the poll linked below.\n\n(You will have to log in to kagstats.com using your KAG account.)\n\nThe poll contains questions regarding all the meaningful changes.\n\nWhether a change stays or not will depend on the results of this poll.";
	string text2 = "kagstats.com/#/survey\n";
	string text3 = "This window will automatically close in $S seconds.";
	ClickButton@ website_button;
	string website_text = "Take me there!";
	Vec2f website_text_dim;
	ClickButton@ close_button;
	string close_text = "x"; // nobody will give a fuck
	Vec2f text_dim_1;
	Vec2f text_dim_2;
	Vec2f text_dim_3;
	Vec2f button_dim;

	Vec2f total_dim;

	Vec2f center;
	Vec2f tl;
	Vec2f tr;
	Vec2f bl;
	Vec2f br;

	PopupGUI()
	{
		GUI::SetFont("menu");
		GUI::GetTextDimensions(text1, text_dim_1);
		GUI::GetTextDimensions(text2, text_dim_2);
		GUI::GetTextDimensions(text3, text_dim_3);
		total_dim = text_dim_1 + Vec2f(0, text_dim_2.y) + Vec2f(0, text_dim_3.y) + Vec2f(20, 0);

		GUI::SetFont("slightly bigger text 2");
		GUI::GetTextDimensions(website_text, website_text_dim);

		this.Update(null);
		@website_button = ClickButton(0, SColor(255, 0, 170, 0), website_text, "slightly bigger text 2");
		@close_button = ClickButton(1, SColor(255, 200, 0, 0), "X");
	}

	void RenderGUI()
	{
		GUI::SetFont("menu");
		GUI::DrawPane(tl, br, SColor(255, 200, 200, 200));

		u32 seconds_left = (banner_time - start_time) / getTicksASecond();

		GUI::DrawText(text1, tl + Vec2f(10, 10), color_white);
		GUI::DrawText(text2, tl + Vec2f(total_dim.x / 2 - text_dim_2.x / 2, text_dim_1.y - 3), SColor(255, 230, 100, 230));
		GUI::DrawText(text3.replace("$S", "" + seconds_left), tl + Vec2f(total_dim.x / 2 - text_dim_3.x / 2, text_dim_1.y + text_dim_2.y), color_white);

		Vec2f button_tl = bl;

		website_button.RenderGUI(button_tl, Vec2f(total_dim.x, website_text_dim.y * 2));
		close_button.RenderGUI(tr - Vec2f(24, 0), Vec2f(24, 24));
	}

	void Update(CControls@ controls)
	{
		center = Vec2f(getScreenWidth() / 2, getScreenHeight() / 2);
		tl = center - Vec2f(total_dim.x / 2, total_dim.y / 2);
		tr = center + Vec2f(total_dim.x / 2, -total_dim.y / 2);
		bl = center - Vec2f(total_dim.x / 2, -total_dim.y / 2 - 20);
		br = center + Vec2f(total_dim.x / 2, total_dim.y / 2 + 20);

		Vec2f button_tl = bl;

		if (controls is null) return;

		website_button.Update(button_tl, Vec2f(total_dim.x, website_text_dim.y * 2), controls);
		close_button.Update(tr - Vec2f(24, 0), Vec2f(24, 24), controls);
	}
}

class ClickButton
{
	u8 id;
	bool hovered;
	SColor color;
	string text;
	string font;

	ClickButton(int _id, SColor _color, string _text, string _font="menu")
	{
		id = _id;
		color = _color;
		text = _text;
		font = _font;
		hovered = false;
	}

	bool isHovered(Vec2f origin, Vec2f size, Vec2f mousepos)
	{
		Vec2f tl = origin;
		Vec2f br = origin + size;

		return (mousepos.x > tl.x && mousepos.y > tl.y &&
		        mousepos.x < br.x && mousepos.y < br.y);
	}

	void RenderGUI(Vec2f origin, Vec2f size)
	{
		SColor new_color = color;

		if (hovered)
		{
			f32 tint_factor = 0.80;
			new_color = color.getInterpolated(color_white, tint_factor);
		}

		GUI::DrawPane(origin, origin+size, new_color);

		Vec2f text_pos = Vec2f(origin.x + size.x / 2, origin.y + size.y / 2);

		if (id == 1) text_pos -= Vec2f(2, 0); // as i said, nobody will give a fuck

		GUI::SetFont(font);
		GUI::DrawTextCentered(text, text_pos, color_white);
	}

	void Update(Vec2f origin, Vec2f size, CControls@ controls)
	{
		if (controls is null) return;

		Vec2f mousepos = controls.getMouseScreenPos();
		const bool mousePressed = controls.isKeyPressed(KEY_LBUTTON);
		const bool mouseJustReleased = controls.isKeyJustReleased(KEY_LBUTTON);

		if (hovered == false && this.isHovered(origin, size, mousepos) == true)
		{
			Sound::Play("select.ogg");
		}

		hovered = this.isHovered(origin, size, mousepos);

		if (hovered && mouseJustReleased)
		{
			hide = true;
			if (id == 0) OpenWebsite("https://kagstats.com/#/survey");
			Sound::Play("buttonclick.ogg");
		}
	}
}

PopupGUI@ rebuild_gui;

u32 start_time = 0;
u32 banner_time = 20 * getTicksASecond(); // 20 seconds

void onInit(CRules@ this)
{
	if (Time() > 1667602800 && Time() < 1668726000)
	{
		hide = false;
		if (!GUI::isFontLoaded("slightly bigger text 2"))
		{
			string font = CFileMatcher("AveriaSerif-Bold.ttf").getFirst();
			GUI::LoadFont("slightly bigger text 2", font, 36, true);
		}

		PopupGUI@ GUI = PopupGUI();
		this.set("popupgui", @GUI);
	}
	else 
	{
		hide = true;
	}
}

void onTick(CRules@ this)
{
	if (getLocalPlayer() !is null)
	{
		CControls@ controls = getControls();

		if (!hide)
		{
			if (start_time >= banner_time)
			{
				hide = true;
				return;
			}

			start_time++;
			PopupGUI@ GUI;
			this.get("popupgui", @GUI);
			if (GUI is null) 
			{
				return;
			}

			GUI.Update(controls);
		}
	}
}

void onRender(CRules@ this)
{
	PopupGUI@ GUI;
	this.get("popupgui", @GUI);
	if (GUI is null) 
	{
		PopupGUI@ GUI = PopupGUI();
		this.set("popupgui", @GUI);
		return;
	}

	if (!hide)
	{
		GUI.RenderGUI();
	}
}
