#ifndef _WIN32
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/types.h>
#endif

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

/*
 * Implements the BSD daemon() functionality, which turns a process into and
 * a daemon.
 */
static int
daemon_daemon(lua_State *lua)
{

#ifndef _WIN32
	switch (fork()) {
	case -1:
		fprintf(stderr, "forking; %s\n", strerror(errno));
		lua_pushboolean(lua, 0);
		return 1;
		/* NOTREACHED */
		break;
	case 0:
		break;
	default:
		exit(0);
		/* NOTREACHED */
		break;
	}

	if (setsid() == -1) {
		fprintf(stderr, "creating session; %s\n", strerror(errno));
	}

	chdir("/");

	close(STDIN_FILENO);
	close(STDOUT_FILENO);
	close(STDERR_FILENO);

	if (open("/dev/null", O_RDWR) == -1 ||
	    dup(STDIN_FILENO) == -1 ||
	    dup(STDIN_FILENO) == -1)
		fprintf(stderr, "duplicating file descriptors; %s\n",
		    strerror(errno));
#endif

	return 0;
}

/* The daemon library. */
static const luaL_Reg lib[] = {
	{ "daemon", daemon_daemon },
	{ NULL, NULL }
};

/*
 * Opens the daemon library.
 */
LUALIB_API int
luaopen_concurrent_daemon(lua_State *lua)
{

#if LUA_VERSION_NUM < 502
	luaL_register(lua, "daemon", lib);
#else
	luaL_newlib(lua, lib);
#endif
	return 1;
}
