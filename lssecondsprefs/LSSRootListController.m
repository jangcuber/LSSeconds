#import "LSSRootListController.h"
#import <spawn.h>

#if defined(THEOS_PACKAGE_SCHEME_ROOTHIDE)
#import <roothide.h>
#endif

@implementation LSSRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}
	return _specifiers;
}

- (void)respring {
	pid_t pid;
#if defined(LSSECONDS_PACKAGE_SCHEME_ROOTLESS)
	const char *args[] = {"/var/jb/usr/bin/killall", "-9", "SpringBoard", NULL};
#else
	const char *args[] = {"/usr/bin/killall", "-9", "SpringBoard", NULL};
#endif
	const char *executable = args[0];
#if defined(THEOS_PACKAGE_SCHEME_ROOTHIDE)
	executable = jbroot(executable);
#endif
	posix_spawn(&pid, executable, NULL, NULL, (char *const *)args, NULL);
}

@end
