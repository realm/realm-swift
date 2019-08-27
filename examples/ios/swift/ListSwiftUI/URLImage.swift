import Foundation
import SwiftUI

private class _URLImageState: ObservableObject {
    static let cache  = NSCache<NSString, UIImage>.init()

    var uiImage = UIImage()
    init() {
        _URLImageState.cache.countLimit = 100
    }

    private var _url: String? = nil
    var url: String? {
        get {
            _url
        }
        set {
            _url = newValue
            if let obj = _URLImageState.cache.object(forKey: NSString.init(string: _url!)) {
                self.uiImage = obj
                self.objectWillChange.send()
                return
            }
            URLSession(configuration: .default).dataTask(with: URL(string: newValue!)!) { data,_,_ in
                guard let data = data else {
                    return
                }

                guard let uiImage = UIImage(data: data) else {
                    return
                }
                _URLImageState.cache.setObject(uiImage, forKey: NSString.init(string: self._url!))
                self.uiImage = uiImage
                self.objectWillChange.send()
            }.resume()
        }
    }
}

struct URLImage: View {
    @ObservedObject private var state = _URLImageState()

    init(_ url: String) {
        state.url = url
    }

    var body: some View {
        Image(uiImage: state.uiImage)
    }
}
