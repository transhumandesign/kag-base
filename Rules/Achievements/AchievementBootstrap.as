/// Handles adding the correct gamemode related achievement scripts
#define CLIENT_ONLY

void onInit(CRules@ this)
{
    // Required regardless of gamemode
    this.AddScript("BaseAchievements");

//    if (this.gamemode_name === "Team Deathmatch") {
        this.AddScript("TDMAchievements.as");
//    }
}