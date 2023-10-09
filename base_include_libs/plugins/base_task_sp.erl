-module(base_task_sp).
-include("../base_terms.hrl").
-author("Sparrow").

%% @doc this function is called by the Schedule component on BASE startup if it was in the list of SPs.
%% this function needs to return the tuple {ok,ServiceTag,{passive,?MODULE} if it started successfully
%% otherwise it should return {error,Description} which will be handled by the BASE core
-callback init(Pars::term(),BH::term())->
    ok| {error,Desc::term()}.

-callback stop(BH::term())->
    ok | {error,Desc::term()}.

-callback handle_task_request(Pars::term(),BH::base_handle())->
    ok|{schedule_task,ID::binary(),TSched::integer(),Data1::term()}.

-export([schedule_task/5, get_schedule_data/2]).


%%%===================================================================
%%%                     External Functions
%%%===================================================================
schedule_task(TSCHED,TYPE,ID,Data1,BH) ->
    base_task_scheduler:schedule_task(TSCHED,TYPE,ID,Data1,BH).
get_schedule_data(AH,BH)->
    base_task_scheduler:get_data1(AH,BH).