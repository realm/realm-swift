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

import UIKit
import RealmSwift

class RepositoriesViewController: UICollectionViewController, UITextFieldDelegate {
    @IBOutlet weak var sortOrderControl: UISegmentedControl!
    @IBOutlet weak var searchField: UITextField!

    var results: Results<Repository>?
    var token: NotificationToken?

    deinit {
        token?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let realm = try! Realm()
        token = realm.observe { [weak self] _, _ in
            self?.reloadData()
        }

        var components = URLComponents(string: "https://api.github.com/search/repositories")!
        components.queryItems = [
            URLQueryItem(name: "q", value: "language:objc"),
            URLQueryItem(name: "sort", value: "stars"),
            URLQueryItem(name: "order", value: "desc")
        ]
        URLSession.shared.dataTask(with: URLRequest(url: components.url!)) { data, _, error in
            if let error = error {
                print(error)
                return
            }

            do {
                let repositories = try JSONSerialization.jsonObject(with: data!, options: []) as! [String: AnyObject]
                let items = repositories["items"] as! [[String: AnyObject]]

                let realm = try Realm()
                try realm.write {
                    for item in items {
                        let repository = Repository()
                        repository.identifier = String(item["id"] as! Int)
                        repository.name = item["name"] as? String
                        repository.avatarURL = item["owner"]!["avatar_url"] as? String

                        realm.add(repository, update: .modified)
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
        }.resume()
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return results?.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! RepositoryCell
        let repository = results![indexPath.item]
        cell.titleLabel.text = repository.name

        URLSession.shared.dataTask(with: URLRequest(url: URL(string: repository.avatarURL!)!)) { (data, _, error) -> Void in
            if let error = error {
                print(error.localizedDescription)
                return
            }

            DispatchQueue.main.async {
                let image = UIImage(data: data!)!
                cell.avatarImageView!.image = image
            }
        }.resume()

        return cell
    }

    func reloadData() {
        let realm = try! Realm()
        results = realm.objects(Repository.self)
        if let text = searchField.text, !text.isEmpty {
            results = results?.filter("name contains[c] %@", text)
        }
        results = results?.sorted(byKeyPath: "name", ascending: sortOrderControl!.selectedSegmentIndex == 0)

        collectionView?.reloadData()
    }

    @IBAction func valueChanged(sender: AnyObject) {
        reloadData()
    }

    @IBAction func clearSearchField(sender: AnyObject) {
        searchField.text = nil
        reloadData()
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        reloadData()
    }
}
