//
//  RepositoriesViewController.swift
//  DownloadCache
//
//  Created by Katsumi Kishikawa on 11/20/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import UIKit
import RealmSwift

class RepositoriesViewController: UICollectionViewController, UITextFieldDelegate {
    @IBOutlet weak var sortOrderControl: UISegmentedControl!
    @IBOutlet weak var searchField: UITextField!

    var results: Results<Repository>?

    override func viewDidLoad() {
        super.viewDidLoad()

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

                    dispatch_async(dispatch_get_main_queue()) {
                        self.reloadData()
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

    func clearData() {
        let realm = try! Realm()
        try! realm.write {
            realm.deleteAll()
        }
    }

    func reloadData() {
        let realm = try! Realm()
        var results = realm.objects(Repository)
        if let text = searchField.text where !text.isEmpty {
            results = results.filter("name contains[c] %@", text)
        }
        self.results = results.sorted("name", ascending: sortOrderControl!.selectedSegmentIndex == 0)

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

