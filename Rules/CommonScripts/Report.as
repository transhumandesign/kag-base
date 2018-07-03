// report logic
// wip

#include "Spectator.as"

bool isSpectating = false;

void test(string message)
{
    print("Hi, " + message);
}

void report(CPlayer@ reportedPlayer, string reportedUsername, string reportedCharactername)
{
    print("Reporting " + reportedUsername);
    print("Reporting " + reportedPlayer.getUsername());
    print("Reporting " + reportedPlayer.getCharacterName());
    print("Reporting " + reportedPlayer.getTeamNum());
    print("Reporting " + reportedUsername);

	//tag player as reported
	reportedPlayer.Tag("reported");

    //get all players in server
    CBlob@[] allBlobs;
	getBlobs(@allBlobs);
	CPlayer@[] allPlayers;

    for (u32 i = 0; i < allBlobs.length; i++)
	{
		if(allBlobs[i].hasTag("player"))
		{
			allPlayers.insertLast(allBlobs[i].getPlayer());
		}
    }

	//print message to mods
	for (u32 i = 0; i < allPlayers.length; i++)
	{
		if(allPlayers[i].isMod())
		{
			print("You're mod");
			client_AddToChat("Report has been made of: " + reportedUsername, SColor(255, 255, 0, 0));
			Sound::Play("/ReportSound.ogg");
		}
	}
}

void moderate(CPlayer@ moderator, CPlayer@ targetPlayer, string targetUsername, string targetCharactername)
{
	int specTeam = getRules().getSpectatorTeamNum();
	CBlob@ blob = moderator.getBlob();
	blob.server_SetPlayer(null);
	blob.server_Die();
	moderator.client_ChangeTeam(specTeam);

	followTarget(targetPlayer);
	isSpectating = true;
}

void followTarget(CPlayer@ targetPlayer)
{
	CCamera@ camera = getCamera();
	CBlob@ targetBlob = targetPlayer !is null ? targetPlayer.getBlob() : null;

	if (targetBlob !is null)
	{
		SetTargetPlayer(targetPlayer);
	}
	else
	{
		camera.setTarget(null);

	}
}

void onRender(CRules@ this, CPlayer@ targetPlayer)
{
	if(isSpectating)
	{
		if (targetPlayer !is null && getLocalPlayerBlob() is null)
		{
			GUI::SetFont("menu");
			GUI::DrawText(
				getTranslatedString("Following {CHARACTERNAME} ({USERNAME})")
				.replace("{CHARACTERNAME}", targetPlayer.getCharacterName())
				.replace("{USERNAME}", targetPlayer.getUsername()),
				Vec2f(getScreenWidth() / 2 - 90, getScreenHeight() * (0.2f)),
				Vec2f(getScreenWidth() / 2 + 90, getScreenHeight() * (0.2f) + 30),
				SColor(0xffffffff), true, true
			);
		}

		GUI::SetFont("menu");

		string text = "";

		text = "You can use the movement keys and clicking to move the camera.";

		if (text != "")
		{
			//translate
			text = getTranslatedString(text);
			//position post translation so centering works properly
			Vec2f ul, lr;
			ul = Vec2f(getScreenWidth() / 2.0, 3.0 * getScreenHeight() / 4);
			Vec2f size;
			GUI::GetTextDimensions(text, size);
			ul -= size * 0.5;
			lr = ul + size;
			//wiggle up and down
			f32 wave = Maths::Sin(getGameTime() / 10.0f) * 5.0f;
			ul.y += wave;
			lr.y += wave;
			//draw
			GUI::DrawButtonPressed(ul - Vec2f(10, 10), lr + Vec2f(10, 10));
			GUI::DrawText(text, ul, SColor(0xffffffff));
		}
	}
}
