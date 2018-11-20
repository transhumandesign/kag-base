//ScriptRenderExample.as
//
//  dive into the wonderful world of script rendering!
//
//  try adding this to a CBlob's or CRules's script list
//
//  tap the eat button (V by default) to swap between "effects"
//
//  blob will render the current effect for whatever blob it's added to
//  (the builder is good for testing in sandbox)
//
//  rules will render the effect for all player blobs
//
//  both options are provided to ensure there is a suitable example for
//  both possible intended uses.
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// render layers available
//
// world layers:
//    Render::layer_background      //after the background layers (parallax etc) - they wipe out the
//    Render::layer_tiles           //after the tilemap
//    Render::layer_objects         //after the objects (sprites, particles)
//    Render::layer_floodlayers     //after the flood layers
//    Render::layer_postworld       //after the entire world
//
// hud layers:
//    Render::layer_prehud          //after the black world borders but before the rest of the HUD
//    Render::layer_posthud         //after the rest of the HUD
//
// non-rendered layers
//    Render::layer_count           //total layer count - useful for looping through the layers if needed for anything
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// transparency matters
//
// alpha blending is required for soft transparency
//
// you can turn it on with
//  Render::SetAlphaBlend(true);
// and off with
//  Render::SetAlphaBlend(false);
//
// however alpha blending also _disables_ z writing **completely**
// so it should be used on layers most closely matching
// the z level it's targetting
//
// Render::layer_objects    - if it should be behind water and fire like other objects
// Render::layer_postworld  - if it should be in front of everything
//
// or else the contents will get overwritten strangely
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// coordinate concerns
//
// you can set the rendering transformation interactively using the
// following functions:
//
//	Render::SetTransformWorldspace    - coordinates in world space
//	Render::SetTransformScreenspace   - coordinates in "screen pixel" space
//	Render::SetTransform              - coordinates in some arbitrary space
//
// the transformation will be automatically reverted between script
// render calls, so there's no need to "clean up" the transformation
//
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// without further ado, here's the script
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// common setup code
//
// this is partly to remind you that you can created textures on the fly
// with scripts, but mostly because we just want a simple texture to show
// the vertex colouring and uv mapping

const string test_name = "_scriptrender_test_texture";

void Setup()
{
	//ensure texture for our use exists
	if(!Texture::exists(test_name))
	{
		if(!Texture::createBySize(test_name, 8, 8))
		{
			warn("texture creation failed");
		}
		else
		{
			ImageData@ edit = Texture::data(test_name);

			for(int i = 0; i < edit.size(); i++)
			{
				edit[i] = SColor((((i + i / 8) % 2) == 0) ? 0xff707070 : 0xff909090);
			}

			if(!Texture::update(test_name, edit))
			{
				warn("texture update failed");
			}
		}
	}
}

//toggle through each render type to give a working example of each call

enum _render_type {
	//world types
	render_type_tris,
	render_type_tris_indexed,
	render_type_tris_cols,
	render_type_tris_cols_indexed,
	render_type_quads,
	render_type_quads_cols,
	render_type_raw_tris,
	render_type_raw_tris_indexed,
	render_type_raw_quads,
	//hud types
	render_type_screenspace,
	render_type_identity,
	render_type_3d,
	render_type_count,
}
int render_type = render_type_3d;
int last_changed = 0;

bool isWorldRenderType(int t)
{
	return t < int(render_type_screenspace);
}

void ChangeIfNeeded()
{
	CControls@ c = getControls();
	if (c is null) return;

	if (c.isKeyJustPressed(c.getActionKeyKey(AK_EAT)) && last_changed != getGameTime())
	{
		last_changed = getGameTime();
		render_type = (render_type + 1) % render_type_count;
	}
}

//blob hooks

void onInit(CBlob@ this)
{
	Setup();
	int cb_id = Render::addBlobScript(Render::layer_objects, this, "ScriptRenderExample.as", "ExampleBlobRenderFunction");
}

void onTick(CBlob@ this)
{
	ChangeIfNeeded();
}

//rules hooks

void onInit(CRules@ this)
{
	Setup();
	int cb_id =     Render::addScript(Render::layer_objects, "ScriptRenderExample.as", "ExampleRulesRenderFunction", 0.0f);
	int hud_cb_id = Render::addScript(Render::layer_prehud, "ScriptRenderExample.as", "ExampleRulesHUDRenderFunction", 0.0f);
}

void onRestart(CRules@ this)
{
	Setup();
}

void onTick(CRules@ this)
{
	ChangeIfNeeded();
}

//render functions
//
// blob functions get the blob they were created with as an argument
//  and are removed safely when that blob is killed/removed
//
// both get the id of their function - they can be removed with
//  Render::RemoveScript if appropriate

void ExampleBlobRenderFunction(CBlob@ this, int id)
{
	RenderWidgetFor(this);
}

void ExampleRulesRenderFunction(int id)
{
	CBlob@[] players;
	getBlobsByTag("player", @players);
	for (uint i = 0; i < players.length; i++)
	{
		RenderWidgetFor(players[i]);
	}
}

void ExampleRulesHUDRenderFunction(int id)
{
	CBlob@[] players;
	getBlobsByTag("player", @players);
	for (uint i = 0; i < players.length; i++)
	{
		RenderHUDWidgetFor(players[i]);
	}
}


//we will build our meshes into here
//for "high performance" stuff you'll generally want to keep them persistent
//but we clear ours each time around rendering
Vec2f[] v_pos;
Vec2f[] v_uv;
SColor[] v_col;

u16[] v_i;

//this is the highest performance option
Vertex[] v_raw;

void ClearRenderState()
{
	//nuke out last invocation's data
	v_pos.clear();
	v_uv.clear();
	v_col.clear();
	v_i.clear();
	v_raw.clear();

	//we are rendering after the world
	//so we can alpha blend relatively safely, although it will still misbehave
	//when rendering over other alpha-blended stuff
	Render::SetAlphaBlend(true);
}

void RenderWidgetFor(CBlob@ this)
{
	//early-out for any non-world types
	if (!isWorldRenderType(render_type)) return;

	Vec2f p = this.getInterpolatedPosition();
	CMap@ map = getMap();

	string render_texture_name = test_name;

	ClearRenderState();

	float x_size = 16;
	float y_size = 16;

	//render just behind our character
	f32 z = this.getSprite().getZ() - 0.1;

	if (render_type == render_type_tris)
	{
		//Render::Triangles is the simplest call possible;
		// it just renders each 3 vertices submitted as a triangle
		// if you need to render a bunch of triangles, you've come to the right place
		// though you may want to check out Render::Quads for many cases...

		v_pos.push_back(p + Vec2f(-x_size,-y_size)); v_uv.push_back(Vec2f(0,0));
		v_pos.push_back(p + Vec2f( x_size,-y_size)); v_uv.push_back(Vec2f(1,0));
		v_pos.push_back(p + Vec2f(      0, y_size)); v_uv.push_back(Vec2f(0.5,1));

		Render::Triangles(render_texture_name, z, v_pos, v_uv);
	}
	else if(render_type == render_type_tris_indexed)
	{
		//Render::TrianglesIndexed is a more complicated call -
		// it accepts any number of vertices and a list of indices
		// that encode "how to render" those vertices
		//
		//each 3 indices make up a triangle, and can share vertices
		// this lets us send less data if we need to render geometry that
		// shares vertices - like quads.

		v_pos.push_back(p + Vec2f(-x_size,-y_size)); v_uv.push_back(Vec2f(0,0));
		v_pos.push_back(p + Vec2f( x_size,-y_size)); v_uv.push_back(Vec2f(1,0));
		v_pos.push_back(p + Vec2f( x_size, y_size)); v_uv.push_back(Vec2f(1,1));
		v_pos.push_back(p + Vec2f(-x_size, y_size)); v_uv.push_back(Vec2f(0,1));

		//we're using the same ordering as Render::Quads uses (clockwise)
		// but you _can_ specify whatever topology you want
		v_i.push_back(0);
		v_i.push_back(1);
		v_i.push_back(2);
		v_i.push_back(0);
		v_i.push_back(2);
		v_i.push_back(3);

		Render::TrianglesIndexed(render_texture_name, z, v_pos, v_uv, v_i);
	}
	else if(render_type == render_type_tris_cols)
	{
		//Render::TrianglesColored is the same as Render::Triangles but also accepts
		// a per-vertex colour, which is multiplied with the texture colour. this can
		// be used for lighting and transparency - though be wary of the caveats of soft transparency!

		v_pos.push_back(p + Vec2f(-x_size,-y_size)); v_uv.push_back(Vec2f(0,0));
		v_pos.push_back(p + Vec2f( x_size,-y_size)); v_uv.push_back(Vec2f(1,0));
		v_pos.push_back(p + Vec2f(      0, y_size)); v_uv.push_back(Vec2f(0.5,1));

		//light the mesh the same way as sprites
		SColor light = map.getColorLight(p);
		for(int i = 0; i < v_pos.length; i++)
		{
			v_col.push_back(light);
		}

		Render::TrianglesColored(render_texture_name, z, v_pos, v_uv, v_col);
	}
	else if(render_type == render_type_tris_cols_indexed)
	{
		//Render::TrianglesColoredIndexed is as to Render::TrianglesIndexed as Render::TrianglesColored is to Render::Triangles
		//
		//We're doing some "creative" colouring though to show that it doesn't have to be based on anything

		v_pos.push_back(p + Vec2f(-x_size,-y_size)); v_uv.push_back(Vec2f(0,0)); v_col.push_back(SColor(0xffffffff));
		v_pos.push_back(p + Vec2f( x_size,-y_size)); v_uv.push_back(Vec2f(1,0)); v_col.push_back(SColor(0x00ff0000));
		v_pos.push_back(p + Vec2f( x_size, y_size)); v_uv.push_back(Vec2f(1,1)); v_col.push_back(SColor(0x000000ff));
		v_pos.push_back(p + Vec2f(-x_size, y_size)); v_uv.push_back(Vec2f(0,1)); v_col.push_back(SColor(0xff00ff00));

		v_i.push_back(0);
		v_i.push_back(1);
		v_i.push_back(2);
		v_i.push_back(0);
		v_i.push_back(2);
		v_i.push_back(3);

		Render::TrianglesColoredIndexed(render_texture_name, z, v_pos, v_uv, v_col, v_i);
	}
	else if(render_type == render_type_quads)
	{
		//Render::Quads lets you render clockwise-wound quads without having
		// to worry about generating your own index buffer.
		//
		// 0--1  the triangles rendered "in the end" look like this
		// |\ |  relative to the vertices passed in - the same
		// | \|  (0,1,2),(0,2,3) clockwise winding as we used for our
		// 3--2  indexed calls above.
		//
		//It works the same way as Render::Triangles - each 4 vertices just form
		// a quad, instead of each 3 vertices forming a triangle.

		v_pos.push_back(p + Vec2f(-x_size,-y_size)); v_uv.push_back(Vec2f(0,0));
		v_pos.push_back(p + Vec2f( x_size,-y_size)); v_uv.push_back(Vec2f(1,0));
		v_pos.push_back(p + Vec2f( x_size, y_size)); v_uv.push_back(Vec2f(1,1));
		v_pos.push_back(p + Vec2f(-x_size, y_size)); v_uv.push_back(Vec2f(0,1));

		Render::Quads(render_texture_name, z, v_pos, v_uv);
	}
	else if(render_type == render_type_quads_cols)
	{
		//Render::QuadsColored is the coloured version of Render:Quads
		//
		//The colours work the same as for the triangle calls, so there's not much to say here.

		v_pos.push_back(p + Vec2f(-x_size,-y_size)); v_uv.push_back(Vec2f(0,0));
		v_pos.push_back(p + Vec2f( x_size,-y_size)); v_uv.push_back(Vec2f(1,0));
		v_pos.push_back(p + Vec2f( x_size, y_size)); v_uv.push_back(Vec2f(1,1));
		v_pos.push_back(p + Vec2f(-x_size, y_size)); v_uv.push_back(Vec2f(0,1));

		//we'll light specifically each vertex here though for some variety

		for(int i = 0; i < v_pos.length; i++)
		{
			v_col.push_back(map.getColorLight(v_pos[i]));
		}

		Render::QuadsColored(render_texture_name, z, v_pos, v_uv, v_col);
	}
	else
	{
		//raw render calls;
		//these send "raw" vertices to the rendering API;
		//there's no "easy" Z swap and no colour-less versions.
		//but they are much faster, particularly for static data

		//Render::RawTriangles is analogous to Render::TrianglesColored
		//Render::RawTrianglesIndexed is analogous to Render::TrianglesColoredIndexed
		//Render::RawQuads is analogous to Render::QuadsColored

		if(render_type == render_type_raw_tris)
		{
			//render an RGB triangle
			v_raw.push_back(Vertex(p.x - x_size, p.y - y_size, z, 0, 0, SColor(0xffff0000)));
			v_raw.push_back(Vertex(p.x + x_size, p.y - y_size, z, 0, 0, SColor(0xff00ff00)));
			v_raw.push_back(Vertex(p.x,          p.y + y_size, z, 0, 0, SColor(0xff0000ff)));

			Render::RawTriangles(render_texture_name, v_raw);
		}
		else if(render_type == render_type_raw_tris_indexed)
		{
			//render a uv mapped diamond
			//
			//   1
			//  /|\
			// 0 | 2
			//  \|/
			//   3
			//
			v_raw.push_back(Vertex(p.x - x_size, p.y,          z, 0, 0, SColor(0xffffffff)));
			v_raw.push_back(Vertex(p.x,          p.y - y_size, z, 1, 0, SColor(0xffffffff)));
			v_raw.push_back(Vertex(p.x + x_size, p.y,          z, 1, 1, SColor(0xffffffff)));
			v_raw.push_back(Vertex(p.x,          p.y + y_size, z, 0, 1, SColor(0xffffffff)));

			//set up the mesh indexing
			v_i.push_back(0);
			v_i.push_back(1);
			v_i.push_back(3);
			v_i.push_back(1);
			v_i.push_back(2);
			v_i.push_back(3);

			Render::RawTrianglesIndexed(render_texture_name, v_raw, v_i);
		}
		else if(render_type == render_type_raw_quads)
		{
			//render the diamond above, but with rotating colours for a bit more fun.

			const float one_third_rotation = (Maths::Pi * 2.0f / 3.0f);
			float t = (getGameTime() / 30.0f) * one_third_rotation;
			SColor col(0xffffffff);
			col.setRed(128 + 127 * Maths::Sin(t));
			col.setGreen(128 + 127 * Maths::Sin(t + one_third_rotation));
			col.setBlue(128 + 127 * Maths::Sin(t - one_third_rotation));

			v_raw.push_back(Vertex(p.x - x_size, p.y,          z, 0, 0, col));
			v_raw.push_back(Vertex(p.x,          p.y - y_size, z, 1, 0, col));
			v_raw.push_back(Vertex(p.x + x_size, p.y,          z, 1, 1, col));
			v_raw.push_back(Vertex(p.x,          p.y + y_size, z, 0, 1, col));

			Render::RawQuads(render_texture_name, v_raw);
		}
	}
}

void RenderHUDWidgetFor(CBlob@ this)
{
	//early-out for any non-screen types
	if (isWorldRenderType(render_type)) return;

	ClearRenderState();

	string render_texture_name = test_name;
	float z = 0;

	if(render_type == render_type_screenspace)
	{
		Render::SetTransformScreenspace();

		//we're rendering in screen space
		//so these positions are 0,0 to screenwidth, screenheight

		//semitransparent sin-scaling rect, small margin

		SColor col(0x80ffffff);

		float w = getDriver().getScreenWidth();
		float h = getDriver().getScreenHeight() * Maths::Abs(Maths::Sin(getGameTime() * 0.01));
		float ma = 10;
		w = Maths::Max(0, w - ma * 2);
		h = Maths::Max(0, h - ma * 2);

		v_raw.push_back(Vertex(ma,      ma,      z, 0, 0, col));
		v_raw.push_back(Vertex(ma,      ma + h,  z, 0, 1, col));
		v_raw.push_back(Vertex(ma + w,  ma + h,  z, 1, 1, col));
		v_raw.push_back(Vertex(ma + w,  ma,      z, 1, 0, col));

		Render::RawQuads(render_texture_name, v_raw);
	}
	else if(render_type == render_type_identity)
	{
		float[] identity;
		Matrix::MakeIdentity(identity);

		Render::SetTransform(identity, identity);

		//we're rendering in device coords

		SColor col(0x80ffffff);

		v_raw.push_back(Vertex(-1, -1,  0.1, 0, 0, col));
		v_raw.push_back(Vertex(-1,  1,  0.1, 0, 1, col));
		v_raw.push_back(Vertex( 1,  1,  0.1, 1, 1, col));
		v_raw.push_back(Vertex( 1, -1,  0.1, 1, 0, col));

		Render::RawQuads(render_texture_name, v_raw);
	}
	else if(render_type == render_type_3d)
	{
		//z buffer rendering
		Render::SetAlphaBlend(false);
		Render::SetZBuffer(true, true);
		//clear the screen z completely
		//so we have a fresh buffer for our rendering layer
		Render::ClearZ();

		float[] view;
		float t = getGameTime();
		Matrix::MakeIdentity(view);
		Matrix::SetTranslation(view,
			Maths::Sin(t * 0.0831f) * 2.2f,
			Maths::Cos(t * 0.0313f) * 2.2f,
			10 + Maths::Sin(t * 0.1f) * 2.2f
		);
		Matrix::SetRotationDegrees(view,
			t * 1.31f,
			t * 2.23f,
			t * 3.1f
		);
		float[] proj;
		//Matrix::MakeOrtho(proj, 10, 10, 10);
		float ratio = f32(getDriver().getScreenWidth()) / f32(getDriver().getScreenHeight());
		Matrix::MakePerspective(proj,
			Maths::Pi / 2.0f,
			ratio,
			0.1, 100
		);

		Render::SetTransform(view, proj);

		//cube
		v_raw.push_back(Vertex(-1, -1, -1,  0, 0, SColor(0xffff0000)));
		v_raw.push_back(Vertex(-1,  1, -1,  0, 1, SColor(0xff00ff00)));
		v_raw.push_back(Vertex( 1,  1, -1,  1, 1, SColor(0xff0000ff)));
		v_raw.push_back(Vertex( 1, -1, -1,  1, 0, SColor(0xffffffff)));
		v_raw.push_back(Vertex(-1, -1,  1,  0, 0, SColor(0xffff0000)));
		v_raw.push_back(Vertex(-1,  1,  1,  0, 1, SColor(0xff00ff00)));
		v_raw.push_back(Vertex( 1,  1,  1,  1, 1, SColor(0xff0000ff)));
		v_raw.push_back(Vertex( 1, -1,  1,  1, 0, SColor(0xffffffff)));

		//generate index buffer
		float[] quad_faces = {
			0, 1, 2, 3,
			0, 1, 5, 4,
			2, 1, 5, 6,
			2, 3, 7, 6,
			0, 3, 7, 4,
			4, 5, 6, 7,
		};
		for(int i = 0; i < quad_faces.length; i += 4)
		{
			int id_0 = quad_faces[i+0];
			int id_1 = quad_faces[i+1];
			int id_2 = quad_faces[i+2];
			int id_3 = quad_faces[i+3];
			v_i.push_back(id_0); v_i.push_back(id_1); v_i.push_back(id_3);
			v_i.push_back(id_1); v_i.push_back(id_2); v_i.push_back(id_3);
		}

		Render::RawTrianglesIndexed(render_texture_name, v_raw, v_i);
	}
}
