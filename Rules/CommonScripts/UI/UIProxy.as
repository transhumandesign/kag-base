#include "UI.as"

namespace UI
{
	funcdef void PROXY_RENDER_FUNCTION( Proxy@ );
	funcdef void PROXY_UPDATE_FUNCTION( Proxy@ );

	shared class Proxy
	{
		Vec2f ul;
		Vec2f lr;
		f32 Z;
		bool selected;
		string caption;
		string image;
		Vec2f imageSize;
		Vec2f align;

		bool dead;
		int timeOut;

		PROXY_RENDER_FUNCTION@ renderFunc;
		PROXY_UPDATE_FUNCTION@ updateFunc;

		Group@ group;
		Control@ control;
		Data@ data;

		Vec2f transitionOffset;
		Vec2f transition_ul;
		Vec2f transition_lr;

		Proxy( PROXY_RENDER_FUNCTION@ _renderFunc, PROXY_UPDATE_FUNCTION@ _updateFunc, 
			   Data@ _data, Group@ _group, Control@ _control, const f32 _Z )
		{
			@renderFunc = _renderFunc;
			@updateFunc = _updateFunc;
			@group = _group;
			@control = _control;
			@data = _data;
			Z = _Z;

			dead = false;
			timeOut = 0;
			align.Set(0.0f, 0.5f);
		}

		int opCmp (const Proxy &in other) const {
			return other.Z > Z ? -1 : 0;
		}
	};

	// add

	Proxy@ AddProxy( Data@ data, PROXY_RENDER_FUNCTION@ _renderFunc, PROXY_UPDATE_FUNCTION@ _updateFunc, 
			   Group@ _group, Control@ _control, const f32 _Z )
	{
		Proxy proxy( _renderFunc, _updateFunc, _group.data, _group, _control, _Z );
		data.proxies.push_back( proxy );
		data.proxies.sortAsc();
		return proxy;
	}

	void RemoveProxies( Data@ data, Group@ group = null )
	{
		if(data is null) return;

		// remove proxy
		for (uint pIt = 0; pIt < data.proxies.length; pIt++)
		{
			Proxy@ proxy = data.proxies[ pIt ];
			if (group is null || group is proxy.group) {
				@proxy.group = null;
				@proxy.control = null;
			}
		}
	}

	void RemoveProxies( Data@ data, Control@ control )
	{
		if(data is null) return;

		// remove proxy
		for (uint pIt = 0; pIt < data.proxies.length; pIt++)
		{
			Proxy@ proxy = data.proxies[ pIt ];
			if (proxy.control is control && proxy.control !is null) {
				@proxy.group = null;
				@proxy.control = null;
			}
		}
	}

	// Proxy@ FindProxy( Data@ data, Control@ control )
	// {
	// 	for (uint pIt = 0; pIt < data.proxies.length; pIt++)
	// 	{
	// 		Proxy@ proxy = data.proxies[ pIt ];
	// 		if (proxy.control is control) {
	// 			return proxy;
	// 		}
	// 	}
	// 	return null;
	// }

	// helpers

	void CalcControlPosition( Group@ group, Proxy@ proxy, const int x, const int y )
	{
		if (group is null || group.columns == 0 || group.rows == 0 || proxy is null || group.proxy is null)
			return;
		Vec2f groupSize( group.proxy.lr.x - group.proxy.ul.x, group.proxy.lr.y - group.proxy.ul.y );
		Vec2f controlsize( groupSize.x / float(group.columns), groupSize.y / float(group.rows) );
		Vec2f controlPos( group.proxy.ul.x + x*controlsize.x, group.proxy.ul.y + y*controlsize.y );
		proxy.ul = controlPos + controlsize * (group.paddingFactor / 2);
		proxy.lr = controlPos + controlsize * (1 - group.paddingFactor / 2);
	}
}