-module(base_receptor).
-author("Sparrow").

%% @doc this function is called when the plugin is first initialised
-callback init(Pars::term(),BH::term())->
  ok | {error,Desc::term()}.

%% @doc this function is called when the plugin is removed from the system
-callback stop(BH::term())->
  ok  | {error,Desc::term()}.

-callback handle_signal(Tag::binary(),Signal::term(),BH::term())->
  ok.

-callback handle_request(Tag::binary(),Signal::term(),FROM::term(),BH::term())->
  ok|{error,Reason::term()}|{reply,REPLY::term()}.


