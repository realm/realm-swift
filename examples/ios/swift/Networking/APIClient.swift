//
//  APIClient.swift
//  SixSquare
//
//  Created by Samuel E. Giddins on 12/10/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

import Foundation

struct APIClient {
    let baseURL: NSURL
    let clientID = "KGB2WZEKYVNAWWVOCG1F3RHFP1VRGCT1SYBBPQWZQULFCNAX"
    let clientSecret = "4NYUGSHVNKASLP2CHTDC1S0YWYIZMQE5S215IMBETZ3WHJOA"
    let versionDate = "20140401"
    let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())

    func request(path: String, var parameters: [String:String], completion: ([String:AnyObject]?) -> ()) -> Void {
        var components = NSURLComponents(URL: baseURL, resolvingAgainstBaseURL: false)!
        components.path? += path
        if components.queryItems == nil {
            components.queryItems = []
        }
        components.queryItems?.append(NSURLQueryItem(name: "client_id", value: clientID))
        components.queryItems?.append(NSURLQueryItem(name: "client_secret", value: clientSecret))
        components.queryItems?.append(NSURLQueryItem(name: "v", value: versionDate))
        for (key, value) in parameters {
            components.queryItems?.append(NSURLQueryItem(name: key, value: value))
        }
        let URL = components.URL!
        session.dataTaskWithURL(URL, completionHandler: { (data, response, error) -> Void in
            completion(NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments, error: nil) as? [String:AnyObject])
        }).resume()
    }
    
    init(baseURL: NSURL) {
        self.baseURL = baseURL
    }
}

