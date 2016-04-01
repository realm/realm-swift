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

#ifndef REALM_REALM_HPP
#define REALM_REALM_HPP

#include <memory>
#include <string>
#include <thread>
#include <vector>

namespace realm {
    class BinaryData;
    class BindingContext;
    class Group;
    class Realm;
    class Replication;
    class Schema;
    class SharedGroup;
    class StringData;
    typedef std::shared_ptr<Realm> SharedRealm;
    typedef std::weak_ptr<Realm> WeakRealm;

    namespace _impl {
        class CollectionNotifier;
        class ListNotifier;
        class RealmCoordinator;
        class ResultsNotifier;
    }

    class Realm : public std::enable_shared_from_this<Realm> {
      public:
        typedef std::function<void(SharedRealm old_realm, SharedRealm realm)> MigrationFunction;

        struct Config {
            std::string path;
            // User-supplied encryption key. Must be either empty or 64 bytes.
            std::vector<char> encryption_key;

            // Optional schema for the file. If nullptr, the existing schema
            // from the file opened will be used. If present, the file will be
            // migrated to the schema if needed.
            std::unique_ptr<Schema> schema;
            uint64_t schema_version;

            MigrationFunction migration_function;
            bool delete_realm_if_migration_needed = false;

            bool read_only = false;
            bool in_memory = false;

            // The following are intended for internal/testing purposes and
            // should not be publicly exposed in binding APIs

            // If false, always return a new Realm instance, and don't return
            // that Realm instance for other requests for a cached Realm. Useful
            // for dynamic Realms and for tests that need multiple instances on
            // one thread
            bool cache = true;
            // Throw an exception rather than automatically upgrading the file
            // format. Used by the browser to warn the user that it'll modify
            // the file.
            bool disable_format_upgrade = false;
            // Disable the background worker thread for producing change
            // notifications. Useful for tests for those notifications so that
            // everything can be done deterministically on one thread, and
            // speeds up tests that don't need notifications.
            bool automatic_change_notifications = true;

            Config();
            Config(Config&&);
            Config(const Config& c);
            ~Config();

            Config& operator=(Config const&);
            Config& operator=(Config&&) = default;
        };

        // Get a cached Realm or create a new one if no cached copies exists
        // Caching is done by path - mismatches for in_memory and read_only
        // Config properties will raise an exception
        // If schema/schema_version is specified, update_schema is called
        // automatically on the realm and a migration is performed. If not
        // specified, the schema version and schema are dynamically read from
        // the the existing Realm.
        static SharedRealm get_shared_realm(Config config);

        // Updates a Realm to a given target schema/version creating tables and
        // updating indexes as necessary. Uses the existing migration function
        // on the Config, and the resulting Schema and version with updated
        // column mappings are set on the realms config upon success.
        void update_schema(std::unique_ptr<Schema> schema, uint64_t version);

        static uint64_t get_schema_version(Config const& config);

        const Config &config() const { return m_config; }

        void begin_transaction();
        void commit_transaction();
        void cancel_transaction();
        bool is_in_transaction() const noexcept;
        bool is_in_read_transaction() const { return !!m_group; }

        bool refresh();
        void set_auto_refresh(bool auto_refresh) { m_auto_refresh = auto_refresh; }
        bool auto_refresh() const { return m_auto_refresh; }
        void notify();

        void invalidate();
        bool compact();
        void write_copy(StringData path, BinaryData encryption_key);

        std::thread::id thread_id() const { return m_thread_id; }
        void verify_thread() const;
        void verify_in_write() const;

        bool can_deliver_notifications() const noexcept;

        // Close this Realm and remove it from the cache. Continuing to use a
        // Realm after closing it will produce undefined behavior.
        void close();

        bool is_closed() { return !m_read_only_group && !m_shared_group; }

        ~Realm();

        void init(std::shared_ptr<_impl::RealmCoordinator> coordinator);
        Realm(Config config);

        // Expose some internal functionality to other parts of the ObjectStore
        // without making it public to everyone
        class Internal {
            friend class _impl::CollectionNotifier;
            friend class _impl::ListNotifier;
            friend class _impl::RealmCoordinator;
            friend class _impl::ResultsNotifier;

            // ResultsNotifier and ListNotifier need access to the SharedGroup
            // to be able to call the handover functions, which are not very wrappable
            static SharedGroup& get_shared_group(Realm& realm) { return *realm.m_shared_group; }

            // CollectionNotifier needs to be able to access the owning
            // coordinator to wake up the worker thread when a callback is
            // added, and coordinators need to be able to get themselves from a Realm
            static _impl::RealmCoordinator& get_coordinator(Realm& realm) { return *realm.m_coordinator; }
        };

        static void open_with_config(const Config& config,
                                     std::unique_ptr<Replication>& history,
                                     std::unique_ptr<SharedGroup>& shared_group,
                                     std::unique_ptr<Group>& read_only_group);

      private:
        Config m_config;
        std::thread::id m_thread_id = std::this_thread::get_id();
        bool m_auto_refresh = true;

        std::unique_ptr<Replication> m_history;
        std::unique_ptr<SharedGroup> m_shared_group;
        std::unique_ptr<Group> m_read_only_group;

        Group *m_group = nullptr;

        std::shared_ptr<_impl::RealmCoordinator> m_coordinator;

      public:
        std::unique_ptr<BindingContext> m_binding_context;

        // FIXME private
        Group *read_group();
    };

    class RealmFileException : public std::runtime_error {
    public:
        enum class Kind {
            /** Thrown for any I/O related exception scenarios when a realm is opened. */
            AccessError,
            /** Thrown if the user does not have permission to open or create
             the specified file in the specified access mode when the realm is opened. */
            PermissionDenied,
            /** Thrown if create_Always was specified and the file did already exist when the realm is opened. */
            Exists,
            /** Thrown if no_create was specified and the file was not found when the realm is opened. */
            NotFound,
            /** Thrown if the database file is currently open in another
             process which cannot share with the current process due to an
             architecture mismatch. */
            IncompatibleLockFile,
            /** Thrown if the file needs to be upgraded to a new format, but upgrades have been explicitly disabled. */
            FormatUpgradeRequired,
        };
        RealmFileException(Kind kind, std::string path, std::string message, std::string underlying) :
            std::runtime_error(std::move(message)), m_kind(kind), m_path(std::move(path)), m_underlying(std::move(underlying)) {}
        Kind kind() const { return m_kind; }
        const std::string& path() const { return m_path; }
        const std::string& underlying() const { return m_underlying; }

    private:
        Kind m_kind;
        std::string m_path;
        std::string m_underlying;
    };

    class MismatchedConfigException : public std::runtime_error {
    public:
        MismatchedConfigException(std::string message) : std::runtime_error(move(message)) {}
    };

    class InvalidTransactionException : public std::runtime_error {
    public:
        InvalidTransactionException(std::string message) : std::runtime_error(move(message)) {}
    };

    class IncorrectThreadException : public std::runtime_error {
    public:
        IncorrectThreadException() : std::runtime_error("Realm accessed from incorrect thread.") {}
    };

    class UninitializedRealmException : public std::runtime_error {
    public:
        UninitializedRealmException(std::string message) : std::runtime_error(move(message)) {}
    };
}

#endif /* defined(REALM_REALM_HPP) */
