/*************************************************************************
 *
 * TIGHTDB CONFIDENTIAL
 * __________________
 *
 *  [2011] - [2014] TightDB Inc
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
#ifndef TIGHTDB_LINK_VIEW_FWD_HPP
#define TIGHTDB_LINK_VIEW_FWD_HPP

#include <tightdb/util/bind_ptr.hpp>

namespace tightdb {

class LinkView;
typedef util::bind_ptr<LinkView> LinkViewRef;
typedef util::bind_ptr<const LinkView> ConstLinkViewRef;

} // namespace tightdb

#endif // TIGHTDB_LINK_VIEW_FWD_HPP
