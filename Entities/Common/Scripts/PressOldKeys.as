
void PressOldKeys(CBlob@ this)
{
	if (this.wasKeyPressed(key_left))
		this.setKeyPressed(key_left, true);
	if (this.wasKeyPressed(key_right))
		this.setKeyPressed(key_right, true);
	if (this.wasKeyPressed(key_up))
		this.setKeyPressed(key_up, true);
	if (this.wasKeyPressed(key_down))
		this.setKeyPressed(key_down, true);

	if (this.wasKeyPressed(key_action1))
		this.setKeyPressed(key_action1, true);
	if (this.wasKeyPressed(key_action2))
		this.setKeyPressed(key_action2, true);
	if (this.wasKeyPressed(key_action3))
		this.setKeyPressed(key_action3, true);

	if (this.wasKeyPressed(key_use))
		this.setKeyPressed(key_use, true);
	if (this.wasKeyPressed(key_inventory))
		this.setKeyPressed(key_inventory, true);
	if (this.wasKeyPressed(key_pickup))
		this.setKeyPressed(key_pickup, true);

	if (this.wasKeyPressed(key_bubbles))
		this.setKeyPressed(key_bubbles, true);
	if (this.wasKeyPressed(key_eat))
		this.setKeyPressed(key_eat, true);
	if (this.wasKeyPressed(key_taunts))
		this.setKeyPressed(key_taunts, true);
	if (this.wasKeyPressed(key_map))
		this.setKeyPressed(key_map, true);

}
