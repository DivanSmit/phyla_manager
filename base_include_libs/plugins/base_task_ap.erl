%%% ====================================================================================== %%%
%%% ====================================================================================== %%%
%%% @copyright (C) 2023, Cybarete Pty Ltd
%%% @doc
%%% The analysis plugin behaviour module defines the callbacks for the
%%% analysis of all task and provides external functions to use.
%%% @end
%%% ====================================================================================== %%%
%%% ====================================================================================== %%%

-module(base_task_ap).
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
