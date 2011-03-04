#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#include <CoreServices/CoreServices.h>


// Default flags for FSEventStreamCreate
const FSEventStreamCreateFlags
FWDefaultFSEventStreamCreateFlags = kFSEventStreamCreateFlagNone;

// Structure for storing metadata parsed from the commandline
typedef struct _global_settings_t {
  CFMutableArrayRef           paths;
  FSEventStreamEventId        sinceWhen;
  CFTimeInterval              latency;
  FSEventStreamCreateFlags    flags;
} global_settings_t;


// Prototypes
static void         append_path(const char *path);
static inline void  parse_cli_settings(int argc,
                                       const char *argv[]);
static inline void  init_global_settings();
static void         callback(ConstFSEventStreamRef streamRef,
                             void *clientCallBackInfo,
                             size_t numEvents,
                             void *eventPaths,
                             const FSEventStreamEventFlags eventFlags[],
                             const FSEventStreamEventId eventIds[]);


// define global settings structure
global_settings_t _global_settings, *settings = &_global_settings;


// Resolve a path and append it to the CLI settings structure
// The FSEvents API will, internally, resolve paths using a similar scheme.
// Performing this ahead of time makes things less confusing, IMHO.
static void append_path(const char *path)
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
  CFArrayAppendValue(settings->paths, pathRef);
  CFRelease(pathRef);
}

// Parse commandline settings
static inline void parse_cli_settings(int argc,
                                      const char *argv[])
{
  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "--since_when") == 0) {
      settings->sinceWhen = strtoull(argv[++i], NULL, 0);
    } else if (strcmp(argv[i], "--latency") == 0) {
      settings->latency = strtod(argv[++i], NULL);
    } else if (strcmp(argv[i], "--no-defer") == 0) {
      settings->flags |= kFSEventStreamCreateFlagNoDefer;
    } else if (strcmp(argv[i], "--watch-root") == 0) {
      settings->flags |= kFSEventStreamCreateFlagWatchRoot;
    } else if (strcmp(argv[i], "--ignore-self") == 0) {
#if MAC_OS_X_VERSION_MAX_ALLOWED >= 1060
      settings->flags |= kFSEventStreamCreateFlagIgnoreSelf;
#else
      fprintf(stderr, "MacOSX10.6.sdk is required for --ignore-self\n");
#endif
    } else {
      append_path(argv[i]);
    }
  }

  if (CFArrayGetCount(settings->paths) == 0) {
    append_path(".");
  }

#ifdef DEBUG
  fprintf(stderr, "settings->since_when   %llu\n", settings->sinceWhen);
  fprintf(stderr, "settings->latency      %f\n", settings->latency);
  fprintf(stderr, "settings->flags        %#.8x\n", settings->flags);
  fprintf(stderr, "settings->paths\n");

  long numpaths = CFArrayGetCount(settings->paths);

  for (long i = 0; i < numpaths; i++) {
    char path[PATH_MAX];
    CFStringGetCString(CFArrayGetValueAtIndex(settings->paths, i),
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

static inline void init_global_settings(){
  memset(settings, 0, sizeof(global_settings_t));

  settings->sinceWhen = 0xFFFFFFFFFFFFFFFFULL;
  settings->latency = 0.5;
  settings->flags = FWDefaultFSEventStreamCreateFlags;
  settings->paths = CFArrayCreateMutable(NULL,
                                         (CFIndex)0,
                                         &kCFTypeArrayCallBacks);
}

int main(int argc, const char *argv[])
{
  init_global_settings();
  parse_cli_settings(argc, argv);

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
