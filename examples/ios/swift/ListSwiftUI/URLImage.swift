import Foundation
import SwiftUI
import Combine

private let cache: NSCache<NSString, NSData>  = {
    let _cache = NSCache<NSString, NSData>.init()
    _cache.countLimit = 100
    return _cache
}()


private final class _URLImageState: ObservableObject {
    var data: Data? {
        didSet {
            DispatchQueue.main.async {
                self.objectWillChange.send(self.data!)
            }
        }
    }

    private var _url: String? = nil
    var url: String? {
        get {
            _url
        }
        set {
            _url = newValue
        }
    }

    public var objectWillChange = PassthroughSubject<Data,Never>()


    func load() {
        if let data = cache.object(forKey: NSString.init(string: _url!)) {
            self.data = data as Data
            return
        }
        URLSession(configuration: .default).dataTask(with: URL(string: url!)!) { data,_,_ in
            guard let data = data else {
                return
            }

            cache.setObject(data as NSData, forKey: NSString.init(string: self._url!))
            self.data = data
        }.resume()
    }
}

struct URLImage: View {
    @ObservedObject private var state = _URLImageState()

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
