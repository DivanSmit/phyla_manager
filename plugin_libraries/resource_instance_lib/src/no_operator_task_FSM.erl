%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. Jul 2024 10:17
%%%-------------------------------------------------------------------
-module(no_operator_task_FSM).
-author("LENOVO").
-behaviour(gen_statem).
%% API
-export([init/1, callback_mode/0, cooldown/3, store_fruit/3, ask_parent/3, finish/3, terminate/3]).


init(Pars) ->
  io:format("FSM Started~n"),

  {ok, cooldown, Pars}.

callback_mode() ->
  [state_functions, state_enter].

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cooldown(enter, _OldState, State) ->
  gen_statem:cast(self(), internal_check),
  {keep_state, State};

cooldown(cast, internal_check, State) ->
  %% TODO do some calculations to get the time delay
  io:format("Cooling Down~n"),
  Delay = 10000, % Just doing a 10s for now
  {keep_state, State, Delay};

cooldown(timeout, _EventContent, State) ->
  {next_state, store_fruit, State};

cooldown(cast, _, {State, OldTIme}) ->
  Delay = 10000,
  {keep_state, State, Delay}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

store_fruit(enter, _OldState, State) ->
  gen_statem:cast(self(), internal_check),
  {keep_state, State};

store_fruit(cast, internal_check, State) ->
  io:format("Storing the fruit~n"),

  Data1 = maps:get(<<"Data1">>, State),
  Delay = maps:get(<<"duration">>, Data1), % Just doing a 10s for now
  {keep_state, {State,base:get_origo()}, Delay};

store_fruit(timeout, _EventContent, {State,_}) ->
  io:format("Time completed~n"),

  {next_state, ask_parent, State};

store_fruit(cast, end_task, {State, _OldTIme}) ->
  {next_state, finish, State};

store_fruit(cast, _, {State, OldTIme}) ->
  io:format("~n *[NO operator]*: Unsupported cast ~n"),
  Data1 = maps:get(<<"Data1">>, State),
  Delay = maps:get(<<"duration">>, Data1),
  RemainingTIme = Delay-base:get_origo()+OldTIme,
  {keep_state, {State,OldTIme}, RemainingTIme}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ask_parent(enter, _OldState, State) ->
  gen_statem:cast(self(), internal_check),
  {keep_state, State};

ask_parent(cast, internal_check, State) ->
  %% TODO ask parent with partner call
  io:format("Going to ask the parent~n"),

  ExH = maps:get(<<"execution">>, State),
  Response = base_link_ep:call_partner(<<"END_Task">>, <<"Request">>, ExH),
  case Response of
    finish -> {next_state, finish, State};
    _ -> {keep_state, State}
  end;

ask_parent(cast, end_task, State) ->
  {next_state, finish, State};

ask_parent(cast, _, State) ->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
finish(enter, OldState, State) ->
  {stop, normal, State};

finish(cast, _, State) ->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
terminate(Reason, _StateName, State) ->
  ok.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


