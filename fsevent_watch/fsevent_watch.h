//
//  fsevent_watch.h
//  fsevent_watch
//
//  Copyright (c) 2011 Travis Tilley. All rights reserved.
//

#ifndef fsevent_watch_h
#define fsevent_watch_h

enum FSEventWatchOutputFormat {
  kFSEventWatchOutputFormatClassic,
  kFSEventWatchOutputFormatNIW
};

// Structure for storing metadata parsed from the commandline
static struct {
  FSEventStreamEventId            sinceWhen;
  CFTimeInterval                  latency;
  FSEventStreamCreateFlags        flags;
  CFMutableArrayRef               paths;
  enum FSEventWatchOutputFormat   format;
} config = {
  (UInt64) kFSEventStreamEventIdSinceNow,
  (double) 0.3,
  (UInt32) kFSEventStreamCreateFlagNone,
  NULL,
  kFSEventWatchOutputFormatClassic
};

// Prototypes
static void         append_path(const char *path);
static inline void  parse_cli_settings(int argc, const char *argv[]);
static void         callback(FSEventStreamRef streamRef,
                             void *clientCallBackInfo,
                             size_t numEvents,
                             void *eventPaths,
                             const FSEventStreamEventFlags eventFlags[],
                             const FSEventStreamEventId eventIds[]);

#endif
