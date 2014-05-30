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

inline ColumnMixed::ColumnMixed(): m_binary_data(0)
{
    create(Allocator::get_default(), 0, 0);
}

inline ColumnMixed::ColumnMixed(Allocator& alloc, Table* table, std::size_t column_ndx):
    m_binary_data(0)
{
    create(alloc, table, column_ndx);
}

inline ColumnMixed::ColumnMixed(Allocator& alloc, Table* table, std::size_t column_ndx,
                                ArrayParent* parent, std::size_t ndx_in_parent, ref_type ref):
    m_binary_data(0)
{
    create(alloc, table, column_ndx, parent, ndx_in_parent, ref);
}

inline void ColumnMixed::update_column_index(std::size_t new_col_ndx, const Spec& spec)
    TIGHTDB_NOEXCEPT
{
    m_types->update_column_index(new_col_ndx, spec);
    m_data->update_column_index(new_col_ndx, spec);
    if (m_binary_data)
        m_binary_data->update_column_index(new_col_ndx, spec);
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

inline void ColumnMixed::adj_accessors_move_last_over(std::size_t target_row_ndx,
                                                      std::size_t last_row_ndx) TIGHTDB_NOEXCEPT
{
    m_data->adj_accessors_move_last_over(target_row_ndx, last_row_ndx);
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

inline void ColumnMixed::detach_subtable_accessors() TIGHTDB_NOEXCEPT
{
    m_data->detach_subtable_accessors();
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
    clear_value(ndx, coltype);

    // Shift value one bit and set lowest bit to indicate that this is not a ref
    value = (value << 1) + 1;
    m_data->set(ndx, value);
}

inline void ColumnMixed::set_int(std::size_t ndx, int64_t value)
{
    detach_subtable_accessors();
    set_int64(ndx, value, mixcol_Int, mixcol_IntNeg);
}

inline void ColumnMixed::set_double(std::size_t ndx, double value)
{
    detach_subtable_accessors();
    int64_t val64 = type_punning<int64_t>(value);
    set_int64(ndx, val64, mixcol_Double, mixcol_DoubleNeg);
}

inline void ColumnMixed::set_value(std::size_t ndx, int64_t value, MixedColType coltype)
{
    TIGHTDB_ASSERT(ndx < m_types->size());

    // Remove refs or binary data (sets type to float)
    clear_value(ndx, coltype);

    // Shift value one bit and set lowest bit to indicate that this is not a ref
    int64_t v = (value << 1) + 1;
    m_data->set(ndx, v);
}

inline void ColumnMixed::set_float(std::size_t ndx, float value)
{
    detach_subtable_accessors();
    int64_t val64 = type_punning<int64_t>( value );
    set_value(ndx, val64, mixcol_Float);
}

inline void ColumnMixed::set_bool(std::size_t ndx, bool value)
{
    detach_subtable_accessors();
    set_value(ndx, (value ? 1 : 0), mixcol_Bool);
}

inline void ColumnMixed::set_datetime(std::size_t ndx, DateTime value)
{
    detach_subtable_accessors();
    set_value(ndx, int64_t(value.get_datetime()), mixcol_Date);
}

inline void ColumnMixed::set_subtable(std::size_t ndx, const Table* t)
{
    TIGHTDB_ASSERT(ndx < m_types->size());
    detach_subtable_accessors();
    typedef _impl::TableFriend tf;
    ref_type ref;
    if (t) {
        ref = tf::clone(*t, m_array->get_alloc()); // Throws
    }
    else {
        ref = tf::create_empty_table(m_array->get_alloc()); // Throws
    }
    clear_value(ndx, mixcol_Table); // Remove any previous refs or binary data
    m_data->set(ndx, ref);
}

//
// Inserts
//

// Insert a int64 value.
// Store 63 bit of the value in m_data. Store sign bit in m_types.

inline void ColumnMixed::insert_int64(std::size_t ndx, int64_t value, MixedColType pos_type,
                                      MixedColType neg_type)
{
    TIGHTDB_ASSERT(ndx <= m_types->size());

    // 'store' the sign-bit in the integer-type
    if ((value & TIGHTDB_BIT63) == 0)
        m_types->insert(ndx, pos_type);
    else
        m_types->insert(ndx, neg_type);

    // Shift value one bit and set lowest bit to indicate that this is not a ref
    value = (value << 1) + 1;
    m_data->insert(ndx, value);
}

inline void ColumnMixed::insert_int(std::size_t ndx, int64_t value)
{
    detach_subtable_accessors();
    insert_int64(ndx, value, mixcol_Int, mixcol_IntNeg);
}

inline void ColumnMixed::insert_double(std::size_t ndx, double value)
{
    detach_subtable_accessors();
    int64_t val64 = type_punning<int64_t>(value);
    insert_int64(ndx, val64, mixcol_Double, mixcol_DoubleNeg);
}

inline void ColumnMixed::insert_float(std::size_t ndx, float value)
{
    TIGHTDB_ASSERT(ndx <= m_types->size());
    detach_subtable_accessors();

    // Convert to int32_t first, to ensure we only access 32 bits from the float.
    int32_t val32 = type_punning<int32_t>(value);

    // Shift value one bit and set lowest bit to indicate that this is not a ref
    int64_t val64 = (int64_t(val32) << 1) + 1;
    m_data->insert(ndx, val64);
    m_types->insert(ndx, mixcol_Float);
}

inline void ColumnMixed::insert_bool(std::size_t ndx, bool value)
{
    TIGHTDB_ASSERT(ndx <= m_types->size());
    detach_subtable_accessors();

    // Shift value one bit and set lowest bit to indicate that this is not a ref
    int64_t v = ((value ? 1 : 0) << 1) + 1;

    m_types->insert(ndx, mixcol_Bool);
    m_data->insert(ndx, v);
}

inline void ColumnMixed::insert_datetime(std::size_t ndx, DateTime value)
{
    TIGHTDB_ASSERT(ndx <= m_types->size());
    detach_subtable_accessors();

    // Shift value one bit and set lowest bit to indicate that this is not a ref
    int64_t v = (int64_t(value.get_datetime()) << 1) + 1;

    m_types->insert(ndx, mixcol_Date);
    m_data->insert(ndx, v);
}

inline void ColumnMixed::insert_string(std::size_t ndx, StringData value)
{
    TIGHTDB_ASSERT(ndx <= m_types->size());
    detach_subtable_accessors();
    init_binary_data_column();

    std::size_t data_ndx = m_binary_data->size();
    m_binary_data->add_string(value);

    // Shift value one bit and set lowest bit to indicate that this is not a ref
    int64_t v = int64_t((uint64_t(data_ndx) << 1) + 1);

    m_types->insert(ndx, mixcol_String);
    m_data->insert(ndx, v);
}

inline void ColumnMixed::insert_binary(std::size_t ndx, BinaryData value)
{
    TIGHTDB_ASSERT(ndx <= m_types->size());
    detach_subtable_accessors();
    init_binary_data_column();

    std::size_t data_ndx = m_binary_data->size();
    m_binary_data->add(value);

    // Shift value one bit and set lowest bit to indicate that this is not a ref
    int64_t v = int64_t((uint64_t(data_ndx) << 1) + 1);

    m_types->insert(ndx, mixcol_Binary);
    m_data->insert(ndx, v);
}

inline void ColumnMixed::insert_subtable(std::size_t ndx, const Table* t)
{
    TIGHTDB_ASSERT(ndx <= m_types->size());
    detach_subtable_accessors();
    typedef _impl::TableFriend tf;
    ref_type ref;
    if (t) {
        ref = tf::clone(*t, m_array->get_alloc()); // Throws
    }
    else {
        ref = tf::create_empty_table(m_array->get_alloc()); // Throws
    }
    m_types->insert(ndx, mixcol_Table);
    m_data->insert(ndx, ref);
}

inline std::size_t ColumnMixed::get_size_from_ref(ref_type root_ref,
                                                  Allocator& alloc) TIGHTDB_NOEXCEPT
{
    const char* root_header = alloc.translate(root_ref);
    ref_type types_ref = to_ref(Array::get(root_header, 0));
    return Column::get_size_from_ref(types_ref, alloc);
}

#ifdef TIGHTDB_ENABLE_REPLICATION

inline void ColumnMixed::recursive_mark_table_accessors_dirty() TIGHTDB_NOEXCEPT
{
    m_data->recursive_mark_table_accessors_dirty();
}

inline void ColumnMixed::refresh_after_advance_transact(std::size_t col_ndx, const Spec& spec)
{
    m_array->init_from_parent();
    m_types->refresh_after_advance_transact(col_ndx, spec); // Throws
    m_data->refresh_after_advance_transact(col_ndx, spec); // Throws
    if (m_binary_data) {
        TIGHTDB_ASSERT(m_array->size() == 3);
        m_binary_data->refresh_after_advance_transact(col_ndx, spec); // Throws
        return;
    }
    // See if m_binary_data needs to be created.
    if (m_array->size() == 3) {
        ref_type ref = m_array->get_as_ref(2);
        m_binary_data = new ColumnBinary(ref, m_array, 2, m_array->get_alloc()); // Throws
    }
}

inline void ColumnMixed::RefsColumn::refresh_after_advance_transact(std::size_t col_ndx,
                                                                    const Spec& spec)
{
    ColumnSubtableParent::refresh_after_advance_transact(col_ndx, spec); // Throws
    std::size_t spec_ndx_in_parent = 0; // Ignored because these are root tables
    m_subtable_map.refresh_after_advance_transact(spec_ndx_in_parent); // Throws
}

#endif // TIGHTDB_ENABLE_REPLICATION

} // namespace tightdb
