#include <string>
#include "Table.h"

#include "../utf8.h"
#include "conditions.h"


class ParentNode { 
public:
	virtual ~ParentNode() {}
	virtual size_t Find(size_t start, size_t end, const Table& table) = 0;
	ParentNode* m_child;
	virtual std::string Verify(void) {
		if(error_code != "")
			return error_code;
		if(m_child == 0)
			return "";
		else
			return m_child->Verify();
	};
protected:
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
//	~NODE() {delete m_child; }

	size_t Find(size_t start, size_t end, const Table& table) {
		for (size_t s = start; s < end; ++s) {

			TableConstRef subtable = table.GetTable(m_column, s);

			const size_t sub = m_child->Find(0, subtable->GetSize(), *subtable);

			if(sub != subtable->GetSize()) {			

				if (m_child2 == 0)
					return s;
				else {
					const size_t a = m_child2->Find(s, end, table);
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
	NODE(T v, size_t column) : m_value(v), m_column(column) {m_child = 0;}
	~NODE() {delete m_child; }

	size_t Find(size_t start, size_t end, const Table& table) {
		const C& column = (C&)(table.GetColumnBase(m_column));
		for (size_t s = start; s < end; ++s) {
			s = column.template TreeFind<T, C, F>(m_value, s, end);
			if(s == (size_t)-1) 
				s = end;

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
		return end;
	}

protected:
	T m_value;
	size_t m_column;
};



template <class F> class STRINGNODE : public ParentNode {
public:
	STRINGNODE(const char* v, size_t column) : m_column(column) {
		m_child = 0;

		m_value = (char *)malloc(strlen(v)*6);
		memcpy(m_value, v, strlen(v) + 1);
		m_ucase = (char *)malloc(strlen(v)*6);
		m_lcase = (char *)malloc(strlen(v)*6);
	
		bool b1 = utf8case(v, m_lcase, false);
		bool b2 = utf8case(v, m_ucase, true);
		if(!b1 || !b2)
			error_code = "Malformed UTF-8: " + std::string(m_value);
	}
	~STRINGNODE() {delete m_child; free((void*)m_value); free((void*)m_ucase); free((void*)m_lcase); }

	size_t Find(size_t start, size_t end, const Table& table) {
		int column_type = table.GetRealColumnType(m_column);

		F function;// = {};

		for (size_t s = start; s < end; ++s) {
			const char* t;

			// todo, can be optimized by placing outside loop
			if (column_type == COLUMN_TYPE_STRING)
				t = table.GetColumnString(m_column).Get(s);
			else
				t = table.GetColumnStringEnum(m_column).Get(s);

			if (function(m_value, m_ucase, m_lcase, t)) {
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
	char* m_value;
	char* m_lcase;
	char* m_ucase;
	size_t m_column;
};



template <> class STRINGNODE<EQUAL> : public ParentNode {
public:
	STRINGNODE(const char* v, size_t column) : m_column(column) {
		m_child = 0;
		m_value = (char *)malloc(strlen(v)*6);
		memcpy(m_value, v, strlen(v) + 1);
		key_ndx = (size_t)-1;
	}
	~STRINGNODE() {delete m_child; free((void*)m_value); }

	size_t Find(size_t start, size_t end, const Table& table) {
		int column_type = table.GetRealColumnType(m_column);
		for (size_t s = start; s < end; ++s) {
			// todo, can be optimized by placing outside loop
			if (column_type == COLUMN_TYPE_STRING)
				s = ((AdaptiveStringColumn&)(table.GetColumnBase(m_column))).Find(m_value, s, end);
			else {
				ColumnStringEnum &cse = (ColumnStringEnum&)(table.GetColumnBase(m_column));
				if(key_ndx == (size_t)-1)
					key_ndx = cse.GetKeyNdx(m_value);
				s = cse.Find(key_ndx, s, end);
			}

			if(s == (size_t)-1)
				s = end;

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
		return end;
	}
protected:
	char* m_value;
	size_t m_column;
private:
	size_t key_ndx;
};


class OR_NODE : public ParentNode {
public:
	OR_NODE(ParentNode* p1) {m_child = 0; m_cond1 = p1; m_cond2 = 0;};
	~OR_NODE() {
		delete m_cond1;
		delete m_cond2;
		delete m_child;
	}

	size_t Find(size_t start, size_t end, const Table& table) {
		for (size_t s = start; s < end; ++s) {
			// Todo, redundant searches can occur
			const size_t f1 = m_cond1->Find(s, end, table);
			const size_t f2 = m_cond2->Find(s, f1, table);
			s = f1 < f2 ? f1 : f2;

			if (m_child == 0)
				return s;
			else {
				const size_t a = m_cond2->Find(s, end, table);
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
