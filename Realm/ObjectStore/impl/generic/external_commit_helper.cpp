////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
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

#include "impl/external_commit_helper.hpp"

#include "impl/realm_coordinator.hpp"

#include <realm/commit_log.hpp>
#include <realm/replication.hpp>

using namespace realm;
using namespace realm::_impl;

ExternalCommitHelper::ExternalCommitHelper(RealmCoordinator& parent)
: m_parent(parent)
, m_history(realm::make_client_history(parent.get_path(), parent.get_encryption_key().data()))
, m_sg(*m_history, parent.is_in_memory() ? SharedGroup::durability_MemOnly : SharedGroup::durability_Full,
       parent.get_encryption_key().data())
, m_thread(std::async(std::launch::async, [=] {
    m_sg.begin_read();
    while (m_sg.wait_for_change()) {
        m_sg.end_read();
        m_sg.begin_read();
        m_parent.on_change();
    }
}))
{
}

ExternalCommitHelper::~ExternalCommitHelper()
{
    m_sg.wait_for_change_release();
    m_thread.wait(); // Wait for the thread to exit
}
