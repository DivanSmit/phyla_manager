%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. Apr 2024 17:36
%%%-------------------------------------------------------------------
-module(configure_process_guardian_ep).
-author("LENOVO").
-behaviour(base_guardian_ep).
%% API
-export([init/2, stop/1, request_spawn_instance/2, spawn_cancelled/4, request_start_instance/3, instance_started/3, request_respawn_instance/2, request_resume_instance/3, instance_resumed/3, instance_end/3, handle_instance_call/4, base_variable_update/4]).


init(Pars, BH) ->
  erlang:error(not_implemented).

stop(BH) ->
  erlang:error(not_implemented).

request_spawn_instance(GuardianHandle, BH) ->
  erlang:error(not_implemented).

spawn_cancelled(Reason, State, ManagerHandle, BH) ->
  erlang:error(not_implemented).

request_start_instance(State, GuardianHandle, BH) ->
  erlang:error(not_implemented).

instance_started(State, GuardianHandle, BH) ->
  erlang:error(not_implemented).

request_respawn_instance(GuardianHandle, BH) ->
  erlang:error(not_implemented).

request_resume_instance(State, GuardianHandle, BH) ->
  erlang:error(not_implemented).

instance_resumed(State, GuardianHandle, BH) ->
  erlang:error(not_implemented).

instance_end(State, GuardianHandle, BH) ->
  erlang:error(not_implemented).

handle_instance_call(Call, State, GuardianHandle, BH) ->
  erlang:error(not_implemented).

base_variable_update(_, State, GuardianHandle, BH) ->
  erlang:error(not_implemented).