bool isCrouching(CBlob@ this)
{
	return
		this.isOnGround() &&
		this.isKeyPressed(key_down) &&
		!this.isKeyPressed(key_left) &&
		!this.isKeyPressed(key_right) &&
		(( // normal crouch check
			!this.isKeyPressed(key_action1) &&
			(!this.isKeyPressed(key_action2) || this.getName() == "archer") // archer grapple special case
		) || this.hasTag("allow crouch"));
}
