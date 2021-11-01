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

class Reminder: EmbeddedObject, ObjectKeyIdentifiable {
     enum Priority: Int, PersistableEnum, CaseIterable, Identifiable, CustomStringConvertible {
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
    @Persisted var title = ""
    @Persisted var notes = ""
    @Persisted var isFlagged = false
    @Persisted var date = Date()
    @Persisted var isComplete = false
    @Persisted var priority: Priority = .low
}

class ReminderList: Object, ObjectKeyIdentifiable {
    @Persisted var name = "New List"
    @Persisted var icon = "list.bullet"
    @Persisted var reminders = RealmSwift.List<Reminder>()
}
