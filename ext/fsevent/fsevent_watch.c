#include <CoreServices/CoreServices.h>

void callback(ConstFSEventStreamRef streamRef,
  void *clientCallBackInfo,
  size_t numEvents,
  void *eventPaths,
  const FSEventStreamEventFlags eventFlags[],
  const FSEventStreamEventId eventIds[]
) {
  // Print modified dirs
  int i;
  char **paths = eventPaths;
  for (i = 0; i < numEvents; i++) {
    printf("%s", paths[i]);
    printf(":");
  }
  printf("\n");
  fflush(stdout);
}

int main (int argc, const char * argv[]) {
  // Collect arguments as paths to watch
  CFMutableArrayRef pathsToWatch = CFArrayCreateMutable(NULL, argc-1, NULL);
  int i;
  for(i=1; i<argc; i++) {
    CFArrayAppendValue(pathsToWatch, CFStringCreateWithCString(kCFAllocatorDefault, argv[i], kCFStringEncodingUTF8));
  }

  // Create event stream
  void *callbackInfo = NULL;
  FSEventStreamRef stream;
  CFAbsoluteTime latency = 0.5;
  stream = FSEventStreamCreate(
    kCFAllocatorDefault,
    callback,
    callbackInfo,
    pathsToWatch,
    kFSEventStreamEventIdSinceNow,
    latency,
    kFSEventStreamCreateFlagNone
  );

  // Add stream to run loop
  FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
  FSEventStreamStart(stream);
  CFRunLoopRun();

  return 2;
}
