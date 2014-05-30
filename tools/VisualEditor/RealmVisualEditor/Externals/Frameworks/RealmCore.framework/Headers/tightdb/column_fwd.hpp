/*************************************************************************
 *
 * TIGHTDB CONFIDENTIAL
 * __________________
 *
 *  [2011] - [2012] TightDB Inc
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
#ifndef TIGHTDB_COLUMN_FWD_HPP
#define TIGHTDB_COLUMN_FWD_HPP

namespace tightdb {


class ColumnBase;
class Column;
template<class T> class BasicColumn;
typedef BasicColumn<double> ColumnDouble;
typedef BasicColumn<float> ColumnFloat;
class AdaptiveStringColumn;
class ColumnStringEnum;
class ColumnBinary;
class ColumnTable;
class ColumnMixed;
class ColumnLink;

} // namespace tightdb

#endif // TIGHTDB_COLUMN_FWD_HPP
