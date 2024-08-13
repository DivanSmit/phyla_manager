%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. Jul 2024 17:49
%%%-------------------------------------------------------------------
-module(sensor_api_rp).
-author("LENOVO").
-behaviour(base_task_rp).
-include("../../../base_include_libs/base_terms.hrl").

%% API
-export([init/2, stop/1, request_reflection/2, start_reflection/3]).


init(Pars, BH) ->
  ok.

stop(BH) ->
  ok.

request_reflection(ReflectorHandle, BH) ->
  {start_reflection, no_state}.

start_reflection(PluginState, ReflectorHandle, BH) ->
  {ok,ExeData} = base_task_rp:get_execution_data(ReflectorHandle,BH),
%%  base_biography:take_task(base_task_rp:get_shell(ReflectorHandle),BH), % Removing unused tasks from Biography

% Extract necessary values from ExeData
  Value = maps:get(<<"value">>, ExeData),
  Type = maps:get(<<"type">>, ExeData),

% Default values for min and max
  Min = maps:get(<<"min">>, ExeData, none),
  Max = maps:get(<<"max">>, ExeData, none),

% Define the alert sending function
  SendAlert = fun(Case) ->
    io:format("sending ~p~n",[Case]),
    MSG = #{
      <<"name">> => myFuncs:myName(BH),
      <<"type">> => Type,
      <<"value">>=> Value,
      <<"time">> => base:get_origo()
    },
    TaskHolons = bhive:discover_bases(#base_discover_query{capabilities = <<"manage_facility">>}, BH),
    base_signal:emit_signal(TaskHolons, <<"ALERT">>, MSG, BH)
              end,

% Check min and max constraints
  case {Min, Max} of
    {none, none} -> ok;
    {MinValue, none} when MinValue > Value -> SendAlert(1);
    {none, MaxValue} when MaxValue < Value -> SendAlert(2);
    {MinValue, MaxValue} when is_float(MinValue) and is_float(MaxValue) ->
      case {MinValue > Value, MaxValue < Value} of
        {true, _} -> SendAlert(3);
        {_, true} -> SendAlert(4);
        _ -> ok
      end;
    _->
      ok
  end,

%%  io:format("~p has a ~p:~p~n",[myFuncs:myName(BH), Type, Value]),

  base_variables:write(<<"SENSORS">>, Type, Value, BH),
  base_task_rp:write_reflection_data(#{<<"type">>=>Type, <<"value">>=>Value}, ReflectorHandle, BH),

  ok.