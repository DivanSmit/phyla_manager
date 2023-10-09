-module(base_task_ap).
-author("Travis").

%% @doc this function is called when the plugin is first initialised
-callback init(Pars::term(),BH::term())->
    ok | {error,Desc::term()}.

%% @doc this function is called when the plugin is removed from the system
-callback stop(BH::term())->
    ok  | {error,Desc::term()}.


%%%===================================================================
%%%                     External Functions
%%%===================================================================

