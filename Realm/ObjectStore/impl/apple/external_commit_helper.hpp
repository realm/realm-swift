////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
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

#ifndef REALM_EXTERNAL_COMMIT_HELPER_HPP
#define REALM_EXTERNAL_COMMIT_HELPER_HPP

#include <CoreFoundation/CFRunLoop.h>
#include <mutex>
#include <vector>

namespace realm {
class Realm;

namespace _impl {
#if TARGET_OS_TV
class ExternalCommitHelper {
public:
    ExternalCommitHelper(Realm* realm);
    ~ExternalCommitHelper();

    void notify_others();
    void add_realm(Realm* realm);
    void remove_realm(Realm* realm);

private:
    struct PerRealmInfo {
        Realm* realm;
        CFRunLoopRef runloop;
        CFRunLoopSourceRef signal;
    };

    void listen();

    // Currently registered realms and the signal for delivering notifications
    // to them
    std::vector<PerRealmInfo> m_realms;

    // Mutex which guards m_realms
    std::mutex m_realms_mutex;

    // The listener thread
    pthread_t m_thread;
};
#else
class ExternalCommitHelper {
public:
    ExternalCommitHelper(Realm* realm);
    ~ExternalCommitHelper();

    void notify_others();
    void add_realm(Realm* realm);
    void remove_realm(Realm* realm);

private:
    // A RAII holder for a file descriptor which automatically closes the wrapped
    // fd when it's deallocated
    class FdHolder {
    public:
        FdHolder() = default;
        ~FdHolder() { close(); }
        operator int() const { return m_fd; }

        FdHolder& operator=(int newFd) {
            close();
            m_fd = newFd;
            return *this;
        }

    private:
        int m_fd = -1;
        void close();

        FdHolder& operator=(FdHolder const&) = delete;
        FdHolder(FdHolder const&) = delete;
    };

    struct PerRealmInfo {
        Realm* realm;
        CFRunLoopRef runloop;
        CFRunLoopSourceRef signal;
    };

    void listen();

    // Currently registered realms and the signal for delivering notifications
    // to them
    std::vector<PerRealmInfo> m_realms;

    // Mutex which guards m_realms
    std::mutex m_realms_mutex;

    // The listener thread
    pthread_t m_thread;

    // Read-write file descriptor for the named pipe which is waited on for
    // changes and written to when a commit is made
    FdHolder m_notify_fd;
    // File descriptor for the kqueue
    FdHolder m_kq;
    // The two ends of an anonymous pipe used to notify the kqueue() thread that
    // it should be shut down.
    FdHolder m_shutdown_read_fd;
    FdHolder m_shutdown_write_fd;
};
#endif
} // namespace _impl
} // namespace realm

#endif /* REALM_EXTERNAL_COMMIT_HELPER_HPP */
