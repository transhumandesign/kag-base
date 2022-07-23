#define CLIENT_ONLY

#include "WheelMenuCommon.as"

void onInit(CRules@ rules)
{
	if (!Texture::exists("pixel"))
	{
		Texture::createFromFile("pixel", "pixel.png");
	}

	Render::addScript(Render::layer_posthud, "WheelMenu.as", "render", 0.0f);
}

void onTick(CRules@ rules)
{
	WheelMenu@ menu = get_active_wheel_menu();
	if (menu is null) return;
	
	menu.update();
}

void render(int)
{
	WheelMenu@ menu = get_active_wheel_menu();
	if (menu is null) return;

	GUI::SetFont("menu");
	menu.render();
}