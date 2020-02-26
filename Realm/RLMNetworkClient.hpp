#ifndef RLMNetworkClient_h
#define RLMNetworkClient_h

#include "RLMNetworkClient.h"
#import "app.hpp"

class RLMAppNetworkClient : public realm::GenericNetworkClient {
    void sendRequestToServer(const char*,
                             const char*,
                             realm::GenericNetworkHeaders,
                             const char *,
                             int,
                             realm::completion_block) override;
};

#endif /* RLMNetworkClient_h */
