
#ifndef Testing_Query_h
#define Testing_Query_h

#include <string>
#include <algorithm>
#include <vector>
#include <stdio.h>
#include <limits.h>
#if defined(_WIN32) || defined(__WIN32__) || defined(_WIN64)
	#include "Win32/pthread/pthread.h"
	#include "query/QueryEngine.h"
#else
	#include <pthread.h>
	#include "QueryEngine.h"
#endif

const size_t MAX_THREADS = 128;
const size_t THREAD_CHUNK_SIZE = 1000;

#define MIN(a, b)  (((a) < (b)) ? (a) : (b))
#define MAX(a, b)  (((a) > (b)) ? (a) : (b))

class Query {
public:
	Query() { 
		update.push_back(0);
		update_override.push_back(0);
		first.push_back(0);
		m_threadcount = 0;
	}
	Query(const Query& copy) {
		update = copy.update;
		update_override = copy.update_override;
		first = copy.first;
		error_code = copy.error_code;
		m_threadcount = copy.m_threadcount;
		copy.first[0] = 0;
	}

	~Query() {
		for(size_t i = 0; i < m_threadcount; i++)
			pthread_detach(threads[i]);
		delete first[0];
	}

	Query& Equal(size_t column_id, int64_t value) {
		ParentNode* const p = new NODE<int64_t, Column, EQUAL>(value, column_id);
		UpdatePointers(p, &p->m_child);
		return *this;
	};
	Query& NotEqual(size_t column_id, int64_t value) {
		ParentNode* const p = new NODE<int64_t, Column, NOTEQUAL>(value, column_id);
		UpdatePointers(p, &p->m_child);
		return *this;
	};
	Query& Greater(size_t column_id, int64_t value) {
		ParentNode* const p = new NODE<int64_t, Column, GREATER>(value, column_id);
		UpdatePointers(p, &p->m_child);
		return *this;
	};
	Query& GreaterEqual(size_t column_id, int64_t value) {
		if(value > LLONG_MIN) {
			ParentNode* const p = new NODE<int64_t, Column, GREATER>(value - 1, column_id);
			UpdatePointers(p, &p->m_child);
		}
		// field >= LLONG_MIN has no effect
		return *this;
	};
	Query& LessEqual(size_t column_id, int64_t value) {
		if(value < LLONG_MAX) {
			ParentNode* const p = new NODE<int64_t, Column, LESS>(value + 1, column_id);
			UpdatePointers(p, &p->m_child);
		}
		// field <= LLONG_MAX has no effect
		return *this;
	};
	Query& Less(size_t column_id, int64_t value) {
		ParentNode* const p = new NODE<int64_t, Column, LESS>(value, column_id);
		UpdatePointers(p, &p->m_child);
		return *this;
	};

	Query& Between(size_t column_id, int64_t from, int64_t to) {
		GreaterEqual(column_id, from);
		LessEqual(column_id, to);
		return *this;
	};
	Query& Equal(size_t column_id, bool value) {
		ParentNode* const p = new NODE<bool, Column, EQUAL>(value, column_id);
		UpdatePointers(p, &p->m_child);
		return *this;
	};


	// STRINGS
	Query& Equal(size_t column_id, const char* value, bool caseSensitive=true) {
		ParentNode* p;
		if(caseSensitive)
			p = new STRINGNODE<EQUAL>(value, column_id);
		else
			p = new STRINGNODE<EQUAL_INS>(value, column_id);
		UpdatePointers(p, &p->m_child);
		return *this;
	};
	Query& BeginsWith(size_t column_id, const char* value, bool caseSensitive=true) {
		ParentNode* p;
		if(caseSensitive)
			p = new STRINGNODE<BEGINSWITH>(value, column_id);
		else
			p = new STRINGNODE<BEGINSWITH_INS>(value, column_id);
		UpdatePointers(p, &p->m_child);
		return *this;
	};
	Query& EndsWith(size_t column_id, const char* value, bool caseSensitive=true) {
		ParentNode* p; 
		if(caseSensitive)
			p = new STRINGNODE<ENDSWITH>(value, column_id);
		else
			p = new STRINGNODE<ENDSWITH_INS>(value, column_id);
		UpdatePointers(p, &p->m_child);
		return *this;
	};
	Query& Contains(size_t column_id, const char* value, bool caseSensitive=true) {
		ParentNode* p; 
		if(caseSensitive)
			p = new STRINGNODE<CONTAINS>(value, column_id);
		else
			p = new STRINGNODE<CONTAINS_INS>(value, column_id);
		UpdatePointers(p, &p->m_child);
		return *this;
	};
	Query& NotEqual(size_t column_id, const char* value, bool caseSensitive=true) {
		ParentNode* p;
		if(caseSensitive)
			p = new STRINGNODE<NOTEQUAL>(value, column_id);
		else
			p = new STRINGNODE<NOTEQUAL_INS>(value, column_id);
		UpdatePointers(p, &p->m_child);
		return *this;
	};

	void LeftParan(void) {
		update.push_back(0);
		update_override.push_back(0);
		first.push_back(0);
	};
	void Or(void) {
		ParentNode* const o = new OR_NODE(first[first.size()-1]);
		first[first.size()-1] = o;
		update[update.size()-1] = &((OR_NODE*)o)->m_cond2;
		update_override[update_override.size()-1] = &((OR_NODE*)o)->m_child;
	};

	void Subtable(size_t column) {

		ParentNode* const p = new SUBTABLE(column);
		UpdatePointers(p, &p->m_child);
		// once subtable conditions have been evaluated, resume evaluation from m_child2
		subtables.push_back(&((SUBTABLE*)p)->m_child2); 
		LeftParan();
	}

	void Parent() {
		RightParan();

		if (update[update.size()-1] != 0)
			update[update.size()-1] = subtables[subtables.size()-1];

		subtables.pop_back();
	}

	void RightParan(void) {
		if(first.size() < 2) {
			error_code = "Unbalanced blockBegin/blockEnd";
			return;
		}

		if (update[update.size()-2] != 0)
			*update[update.size()-2] = first[first.size()-1];
		
		if(first[first.size()-2] == 0)
			first[first.size()-2] = first[first.size()-1];

		if(update_override[update_override.size()-1] != 0)
			update[update.size() - 2] = update_override[update_override.size()-1];
		else if(update[update.size()-1] != 0)
			update[update.size() - 2] = update[update.size()-1];

		first.pop_back();
		update.pop_back();
		update_override.pop_back();
	};

	TableView FindAll(Table& table, size_t start = 0, size_t end = (size_t)-1, size_t limit = (size_t)-1) {
		TableView tv(table);
		FindAll(table, tv, start, end, limit);
		return tv;
	}

	void FindAll(Table& table, TableView& tv, size_t start = 0, size_t end = (size_t)-1, size_t limit = (size_t)-1) {
		Init(table);
		
		size_t r  = start - 1;
		if(end == (size_t)-1)
			end = table.GetSize();

		// User created query with no criteria; return everything
		if(first[0] == 0) {
			for(size_t i = start; i < end; i++)
				tv.GetRefColumn().Add(i);
		}
		else if(m_threadcount > 0) {
			// Use multithreading
			FindAllMulti(table, tv, start, end);
			return;
		} 
		else {
			const size_t table_size = table.GetSize();
			
			// Use single threading
			for(;;) {
				r = first[0]->Find(r + 1, table_size);
				if (r == table_size || tv.GetSize() == limit)
					break;
				tv.GetRefColumn().Add(r);
			}
		}
	}

	int64_t Sum(const Table& table, size_t column, size_t *resultcount, size_t start = 0, size_t end = (size_t)-1, 
		size_t limit = (size_t)-1) const {
		Init(table);
		
		size_t r = start - 1;
		size_t results = 0;
		int64_t sum = 0;
		
		const Column& c = table.GetColumn(column);
		const size_t table_size = table.GetSize();

		for (;;) {
			r = FindInternal(table, r + 1, end);
			if (r == (size_t)-1 || r == table_size || results == limit)
				break;
			++results;
			sum += c.Get(r);
		}

		if(resultcount != 0)
			*resultcount = results;
		return sum;
	}

	int64_t Max(const Table& table, size_t column, size_t *resultcount, size_t start = 0, size_t end = (size_t)-1, 
		size_t limit = (size_t)-1) const {
		Init(table);
		
		size_t r = start - 1;
		size_t results = 0;
		int64_t max = 0;

		for (;;) {
			r = FindInternal(table, r + 1, end);
			if (r == (size_t)-1 || r == table.GetSize() || results == limit)
				break;
			const int64_t g = table.Get(column, r);
			if (results == 0 || g > max)
				max = g;
			results++;
		}

		if(resultcount != 0)
			*resultcount = results;
		return max;
	}

	int64_t Min(const Table& table, size_t column, size_t *resultcount, size_t start = 0, size_t end = (size_t)-1, size_t limit = (size_t)-1) const {
		Init(table);
		
		size_t r = start - 1;
		size_t results = 0;
		int64_t min = 0;
		
		for (;;) {
			r = FindInternal(table, r + 1, end);
			if (r == (size_t)-1 || r == table.GetSize() || results == limit)
				break;
			const int64_t g = table.Get(column, r);
			if (results == 0 || g < min)
				min = g;
			++results;
		}
		if(resultcount != 0)
			*resultcount = results;
		return min;
	}

	size_t Count(const Table& table, size_t start = 0, size_t end = (size_t)-1, size_t limit = (size_t)-1) const {
		Init(table);
		
		size_t r = start - 1;
		size_t results = 0;
		
		for(;;) {
			r = FindInternal(table, r + 1, end);
			if (r == (size_t)-1 || r == table.GetSize() || results == limit)
				break;
			++results;
		}
		return results;
	}

	double Avg(const Table& table, size_t column, size_t *resultcount, size_t start = 0, size_t end = (size_t)-1, size_t limit = (size_t)-1) const {
		Init(table);
		
		size_t resultcount2;

		const int64_t sum = Sum(table, column, &resultcount2, start, end, limit);
		const double avg = (float)sum / (float)resultcount2;
		
		if (resultcount != 0)
			*resultcount = resultcount2;
		return avg;
	}
	
	// todo, not sure if start, end and limit could be useful for delete.
	size_t Delete(Table& table, size_t start = 0, size_t end = (size_t)-1, size_t limit = (size_t)-1) const {
		size_t r = start - 1;
		size_t results = 0;
		Init(table);
		
		for (;;) {
			r = FindInternal(table, r + 1 - results, end);
			if (r == (size_t)-1 || r == table.GetSize() || results == limit)
				break;
			++results;
			table.DeleteRow(r);
		}
		return results;
	}

	void FindAllMulti(Table& table, TableView& tv, size_t start = 0, size_t end = (size_t)-1) {
		// Initialization
		Init(table);
		ts.next_job = start;
		ts.end_job = end;
		ts.done_job = 0;
		ts.count = 0;
		ts.table = &table;
		ts.node = first[0];

		// Signal all threads to start
		pthread_mutex_unlock(&ts.jobs_mutex);
		pthread_cond_broadcast(&ts.jobs_cond);

		// Wait until all threads have completed
		pthread_mutex_lock(&ts.completed_mutex);
		while(ts.done_job < ts.end_job)
			pthread_cond_wait(&ts.completed_cond, &ts.completed_mutex);
		pthread_mutex_lock(&ts.jobs_mutex);
		pthread_mutex_unlock(&ts.completed_mutex);

		// Sort search results because user expects ascending order
		std::sort (ts.chunks.begin(), ts.chunks.end(), &Query::comp);
		for (size_t i = 0; i < ts.chunks.size(); ++i) {
			const size_t from = ts.chunks[i].first;
			const size_t upto = (i == ts.chunks.size() - 1) ? (size_t)-1 : ts.chunks[i + 1].first;
			size_t first = ts.chunks[i].second;
			
			while(first < ts.results.size() && ts.results[first] < upto && ts.results[first] >= from) {
				tv.GetRefColumn().Add(ts.results[first]);
				++first;
			}
		}
	}

	int SetThreads(unsigned int threadcount) {
#if defined(_WIN32) || defined(__WIN32__) || defined(_WIN64)
		pthread_win32_process_attach_np ();
#endif
		pthread_mutex_init(&ts.result_mutex, NULL);
		pthread_cond_init(&ts.completed_cond, NULL);
		pthread_mutex_init(&ts.jobs_mutex, NULL);
		pthread_mutex_init(&ts.completed_mutex, NULL);
		pthread_cond_init(&ts.jobs_cond, NULL);

		pthread_mutex_lock(&ts.jobs_mutex);

		for (size_t i = 0; i < m_threadcount; ++i)
			pthread_detach(threads[i]);

		for (size_t i = 0; i < threadcount; ++i) {
			int r = pthread_create(&threads[i], NULL, query_thread, (void*)&ts);
			if(r != 0)
				assert(false); //todo
		}

		m_threadcount = threadcount;
		return 0;
	}

	std::string error_code;

	std::string Verify(void) {
		if(first.size() == 0)
			return "";

		if(error_code != "") // errors detected by QueryInterface
			return error_code;

		if(first[0] == 0)
			return "Syntax error";

		return first[0]->Verify(); // errors detected by QueryEngine
	}

protected:
	friend class XQueryAccessorInt;
	friend class XQueryAccessorString;
	
	void Init(const Table& table) const {
		if (first[0] != NULL) {
			ParentNode* top = (ParentNode*)first[0];
			top->Init(table);
		}
	}
	
	size_t FindInternal(const Table& table, size_t start = 0, size_t end = (size_t)-1) const {
		if (end == (size_t)-1) end = table.GetSize();
		if (start == end) return (size_t)-1;
		
		size_t r;
		if (first[0] != 0)
			r = first[0]->Find(start, end);
		else
			r = start; // user built an empty query; return any first
		
		if (r == table.GetSize())
			return (size_t)-1;
		else
			return r;
	}

	void UpdatePointers(ParentNode *p, ParentNode **newnode) {
		if(first[first.size()-1] == 0)
			first[first.size()-1] = p;

		if(update[update.size()-1] != 0)
			*update[update.size()-1] = p;

		update[update.size()-1] = newnode;
	}
	
	static bool comp(const std::pair<size_t, size_t>& a, const std::pair<size_t, size_t>& b) {
		return a.first < b.first;
	}
	
	static void *query_thread(void *arg) {
		thread_state *ts = (thread_state *)arg;
		
		std::vector<size_t> res;
		std::vector<std::pair<size_t, size_t> > chunks;
		
		for(;;) {
			// Main waiting loop that waits for a query to start
			pthread_mutex_lock(&ts->jobs_mutex);
			while(ts->next_job == ts->end_job)
				pthread_cond_wait(&ts->jobs_cond, &ts->jobs_mutex);
			pthread_mutex_unlock(&ts->jobs_mutex);
			
			for(;;) {
				// Pick a job
				pthread_mutex_lock(&ts->jobs_mutex);
				if(ts->next_job == ts->end_job)
					break;
				const size_t chunk = MIN(ts->end_job - ts->next_job, THREAD_CHUNK_SIZE);
				const size_t mine = ts->next_job;
				ts->next_job += chunk;
				size_t r = mine - 1;
				const size_t end = mine + chunk;
				
				pthread_mutex_unlock(&ts->jobs_mutex);
				
				// Execute job
				for(;;) {
					r = ts->node->Find(r + 1, end);
					if(r == end)
						break;
					res.push_back(r);
				}
				
				// Append result in common queue shared by all threads.
				pthread_mutex_lock(&ts->result_mutex);
				ts->done_job += chunk;
				if(res.size() > 0) {
					ts->chunks.push_back(std::pair<size_t, size_t>(mine, ts->results.size()));
					ts->count += res.size();
					for(size_t i = 0; i < res.size(); i++) {
						ts->results.push_back(res[i]);
					}	
					res.clear();
				}
				pthread_mutex_unlock(&ts->result_mutex);
				
				// Signal main thread that we might have compleeted
				pthread_mutex_lock(&ts->completed_mutex);
				pthread_cond_signal(&ts->completed_cond);
				pthread_mutex_unlock(&ts->completed_mutex);
				
			}
		}		
		return 0;
	}
	
	struct thread_state {
		pthread_mutex_t result_mutex;
		pthread_cond_t completed_cond;
		pthread_mutex_t completed_mutex;
		pthread_mutex_t jobs_mutex;
		pthread_cond_t jobs_cond;
		size_t next_job;
		size_t end_job;
		size_t done_job;
		size_t count;
		ParentNode *node;
		Table *table;
		std::vector<size_t> results;
		std::vector<std::pair<size_t, size_t> > chunks;
	} ts;
	pthread_t threads[MAX_THREADS];

	mutable std::vector<ParentNode *>first;
	std::vector<ParentNode **>update;
	std::vector<ParentNode **>update_override;
	std::vector<ParentNode **>subtables;
	private:
	size_t m_threadcount;
};

class XQueryAccessorInt {
public:
	XQueryAccessorInt(size_t column_id) : m_column_id(column_id) {}
	Query& Equal(int64_t value) {return m_query->Equal(m_column_id, value);}
	Query& NotEqual(int64_t value) {return m_query->NotEqual(m_column_id, value);}
	Query& Greater(int64_t value) {return m_query->Greater(m_column_id, value);}
	Query& GreaterEqual(int64_t value) {return m_query->GreaterEqual(m_column_id, value);}
	Query& Less(int64_t value) {return m_query->Less(m_column_id, value);}
	Query& LessEqual(int64_t value) {return m_query->LessEqual(m_column_id, value);}
	Query& Between(int64_t from, int64_t to) {return m_query->Between(m_column_id, from, to);}
protected:
	Query* m_query;
	size_t m_column_id;
}; 
 
class XQueryAccessorString {
public:
	XQueryAccessorString(size_t column_id) : m_column_id(column_id) {}
	Query& Equal(const char *value, bool CaseSensitive) {return m_query->Equal(m_column_id, value, CaseSensitive);}
	Query& BeginsWith(const char *value, bool CaseSensitive) {return m_query->Equal(m_column_id, value, CaseSensitive);}
	Query& EndsWith(const char *value, bool CaseSensitive) {return m_query->EndsWith(m_column_id, value, CaseSensitive);}
	Query& Contains(const char *value, bool CaseSensitive) {return m_query->Contains(m_column_id, value, CaseSensitive);}
	Query& NotEqual(const char *value, bool CaseSensitive) {return m_query->NotEqual(m_column_id, value, CaseSensitive);}
protected:
	Query* m_query;
	size_t m_column_id;
};

class XQueryAccessorBool {
public:
	XQueryAccessorBool(size_t column_id) : m_column_id(column_id) {}
	Query& Equal(bool value) {return m_query->Equal(m_column_id, value);}
protected:
	Query* m_query;
	size_t m_column_id;
};

class XQueryAccessorMixed {
public:
	XQueryAccessorMixed(size_t column_id) : m_column_id(column_id) {}
protected:
	Query* m_query;
	size_t m_column_id;
}; 

#endif
