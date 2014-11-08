/*************************************************************************
 *
 * TIGHTDB CONFIDENTIAL
 * __________________
 *
 *  [2011] - [2013] TightDB Inc
 *  All Rights Reserved.
 *
 * NOTICE:  All information contained herein is, and remains
 * the property of TightDB Incorporated and its suppliers,
 * if any.  The intellectual and technical concepts contained
 * herein are proprietary to TightDB Incorporated
 * and its suppliers and may be covered by U.S. and Foreign Patents,
 * patents in process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from TightDB Incorporated.
 *
 **************************************************************************/
#ifndef TIGHTDB_VERSION_HPP
#define TIGHTDB_VERSION_HPP

#include <string>
#include <sstream>

#define TIGHTDB_VER_MAJOR 0
#define TIGHTDB_VER_MINOR 85
#define TIGHTDB_VER_PATCH 0

namespace tightdb {

enum Feature {
    feature_Debug,
    feature_Replication
};

class Version {
public:
    static int get_major() { return TIGHTDB_VER_MAJOR; }
    static int get_minor() { return TIGHTDB_VER_MINOR; }
    static int get_patch() { return TIGHTDB_VER_PATCH; }
    static std::string get_version();
    static bool is_at_least(int major, int minor, int patch);
    static bool has_feature(Feature feature);
};


} // namespace tightdb

#endif // TIGHTDB_VERSION_HPP
