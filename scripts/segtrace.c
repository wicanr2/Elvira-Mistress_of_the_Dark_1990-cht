/* LD_PRELOAD SIGSEGV/SIGABRT backtrace shim — 全速重現時序敏感崩潰並印 stack。
 * 編譯: gcc -shared -fPIC -o segtrace.so segtrace.c -ldl
 * 用法: LD_PRELOAD=./segtrace.so <program>
 */
#define _GNU_SOURCE
#include <execinfo.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

static void handler(int sig) {
	void *bt[64];
	int n = backtrace(bt, 64);
	fprintf(stderr, "\n=== SEGTRACE: signal %d, %d frames ===\n", sig, n);
	fflush(stderr);
	backtrace_symbols_fd(bt, n, 2);   // fd 2 = stderr
	fflush(stderr);
	_exit(139);
}

__attribute__((constructor))
static void install(void) {
	struct sigaction sa;
	sa.sa_handler = handler;
	sigemptyset(&sa.sa_mask);
	sa.sa_flags = SA_RESETHAND;
	sigaction(SIGSEGV, &sa, NULL);
	sigaction(SIGABRT, &sa, NULL);
	sigaction(SIGBUS, &sa, NULL);
}
