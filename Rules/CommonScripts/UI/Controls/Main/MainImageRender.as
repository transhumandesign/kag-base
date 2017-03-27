// main menu skin

namespace UI
{
	namespace Image
	{
		void Render( Proxy@ proxy )
		{
			GUI::DrawIcon( proxy.image, 
				(proxy.ul + proxy.lr)/2 - proxy.imageSize 
				);
		}
	}
}