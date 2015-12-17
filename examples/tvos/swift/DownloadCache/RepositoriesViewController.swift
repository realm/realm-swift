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
        let realm = try! Realm()
        if let token = token {
            realm.removeNotification(token)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let realm = try! Realm()
        token = realm.addNotificationBlock { [weak self] notification, realm in
            self?.reloadData()
        }

        let components = NSURLComponents(string: "https://api.github.com/search/repositories")!
        components.queryItems = [
            NSURLQueryItem(name: "q", value: "language:objc"),
            NSURLQueryItem(name: "sort", value: "stars"),
            NSURLQueryItem(name: "order", value: "desc")
        ]
        NSURLSession.sharedSession().dataTaskWithRequest(NSURLRequest(URL: components.URL!)) { (data, response, error) -> Void in
            if let error = error {
                NSLog("%@", error.localizedDescription)
                return
            }

            do {
                let repositories = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as! [String: AnyObject]
                let items = repositories["items"] as! [[String: AnyObject]]

                let realm = try Realm()
                try realm.write {
                    for item in items {
                        let repository = Repository()
                        repository.identifier = String(item["id"] as! Int)
                        repository.name = item["name"] as? String
                        repository.avatarURL = item["owner"]!["avatar_url"] as? String;

                        realm.add(repository, update: true)
                    }
                }

            } catch (let error as NSError) {
                NSLog("%@", error.localizedDescription)
            }
        }.resume()
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return results?.count ?? 0
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! RepositoryCell

        let repository = results![indexPath.item];

        cell.titleLabel.text = repository.name

        NSURLSession.sharedSession().dataTaskWithRequest(NSURLRequest(URL: NSURL(string: repository.avatarURL!)!)) { (data, response, error) -> Void in
            if let error = error {
                NSLog("%@", error.localizedDescription)
                return
            }

            dispatch_async(dispatch_get_main_queue()) {
                let image = UIImage(data: data!)!
                cell.avatarImageView!.image = image
            }
        }.resume()

        return cell
    }

    func reloadData() {
        let realm = try! Realm()
        results = realm.objects(Repository)
        if let text = searchField.text where !text.isEmpty {
            results = results?.filter("name contains[c] %@", text)
        }
        results = results?.sorted("name", ascending: sortOrderControl!.selectedSegmentIndex == 0)

        collectionView?.reloadData()
    }

    @IBAction func valueChanged(sender: AnyObject) {
        reloadData()
    }

    @IBAction func clearSearchField(sender: AnyObject) {
        searchField.text = nil
        reloadData()
    }

    func textFieldDidEndEditing(textField: UITextField) {
        reloadData()
    }
}

