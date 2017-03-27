const string delay_property = "brain_delay";
const string state_property = "brain_state";

const string target_property = "brain_target_id";
const string friend_property = "brain_friend_id";

const string target_searchrad_property = "brain_target_rad";

const string terr_pos_property = "brain_territory_pos";
const string terr_rad_property = "brain_territory_rad";

const string personality_property = "brain_personality";

const string target_lose_random = "target_lose_random";

const u8 	AGGRO_BIT		= 0x1;
const u8 	SCARED_BIT		= 0x2;
const u8	STILL_IDLE_BIT	= 0x4;
const u8 	TAMABLE_BIT	= 0x8;
const u8 	DONT_GO_DOWN_BIT	= 0x10;

enum modes
{
	MODE_IDLE = 0,
	MODE_TARGET,
	MODE_FLEE,
	MODE_FRIENDLY
}

shared class AnimalVars
{
	Vec2f walkForce;
	Vec2f runForce;
	Vec2f slowForce;
	Vec2f jumpForce;
	f32 maxVelocity;
};
