#ifndef TIGHTDB_VIEWS_HPP
#define TIGHTDB_VIEWS_HPP

#include <tightdb/column.hpp>
#include <tightdb/column_string_enum.hpp>

using namespace tightdb;

// This class is for common functionality of ListView and LinkView which inherit from it. Currently it only 
// supports sorting.
class RowIndexes
{
public:
    RowIndexes(Column::unattached_root_tag urt, tightdb::Allocator& alloc) : m_row_indexes(urt, alloc), 
        m_auto_sort(false)  {}
    RowIndexes(Column::move_tag mt, Column& col) : m_row_indexes(mt, col), m_auto_sort(false) {}
    virtual ~RowIndexes() {};

    // Return a column of the table that m_row_indexes are pointing at (which is the target table for LinkList and
    // parent table for TableView)
    virtual const ColumnBase& get_column_base(size_t index) const = 0;

    virtual size_t size() const = 0;

    // These two methods are overridden by TableView. They are no-ops for LinkView because sync'ed automatically
    virtual void sync_if_needed() const {}
    virtual bool is_in_sync() const { return true; }

    // Predicate for std::sort
    struct Sorter
    {
        Sorter(){}
        Sorter(std::vector<size_t> columns, std::vector<bool> ascending) : m_columns(columns), m_ascending(ascending) {};
        bool operator()(size_t i, size_t j) const
        {
            for (size_t t = 0; t < m_columns.size(); t++) {
                const ColumnBase& cb = m_row_indexes_class->get_column_base(m_columns[t]);

                // todo/fixme, cache casted pointers for speed
                const ColumnTemplateBase* ctb = dynamic_cast<const ColumnTemplateBase*>(&cb);
                TIGHTDB_ASSERT(ctb);

                // todo/fixme, special treatment of ColumnStringEnum by calling ColumnStringEnum::compare_values()
                // instead of the general ColumnTemplate::compare_values() becuse it cannot overload inherited 
                // `int64_t get_val()` of Column. Such column inheritance needs to be cleaned up 
                int c;             
                if (dynamic_cast<const ColumnStringEnum*>(&cb))
                    c = static_cast<const ColumnStringEnum*>(&cb)->compare_values(i, j);
                else
                    c = ctb->compare_values(i, j);

                if (c != 0)
                    return m_ascending[t] ? c > 0 : c < 0;
            }
            return false; // row i == row j
        }
        std::vector<size_t> m_columns;
        RowIndexes* m_row_indexes_class;
        std::vector<bool> m_ascending;
    };

    // Sort m_row_indexes according to one column
    void sort(size_t column, bool ascending = true);

    // Sort m_row_indexes according to multiple columns
    void sort(std::vector<size_t> columns, std::vector<bool> ascending);

    // Re-sort view according to last used criterias
    void re_sort();

    Column m_row_indexes;
    Sorter m_sorting_predicate; // Stores sorting criterias (columns + ascending)
    bool m_auto_sort;
};

#endif // TIGHTDB_VIEWS_HPP
