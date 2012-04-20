#ifndef CONDITIONS_H
#define CONDITIONS_H

#include <string>
#include "../utf8.h"

namespace tightdb {

struct CONTAINS { 
	CONTAINS() {};
	bool operator()(const char *v1, const char* v1_upper, const char* v1_lower, const char *v2) const { (void)v1_lower; (void)v1_upper; return strstr(v2, v1) != 0; }
};

// is v2 a prefix of v1?
struct BEGINSWITH { 
	bool operator()(const char *v1, const char* v1_upper, const char* v1_lower, const char *v2) const { (void)v1_lower; (void)v1_upper; return(strstr(v1, v2) == v1); }
};

// does v1 end with s2?
struct ENDSWITH { 
	bool operator()(const char *v1, const char* v1_upper, const char* v1_lower, const char *v2) const { 
		(void)v1_lower;
		(void)v1_upper;
		const size_t l1 = strlen(v1);
		const size_t l2 = strlen(v2);
		if (l1 > l2)
			return false;

		return (strcmp(v1, v2 + l2 - l1) == 0); 
	}
};

struct EQUAL { 
	bool operator()(const char *v1, const char* v1_upper, const char* v1_lower, const char *v2) const { (void)v1_lower; (void)v1_upper; return strcmp(v1, v2) == 0; }
	template<class T> bool operator()(const T& v1, const T& v2) const {return v1 == v2;}
};

struct NOTEQUAL { 
	bool operator()(const char *v1, const char* v1_upper, const char* v1_lower, const char *v2) const { (void)v1_lower; (void)v1_upper; return strcmp(v1, v2) != 0; }
	template<class T> bool operator()(const T& v1, const T& v2) const { return v1 != v2; }
};

// does v1 contain v2?
struct CONTAINS_INS { 
	bool operator()(const char *v1, const char* v1_upper, const char* v1_lower, const char *v2) const { (void)v1; return case_strstr(v1_upper, v1_lower, v2); }
};

// is v2 a prefix of v1?
struct BEGINSWITH_INS { 
	bool operator()(const char *v1, const char* v1_upper, const char* v1_lower, const char *v2) const { (void)v1; return(case_prefix(v1_upper, v1_lower, v2) != (size_t)-1); }
};

// does v1 end with s2?
struct ENDSWITH_INS { 
	bool operator()(const char *v1, const char* v1_upper, const char* v1_lower, const char *v2) const { 
		const size_t l1 = strlen(v1);
		const size_t l2 = strlen(v2);
		if (l1 > l2)
			return false;

		bool r = case_cmp(v1_upper, v1_lower, v2 + l2 - l1); 
		return r;
	}
};

struct EQUAL_INS { 
	bool operator()(const char *v1, const char* v1_upper, const char* v1_lower, const char *v2) const { (void)v1; return case_cmp(v1_upper, v1_lower, v2); }
};

struct NOTEQUAL_INS { 
	bool operator()(const char *v1, const char* v1_upper, const char* v1_lower, const char *v2) const { (void)v1_lower; (void)v1; return !case_cmp(v1_upper, v1_lower, v2); }
};

struct GREATER { 
	template<class T> bool operator()(const T& v1, const T& v2) const {return v1 > v2;}
};

struct LESS { 
	template<class T> bool operator()(const T& v1, const T& v2) const {return v1 < v2;}
};

struct LESSEQUAL { 
	template<class T> bool operator()(const T& v1, const T& v2) const {return v1 <= v2;}
};

struct GREATEREQUAL { 
	template<class T> bool operator()(const T& v1, const T& v2) const {return v1 >= v2;}
};

}

#endif
