// main menu skin

namespace UI
{
  namespace Label
  {
    void Render( Proxy@ proxy )
    {
          Vec2f dim;
          GUI::GetTextDimensions( proxy.caption, dim );
          Vec2f pos = proxy.ul;
          pos += Vec2f( proxy.align.x*(proxy.lr.x - proxy.ul.x), proxy.align.y*(proxy.lr.y - proxy.ul.y) );
          GUI::DrawText( proxy.caption, pos, CAPTION_COLOR );
    }
    }
}