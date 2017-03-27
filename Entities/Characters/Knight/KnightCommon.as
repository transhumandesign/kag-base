//common knight header
namespace KnightStates
{
	enum States
	{
		normal = 0,
		shielding,
		shielddropping,
		shieldgliding,
		sword_drawn,
		sword_cut_mid,
		sword_cut_mid_down,
		sword_cut_up,
		sword_cut_down,
		sword_power,
		sword_power_super
	}
}

namespace KnightVars
{
	const ::s32 resheath_time = 2;

	const ::s32 slash_charge = 15;
	const ::s32 slash_charge_level2 = 38;
	const ::s32 slash_charge_limit = slash_charge_level2 + slash_charge + 10;
	const ::s32 slash_move_time = 4;
	const ::s32 slash_time = 13;
	const ::s32 double_slash_time = 8;

	const ::f32 slash_move_max_speed = 3.5f;

	const u32 glide_down_time = 50;
}

shared class KnightInfo
{
	u8 swordTimer;
	u8 shieldTimer;
	bool doubleslash;
	u8 tileDestructionLimiter;
	u32 slideTime;

	u8 state;
	Vec2f slash_direction;
	s32 shield_down;
};


namespace BombType
{
	enum type
	{
		bomb = 0,
		water,
		count
	};
}

const string[] bombNames = { "Bomb",
                             "Water Bomb"
                           };

const string[] bombIcons = { "$Bomb$",
                             "$WaterBomb$"
                           };

const string[] bombTypeNames = { "mat_bombs",
                                 "mat_waterbombs"
                               };


//checking state stuff

bool isShieldState(u8 state)
{
	return (state >= KnightStates::shielding && state <= KnightStates::shieldgliding);
}

bool isSpecialShieldState(u8 state)
{
	return (state > KnightStates::shielding && state <= KnightStates::shieldgliding);
}

bool isSwordState(u8 state)
{
	return (state >= KnightStates::sword_drawn && state <= KnightStates::sword_power_super);
}

bool inMiddleOfAttack(u8 state)
{
	return ((state > KnightStates::sword_drawn && state <= KnightStates::sword_power_super));
}

//checking angle stuff

f32 getCutAngle(CBlob@ this, u8 state)
{
	f32 attackAngle = (this.isFacingLeft() ? 180.0f : 0.0f);

	if (state == KnightStates::sword_cut_mid)
	{
		attackAngle += (this.isFacingLeft() ? 30.0f : -30.0f);
	}
	else if (state == KnightStates::sword_cut_mid_down)
	{
		attackAngle -= (this.isFacingLeft() ? 30.0f : -30.0f);
	}
	else if (state == KnightStates::sword_cut_up)
	{
		attackAngle += (this.isFacingLeft() ? 80.0f : -80.0f);
	}
	else if (state == KnightStates::sword_cut_down)
	{
		attackAngle -= (this.isFacingLeft() ? 80.0f : -80.0f);
	}

	return attackAngle;
}

f32 getCutAngle(CBlob@ this)
{
	Vec2f aimpos = this.getMovement().getVars().aimpos;
	int tempState;
	Vec2f vec;
	int direction = this.getAimDirection(vec);

	if (direction == -1)
	{
		tempState = KnightStates::sword_cut_up;
	}
	else if (direction == 0)
	{
		if (aimpos.y < this.getPosition().y)
		{
			tempState = KnightStates::sword_cut_mid;
		}
		else
		{
			tempState = KnightStates::sword_cut_mid_down;
		}
	}
	else
	{
		tempState = KnightStates::sword_cut_down;
	}

	return getCutAngle(this, tempState);
}

//shared attacking/bashing constants (should be in KnightVars but used all over)

const int DELTA_BEGIN_ATTACK = 2;
const int DELTA_END_ATTACK = 5;
const f32 DEFAULT_ATTACK_DISTANCE = 16.0f;
const f32 MAX_ATTACK_DISTANCE = 18.0f;
const f32 SHIELD_KNOCK_VELOCITY = 3.0f;

const f32 SHIELD_BLOCK_ANGLE = 175.0f;
const f32 SHIELD_BLOCK_ANGLE_GLIDING = 140.0f;
const f32 SHIELD_BLOCK_ANGLE_SLIDING = 160.0f;