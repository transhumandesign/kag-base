// Interface for sending Game Events with callbacks to be picked
// up by other code, for eg tracking stats or giving coins for
// obscure things.

funcdef void CGameplayEvent(CBitStream@);

enum CGameplayEvent_IDs
{
	//0 is error
	BuildBlock = 1,
	BuildBlob,
	HitVehicle,
	KillVehicle,
	CaptureFlag,
	End
};

void GE_BuildBlock(u16 player_id, u16 tile)
{
	CGameplayEvent@ onBuildBlock;
	CBitStream params;
	params.write_u8(CGameplayEvent_IDs::BuildBlock);
	params.write_u16(player_id);
	params.write_u16(tile);
	if (getRules().get("awardCoins handle", @onBuildBlock)) // CTF_Trading.as
	{
		onBuildBlock(params);
	}
}

void GE_BuildBlob(u16 player_id, string blobname)
{
	CGameplayEvent@ onBuildBlob;
	CBitStream params;
	params.write_u8(CGameplayEvent_IDs::BuildBlob);
	params.write_u16(player_id);
	params.write_string(blobname);
	if (getRules().get("awardCoins handle", @onBuildBlob)) // CTF_Trading.as
	{
		onBuildBlob(params);
	}
}

void GE_HitVehicle(u16 player_id, f32 dmg)
{
	CGameplayEvent@ onVehicleDamage;
	CBitStream params;
	params.write_u8(CGameplayEvent_IDs::HitVehicle);
	params.write_u16(player_id);
	params.write_f32(dmg);
	if (getRules().get("awardCoins handle", @onVehicleDamage)) // CTF_Trading.as
	{
		onVehicleDamage(params);
	}
}

void GE_KillVehicle(u16 player_id)
{
	CGameplayEvent@ onVehicleKill;
	CBitStream params;
	params.write_u8(CGameplayEvent_IDs::KillVehicle);
	params.write_u16(player_id);
	if (getRules().get("awardCoins handle", @onVehicleKill)) // CTF_Trading.as
	{
		onVehicleKill(params);
	}
}

void GE_CaptureFlag(u16 player_id)
{
	CGameplayEvent@ onFlagCap;
	CBitStream params;
	params.write_u8(CGameplayEvent_IDs::CaptureFlag);
	params.write_u16(player_id);
	if (getRules().get("awardCoins handle", @onFlagCap)) // CTF_Trading.as
	{
		onFlagCap(params);
	}
}