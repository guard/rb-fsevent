#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>


// Default flags for FSEventStreamCreate
const FSEventStreamCreateFlags
FWDefaultFSEventStreamCreateFlags = kFSEventStreamCreateFlagNone;

// Structure for storing metadata parsed from the commandline
typedef struct _cli_settings_t {
  CFMutableArrayRef           paths;
  FSEventStreamEventId        sinceWhen;
  CFTimeInterval              latency;
  FSEventStreamCreateFlags    flags;
} cli_settings_t;


// Prototypes
void          append_path(cli_settings_t *cli_settings, const char *path);
void          parse_cli_settings(int argc,
                                 const char *argv[],
                                 cli_settings_t *cli_settings);
static void   callback(ConstFSEventStreamRef streamRef,
                       void *clientCallBackInfo,
                       size_t numEvents,
                       void *eventPaths,
                       const FSEventStreamEventFlags eventFlags[],
                       const FSEventStreamEventId eventIds[]);


// Resolve a path and append it to the CLI settings structure
// The FSEvents API will, internally, resolve paths using a similar scheme.
// Performing this ahead of time makes things less confusing, IMHO.
void append_path(cli_settings_t *cli_settings, const char *path)
{
#ifdef DEBUG
  fprintf(stderr, "\n");
  fprintf(stderr, "append_path called for: %s\n", path);
#endif

  char fullPath[PATH_MAX];

  if (realpath(path, fullPath) == NULL) {
#ifdef DEBUG
    fprintf(stderr, "  realpath not directly resolvable from path\n");
#endif

    if (path[0] != '/') {
#ifdef DEBUG
      fprintf(stderr, "  passed path is not absolute\n");
#endif
      size_t len;
      getcwd(fullPath, sizeof(fullPath));
#ifdef DEBUG
      fprintf(stderr, "  result of getcwd: %s\n", fullPath);
#endif
      len = strlen(fullPath);
      fullPath[len] = '/';
      strlcpy(&fullPath[len + 1], path, sizeof(fullPath) - (len + 1));
    } else {
#ifdef DEBUG
      fprintf(stderr, "  assuming path does not YET exist\n");
#endif
      strlcpy(fullPath, path, sizeof(fullPath));
    }
  }

#ifdef DEBUG
  fprintf(stderr, "  resolved path to: %s\n", fullPath);
  fprintf(stderr, "\n");
  fflush(stderr);
#endif

  CFStringRef pathRef = CFStringCreateWithCString(kCFAllocatorDefault,
                                                  fullPath,
                                                  kCFStringEncodingUTF8);
  CFArrayAppendValue(cli_settings->paths, pathRef);
  CFRelease(pathRef);
}

// Parse commandline settings
void parse_cli_settings(int argc,
                        const char *argv[],
                        cli_settings_t *cli_settings)
{
  memset(cli_settings, 0, sizeof(cli_settings_t));

  cli_settings->sinceWhen = 0xFFFFFFFFFFFFFFFFULL;
  cli_settings->latency = 0.5;
  cli_settings->flags = FWDefaultFSEventStreamCreateFlags;
  cli_settings->paths = CFArrayCreateMutable(NULL,
                                             (CFIndex)0,
                                             &kCFTypeArrayCallBacks);

  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "--since_when") == 0) {
      cli_settings->sinceWhen = strtoull(argv[++i], NULL, 0);
    } else if (strcmp(argv[i], "--latency") == 0) {
      cli_settings->latency = strtod(argv[++i], NULL);
    } else if (strcmp(argv[i], "--no-defer") == 0) {
      cli_settings->flags |= kFSEventStreamCreateFlagNoDefer;
    } else if (strcmp(argv[i], "--watch-root") == 0) {
      cli_settings->flags |= kFSEventStreamCreateFlagWatchRoot;
    } else if (strcmp(argv[i], "--ignore-self") == 0) {
      cli_settings->flags |= kFSEventStreamCreateFlagIgnoreSelf;
    } else {
      append_path(cli_settings, argv[i]);
    }
  }

  if (CFArrayGetCount(cli_settings->paths) == 0) {
    append_path(cli_settings, ".");
  }

#ifdef DEBUG
  fprintf(stderr, "cli_settings->since_when   %llu\n", cli_settings->sinceWhen);
  fprintf(stderr, "cli_settings->latency      %f\n", cli_settings->latency);
  fprintf(stderr, "cli_settings->flags        %#.8x\n", cli_settings->flags);
  fprintf(stderr, "cli_settings->paths\n");

  long numpaths = CFArrayGetCount(cli_settings->paths);

  for (long i = 0; i < numpaths; i++) {
    char path[PATH_MAX];
    CFStringGetCString(CFArrayGetValueAtIndex(cli_settings->paths, i),
                       path,
                       PATH_MAX,
                       kCFStringEncodingUTF8);
    fprintf(stderr, "  %s\n", path);
  }

  fprintf(stderr, "\n");
  fflush(stderr);
#endif
}

static void callback(ConstFSEventStreamRef streamRef,
                     void *clientCallBackInfo,
                     size_t numEvents,
                     void *eventPaths,
                     const FSEventStreamEventFlags eventFlags[],
                     const FSEventStreamEventId eventIds[])
{
  char **paths = eventPaths;

#ifdef DEBUG
  fprintf(stderr, "\n");
  fprintf(stderr, "FSEventStreamCallback fired!\n");
  fprintf(stderr, "  numEvents: %lu\n", numEvents);

  for (size_t i = 0; i < numEvents; i++) {
    fprintf(stderr, "  event path: %s\n", paths[i]);
  }

  fprintf(stderr, "\n");
  fflush(stderr);
#endif

  for (size_t i = 0; i < numEvents; i++) {
    fprintf(stdout, "%s", paths[i]);
    fprintf(stdout, ":");
  }

  fprintf(stdout, "\n");
  fflush(stdout);
}

int main(int argc, const char *argv[])
{
  cli_settings_t _cli_settings, *settings = &_cli_settings;
  parse_cli_settings(argc, argv, settings);

  FSEventStreamContext *context = NULL;
  FSEventStreamRef stream;
  stream = FSEventStreamCreate(kCFAllocatorDefault,
                               callback,
                               context,
                               settings->paths,
                               settings->sinceWhen,
                               settings->latency,
                               settings->flags);

#ifdef DEBUG
  FSEventStreamShow(stream);
  fprintf(stderr, "\n");
  fflush(stderr);
#endif

  FSEventStreamScheduleWithRunLoop(stream,
                                   CFRunLoopGetCurrent(),
                                   kCFRunLoopDefaultMode);
  FSEventStreamStart(stream);
  CFRunLoopRun();

  return 2;
}
