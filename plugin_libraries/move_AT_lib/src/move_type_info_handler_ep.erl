%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. Oct 2023 11:47
%%%-------------------------------------------------------------------
-module(move_type_info_handler_ep).
-author("LENOVO").
-behaviour(base_receptor).
%% API
-export([init/2, stop/1, handle_signal/3, handle_request/4]).


init(Pars, BH) ->
  ok.

stop(BH) ->
  ok.

handle_signal(<<"END">>, GH, BH) ->
%%  TODO end instance call
%%  io:format("Recieved end request, GH:~p~n",[GH]),
  case base_guardian_ep:end_instance(GH, BH) of
    ok -> io:format("Succsessfull~n");
    _ -> io:format("Not Successfull~n")
  end,
  ok.

handle_request(<<"SPAWN_MOVE_INSTANCE">>,Payload, FROM, BH)->
%%  io:format("Recieved SPAWN_MOVE_INSTANCE~n"),

  IDInt = rand:uniform(1000),
  ID = integer_to_binary(IDInt),

  case maps:get(<<"name">>, Payload) of
    no_entry ->
      Name = list_to_binary("PS_" ++ integer_to_list(IDInt));
    _ ->
      Name = maps:get(<<"name">>, Payload)
  end,

  {ok, Recipe} = move_guardian_sp:generate_instance_recipe(Name, ID, BH), %% TODO add the time into the equation, or add it in the attributes
  Tsched = base:get_origo(),
  Data1 = Payload, %% Meta data with Process ID
  spawn(fun()->
    base_guardian_sp:schedule_instance_guardian(Tsched,Recipe,Data1,BH)
        end),
  Reply = Name,
  {reply, Reply}.
