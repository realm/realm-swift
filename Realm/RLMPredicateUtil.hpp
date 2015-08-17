////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <Foundation/Foundation.h>

class RLMPredicateExpressionTransformer {
    using ExpressionVisitor = NSExpression *(*)(NSExpression *);

public:
    static NSPredicate *transform(NSPredicate *predicate, ExpressionVisitor visitor) {
        RLMPredicateExpressionTransformer self(visitor);
        return self.visit(predicate);
    }

private:
    RLMPredicateExpressionTransformer(ExpressionVisitor visitor) : m_visitor(visitor) { }

    NSExpression *visit(NSExpression *expression) const;
    NSPredicate *visit(NSPredicate *predicate) const;

    ExpressionVisitor m_visitor;
};
