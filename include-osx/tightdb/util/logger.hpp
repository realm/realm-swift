/*************************************************************************
 *
 * TIGHTDB CONFIDENTIAL
 * __________________
 *
 *  [2011] - [2013] TightDB Inc
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
#ifndef TIGHTDB_UTIL_LOGGER_HPP
#define TIGHTDB_UTIL_LOGGER_HPP

#include <string>
#include <sstream>
#include <iostream>

#include <tightdb/util/features.h>
#include <tightdb/util/tuple.hpp>
#include <tightdb/util/thread.hpp>

namespace tightdb {
namespace util {


/// Examples:
///
///    logger.log("Overlong message from master coordinator");
///    logger.log("Listening for peers on %1:%2", listen_address, listen_port);
///    logger.log_with_tuple("c=%3, a=%1, b=%2", (tuple(), a, b, c));
class Logger {
public:
#ifdef TIGHTDB_HAVE_CXX11_VARIADIC_TEMPLATES

    template<class... Params> void log(const char* message, Params... params)
    {
        State state(message);
        log_impl(state, params...);
    }

#else

    void log(const char* message)
    {
        State state(message);
        log_impl_with_tuple(state, tuple());
    }

    template<class A> void log(const char* message, const A& a)
    {
        State state(message);
        log_impl_with_tuple(state, tuple(a));
    }

    template<class A, class B> void log(const char* message, const A& a, const B& b)
    {
        State state(message);
        log_impl_with_tuple(state, tuple(a,b));
    }

    template<class A, class B, class C>
    void log(const char* message, const A& a, const B& b, const C& c)
    {
        State state(message);
        log_impl_with_tuple(state, tuple(a,b,c));
    }

    template<class A, class B, class C, class D>
    void log(const char* message, const A& a, const B& b, const C& c, const D& d)
    {
        State state(message);
        log_impl_with_tuple(state, tuple(a,b,c,d));
    }

    template<class A, class B, class C, class D, class E>
    void log(const char* message, const A& a, const B& b, const C& c, const D& d,
             const E& e)
    {
        State state(message);
        log_impl_with_tuple(state, tuple(a,b,c,d,e));
    }

    template<class A, class B, class C, class D, class E, class F>
    void log(const char* message, const A& a, const B& b, const C& c, const D& d,
             const E& e, const F& f)
    {
        State state(message);
        log_impl_with_tuple(state, tuple(a,b,c,d,e,f));
    }

#endif

    template<class L> void log_with_tuple(const char* message, const Tuple<L>& params)
    {
        State state(message);
        log_impl_with_tuple(state, params);
    }

    virtual ~Logger() {}

protected:
    virtual void do_log(const std::string& message)
    {
        std::cerr << message << '\n' << std::flush;
    }

    static void do_log(Logger* logger, const std::string& message)
    {
        logger->do_log(message);
    }

private:
    struct State {
        std::string m_message;
        std::string m_search;
        int m_param_num;
        std::ostringstream m_formatter;
        State(const char* s): m_message(s), m_search(m_message), m_param_num(1) {}
    };

    template<class T> struct Subst {
        void operator()(const T& param, State* state)
        {
            state->m_formatter << "%" << state->m_param_num;
            std::string key = state->m_formatter.str();
            state->m_formatter.str(std::string());
            std::string::size_type j = state->m_search.find(key);
            if (j != std::string::npos) {
                state->m_formatter << param;
                std::string str = state->m_formatter.str();
                state->m_formatter.str(std::string());
                state->m_message.replace(j, key.size(), str);
                state->m_search.replace(j, key.size(), std::string(str.size(), '\0'));
            }
            ++state->m_param_num;
        }
    };

    void log_impl(State& state)
    {
        do_log(state.m_message);
    }

#ifdef TIGHTDB_HAVE_CXX11_VARIADIC_TEMPLATES
    template<class Param, class... Params>
    void log_impl(State& state, const T& param, Params... params)
    {
        Subst<T>()(param, &state);
        log_impl(state, params...);
    }
#endif

    template<class L> void log_impl_with_tuple(State& state, const Tuple<L>& params)
    {
        for_each<Subst>(params, &state);
        log_impl(state);
    }
};



/// this makes all the log() methods are thread-safe.
class ThreadSafeLogger: public Logger {
public:
    ThreadSafeLogger(Logger& base_logger): m_base_logger(&base_logger) {}

protected:
    Logger* const m_base_logger;
    Mutex m_mutex;

    void do_log(const std::string& msg) TIGHTDB_OVERRIDE
    {
        LockGuard l(m_mutex);
        Logger::do_log(m_base_logger, msg);
    }
};



class PrefixLogger: public Logger {
public:
    PrefixLogger(std::string prefix, Logger& base_logger):
        m_prefix(prefix), m_base_logger(&base_logger) {}

protected:
    const std::string m_prefix;
    Logger* const m_base_logger;

    void do_log(const std::string& msg) TIGHTDB_OVERRIDE
    {
        Logger::do_log(m_base_logger, m_prefix + msg);
    }
};


} // namespace util
} // namespace tightdb

#endif // TIGHTDB_UTIL_LOGGER_HPP
