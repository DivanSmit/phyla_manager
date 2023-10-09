-module(base_subscription).
-export([create_subscription/3]).

-record(base_subscription,{subscriber_bc::term(),provider_bc::term()}).

create_subscription(SubscriberBC,ProviderBC,Terms)->
  ok.
