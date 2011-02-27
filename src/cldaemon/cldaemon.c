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
cldaemon_daemon(lua_State *lua)
{

#ifndef _WIN32
	switch (fork()) {
	case -1:
		fprintf(stderr, "forking; %s\n", strerror(errno));
		exit(1);
		break;
	case 0:
		break;
	default:
		exit(0);
		break;
	}

	if (setsid() == -1) {
		fprintf(stderr, "creating session; %s\n", strerror(errno));
		exit(1);
	}
	switch (fork()) {
	case -1:
		fprintf(stderr, "creating session; %s\n", strerror(errno));
		exit(1);
		break;
	case 0:
		break;
	default:
		exit(0);
		break;
	}

	close(STDIN_FILENO);
	close(STDOUT_FILENO);
	close(STDERR_FILENO);
	if (open("/dev/null", O_RDWR) != -1) {
		dup(STDIN_FILENO);
		dup(STDIN_FILENO);
	}
#endif

	return 0;
}

/* The cldaemon library. */
static const luaL_reg lib[] = {
	{ "daemon", cldaemon_daemon },
	{ NULL, NULL }
};

/*
 * Opens the cldaemon library.
 */
LUALIB_API int
luaopen_cldaemon(lua_State *lua)
{

	luaL_openlib(lua, "cldaemon", lib, 0);

	return 1;
}
