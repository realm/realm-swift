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
import SwiftUI
import Combine

/// A static cache to allow the reuse of downloaded images.
private let cache: NSCache<NSString, NSData>  = {
    let cache = NSCache<NSString, NSData>()
    cache.countLimit = 100
    return cache
}()

private final class URLImageState: ObservableObject {
    /// The URL of a given image.
    var url: String?
    /// The publisher that will notify the view when the image download is complete.
    var objectWillChange = PassthroughSubject<Data, Never>()
    /// The `Data` of a downloaded image.
    var data: Data? {
        didSet {
            // Dispatch to our publisher that we have received a new set of data.
            DispatchQueue.main.async {
                self.objectWillChange.send(self.data!)
            }
        }
    }

    /// Asynchronously load the data for an image.
    func load() {
        // See if we have downloaded an image for this URL before. If so,
        // fetch the image and set it to our data field.
        if let data = cache.object(forKey: NSString(string: url!)) {
            self.data = data as Data
            return
        }

        // Download an image from the given URL.
        URLSession(configuration: .default).dataTask(with: URL(string: url!)!) { data, _, _ in
            // TODO: Handle errors. In the meantime, if we have nonnull data, continue.
            guard let data = data else {
                return
            }

            // Add the data to our cache using bridged types.
            cache.setObject(data as NSData, forKey: NSString(string: self.url!))
            self.data = data
        }.resume()
    }
}

/// A view that displays an image from a given URL.
struct URLImage: View {
    @ObservedObject private var state = URLImageState()

    init(_ url: String) {
        state.url = url
        state.load()
    }

    var body: some View {
        state.data.flatMap {
            UIImage(data: $0).flatMap {
                Image(uiImage: $0).renderingMode(.original)
            }
        }
    }
}
