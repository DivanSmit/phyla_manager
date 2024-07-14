%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. May 2024 11:06
%%%-------------------------------------------------------------------
-module(facility_manager_info_handler_ep).
-author("LENOVO").
-behaviour(base_receptor).
-include("../../../base_include_libs/base_terms.hrl").

%% API
-export([init/2, stop/1, handle_signal/3, handle_request/4]).


init(Pars, BH) ->
  io:format("Installed FM INFO~n"),
  ok.

stop(BH) ->
  ok.

handle_signal(<<"ALERT">>, Data, BH) ->
  %% TODO Implement a FM dashboard with notifications. Save unread notifications in var and send when requested
    io:format("!!ALERT!! -> [~s] - ~s measured ~s: ~p~n",[
    myFuncs:convert_unix_time_to_normal(maps:get(<<"time">>,Data),string),
    binary_to_list(maps:get(<<"name">>,Data)),
    binary_to_list(maps:get(<<"type">>,Data)),
    maps:get(<<"value">>,Data)
  ]),
  ok.

handle_request(<<"TEST">>,Data, FROM, BH)->

  Reply = #{<<"Reply">>=>ok},
  {reply, Reply};

handle_request(<<"SPAWN">>,<<"currentConfig">>, FROM, BH)->
%%  io:format("FM received request to create new Treatment Process~n"),
  TaskHolons = bhive:discover_bases(#base_discover_query{capabilities = <<"SPAWN_TREATMENT_PROCESS_INSTANCE">>}, BH),
  CurrentConfig = base_signal:emit_request(TaskHolons, <<"currentConfig">>, none, BH),

  % The UI needs to remember the Treatment ID to know what the corresponding Treatment Process is.
  Reply = #{<<"Reply">>=>CurrentConfig},
  {reply, Reply};

%% TODO setup the UI to send messages to the FM instead of PT Type
handle_request(<<"newConfig">>,Configurations, FROM, BH)->
%%  io:format("FM received request to create new Treatment Process~n"),
  TaskHolons = bhive:discover_bases(#base_discover_query{capabilities = <<"SPAWN_TREATMENT_PROCESS_INSTANCE">>}, BH),
  TreatmentID = base_signal:emit_request(TaskHolons, <<"SPAWN_TREATMENT_PROCESS_INSTANCE">>,Configurations, BH),

  % The UI needs to remember the Treatment ID to know what the corresponding Treatment Process is.
  Reply = #{<<"Reply">>=>TreatmentID},
  {reply, Reply}.



