// getting / setting WAR population property

shared u32 getPopulation(int teamNum)
{
	return getRules().get_u32("team population " + teamNum);
}

shared void setPopulation(int teamNum, u32 count)
{
	getRules().set_u32("team population " + teamNum, count);
}