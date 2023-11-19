%%% ====================================================================================== %%%
%%% ====================================================================================== %%%
%%% @copyright (C) 2023, Cybarete Pty Ltd
%%% @doc
%%% The guardian schedule behaviour module defines the callbacks for the
%%% scheduling of a guardian task and provides external functions to use.
%%% @end
%%% ====================================================================================== %%%
%%% ====================================================================================== %%%

-module(base_guardian_sp).
-compile(export_all).
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
%%%                                 TEMPLATE FUNCTIONS
%%% ====================================================================================== %%%

%% @doc These functions do not act as callbacks but are here to help structure your plugin

-callback instance_spawn_request(Pars::term(),BH::term())->
  ok.

-callback generate_instance_recipe(Pars::term(),BH::term())->
  {ok,Recipe::term()} | {error,Desc::term()}.

%%% ====================================================================================== %%%
%%%                                 EXTERNAL FUNCTIONS
%%% ====================================================================================== %%%

-spec schedule_instance_guardian(Tsched::integer(),Brecipe::map(),Data1::term(),BH::base_handle())-> ok.
schedule_instance_guardian(Tsched,Brecipe,Data1,BH)->
  base_guardian:schedule_instance_guardian(Tsched,Brecipe,Data1,BH).