#import "RLMNetworkTransport.h"

namespace realm {
namespace app {
struct GenericEventSubscriber;
}
}

@interface RLMEventSubscriber : NSObject<RLMEventDelegate>

- (instancetype)initWithGenericEventSubscriber:(realm::app::GenericEventSubscriber&&)subscriber;
- (void)didReceiveEvent:(NSData *)event;
- (void)didReceiveError:(NSError *)error;
- (void)didOpen;
- (void)didClose;

@end

