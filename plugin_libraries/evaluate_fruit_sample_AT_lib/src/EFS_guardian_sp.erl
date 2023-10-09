%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 20. Sep 2023 16:35
%%%-------------------------------------------------------------------
-module('EFS_guardian_sp').
-author("LENOVO").
-behaviour(base_guardian_sp).
%% API
-export([init/2, stop/1, instance_spawn_request/2, generate_instance_recipe/2]).


init(Pars, BH) ->
  ok.

stop(BH) ->
  erlang:error(not_implemented).

instance_spawn_request(Pars, BH) ->
  erlang:error(not_implemented).

generate_instance_recipe(Pars, BH) ->
  erlang:error(not_implemented).