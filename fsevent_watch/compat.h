//
//  compat.h
//  fsevent_watch
//
//  Copyright (c) 2011 Travis Tilley. All rights reserved.
//

#ifndef __FSEVENTS__
#include <CarbonCore/FSEvents.h>
#endif

#ifndef fsevent_watch_compat_h
#define fsevent_watch_compat_h

#if MAC_OS_X_VERSION_MAX_ALLOWED < 1060
// ignoring events originating from the current process introduced in 10.6
FSEventStreamCreateFlags kFSEventStreamCreateFlagIgnoreSelf = 0x00000008;
#endif

#if MAC_OS_X_VERSION_MAX_ALLOWED < 1070
// file-level events introduced in 10.7
FSEventStreamCreateFlags kFSEventStreamCreateFlagFileEvents = 0x00000010;
FSEventStreamEventFlags kFSEventStreamEventFlagItemCreated = 0x00000100,
                        kFSEventStreamEventFlagItemRemoved = 0x00000200,
                        kFSEventStreamEventFlagItemInodeMetaMod = 0x00000400,
                        kFSEventStreamEventFlagItemRenamed = 0x00000800,
                        kFSEventStreamEventFlagItemModified = 0x00001000,
                        kFSEventStreamEventFlagItemFinderInfoMod = 0x00002000,
                        kFSEventStreamEventFlagItemChangeOwner = 0x00004000,
                        kFSEventStreamEventFlagItemXattrMod = 0x00008000,
                        kFSEventStreamEventFlagItemIsFile = 0x00010000,
                        kFSEventStreamEventFlagItemIsDir = 0x00020000,
                        kFSEventStreamEventFlagItemIsSymlink = 0x00040000;
#endif

#endif // fsevent_watch_compat_h
