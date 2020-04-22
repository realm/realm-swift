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
import Realm
import Realm.Private

/**
An object representing the Realm App configuration

- see: `RLMAppConfiguration`
*/
public typealias AppConfiguration = RLMAppConfiguration

/**
An object representing a client which performs network calls on
Realm Cloud user api keys

- see: `RLMUserAPIKeyProviderClient`
*/
public typealias UserAPIKeyProviderClient = RLMUserAPIKeyProviderClient

/**
An object representing a client which performs network calls on
Realm Cloud user registration & password functions

- see: `RLMUsernamePasswordProviderClient`
*/
public typealias UsernamePasswordProviderClient = RLMUsernamePasswordProviderClient

/**
An object which is used within UserAPIKeyProviderClient

- see: `RLMUserAPIKey`
*/
public typealias UserAPIKey = RLMUserAPIKey

/**
A `AppCredentials` represents data that uniquely identifies a Realm Object Server user.
*/
public typealias AppCredentials = RLMAppCredentials

/// The `RealmApp` has the fundamental set of methods for communicating with a Realm
/// application backend.

/// This interface provides access to login and authentication.
public typealias RealmApp = RLMApp
