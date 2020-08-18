#import "RLMNetworkTransport.h"
#import "sync/generic_network_transport.hpp"

namespace realm {
namespace app {
struct GenericEventSubscriber;
}
}

@interface RLMEventSubscriber : NSObject<RLMEventDelegate>
- (void)didReceiveEvent:(NSData *)event;
- (void)didReceiveError:(NSError *)error;
- (void)didOpen;
- (void)didCloseWithError:(NSError *)error;

@end

@interface RLMNetworkTransport()

- (RLMRequest *)RLMRequestFromRequest:(realm::app::Request)request;

@end

