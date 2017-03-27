// Research

#include "Help.as"
#include "WARCosts.as"
#include "ScrollCommon.as"
#include "WAR_Structs.as"
#include "RulesCore.as"
#include "ResearchCommon.as"

const int OPT_TICK = 15;

void onInit( CBlob@ this )
{
	this.addCommandID("research");
	this.addCommandID("use scroll");   	
	this.addCommandID("show research");	
	this.addCommandID(tech_vote_cmd);

	this.getCurrentScript().tickFrequency = OPT_TICK;

	this.Tag("update_paths");
	this.Tag("research");

	ResearchStatus stat;
	this.set( "techs", @stat );
	
	// only 1 research room allowed
	ScrollSet@ scrolls;
	// get new scrolls from rules		
	@scrolls = getScrollSet( "all scrolls" );		
	if (scrolls !is null)
	{
		ResearchStatus@ stat;
		this.get( "techs", @stat );
		ScrollSet@ set = stat.scrolls;	   			
		for (uint i = 0; i < scrolls.names.length; i++)
		{	  
			const string defname = scrolls.names[i];
			ScrollDef@ def;
			scrolls.scrolls.get( defname, @def);
			if (def !is null && def.level >= 0.0f)
			{
				copyFrom( scrolls.scrolls, defname, set.scrolls );
				set.names.push_back( defname );
			}
		}
		
		stat.team = this.getTeamNum();
		stat.GenerateResearchersFromScrolls();
	}  
	else
		warn("Research: No research techs found");
}

void onTick( CBlob@ this )
{
	const u32 gametime = getGameTime();
	int teamNum = this.getTeamNum();
	
	ResearchStatus@ stat;
	this.get( "techs", @stat );
	if (stat is null)
		return;
	
	if(this.hasTag("update_paths"))
	{
		stat.FindPathsFromVotes();
		this.Untag("update_paths");
	}
	
	if (getRules().isMatchRunning())
	{
		for (uint i = 0; i < stat.researchers.length; i++)
		{	  
			ResearchPoint@ r = stat.researchers[i];
			if (getRules().exists("tutorial")){
				r.Update(stat.scrolls, OPT_TICK*5.0f);
			}
			else
			if (getNet().isServer() && getNet().isClient() && !getRules().exists("singleplayer")) // localhost fast for testing
				r.Update(stat.scrolls, OPT_TICK*30.0f);
			else
			r.Update(stat.scrolls, OPT_TICK*1.0f);
		}
	}
}

void GetButtonsFor( CBlob@ this, CBlob@ caller )
{
	// add button for adding scroll if caller has it

	CBitStream params;
	params.write_u16( caller.getNetworkID() );	
	if (this.getTeamNum() != 255 && caller.getTeamNum() == this.getTeamNum())
	{
		CBlob@ carried = caller.getCarriedBlob();
		bool overlapping = this.isOverlapping(caller);
		Vec2f offset = !overlapping ? Vec2f_zero : Vec2f(-12, -7);
		if ( overlapping && carried !is null && carried.getName() == "scroll" && carried.hasTag("tech"))
		{
			params.write_u16( carried.getNetworkID() );
			caller.CreateGenericButton( "$scroll$", offset, this, this.getCommandID("use scroll"), "Use scroll", params );
		}
		else
		{
			caller.CreateGenericButton(27, offset, this, this.getCommandID("show research"), "Research", params );
		}
	}
	
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	bool isServer = getNet().isServer();
								 												 
	if (isServer && cmd == this.getCommandID("use scroll"))
	{
		u16 callerID;
		if (!params.saferead_netid(callerID))
			return;
		u16 scrollID;
		if (!params.saferead_netid(scrollID))
			return;
		CBlob@ caller = getBlobByNetworkID( callerID );	 		
		CBlob@ scroll = getBlobByNetworkID( scrollID );	 		
		if (caller !is null && scroll !is null)
		{	
			if (this.server_PutInInventory( scroll )) {
			}
		}
	}
	else if (cmd == this.getCommandID(tech_vote_cmd))
	{
		string name, tech;
		if(!params.saferead_string(name))
			return;
		if(!params.saferead_string(tech))
			return;
		
		ResearchStatus@ stat;
		this.get( "techs", @stat );
		if (stat is null)
			return;

		ScrollSet@ scrolls = stat.scrolls;
		
		ScrollDef@ def;
		scrolls.scrolls.get( tech, @def);
		if (def !is null)
		{
			def.toggleVote(name);
			this.Tag("update_paths"); 
		}
	}
	else if (cmd == this.getCommandID("show research"))
	{
		u16 callerID;
		if (!params.saferead_netid(callerID))
			return;
		CBlob@ caller = getBlobByNetworkID( callerID );	 		
		if (caller !is null && caller.isMyPlayer())
		{
			this.Tag("show research");
		}
	}
}
		  
void onAddToInventory( CBlob@ this, CBlob@ blob )
{
	if (blob.hasTag("tech"))
	{			
		ResearchStatus@ stat;
		this.get( "techs", @stat );
		if (stat !is null)
		{
			ScrollSet@ scrolls = stat.scrolls;	   		
			ScrollDef@ def;

			// traverse scroll defname0 scroll defname1 scroll defname2 ...
			uint i = 0;
			while (blob.exists("scroll defname"+i))
			{
				scrolls.scrolls.get( blob.get_string("scroll defname"+i), @def);
				if (def !is null && !def.hasTech()) 
				{
					def.special_unlock = true;
					ResearchCompleteNotify( def, this.getTeamNum() );
				}	
				i++;
			}
		}
	}
}

void onChangeTeam( CBlob@ this, const int oldTeam )
{
	ResearchStatus@ stat;
	this.get( "techs", @stat );
	if (stat !is null)
	{
		stat.ChangeResearchersTeam( this.getTeamNum() );
	}	
}

// network

void onSendCreateData( CBlob@ this, CBitStream@ stream )
{	 
	ResearchStatus@ stat;
	this.get( "techs", @stat );
	if (stat !is null) {
		stat.Serialise(stream);
	}
	else
		warn("Researching.as: no techs in onSendCreateData "); 
}

bool onReceiveCreateData( CBlob@ this, CBitStream@ stream )
{
	this.Tag("update_paths");
					
	ResearchStatus @stat;
	this.get( "techs", @stat );
	return stat.Unserialise(stream);
}
