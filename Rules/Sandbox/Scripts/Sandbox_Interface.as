#include "CTF_Structs.as";

void onInit(CRules@ this)
{
}

void onRender(CRules@ this)
{
	CPlayer@ p = getLocalPlayer();

	if (p is null || !p.isMyPlayer()) { return; }

	string propname = "ctf spawn time " + p.getUsername();
	if (p.getBlob() is null && this.exists(propname))
	{
		u8 spawn = this.get_u8(propname);

		if (spawn != 255)
		{
			GUI::SetFont("menu");
			GUI::DrawText("Respawn in: " + spawn , Vec2f(getScreenWidth() / 2 - 70, getScreenHeight() / 3 + Maths::Sin(getGameTime() / 3.0f) * 5.0f), SColor(255, 255, 255, 55));
		}
	}
}
