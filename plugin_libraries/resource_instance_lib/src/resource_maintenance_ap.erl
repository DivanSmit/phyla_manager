%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 15. Aug 2024 19:24
%%%-------------------------------------------------------------------
-module(resource_maintenance_ap).
-author("LENOVO").
-behaviour(base_task_ap).
-include("../../../base_include_libs/base_terms.hrl").
%% API
-export([init/2, stop/1]).


init(Pars, BH) ->
  timer:sleep(3000),
  Maintenance = base_attributes:read(<<"attributes">>, <<"maintenance">>, BH),
  case map_size(Maintenance) of
    0 -> ok;
    _ -> analysis(BH)
  end,
  ok.

stop(BH) ->
  erlang:error(not_implemented).

analysis(BH)->

  Maintenance = base_attributes:read(<<"attributes">>, <<"maintenance">>, BH),
  Frequency = maps:get(<<"frequency">>, Maintenance),
  MaxDuration = maps:get(<<"max">>, Maintenance),
  CurrentDuration = base_variables:read(<<"Maintenance">>, <<"TotalDuration">>, BH),
  if
    MaxDuration > CurrentDuration -> ok;
    true ->
      %% Schedule the Process
      Data = #{
        <<"name">>=>myFuncs:myName(BH),
        <<"StartTime">>=> maps:get(<<"prepTime">>,Maintenance)+base:get_origo(),
        <<"Duration">>=> maps:get(<<"duration">>, Maintenance)
      },

      Scheduled = base_variables:read(<<"Maintenance">>, <<"Scheduled">>, BH),
      if
        Scheduled == false ->
          TaskHolons = bhive:discover_bases(#base_discover_query{capabilities = <<"SPAWN_PROCESS_TASK_INSTANCE">>}, BH),
          base_signal:emit_signal(TaskHolons, <<"ScheduleMaintenance">>, Data, BH),
          base_variables:write(<<"Maintenance">>, <<"Scheduled">>, true, BH);
        true -> ok
      end
  end,

  spawn(fun() ->
    timer:sleep(Frequency),% Every Two minutes
    analysis(BH)
        end),
  ok.