////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 Realm Inc.
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

import RealmSwift
import Foundation

@objcMembers class Reminder: EmbeddedObject, ObjectKeyIdentifiable {
    @objc enum Priority: Int, RealmEnum, CaseIterable, Identifiable, CustomStringConvertible {
        var id: Int { self.rawValue }

        case low, medium, high

        var description: String {
            switch self {
            case .low: return "low"
            case .medium: return "medium"
            case .high: return "high"
            }
        }
    }
    dynamic var title = ""
    dynamic var notes = ""
    dynamic var isFlagged = false
    dynamic var date = Date()
    dynamic var isComplete = false
    dynamic var priority: Priority = .low
}

@objcMembers class ReminderList: Object, ObjectKeyIdentifiable {
    dynamic var name = "New List"
    dynamic var icon: String = "list.bullet"
    var reminders = RealmSwift.List<Reminder>()
}
