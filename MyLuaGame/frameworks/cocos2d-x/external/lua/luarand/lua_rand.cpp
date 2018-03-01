#include "lua_rand.h"

#include "Rand.h"
#include <map>

std::map <lua_State*, RakNetRandom*> mapRandom;

extern "C" {

int _randomseed(lua_State* L)
{
	int nargs = lua_gettop(L);

	if (mapRandom.find(L) == mapRandom.end())
		return 0;

	RakNetRandom* rand = mapRandom[L];
	rand->SeedMT(lua_tonumber(L, 1));
	return 0;
}

int _random(lua_State* L)
{
	int nargs = lua_gettop(L);

	RakNetRandom* rand = mapRandom[L];
	if (nargs == 0)
	{
		lua_pushnumber(L, rand->FrandomMT());
	}
	else if (nargs == 1)
	{
		int m = lua_tointeger(L, 1);
		unsigned int r = rand->RandomMT();
		lua_pushinteger(L, 1 + (r % m));
	}
	else
	{
		int m = lua_tointeger(L, 1);
		int n = lua_tointeger(L, 2);
		unsigned int r = rand->RandomMT();
		lua_pushinteger(L, m + (r % (n - m + 1)));
	}

	return 1;
}

/* code support functions */
static luaL_Reg func[] = {
	{"randomseed",   _randomseed},
	{"random",  _random},
	{NULL,          NULL}
};

int luaopen_random(lua_State* L)
{
#if LUA_VERSION_NUM > 501 && !defined(LUA_COMPAT_MODULE)
	lua_newtable(L);
	luaL_setfuncs(L, func, 0);
#else
	luaL_openlib(L, "ymrand", func, 0);
#endif
	/* make version string available to scripts */
	lua_pushstring(L, "_VERSION");
	lua_pushstring(L, LUARANDOM_VERSION);
	lua_rawset(L, -3);
	lua_pushstring(L, "_COPYRIGHT");
	lua_pushstring(L, LUARANDOM_COPYRIGHT);
	lua_rawset(L, -3);
	lua_pushstring(L, "_AUTHORS");
	lua_pushstring(L, LUARANDOM_AUTHORS);
	lua_rawset(L, -3);
	/* initialize lookup tables */

	mapRandom[L] = new RakNetRandom();
	return 1;
}

int luaclose_random(lua_State* L)
{
	if (mapRandom.find(L) == mapRandom.end())
		return 0;

	delete mapRandom[L];
	mapRandom.erase(L);
	return 0;
}

}
