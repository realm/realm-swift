//
//  RealmSync.swift
//  Realm
//
//  Created by Simon Ask Ulsnes on 07/06/2016.
//  Copyright © 2016 Realm. All rights reserved.
//

import Realm
import Realm.Private
import Foundation

public extension Realm {
    func refreshCredentialsWithProvider(provider: RLMRealmSyncIdentityProvider, token: String, appID: String) {
        self.rlmRealm.refreshCredendialsWithProvider(provider, andToken: token, withAppID: appID)
    }
}