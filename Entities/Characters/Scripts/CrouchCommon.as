//used to determine if a player is crouching or not
//(not safe to use before their logic script has been run during ontick)
bool isCrouching(CBlob@ this)
{
	return
		//must be on ground and pressing down
		this.isOnGround()
		&& this.isKeyPressed(key_down)
		//cannot have movement intent
		&& !this.isKeyPressed(key_left)
		&& !this.isKeyPressed(key_right)
		//cannot have banned crouch (done in actor logic scripts)
		&& !this.hasTag("prevent crouch");
}
