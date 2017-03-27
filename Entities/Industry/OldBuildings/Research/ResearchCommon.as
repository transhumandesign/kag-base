// Research 

// shared data

const string tech_vote_cmd = "tech vote";

// specific helper functions on scroll defs and sets + research points

#include "ScrollCommon.as"

shared bool hasResearchGotTech( CBlob@ this, const string &in tech ) 
{
	ResearchStatus@ stat;
	this.get( "techs", @stat );

	if (stat is null)
	{
		warn("Could not find set tech " + tech );
		return false;
	}

	ScrollSet@ set = stat.scrolls;
	for (uint i = 0; i < set.names.length; i++)
	{	  
		const string defname = set.names[i];
		if (defname == tech)
		{
			ScrollDef@ def;
			set.scrolls.get( defname, @def);
			if (def !is null) {
				return def.hasTech();
			}
		}
	}	
	return false;
}

shared u8 getVotes(const string &in name, const ScrollSet@ scrolls)
{
	ScrollDef@ temp;
	scrolls.scrolls.get(name, @temp);
	if (temp !is null) {
		return temp.votes;
	}
	return 0;
}

shared string highestVotedChild(const ScrollDef@ this, const ScrollSet@ scrolls)
{
	uint len = this.connections.length;
	s32 highest = -1; //default to first in array
	string result = "";
	for(uint i = 0; i < len; ++i)
	{
		string name = this.connections[i];
		s32 votes = getVotes(name, scrolls);
		if(votes > highest)
		{
			highest = votes;
			result = name;
		}
	}
	return result;
}

shared void ResearchCompleteNotify( ScrollDef@ def, const u8 team )
{	
	CPlayer@ player = getLocalPlayer();
	if (player !is null && player.getTeamNum() == team && !getNet().isServer())  // only on multiplayer
	{
		Sound::Play("/ResearchComplete.ogg");
		client_AddToChat( def.name + " available." );
	}	
}

shared bool canResearch( ScrollSet@ scrolls, const string &in name )
{			   
	for (uint i = 0; i < scrolls.names.length; i++)
	{	  
		const string defname = scrolls.names[i];
		ScrollDef@ def;
		scrolls.scrolls.get( defname, @def);
		
		//TODO: if we want to, distinguish between special unlocks and percent unlocks here
		if (def !is null && def.hasTech())
		{
			//vote based
			//if (name == highestVotedChild(def, scrolls))
			//{
				return true;
			//}
			//progression on all (off)
			/* for (uint j = 0; j < def.connections.length; j++)
			{
				const string nextName = def.connections[j];
				if (nextName == name)
					return true;
			}*/
		}
	}
	return false;
}

// classes

shared class ResearchPoint {
	
	string current;
	string target;
	string[] targets;
	u8 team;
	
	//allows passing in arrays
	ResearchPoint()
	{
		current = "";
		target = "";
		team = 255;
	}
	
	//logic
	
	void Update(ScrollSet@ scrolls, const int OPT_TICK)
	{
		if (team == 255)
			return;

		ScrollDef@ def;
		scrolls.scrolls.get( current, @def );
		
		if(def is null) return;
		
		bool research_current = false;
		if(!def.hasTech()) //semi-hack?
		{
			research_current = true;
		}
		else if(current == target && targets.length > 0)
		{
			target = targets[0];
			targets.erase(0);
		}
		
		if(target == "")
			return;
		
		if(!research_current)
		{
			scrolls.scrolls.get( target, @def );
		}
		if (def !is null && (canResearch( scrolls, target ) || research_current))
		{	
			def.researching = true;
			if (def.percent < 1.0f && def.timeSecs > 0)
			{
				// start research
				// calc research percentage
				def.percent += (f32(OPT_TICK)/f32(getTicksASecond()))/f32(def.timeSecs);
				if (def.percent >= 1.0f) {
					ResearchCompleteNotify( def, team );
				}
			}
			else
			{
				def.percent = 1.0f;		  				
			}
			
			if(def.hasTech())
			{
				if(def.connections.length > 0) //dead end?
					def.researching = false;
				
				current = target; //advance on next update
			}
		}
	}
	
	//net
	
	void Serialise(CBitStream@ stream)
	{
		stream.write_string(current);
		stream.write_string(target);
		//stream.write_u8(team);   // opt: read later
	}
	
	bool Unserialise(CBitStream@ stream)
	{
		if(!stream.saferead_string(current)) return false;
		if(!stream.saferead_string(target)) return false;
		//if(!stream.saferead_u8(team)) return false;  // opt
		
		return true;
	}
};

shared class ResearchStatus 
{
	ResearchPoint[] researchers;
	ScrollSet scrolls;
	u8 team;
	
	bool isResearching(const string &in tech, const string &in from)
	{
		for (uint i = 0; i < researchers.length; i++)
		{
			ResearchPoint@ p = researchers[i];
			if(p.current == from && p.target == tech)
				return true;
		}
		return false;
	}
	
	void GenerateResearchersFromScrolls()
	{
		researchers.clear();
		
		for (uint i = 0; i < scrolls.names.length; i++)
		{
			const string defname = scrolls.names[i];
			ScrollDef@ def;
			scrolls.scrolls.get( defname, @def );
			if (def !is null)
			{
				if(def.level <= 0.0f)
				{
					ResearchPoint p;
					p.current = defname;
					p.target = defname;
					p.team = team;
					researchers.push_back(p);
				}
			}
		}
	}

	void ChangeResearchersTeam( const int _team)
	{		
		team = _team;
		for (uint i = 0; i < researchers.length; i++)
		{
			researchers[i].team = _team;
		}
	}
	
	int GetVotesCovered(const string[][] &in names)
	{
		int votes = 0;
		string[] seen;
		for(uint i = 0; i < names.length; ++i)
		{
			const string[] current = names[i];
			for(uint j = 0; j < current.length; ++j)
			{
				const string defname = current[j];
				//would be nice if find() worked in string arrays :(
				bool found = false;
				for(uint k = 0; k < seen.length; k++)
				{
					if(seen[k] == defname)
					{
						found = true;
						
						votes -= 10; //try not to repeat covered ground
						
						break;
					}
				}
				if (!found)
				{
					seen.push_back(defname);
					ScrollDef@ def;
					scrolls.scrolls.get( defname, @def );
					if (def !is null)
					{
						votes += (def.votes * 100) + def.weight;
					}
				}
			}
		}
		return votes;
	}
	
	
	//get all possible paths (with a dead end) from "from"
	//depth first search with terminating nodes saved.
	//will not handle anything remotely resembling a cycle :) don't do it
	string[][] getAllPaths(string &in from)
	{
		string[][] res;
		string[] seen;
		string[] s = {from};
		while(s.length > 0)
		{
			string current = s[s.length-1];
			seen.push_back(current);
			
			ScrollDef@ def;
			scrolls.scrolls.get( current, @def );
			if (def !is null)
			{
				if(def.connections.length == 0)
				{
					//dead end
					res.push_back(s);
				}
				else
				{
					//search the children for undiscovered nodes
					bool skip = false;
					for(uint i = 0; i < def.connections.length; i++)
					{
						const string child = def.connections[i];
						
						//would be nice if find() worked in string arrays :(
						bool found = false;
						for(uint j = 0; j < seen.length; j++)
						{
							if(seen[j] == child)
							{
								found = true;
								break;
							}
						}
						
						if(found) continue;
						
						//otherwise...
						s.push_back(child);
						skip = true;
						break;
					}
					
					if(skip) continue;
					
					//else, remove connections from seen
					//so that they can be rexplored from other angles
					
					for(uint i = 0; i < def.connections.length; i++)
					{
						const string child = def.connections[i];
						
						//would be nice if find() worked in string arrays :(
						for(uint j = 0; j < seen.length; j++)
						{
							if(seen[j] == child)
							{
								seen.erase(j--);
							}
						}
					}
				}
				
			}

			s.pop_back();
		}
		return res;
	}
	
	//this function is crazy expensive.
	//seriously
	void FindPathsFromVotes()
	{
		// note that the research is generally a directed acyclic graph
		// (or it really should be, modders!)
		// this means we can use a straightforward depth first search 
		// with backtracking to find the best set of nodes
		
		// copy current research points (the targets of each researcher)
		// these cannot change, and are therefore our starting points.
		uint res_len = researchers.length;

		if (res_len == 0) {
			return;
		}

		string[] new_researchers;
		for(uint i = 0; i < res_len; ++i)
		{
			new_researchers.push_back(researchers[i].target);
		}
		
		//copy the arrays in here
		// 1d: researcher started at
		// 2d: paths found
		// 3d: string in path
		string[][][] all_researchers;
		
		//for each researcher, find all possible paths for that researcher
		for(uint i = 0; i < res_len; ++i)
		{
			all_researchers.push_back(getAllPaths(new_researchers[i]));
		}
		
		//we'll put the best choices for all in here
		string[][] best_researchers;
		best_researchers.resize(res_len);
		int best_vote = -1;
		
		string[][] current_researchers;
		current_researchers.resize(res_len);
		
		int[] comb;
		comb.resize(res_len);
		for(uint i = 0; i < res_len; ++i)
			comb[i] = 0;
		
		bool done = false;
		while (!done)
		{
			
			for(uint i = 0; i < res_len; ++i)
			{
				current_researchers[i] = all_researchers[i][comb[i]];
			}
			
			int current_vote = GetVotesCovered(current_researchers);
			if(current_vote > best_vote)
			{
				best_vote = current_vote;
				best_researchers = current_researchers;
			}
			
			//calc next combination
			uint i = comb.length;
			while(i --> 0)
			{
				if(comb[i] < all_researchers[i].length-1)
				{
					comb[i]++;
					break;
				}
				else
				{
					if(i == 0) //we've done all combinations!
					{
						done = true;
						break;
					}
					
					comb[i] = 0;
				}
			}
		}
		
		
		//copy the found array back into the researchers and let them do their thing
		for(uint i = 0; i < res_len; ++i)
		{
			if(best_researchers[i].length > 0)
			{
				best_researchers[i].erase(0); //chop off the first element (the target they already have
				researchers[i].targets = best_researchers[i]; //copy the new list of targets
			}
		}
	}
	
	//net
	
	void Serialise(CBitStream@ stream)
	{
		stream.write_u8( team );
		stream.write_u8( scrolls.names.length );
		for (uint i = 0; i < scrolls.names.length; i++)
		{
			const string defname = scrolls.names[i];
			ScrollDef@ def;
			scrolls.scrolls.get( defname, @def );
			if (def !is null)
			{
				stream.write_string(defname);
				def.Serialise(stream);
			}
			else warn("Serialise: def not found " + defname );
		}
		stream.write_u8( researchers.length );
		for (uint i = 0; i < researchers.length; i++)
		{
			researchers[i].Serialise(stream);
		}
	}
	
	bool Unserialise(CBitStream@ stream)
	{
		scrolls = ScrollSet();
		if (!stream.saferead_u8(team))
			return false;	
		u8 length;
		if (!stream.saferead_u8(length))
			return false;
		for (uint i = 0; i < length; i++)
		{
			//unserialise the name
			string defname;
			if (!stream.saferead_string(defname))
				return false;
			
			//unserialise the definition
			ScrollDef def;
			if(!def.Unserialise(stream)) return false;
			
			scrolls.names.push_back(defname); //add the name
			scrolls.scrolls.set( defname, def );
		}
		
		researchers.clear();
		u8 length2;
		if (!stream.saferead_u8(length2))
			return false;
		for (uint i = 0; i < length2; i++)
		{
			ResearchPoint p;
			if (!p.Unserialise(stream)) return false;	 
			p.team = team;
			researchers.push_back(p);
		}
		
		return true;
	}
};
