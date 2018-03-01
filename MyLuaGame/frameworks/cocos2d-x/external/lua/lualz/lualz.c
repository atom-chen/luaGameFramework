#include "lualz.h"
#include "lz4.h"

#include <stdlib.h>
#include <string.h>

#include "lua.h"
#include "lauxlib.h"

static int compress(lua_State *L);
static int decompress(lua_State *L);
static int compressBound(lua_State *L);

/* code support functions */
static luaL_Reg func[] = {
	{"compress",   compress},
	{"decompress",  decompress},
	{"compressBound",  compressBound},
	{NULL,          NULL}
};


// int, srcLen
static int compressBound(lua_State *L)
{
	int srcLen = lua_tonumber(L, 1);
	lua_pushnumber(L, LZ4_compressBound(srcLen));
	return 1;
}

// char*, dest
// int, destLen
// const char* src
// int, srcLen
static int compress(lua_State *L)
{
// 	char* dest = (char*)lua_topointer(L, 1);
// 	int destOff = lua_tonumber(L, 2);
//	int destLen = lua_tonumber(L, 1);
	char* dest = NULL;
	const char* src = lua_tostring(L, 1);
	int srcLen = lua_tonumber(L, 2);

	int cpLen = LZ4_compressBound(srcLen);
	dest = (char*)malloc(cpLen);
	cpLen = LZ4_compress_limitedOutput(src, dest, srcLen, cpLen);
	lua_pushlstring(L, dest, cpLen);
	free(dest);
	return 1;
}

// char*, dest
// int, destLen
// const char* src
// int, srcLen
static int decompress(lua_State *L)
{
// 	char* dest = (char*)lua_topointer(L, 1);
	char* dest = NULL;
 	int destLen = lua_tonumber(L, 1);
	const char* src = lua_tostring(L, 2);
	int srcLen = lua_tonumber(L, 3);

	dest = (char*)malloc(destLen);
	destLen = LZ4_decompress_safe(src, dest, srcLen, destLen);
	if (destLen <= 0)
	{
		free(dest);
		lua_pushnil(L);
		return 1;
	}
	lua_pushlstring(L, dest, destLen);
	free(dest);
	return 1;
}

LUALZ4_API int luaopen_lz4(lua_State *L)
{
#if LUA_VERSION_NUM > 501 && !defined(LUA_COMPAT_MODULE)
	lua_newtable(L);
	luaL_setfuncs(L, func, 0);
#else
	luaL_openlib(L, "lz4", func, 0);
#endif
	/* make version string available to scripts */
	lua_pushstring(L, "_VERSION");
	lua_pushstring(L, LUALZ4_VERSION);
	lua_rawset(L, -3);
	lua_pushstring(L, "_COPYRIGHT");
	lua_pushstring(L, LUALZ4_COPYRIGHT);
	lua_rawset(L, -3);
	lua_pushstring(L, "_AUTHORS");
	lua_pushstring(L, LUALZ4_AUTHORS);
	lua_rawset(L, -3);
	/* initialize lookup tables */
	return 1;
}

