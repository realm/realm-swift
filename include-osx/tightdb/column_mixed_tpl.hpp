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

namespace tightdb {

inline ColumnMixed::ColumnMixed(Allocator& alloc, ref_type ref,
                                Table* table, std::size_t column_ndx)
{
    create(alloc, ref, table, column_ndx);
}

inline void ColumnMixed::adj_accessors_insert_rows(std::size_t row_ndx,
                                                   std::size_t num_rows) TIGHTDB_NOEXCEPT
{
    m_data->adj_accessors_insert_rows(row_ndx, num_rows);
}

inline void ColumnMixed::adj_accessors_erase_row(std::size_t row_ndx) TIGHTDB_NOEXCEPT
{
    m_data->adj_accessors_erase_row(row_ndx);
}

inline void ColumnMixed::adj_accessors_move(std::size_t target_row_ndx,
                                            std::size_t source_row_ndx) TIGHTDB_NOEXCEPT
{
    m_data->adj_accessors_move(target_row_ndx, source_row_ndx);
}

inline void ColumnMixed::adj_acc_clear_root_table() TIGHTDB_NOEXCEPT
{
    m_data->adj_acc_clear_root_table();
}

inline ref_type ColumnMixed::get_subtable_ref(std::size_t row_ndx) const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(row_ndx < m_types->size());
    if (m_types->get(row_ndx) != type_Table)
        return 0;
    return m_data->get_as_ref(row_ndx);
}

inline std::size_t ColumnMixed::get_subtable_size(std::size_t row_ndx) const TIGHTDB_NOEXCEPT
{
    ref_type top_ref = get_subtable_ref(row_ndx);
    if (top_ref == 0)
        return 0;
    return _impl::TableFriend::get_size_from_ref(top_ref, m_data->get_alloc());
}

inline Table* ColumnMixed::get_subtable_accessor(std::size_t row_ndx) const TIGHTDB_NOEXCEPT
{
    return m_data->get_subtable_accessor(row_ndx);
}

inline void ColumnMixed::discard_subtable_accessor(std::size_t row_ndx) TIGHTDB_NOEXCEPT
{
    m_data->discard_subtable_accessor(row_ndx);
}

inline Table* ColumnMixed::get_subtable_ptr(std::size_t row_ndx)
{
    TIGHTDB_ASSERT(row_ndx < m_types->size());
    if (m_types->get(row_ndx) != type_Table)
        return 0;
    return m_data->get_subtable_ptr(row_ndx); // Throws
}

inline const Table* ColumnMixed::get_subtable_ptr(std::size_t subtable_ndx) const
{
    return const_cast<ColumnMixed*>(this)->get_subtable_ptr(subtable_ndx);
}

inline void ColumnMixed::discard_child_accessors() TIGHTDB_NOEXCEPT
{
    m_data->discard_child_accessors();
}


//
// Getters
//

#define TIGHTDB_BIT63 0x8000000000000000ULL

inline int64_t ColumnMixed::get_value(std::size_t ndx) const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(ndx < m_types->size());

    // Shift the unsigned value right - ensuring 0 gets in from left.
    // Shifting signed integers right doesn't ensure 0's.
    uint64_t value = uint64_t(m_data->get(ndx)) >> 1;
    return int64_t(value);
}

inline int64_t ColumnMixed::get_int(std::size_t ndx) const TIGHTDB_NOEXCEPT
{
    // Get first 63 bits of the integer value
    int64_t value = get_value(ndx);

    // restore 'sign'-bit from the column-type
    MixedColType col_type = MixedColType(m_types->get(ndx));
    if (col_type == mixcol_IntNeg) {
        // FIXME: Bad cast of result of '|' from unsigned to signed
        value |= TIGHTDB_BIT63; // set sign bit (63)
    }
    else {
        TIGHTDB_ASSERT(col_type == mixcol_Int);
    }
    return value;
}

inline bool ColumnMixed::get_bool(std::size_t ndx) const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(m_types->get(ndx) == mixcol_Bool);

    return (get_value(ndx) != 0);
}

inline DateTime ColumnMixed::get_datetime(std::size_t ndx) const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(m_types->get(ndx) == mixcol_Date);

    return DateTime(std::time_t(get_value(ndx)));
}

inline float ColumnMixed::get_float(std::size_t ndx) const TIGHTDB_NOEXCEPT
{
    TIGHTDB_STATIC_ASSERT(std::numeric_limits<float>::is_iec559, "'float' is not IEEE");
    TIGHTDB_STATIC_ASSERT((sizeof (float) * CHAR_BIT == 32), "Assume 32 bit float.");
    TIGHTDB_ASSERT(m_types->get(ndx) == mixcol_Float);

    return type_punning<float>(get_value(ndx));
}

inline double ColumnMixed::get_double(std::size_t ndx) const TIGHTDB_NOEXCEPT
{
    TIGHTDB_STATIC_ASSERT(std::numeric_limits<double>::is_iec559, "'double' is not IEEE");
    TIGHTDB_STATIC_ASSERT((sizeof (double) * CHAR_BIT == 64), "Assume 64 bit double.");

    int64_t int_val = get_value(ndx);

    // restore 'sign'-bit from the column-type
    MixedColType col_type = MixedColType(m_types->get(ndx));
    if (col_type == mixcol_DoubleNeg)
        int_val |= TIGHTDB_BIT63; // set sign bit (63)
    else {
        TIGHTDB_ASSERT(col_type == mixcol_Double);
    }
    return type_punning<double>(int_val);
}

inline StringData ColumnMixed::get_string(std::size_t ndx) const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(ndx < m_types->size());
    TIGHTDB_ASSERT(m_types->get(ndx) == mixcol_String);
    TIGHTDB_ASSERT(m_binary_data);

    std::size_t data_ndx = std::size_t(int64_t(m_data->get(ndx)) >> 1);
    return m_binary_data->get_string(data_ndx);
}

inline BinaryData ColumnMixed::get_binary(std::size_t ndx) const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(ndx < m_types->size());
    TIGHTDB_ASSERT(m_types->get(ndx) == mixcol_Binary);
    TIGHTDB_ASSERT(m_binary_data);

    std::size_t data_ndx = std::size_t(uint64_t(m_data->get(ndx)) >> 1);
    return m_binary_data->get(data_ndx);
}

//
// Setters
//

// Set a int64 value.
// Store 63 bit of the value in m_data. Store sign bit in m_types.

inline void ColumnMixed::set_int64(std::size_t ndx, int64_t value, MixedColType pos_type, MixedColType neg_type)
{
    TIGHTDB_ASSERT(ndx < m_types->size());

    // If sign-bit is set in value, 'store' it in the column-type
    MixedColType coltype = ((value & TIGHTDB_BIT63) == 0) ? pos_type : neg_type;

    // Remove refs or binary data (sets type to double)
    clear_value_and_discard_subtab_acc(ndx, coltype); // Throws

    // Shift value one bit and set lowest bit to indicate that this is not a ref
    value = (value << 1) + 1;
    m_data->set(ndx, value);
}

inline void ColumnMixed::set_int(std::size_t ndx, int64_t value)
{
    set_int64(ndx, value, mixcol_Int, mixcol_IntNeg); // Throws
}

inline void ColumnMixed::set_double(std::size_t ndx, double value)
{
    int64_t val64 = type_punning<int64_t>(value);
    set_int64(ndx, val64, mixcol_Double, mixcol_DoubleNeg); // Throws
}

inline void ColumnMixed::set_value(std::size_t ndx, int64_t value, MixedColType coltype)
{
    TIGHTDB_ASSERT(ndx < m_types->size());

    // Remove refs or binary data (sets type to float)
    clear_value_and_discard_subtab_acc(ndx, coltype); // Throws

    // Shift value one bit and set lowest bit to indicate that this is not a ref
    int64_t v = (value << 1) + 1;
    m_data->set(ndx, v); // Throws
}

inline void ColumnMixed::set_float(std::size_t ndx, float value)
{
    int64_t val64 = type_punning<int64_t>(value);
    set_value(ndx, val64, mixcol_Float); // Throws
}

inline void ColumnMixed::set_bool(std::size_t ndx, bool value)
{
    set_value(ndx, (value ? 1 : 0), mixcol_Bool); // Throws
}

inline void ColumnMixed::set_datetime(std::size_t ndx, DateTime value)
{
    set_value(ndx, int64_t(value.get_datetime()), mixcol_Date); // Throws
}

inline void ColumnMixed::set_subtable(std::size_t ndx, const Table* t)
{
    TIGHTDB_ASSERT(ndx < m_types->size());
    typedef _impl::TableFriend tf;
    ref_type ref;
    if (t) {
        ref = tf::clone(*t, m_array->get_alloc()); // Throws
    }
    else {
        ref = tf::create_empty_table(m_array->get_alloc()); // Throws
    }
    // Remove any previous refs or binary data
    clear_value_and_discard_subtab_acc(ndx, mixcol_Table); // Throws
    m_data->set(ndx, ref); // Throws
}

//
// Inserts
//

inline void ColumnMixed::insert_value(std::size_t row_ndx, int_fast64_t types_value,
                                      int_fast64_t data_value)
{
    std::size_t size = m_types->size(); // Slow
    bool is_append = row_ndx == size;
    std::size_t row_ndx_2 = is_append ? tightdb::npos : row_ndx;
    std::size_t num_rows = 1;
    m_types->do_insert(row_ndx_2, types_value, num_rows); // Throws
    m_data->do_insert(row_ndx_2, data_value, num_rows); // Throws
}

// Insert a int64 value.
// Store 63 bit of the value in m_data. Store sign bit in m_types.

inline void ColumnMixed::insert_int(std::size_t ndx, int_fast64_t value, MixedColType type)
{
    int_fast64_t types_value = type;
    // Shift value one bit and set lowest bit to indicate that this is not a ref
    int_fast64_t data_value =  1 + (value << 1);
    insert_value(ndx, types_value, data_value); // Throws
}

inline void ColumnMixed::insert_pos_neg(std::size_t ndx, int_fast64_t value, MixedColType pos_type,
                                        MixedColType neg_type)
{
    // 'store' the sign-bit in the integer-type
    MixedColType type = (value & TIGHTDB_BIT63) == 0 ? pos_type : neg_type;
    int_fast64_t types_value = type;
    // Shift value one bit and set lowest bit to indicate that this is not a ref
    int_fast64_t data_value =  1 + (value << 1);
    insert_value(ndx, types_value, data_value); // Throws
}

inline void ColumnMixed::insert_int(std::size_t ndx, int_fast64_t value)
{
    insert_pos_neg(ndx, value, mixcol_Int, mixcol_IntNeg); // Throws
}

inline void ColumnMixed::insert_double(std::size_t ndx, double value)
{
    int_fast64_t value_2 = type_punning<int64_t>(value);
    insert_pos_neg(ndx, value_2, mixcol_Double, mixcol_DoubleNeg); // Throws
}

inline void ColumnMixed::insert_float(std::size_t ndx, float value)
{
    int_fast64_t value_2 = type_punning<int32_t>(value);
    insert_int(ndx, value_2, mixcol_Float); // Throws
}

inline void ColumnMixed::insert_bool(std::size_t ndx, bool value)
{
    int_fast64_t value_2 = int_fast64_t(value);
    insert_int(ndx, value_2, mixcol_Bool); // Throws
}

inline void ColumnMixed::insert_datetime(std::size_t ndx, DateTime value)
{
    int_fast64_t value_2 = int_fast64_t(value.get_datetime());
    insert_int(ndx, value_2, mixcol_Date); // Throws
}

inline void ColumnMixed::insert_string(std::size_t ndx, StringData value)
{
    ensure_binary_data_column();
    std::size_t blob_ndx = m_binary_data->size();
    m_binary_data->add_string(value); // Throws

    int_fast64_t value_2 = int_fast64_t(blob_ndx);
    insert_int(ndx, value_2, mixcol_String); // Throws
}

inline void ColumnMixed::insert_binary(std::size_t ndx, BinaryData value)
{
    ensure_binary_data_column();
    std::size_t blob_ndx = m_binary_data->size();
    m_binary_data->add(value); // Throws

    int_fast64_t value_2 = int_fast64_t(blob_ndx);
    insert_int(ndx, value_2, mixcol_Binary); // Throws
}

inline void ColumnMixed::insert_subtable(std::size_t ndx, const Table* t)
{
    typedef _impl::TableFriend tf;
    ref_type ref;
    if (t) {
        ref = tf::clone(*t, m_array->get_alloc()); // Throws
    }
    else {
        ref = tf::create_empty_table(m_array->get_alloc()); // Throws
    }
    int_fast64_t types_value = mixcol_Table;
    int_fast64_t data_value = int_fast64_t(ref);
    insert_value(ndx, types_value, data_value); // Throws
}

// Implementing pure virtual method of ColumnBase.
inline void ColumnMixed::insert(std::size_t row_ndx, std::size_t num_rows, bool is_append)
{
    std::size_t row_ndx_2 = is_append ? tightdb::npos : row_ndx;

    int_fast64_t type_value = mixcol_Int;
    m_types->do_insert(row_ndx_2, type_value, num_rows); // Throws

    // The least significant bit indicates that the rest of the bits form an
    // integer value, so 1 is actually zero.
    int_fast64_t data_value = 1;
    m_data->do_insert(row_ndx_2, data_value, num_rows); // Throws
}

inline std::size_t ColumnMixed::get_size_from_ref(ref_type root_ref,
                                                  Allocator& alloc) TIGHTDB_NOEXCEPT
{
    const char* root_header = alloc.translate(root_ref);
    ref_type types_ref = to_ref(Array::get(root_header, 0));
    return Column::get_size_from_ref(types_ref, alloc);
}

inline void ColumnMixed::clear_value_and_discard_subtab_acc(std::size_t row_ndx, MixedColType new_type)
{
    MixedColType old_type = clear_value(row_ndx, new_type);
    if (old_type == mixcol_Table)
        m_data->discard_subtable_accessor(row_ndx);
}

inline void ColumnMixed::mark(int type) TIGHTDB_NOEXCEPT
{
    m_data->mark(type);
}

inline void ColumnMixed::refresh_accessor_tree(std::size_t col_ndx, const Spec& spec)
{
    m_array->init_from_parent();
    m_types->refresh_accessor_tree(col_ndx, spec); // Throws
    m_data->refresh_accessor_tree(col_ndx, spec); // Throws
    if (m_binary_data) {
        TIGHTDB_ASSERT(m_array->size() == 3);
        m_binary_data->refresh_accessor_tree(col_ndx, spec); // Throws
        return;
    }
    // See if m_binary_data needs to be created.
    if (m_array->size() == 3) {
        ref_type ref = m_array->get_as_ref(2);
        m_binary_data = new ColumnBinary(m_array->get_alloc(), ref); // Throws
        m_binary_data->set_parent(m_array, 2);
    }
}

inline void ColumnMixed::RefsColumn::refresh_accessor_tree(std::size_t col_ndx, const Spec& spec)
{
    ColumnSubtableParent::refresh_accessor_tree(col_ndx, spec); // Throws
    std::size_t spec_ndx_in_parent = 0; // Ignored because these are root tables
    m_subtable_map.refresh_accessor_tree(spec_ndx_in_parent); // Throws
}

} // namespace tightdb
