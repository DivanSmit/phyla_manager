%%% ====================================================================================== %%%
%%% ====================================================================================== %%%
%%% @copyright (C) 2023, Cybarete Pty Ltd
%%% @doc
%%% The schedule plugin behaviour module defines the callbacks for the
%%% scheduling of a basic task and provides external functions to use.
%%% @end
%%% ====================================================================================== %%%
%%% ====================================================================================== %%%

-module(base_task_sp).
-export([schedule_task/5]).
-include("../base_terms.hrl").

%%% ====================================================================================== %%%
%%%                                 CALLBACK FUNCTIONS
%%% ====================================================================================== %%%

%% @doc this function is called when the plugin is first initialised
-callback init(Pars::term(),BH::term())->
    ok.

%% @doc this function is called when the plugin is removed from the system
-callback stop(BH::term())->
    ok.

%%% ====================================================================================== %%%
%%%                                 EXTERNAL FUNCTIONS
%%% ====================================================================================== %%%

%% @doc this function will schedule a basic task with the given Tsched time (epoch), Type, ID and Data1 for the given base holon.
schedule_task(TSCHED,TYPE,ID,Data1,BH) ->
    base_task_scheduler:schedule_task(TSCHED,TYPE,ID,Data1,BH).
