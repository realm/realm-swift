
#ifndef __TDB_TABLE_REF__
#define __TDB_TABLE_REF__

#include <algorithm>
#include <ostream>

namespace tightdb {

/**
 * A "smart" reference to a table.
 *
 * This kind of table reference is often needed when working with
 * subtables. For example:
 *
 * \code{.cpp}
 *
 *   void func(Table &table)
 *   {
 *     Table &sub1 = *table.GetTable(0,0); // INVALID! (sub1 becomes 'dangeling')
 *     TableRef sub2 = table.GetTable(0,0); // Safe!
 *   }
 *
 * \endcode
 *
 * \note When a top-level table is destroyed, all "smart" table
 * references obtained from it, or from any of its subtables, are
 * invalidated.
 */
template<class T> struct BasicTableRef
{
	/**
	 * Construct a null reference.
	 */
	BasicTableRef(): m_table(0) {}

	/**
	 * Copy a reference.
	 */
	BasicTableRef(BasicTableRef const &r) { bind(r.m_table); }

	/**
	 * Copy a reference from a pointer compatible table type.
	 */
	template<class U> BasicTableRef(BasicTableRef<U> const &r) { bind(r.m_table); }

	~BasicTableRef() { unbind(); }

	/**
	 * Copy a reference.
	 */
	BasicTableRef &operator=(BasicTableRef const &r) { reset(r.m_table); return *this; }

	/**
	 * Copy a reference from a pointer compatible table type.
	 */
	template<class U> BasicTableRef &operator=(BasicTableRef<U> const &r);

	/**
	 * Allow comparison between related reference types.
	 */
	template<class U> bool operator==(BasicTableRef<U> const &) const;

	/**
	 * Allow comparison between related reference types.
	 */
	template<class U> bool operator!=(BasicTableRef<U> const &) const;

	/**
	 * Allow comparison between related reference types.
	 */
	template<class U> bool operator<(BasicTableRef<U> const &) const;

	/**
	 * Dereference this table reference.
	 */
	T &operator*() const { return *m_table; }

	/**
	 * Dereference this table reference for method invocation.
	 */
	T *operator->() const { return m_table; }

	/**
	 * Efficient swapping that avoids binding and unbinding.
	 */
	void swap(BasicTableRef &r) { using std::swap; swap(m_table, r.m_table); }

private:
	typedef T *BasicTableRef::*unspecified_bool_type;

public:
	/**
	 * Test if this is a proper reference (ie. not a null reference.)
	 *
	 * \return True if, and only if this is a proper reference.
	 */
	operator unspecified_bool_type() const;

private:
	friend class Table;
	friend class TopLevelTable;
	template<class> friend class BasicTableRef;

	template<class U, class V> friend
	BasicTableRef<U> static_table_cast(BasicTableRef<V> const &);
	template<class U, class V> friend
	BasicTableRef<U> dynamic_table_cast(BasicTableRef<V> const &);
	template<class C, class U, class V>	friend
	std::basic_ostream<C,U> &operator<<(std::basic_ostream<C,U> &, BasicTableRef<V> const &);

	T *m_table;

	BasicTableRef(T *t) { bind(t); }

	void reset(T * = 0);
	void bind(T *);
	void unbind();
};


/**
 * Efficient swapping that avoids access to the referenced object,
 * in particular, its reference count.
 */
template<class T> inline void swap(BasicTableRef<T> &, BasicTableRef<T> &);

template<class T, class U> BasicTableRef<T> static_table_cast(BasicTableRef<U> const &);

template<class T, class U> BasicTableRef<T> dynamic_table_cast(BasicTableRef<U> const &);

template<class C, class T, class U>
std::basic_ostream<C,T> &operator<<(std::basic_ostream<C,T> &, BasicTableRef<U> const &);





// Implementation:

template<class T> template<class U>
inline BasicTableRef<T> &BasicTableRef<T>::operator=(BasicTableRef<U> const &r)
{
	reset(r.m_table);
	return *this;
}

template<class T> template<class U>
inline bool BasicTableRef<T>::operator==(BasicTableRef<U> const &r) const
{
	return m_table == r.m_table;
}

template<class T> template<class U>
inline bool BasicTableRef<T>::operator!=(BasicTableRef<U> const &r) const
{
	return m_table != r.m_table;
}

template<class T> template<class U>
inline bool BasicTableRef<T>::operator<(BasicTableRef<U> const &r) const
{
	return m_table < r.m_table;
}

template<class T>
inline BasicTableRef<T>::operator unspecified_bool_type() const
{
	return m_table ? &BasicTableRef::m_table : 0;
}

template<class T> inline void BasicTableRef<T>::reset(T *t)
{
	if(t == m_table) return;
	unbind();
	bind(t);
}

template<class T> inline void BasicTableRef<T>::bind(T *t)
{
	if (t) t->bind_ref();
	m_table = t;
}

template<class T> inline void BasicTableRef<T>::unbind()
{
	if (m_table) m_table->unbind_ref();
}

template<class T> inline void swap(BasicTableRef<T> &r, BasicTableRef<T> &s)
{
	r.swap(s);
}

template<class T, class U> BasicTableRef<T> static_table_cast(BasicTableRef<U> const &t)
{
	return BasicTableRef<T>(static_cast<T *>(t.m_table));
}

template<class T, class U> BasicTableRef<T> dynamic_table_cast(BasicTableRef<U> const &t)
{
	return BasicTableRef<T>(dynamic_cast<T *>(t.m_table));
}

template<class C, class T, class U>
std::basic_ostream<C,T> &operator<<(std::basic_ostream<C,T> &out, BasicTableRef<U> const &t)
{
	out << static_cast<void *>(t.m_table);
	return out;
}

}

#endif //__TDB_TABLE_REF__
