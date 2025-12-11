CBlob@ createSign(Vec2f position, const string &in text)
{
	CBlob@ sign = server_CreateBlobNoInit("sign");
	if (sign !is null)
	{
		sign.setPosition(position);
		
		if (text.size() > 0)
			sign.set_string("text", text);
		
		sign.Init();
		sign.getShape().SetStatic(true);
	}
	return sign;
}