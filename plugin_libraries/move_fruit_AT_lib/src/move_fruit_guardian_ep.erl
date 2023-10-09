%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 20. Sep 2023 16:50
%%%-------------------------------------------------------------------
-module(move_fruit_guardian_ep).
-author("LENOVO").
-behaviour(base_guardian_ep).
%% API
-export([init/2, stop/1, request_spawn_instance/2, spawn_cancelled/4, request_start_instance/3, instance_started/3, request_respawn_instance/2, request_resume_instance/3, instance_resumed/3, instance_end/3, handle_instance_call/4]).


init(Pars, BH) ->
  ok.

stop(BH) ->
  ok.

request_spawn_instance(GuardianHandle, BH) ->
  {spawn_instance,#{}}.

spawn_cancelled(Reason, State, ManagerHandle, BH) ->
  ok.

request_start_instance(State, GuardianHandle, BH) ->

  %%  This is where we add the attributes and state variables
  {start_instance, State}.

instance_started(State, GuardianHandle, BH) ->
  spawn(fun()->
    InstBC = base_guardian_ep:get_instance_bc(GuardianHandle, BH),
    InstName = base_business_card:get_name(InstBC),
    io:format("~n ~p has started ~n",[InstName]) end),
  {ok,State}.

request_respawn_instance(GuardianHandle, BH) ->
  erlang:error(not_implemented).

request_resume_instance(State, GuardianHandle, BH) ->
  erlang:error(not_implemented).

instance_resumed(State, GuardianHandle, BH) ->
  erlang:error(not_implemented).

instance_end(State, GuardianHandle, BH) ->
  io:format("~n Bye Bye Move Fruit Instance~n"),
  {ok, archive}.

handle_instance_call(Call, State, GuardianHandle, BH) ->
  erlang:error(not_implemented).

%% Handling custom functions--------------------------------------------------------------------------