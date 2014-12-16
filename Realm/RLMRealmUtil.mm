////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMRealmUtil.h"

#import "RLMRealm_Private.hpp"

#import <sys/event.h>
#import <sys/stat.h>
#import <sys/time.h>
#import <unistd.h>

// Global realm state
static NSMutableDictionary *s_realmsPerPath = [NSMutableDictionary new];

void RLMCacheRealm(RLMRealm *realm) {
    @synchronized(s_realmsPerPath) {
        if (!s_realmsPerPath[realm.path]) {
            s_realmsPerPath[realm.path] = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsObjectPersonality
                                                                valueOptions:NSPointerFunctionsWeakMemory];
        }
        [s_realmsPerPath[realm.path] setObject:realm forKey:@(realm->_threadID)];
    }
}

RLMRealm *RLMGetAnyCachedRealmForPath(NSString *path) {
    @synchronized(s_realmsPerPath) {
        return [s_realmsPerPath[path] objectEnumerator].nextObject;
    }
}

RLMRealm *RLMGetCurrentThreadCachedRealmForPath(NSString *path) {
    mach_port_t threadID = pthread_mach_thread_np(pthread_self());
    @synchronized(s_realmsPerPath) {
        return [s_realmsPerPath[path] objectForKey:@(threadID)];
    }
}

void RLMClearRealmCache() {
    @synchronized(s_realmsPerPath) {
        [s_realmsPerPath removeAllObjects];
    }
}

@implementation RLMWeakNotifier {
    __weak RLMRealm *_realm;
    int _notifyFd;
    int _shutdownFd;
}

static void checkError(int ret) {
    if (ret < 0 && errno != EEXIST) {
        @throw RLMException(@(strerror(errno)));
    }
}

- (instancetype)initWithRealm:(RLMRealm *)realm {
    self = [super init];
    if (self) {
        _realm = realm;

        const char *path = [realm.path stringByAppendingString:@".note"].UTF8String;
        checkError(mkfifo(path, 0600));

        checkError(_notifyFd = open(path, O_RDWR));
        // return -1 if pipe is full rather than blocking
        fcntl(_notifyFd, F_SETFL, O_NONBLOCK);

        int pipeFd[2];
        checkError(pipe(pipeFd));
        _shutdownFd = pipeFd[1];

        CFRunLoopRef runLoop = CFRunLoopGetCurrent();

        // Add a source to the current runloop that we'll signal every time
        // there's a commit
        CFRunLoopSourceContext ctx{};
        ctx.info = (__bridge void *)self;
        ctx.perform = [](void *info) {
            RLMWeakNotifier *notifier = (__bridge RLMWeakNotifier *)info;
            if (RLMRealm *realm = notifier->_realm) {
                [realm handleExternalCommit];
            }
        };
        CFRunLoopSourceRef signal = CFRunLoopSourceCreate(0, 0, &ctx);
        CFRunLoopAddSource(runLoop, signal, kCFRunLoopDefaultMode);
        CFRelease(signal);

        int kq = kqueue();
        checkError(kq);

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), [=] {
            // Set up the kqueue to wait for data to become available to read
            // on either the fifo shared with other processes or the pipe used
            // to signal shutdowns
            struct kevent ke[2];
            EV_SET(&ke[0], _notifyFd, EVFILT_READ, EV_ADD | EV_CLEAR, 0, 0, 0);
            EV_SET(&ke[1], pipeFd[0], EVFILT_READ, EV_ADD | EV_CLEAR, 0, 0, 0);
            kevent(kq, ke, 2, nullptr, 0, nullptr);

            while (true) {
                struct kevent ev;
                // Wait until there's more data available on either of the fds.
                // EV_CLEAR makes it only return each event once, so we don't
                // need to actually read from the fifo (which is good, as it
                // means that a single write can wake up everyone waiting on the fifo)
                int ret = kevent(kq, nullptr, 0, &ev, 1, nullptr);
                if (ret <= 0) {
                    continue;
                }

                if (ev.ident == (uint32_t)pipeFd[0]) {
                    // Someone called -stop, so tear everything down and exit
                    CFRunLoopSourceInvalidate(signal);
                    close(_notifyFd);
                    close(pipeFd[0]);
                    close(pipeFd[1]);
                    close(kq);
                    return;
                }

                CFRunLoopSourceSignal(signal);
                CFRunLoopWakeUp(runLoop);
            }
        });
    }
    return self;
}

static void notifyFd(int fd) {
    while (true) {
        char c = 0;
        ssize_t ret = write(fd, &c, 1);
        if (ret == 1) {
            break;
        }
        assert(ret == -1 && errno == EAGAIN);

        // pipe is full so read some data from it to make space
        char buff[1024];
        read(fd, buff, sizeof buff);
    }
}

- (void)stop {
    // wake up the kqueue
    notifyFd(_shutdownFd);
}

- (void)notifyOtherRealms {
    notifyFd(_notifyFd);
}
@end
