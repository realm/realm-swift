////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Realm Inc.
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

import Foundation

@objc(TimeoutProxyServer)
class TimeoutProxyServer: NSObject {
    var incomingRequests: [FileHandle: CFHTTPMessage] = [:]
    var socket: CFSocket?
    let port: Int
    var listeningHandle: FileHandle?

    @objc init(port: Int) {
        self.port = port
    }

    @objc func start() throws {
        socket = CFSocketCreate(kCFAllocatorDefault,
                                PF_INET,
                                SOCK_STREAM,
                                IPPROTO_TCP, 0, nil, nil)
        guard let socket = socket else {
            throw NSError(domain: "TimeoutServerError",
                          code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Unable to create socket"])
        }


        var reuse = true
        let fileDescriptor = CFSocketGetNative(socket)
        guard setsockopt(fileDescriptor, SOL_SOCKET, SO_REUSEADDR,
                       &reuse, socklen_t(MemoryLayout.size(ofValue: Int.self))) != 0 else {
            throw NSError(domain: "TimeoutServerError",
                          code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Unable to set socket options"])
        }

        var address = sockaddr_in()
        address.sin_len = __uint8_t(MemoryLayout.size(ofValue: address))
        address.sin_family = sa_family_t(AF_INET)
        address.sin_addr.s_addr = INADDR_ANY.bigEndian
        address.sin_port = UInt16(port).bigEndian

        let data = Data(bytes: &address, count: MemoryLayout.size(ofValue: address)) as CFData
        guard CFSocketSetAddress(socket, data) == .success else {
            throw NSError(domain: "TimeoutServerError",
                          code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Unable to create socket"])
        }

        listeningHandle = FileHandle(fileDescriptor: fileDescriptor, closeOnDealloc: true)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(receiveIncomingConnectionNotification(notification:)),
                                               name: NSNotification.Name.NSFileHandleConnectionAccepted,
                                               object: nil)
        listeningHandle!.acceptConnectionInBackgroundAndNotify()
    }

    @objc func receiveIncomingConnectionNotification(notification: Notification) {
        let userInfo = notification.userInfo
        let incomingFileHandle = userInfo?[NSFileHandleNotificationFileHandleItem] as? FileHandle

        if let incomingFileHandle = incomingFileHandle {
            incomingRequests[incomingFileHandle] = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, true).takeRetainedValue()
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(receiveIncomingDataNotification(notification:)),
                                                   name: NSNotification.Name.NSFileHandleDataAvailable,
                                                   object: incomingFileHandle)

            incomingFileHandle.waitForDataInBackgroundAndNotify()
        }

        listeningHandle?.acceptConnectionInBackgroundAndNotify()
    }

    @objc func receiveIncomingDataNotification(notification: Notification) {
        // let the incoming requests timeout
    }
}
