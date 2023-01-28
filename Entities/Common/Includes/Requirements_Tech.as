// I split tech requirement checking because the headers are LARGE

#include "Requirements.as"
#include "ResearchCommon.as"

bool hasRequirements_Tech( CInventory@ inv, CBitStream &inout bs, CBitStream &inout missingBs )
{
	return (hasRequirements_Tech( inv, null, bs, missingBs ));
}

/**
 * A note if you use fake techs:
 * be sure to add UseFakeTechs.as to your rules :)
 */

void RemoveFakeTechs(CRules@ this)
{
	string[]@ technames;
	this.get("_faketech", @technames);
	if (technames !is null)
	{
		for(uint i = 0; i < technames.length; ++i)
		{
			string name = technames[i];
			this.set_bool(name, false);
			this.Sync(name, true);
		}

		technames.clear();
	}
}

/**
 * A note if you use fake techs:
 * be sure to add UseFakeTechs.as to your rules :)
 */
void GiveFakeTech( CRules@ this, const string tech, const int teamnum)
{
	if (!HasFakeTech( this, tech, teamnum))
	{
		const string name = tech+teamnum;
		this.set_bool(name, true);
		this.Sync(name, true);
		string[]@ technames;
		this.get("_faketech", @technames);
		if (technames !is null)
		{
			technames.push_back(name);
		}
		else
		{
			string[] newtechnames;
			newtechnames.push_back(name);
			this.set("_faketech", newtechnames);
		}
	}
}

/**
 * A note if you use fake techs:
 * be sure to add UseFakeTechs.as to your rules :)
 */
bool HasFakeTech( CRules@ this, const string tech, const int teamnum)
{
	const string name = tech+teamnum;
	if (this.exists(name))
		return this.get_bool(name);

	return false;
}

bool hasRequirements_Tech( CInventory@ inv1, CInventory@ inv2, CBitStream &inout bs, CBitStream &inout missingBs )
{
	string req, blobName, friendlyName;
	u16 quantity = 0;
	missingBs.Clear();
	bs.ResetBitIndex();
	bool has = true;

	while (!bs.isBufferEnd())
	{
		ReadRequirement( bs, req, blobName, friendlyName, quantity );

		bool want_tech = (req == "tech");
		bool techreq = (want_tech || req == "not tech");
		if (techreq && inv1 !is null)
		{
			bool hasTech = false;
			int teamNum = inv1.getBlob().getTeamNum();

			if (HasFakeTech(getRules(), blobName, teamNum))
			{
				hasTech = true;
			}
			else
			{
				CBlob@[] researchs;
				if (getBlobsByTag( "research", @researchs ))
				{
					for (uint step = 0; step < researchs.length; ++step)
					{
						CBlob@ research = researchs[step];
						if (research.getTeamNum() == teamNum)
						{
							if (hasResearchGotTech( research, blobName ))
							{
								hasTech = true;
								break;
							}
						}
					}
				}
			}

				// doesn't have and wants		has and doesn't want
			if ( (!hasTech && want_tech ) || (hasTech && !want_tech) )
			{
				AddRequirement( missingBs, req, blobName, friendlyName, quantity );
				has = false;
			}
		}
	}

	missingBs.ResetBitIndex();
	bs.ResetBitIndex();
	return has && hasRequirements( inv1, inv2, bs, missingBs );
}

void SetItemDescription_Tech( CGridButton@ button, CBlob@ caller, CBitStream &in reqs, const string& in description, CInventory@ anotherInventory = null )
{
	if (button !is null && caller !is null && caller.getInventory() !is null)
	{
		CBitStream missing;

		if (hasRequirements_Tech( caller.getInventory(), anotherInventory, reqs, missing )) {
			button.hoverText = description + "\n\n " + getButtonRequirementsText( reqs, false );
			button.SetEnabled( true );
		}
		else
		{
			button.hoverText = description + "\n\n " + getButtonRequirementsText( missing, true );
			button.SetEnabled( false );
		}
	}
}
