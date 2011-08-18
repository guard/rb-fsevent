#ifndef fsevent_watch_common_h
#define fsevent_watch_common_h

#include <CoreServices/CoreServices.h>
#include "compat.h"

#define COMPILED_AT __DATE__ " " __TIME__

#define FLAG_CHECK(flags, flag) ((flags) & (flag))

#define FPRINTF_FLAG_CHECK(flags, flag, msg, fd)  \
  do {                                            \
    if (FLAG_CHECK(flags, flag)) {                \
      fprintf(fd, "%s", msg "\n"); } }                 \
  while (0)

#define FLAG_CHECK_STDERR(flags, flag, msg)       \
  FPRINTF_FLAG_CHECK(flags, flag, msg, stderr)

enum FSEventWatchOutputFormat {
  kFSEventWatchOutputFormatClassic,
  kFSEventWatchOutputFormatNIW
};

#endif /* fsevent_watch_common_h */
