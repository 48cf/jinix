#include <dlfcn.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>

// typedef int (*execl_t)(const char *, const char *, ...);
// typedef int (*execlp_t)(const char *, const char *, ...);
// typedef int (*execle_t)(const char *, const char *, ...);
// typedef int (*execv_t)(const char *, char *const[]);
// typedef int (*execvp_t)(const char *, char *const[]);
// typedef int (*execvpe_t)(const char *, char *const[], char *const[]);

// static execl_t real_execl = NULL;
// static execlp_t real_execlp = NULL;
// static execle_t real_execle = NULL;
// static execv_t real_execv = NULL;
// static execvp_t real_execvp = NULL;
// static execvpe_t real_execvpe = NULL;

__attribute__((constructor)) void initializeSymbols() {}

int execv(const char *pathname, char *const argv[]) {
  printf("execv called with pathname: \"%s\"\n", pathname);
  printf("execv called with argv: ");

  for (int i = 0; argv[i] != NULL; i++) {
    printf("- \"%s\"\n", argv[i]);
  }

  errno = ENOSYS;
  return -1;
}

int execvp(const char *file, char *const argv[]) {
  printf("execvp called with file: \"%s\"\n", file);
  printf("execvp called with argv: ");

  for (int i = 0; argv[i] != NULL; i++) {
    printf("- \"%s\"\n", argv[i]);
  }

  errno = ENOSYS;
  return -1;
}

int execvpe(const char *file, char *const argv[], char *const envp[]) {
  printf("execvpe called with file: \"%s\"\n", file);
  printf("execvpe called with argv: ");

  for (int i = 0; argv[i] != NULL; i++) {
    printf("- \"%s\"\n", argv[i]);
  }

  printf("execvpe called with envp: ");

  for (int i = 0; envp[i] != NULL; i++) {
    printf("- \"%s\"\n", envp[i]);
  }

  errno = ENOSYS;
  return -1;
}
