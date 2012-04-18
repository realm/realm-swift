#include <string>
#include "Table.h"

#include "../utf8.h"
#include "conditions.h"


class ParentNode { 
public:
	ParentNode() : m_table(NULL) {}
	virtual ~ParentNode() {}
	virtual void Init(const Table& table) {m_table = &table; if (m_child) m_child->Init(table);}
	virtual size_t Find(size_t start, size_t end) = 0;
	
	virtual std::string Verify(void) {
		if(error_code != "")
			return error_code;
		if(m_child == 0)
			return "";
		else
			return m_child->Verify();
	};
	
	ParentNode* m_child;
	
protected:
	const Table* m_table;
	std::string error_code;
};



/*
template <class T, class C, class F> class NODE : public ParentNode {
public:
	NODE(T v, size_t column) : m_value(v), m_column(column)  {m_child = 0;}
	~NODE() {delete m_child; }

	size_t Find(size_t start, size_t end, const Table& table) {
		const C& column = (C&)(table.GetColumnBase(m_column));
		const F function = {};
		for (size_t s = start; s < end; ++s) {
			const T t = column.Get(s);
			if (function(t, m_value)) {
				if (m_child == 0)
					return s;
				else {
					const size_t a = m_child->Find(s, end, table);
					if (s == a)
						return s;
					else
						s = a - 1;
				}
			}
		}
		return end;
	}

protected:
	T m_value;
	size_t m_column;
};
*/

// Not finished
class SUBTABLE : public ParentNode {
public:
	SUBTABLE(size_t column) : m_column(column) {m_child = 0; m_child2 = 0;}
	SUBTABLE() {};
	
	void Init(const Table& table) {
		m_table = &table;
		
		if (m_child) m_child->Init(table);
		if (m_child2) m_child2->Init(table);
	}

	size_t Find(size_t start, size_t end) {
		assert(m_table);
		assert(m_child);
		
		for (size_t s = start; s < end; ++s) {
			const TableRef subtable = ((Table*)m_table)->GetTable(m_column, s);

			m_child->Init(*subtable);
			const size_t subsize = subtable->GetSize();
			const size_t sub = m_child->Find(0, subsize);

			if(sub != subsize) {			
				if (m_child2 == 0)
					return s;
				else {
					const size_t a = m_child2->Find(s, end);
					if (s == a)
						return s;
					else
						s = a - 1;
				}
			}
		}
		return end;
	}
//protected:
	ParentNode* m_child2;
	size_t m_column;
};


template <class T, class C, class F> class NODE : public ParentNode {
public:
	NODE(T v, size_t column) : m_value(v), m_column_id(column) {m_child = 0;}
	~NODE() {delete m_child; }
	
	void Init(const Table& table) {
		m_table = &table;
		m_column = (C*)&table.GetColumnBase(m_column_id);
		
		if (m_child) m_child->Init(table);
	}

	size_t Find(size_t start, size_t end) {
		assert(m_table);
		
		for (size_t s = start; s < end; ++s) {
			s = m_column->template TreeFind<T, C, F>(m_value, s, end);
			if (s == (size_t)-1) 
				s = end;

			if (m_child == 0)
				return s;
			else {
				const size_t a = m_child->Find(s, end);
				if (s == a)
					return s;
				else
					s = a - 1;
			}
		}
		return end;
	}

protected:
	C* m_column;
	T m_value;
	size_t m_column_id;
};



template <class F> class STRINGNODE : public ParentNode {
public:
	STRINGNODE(const char* v, size_t column) : m_column_id(column) {
		m_child = 0;

		m_value = (char *)malloc(strlen(v)*6);
		memcpy(m_value, v, strlen(v) + 1);
		m_ucase = (char *)malloc(strlen(v)*6);
		m_lcase = (char *)malloc(strlen(v)*6);
	
		const bool b1 = utf8case(v, m_lcase, false);
		const bool b2 = utf8case(v, m_ucase, true);
		if (!b1 || !b2)
			error_code = "Malformed UTF-8: " + std::string(m_value);
	}
	~STRINGNODE() {delete m_child; free((void*)m_value); free((void*)m_ucase); free((void*)m_lcase); }
	
	void Init(const Table& table) {
		m_table = &table;
		m_column = &table.GetColumnBase(m_column_id);
		m_column_type = table.GetRealColumnType(m_column_id);
		
		if (m_child) m_child->Init(table);
	}

	size_t Find(size_t start, size_t end) {
		F function;// = {};

		for (size_t s = start; s < end; ++s) {
			const char* t;

			// todo, can be optimized by placing outside loop
			if (m_column_type == COLUMN_TYPE_STRING)
				t = ((const AdaptiveStringColumn*)m_column)->Get(s);
			else {
				//TODO: First check if string is in key list
				t = ((const ColumnStringEnum*)m_column)->Get(s);
			}

			if (function(m_value, m_ucase, m_lcase, t)) {
				if (m_child == 0)
					return s;
				else {
					const size_t a = m_child->Find(s, end);
					if (s == a)
						return s;
					else
						s = a - 1;
				}
			}
		}
		return end;
	}

protected:
	char* m_value;
	char* m_lcase;
	char* m_ucase;
	size_t m_column_id;
	const ColumnBase* m_column;
	ColumnType m_column_type;
};



template <> class STRINGNODE<EQUAL> : public ParentNode {
public:
	STRINGNODE(const char* v, size_t column) : m_column_id(column), m_key_ndx((size_t)-1) {
		m_child = 0;
		m_value = (char *)malloc(strlen(v)*6);
		memcpy(m_value, v, strlen(v) + 1);
	}
	~STRINGNODE() {delete m_child; free((void*)m_value); }
	
	void Init(const Table& table) {
		m_table = &table;
		m_column = &table.GetColumnBase(m_column_id);
		m_column_type = table.GetRealColumnType(m_column_id);
		
		if (m_column_type == COLUMN_TYPE_STRING_ENUM) {
			m_key_ndx =  ((const ColumnStringEnum*)m_column)->GetKeyNdx(m_value);
		}
		
		if (m_child) m_child->Init(table);
	}

	size_t Find(size_t start, size_t end) {
		assert(m_table);
		
		for (size_t s = start; s < end; ++s) {
			// todo, can be optimized by placing outside loop
			if (m_column_type == COLUMN_TYPE_STRING)
				s = ((const AdaptiveStringColumn*)m_column)->Find(m_value, s, end);
			else {
				if (m_key_ndx == -1) s = end; // not in key set
				else {
					const ColumnStringEnum* const cse = (const ColumnStringEnum*)m_column;
					s = cse->Find(m_key_ndx, s, end);
				}
			}

			if (s == (size_t)-1)
				s = end;

			if (m_child == 0)
				return s;
			else {
				const size_t a = m_child->Find(s, end);
				if (s == a)
					return s;
				else
					s = a - 1;
			}
		}
		return end;
	}
	
protected:
	char*  m_value;
	size_t m_column_id;
	
private:
	const ColumnBase* m_column;
	ColumnType m_column_type;
	size_t m_key_ndx;
};


class OR_NODE : public ParentNode {
public:
	OR_NODE(ParentNode* p1) {m_child = 0; m_cond1 = p1; m_cond2 = 0;};
	~OR_NODE() {
		delete m_cond1;
		delete m_cond2;
		delete m_child;
	}
	
	void Init(const Table& table) {
		m_cond1->Init(table);
		m_cond2->Init(table);
	}

	size_t Find(size_t start, size_t end) {
		for (size_t s = start; s < end; ++s) {
			// Todo, redundant searches can occur
			const size_t f1 = m_cond1->Find(s, end);
			const size_t f2 = m_cond2->Find(s, f1);
			s = f1 < f2 ? f1 : f2;

			if (m_child == 0)
				return s;
			else {
				const size_t a = m_cond2->Find(s, end);
				if (s == a)
					return s;
				else
					s = a - 1;
			}
		}
		return end;
	}
	
	virtual std::string Verify(void) {
		if(error_code != "")
			return error_code;
		if(m_cond1 == 0)
			return "Missing left-hand side of OR";
		if(m_cond2 == 0)
			return "Missing right-hand side of OR";
		std::string s;
		if(m_child != 0)
			s = m_child->Verify();
		if(s != "")
			return s;
		s = m_cond1->Verify();
		if(s != "")
			return s;
		s = m_cond2->Verify();
		if(s != "")
			return s;
		return "";
	}
	
	ParentNode* m_cond1;
	ParentNode* m_cond2;
};
