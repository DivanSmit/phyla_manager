-module(base_task_rp).
-author("Sparrow").
-export([get_schedule_data/2, get_execution_data/2, get_reflection_data/2]).

%% @doc this function is called when the plugin is first initialised
-callback init(Pars::term(),BH::term())->
    ok | {error,Desc::term()}.

%% @doc this function is called when the plugin is removed from the system
-callback stop(BH::term())->
    ok  | {error,Desc::term()}.

-callback start_reflection(ReflectorHandle::term(),BH::term())->
    {ok,NewState::term()}.


%%%===================================================================
%%%                     External Functions
%%%===================================================================

get_schedule_data(ExH,BH)->
    reflector:get_data1(ExH,BH).

get_execution_data(ExH,BH)->
    reflector:get_data2(ExH,BH).

get_reflection_data(ExH,BH)->
    reflector:get_data3(ExH,BH).