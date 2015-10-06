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

// Intentionally left empty, because this exposes a type conforming to
// Swift 2.0's ErrorType to be able to catch errors with the builtin
// error handling in built variants of the Realm Swift binding targeting
// these newer Swift versions.
//
// If you're using Swift 1.2, you will need to use error pointers instead
// and can rely on the error's code and compare it to constants exposed in
// RLMConstants.h to differentiate possible error causes, as seen in the
// example below:
//
//     var error: NSError?
//     let realm = Realm(configuration: Configuration.defaultConfiguration, error: &error)
//     switch error.code {
//     case RLMError.IncompatibleLockFile:
//          #if !(TARGET_IPHONE_SIMULATOR)
//             print("Make sure that the browser is not attached simultaneously.")
//          #endif
//          break
//     }
