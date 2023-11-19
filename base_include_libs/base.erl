%%% ====================================================================================== %%%
%%% ====================================================================================== %%%
%%% @copyright (C) 2023, Cybarete Pty Ltd
%%% @doc
%%% The base module defines the api key BASE functions
%%% @end
%%% ====================================================================================== %%%
%%% ====================================================================================== %%%

-module(base).
-include("base_terms.hrl").

-export([
  get_my_bc/1,
  get_origo/0,
  backup_sectors/1,

  wait_for_base_ready/1,
  get_local_dir/0,
  critical_error/2,
  warning/2,
  log/2,
  error/2,
  alert/2,
  component_error/2,
  get_my_short_bc/1,
  restart/1,
  shut_down/1]).

%%% ====================================================================================== %%%
%%%                                 EXTERNAL FUNCTIONS
%%% ====================================================================================== %%%

%% @doc will return the BC for this BASE
get_my_bc(BH)->
  cm:get_my_bc(BH).

get_my_short_bc(BH)->
  cm:get_my_short_bc(BH).

%% @doc gets unix millis of NOW in system time
get_origo() ->
  os:system_time(millisecond).

backup_sectors(BH)->
  cm:backup_sectors(BH).

wait_for_base_ready(BH)->
  cm:wait_for_base_ready(BH).

get_local_dir()->
  cm:get_local_dir().

critical_error(#base_error{sector = Sector,description = Desc},BH)->
  cm:critical_error(#base_error{sector = Sector,description = Desc},BH).

warning(W,BH)->
  cm:warning(W,BH).

log(L,BH)->
  cm:log(L,BH).

error(E,BH)->
  cm:error(E,BH).

alert(A,BH)->
  cm:alert(A,BH).

component_error(E,BH)->
  cm:component_error(E,BH).

shut_down(BH)->
  cm:shut_down(BH).

restart(BH)->
  cm:restart(BH).




