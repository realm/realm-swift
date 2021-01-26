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
import SwiftUI

@objcMembers class Reminder: EmbeddedObject, ObjectKeyIdentifiable {
    @objc enum Priority: Int, RealmEnum, CaseIterable, Identifiable, CustomStringConvertible {
        var id: Int { self.rawValue }
        case low = 0, medium = 1, high = 2

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

struct UnmanagedReminderRowView: View {
    var body: some View {
        EmptyView()
    }
}

#if os(macOS)
struct ReminderRowView: View {
    @ObservedRealmObject var list: ReminderList
    @ObservedRealmObject var reminder: Reminder
    @State var showPopover = false

    var body: some View {
        HStack {
            TextField("title", text: $reminder.title)
            .popover(isPresented: $showPopover, content: {
                ReminderFormView(list: list, reminder: reminder, showReminderForm: $showPopover).padding()
            })
            Button(action: {
                showPopover = true
            }, label: {
                Image(systemName: "info.circle").buttonStyle(BorderlessButtonStyle())
            })
        }
    }
}
#else
struct ReminderRowView: View {
    @ObservedRealmObject var list: ReminderList
    @ObservedRealmObject var reminder: Reminder
    @State var hasFocus: Bool?
    @State var showReminderForm = false


    var body: some View {
        NavigationLink(destination: ReminderFormView(list: list,
                                                     reminder: reminder,
                                                     showReminderForm: $showReminderForm), isActive: $showReminderForm) {
            TextField("title", text: reminder.bind(\.title))
        }.isDetailLink(true)
    }
}
#endif

struct ReminderFormView: View {
    @ObservedRealmObject var list: ReminderList
    @ObservedRealmObject var reminder: Reminder
    @Binding var showReminderForm: Bool

    var body: some View {
        var view = Form {
            TextField("title", text: $reminder.title)
            DatePicker("date", selection: $reminder.date)
            Picker("priority", selection: $reminder.priority, content: {
                ForEach(Reminder.Priority.allCases) { priority in
                    Text(priority.description).tag(priority)
                }
            })
        }
        #if os(macOS)
        return view
        #else
        return view.navigationBarItems(trailing:
        Button("Save") {
            if reminder.realm == nil {
                $list.reminders.append(reminder)
            }

            showReminderForm.toggle()
        }.disabled(reminder.title.isEmpty))
        #endif
    }
}
struct ReminderListView: View {
    @ObservedRealmObject var list: ReminderList
    @StateRealmObject var selection: Reminder?
    @State var showReminderForm: Bool = false

    var body: some View {
        let view = VStack {
            Text(list.name).font(.title)
            List(selection: $selection) {
                ForEach(list.reminders) { reminder in
                    ReminderRowView(list: list, reminder: reminder).tag(reminder)
                }.onMove(perform: $list.reminders.move)
                .onDelete(perform: $list.reminders.remove)
            }
        }
        #if os(iOS)
        return view.navigationBarItems(trailing: HStack {
            EditButton()
            Button("Add") {
                $list.reminders.append(Reminder())
            }
        })
        #else
        return view
        #endif
    }
}

struct ReminderListRowView: View {
    @ObservedRealmObject var list: ReminderList

    var body: some View {
        HStack {
            Image(systemName: list.icon)
            TextField("List Name", text: $list.name)
            Spacer()
            Text("\(list.reminders.count)")
        }.frame(minWidth: 100)
    }
}

struct ContentView: View {
    @StateRealmObject(ReminderList.self) var lists
    @StateRealmObject var selection: ReminderList?
    @State var searchFilter: String = ""
    var filter: NSPredicate {
        searchFilter.isEmpty ? NSPredicate(format: "TRUEPREDICATE") : NSPredicate(format: "name CONTAINS[c] %@",
                                                                                  searchFilter)
    }

    var body: some View {
        NavigationView {
            VStack {
                TextField("􀊫 Search", text: $searchFilter)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom).padding(.trailing).padding(.leading)
                HStack { Text("My Lists").font(.footnote).padding(); Spacer() }
                List(selection: $selection) {
                    ForEach(lists.filter(filter)) { list in
                        NavigationLink(destination: ReminderListView(list: list).tag(list)) {
                            ReminderListRowView(list: list)
                        }
                        .contextMenu(menuItems: {
                            Button("Delete") {
                                $lists.remove(list)
                            }
                        })
                    }
                }
                Spacer()
                HStack {
                    Button("􀁌 Add List") {
                        $lists.append(ReminderList())
                    }.buttonStyle(BorderlessButtonStyle())
                    .padding()
                    Spacer()
                }
            }.frame(minWidth: 150)
            if let selection = selection {
                ReminderListView(list: selection)
            }
        }.toolbar {
            ToolbarItem {
                Button(action: {
                    $selection.reminders.append(Reminder())
                }, label: {
                    Image(systemName: "plus")
                })
                .accessibility(identifier: "add fresh person").disabled(false)
            }
        }.navigationTitle("")
    }
}

@main
struct App: SwiftUI.App {
    var view: some View {
        ContentView()
    }

    var body: some Scene {
        if let realmPath = ProcessInfo.processInfo.environment["REALM_PATH"] {
            Realm.Configuration.defaultConfiguration =
                Realm.Configuration(fileURL: URL(string: realmPath)!, deleteRealmIfMigrationNeeded: true)
        } else {
            Realm.Configuration.defaultConfiguration =
                Realm.Configuration(deleteRealmIfMigrationNeeded: true)
        }
        return WindowGroup {
            view
        }
    }
}
