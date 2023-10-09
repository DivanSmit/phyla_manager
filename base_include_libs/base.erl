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


%% @doc will retun the BC for this BASE
get_my_bc(BH)->
  cm:get_my_bc(BH).

get_my_short_bc(BH)->
  cm:get_my_short_bc(BH).

%% @doc Gets unix millis of NOW in system time
get_origo() ->
  os:system_time(millisecond).

%% @doc Tells the base to make a backup of its sectors. If the BASE is an instance, it will back up to the Type
%% if it's a type it will back up to the disk ETS sector copies of its ETS tables.
%% If the BASE is a TYPE, dont over use this call since it will saturate the disk with writes
%% (imagine 1000 instances and you back up everything in the type everytime they change state).
%% Instead use the standard type_backup_ep that will back up the sectors every minute
backup_sectors(BH)->
  cm:backup_sectors(BH).


%% @doc This will suspend a process until the BASE has set its base_ready SBB variable to true or continue
%% immediately if it's already true. If you want a BASE to do something as soon as it's started up and ready
%% a process can be spawned with this function at its top. See the BHive boilerlate for an example
wait_for_base_ready(BH)->
  cm:wait_for_base_ready(BH).

get_local_dir()->
  cm:get_local_dir().

%-------------------------------------------------------------------------
% ERROR HANDLING

%% @doc Used to throw errors to the BASE which can be used to debug or trigger plugins to act. Currently not fully developed
%% a critical base error means the BASE is diasbled and cannot perform as it should. Sector crashes will throw this.
critical_error(#base_error{sector = Sector,description = Desc},BH)->
  cm:critical_error(#base_error{sector = Sector,description = Desc},BH).

%% @doc Used to throw warnings to the BASE which can be used to debug or trigger plugins to act. Currently not fully developed
warning(W,BH)->
  cm:warning(W,BH).

log(L,BH)->
  cm:log(L,BH).

%% @doc Used to throw errors to the BASE which can be used to debug or trigger plugins to act. Currently not fully developed
error(E,BH)->
  cm:error(E,BH).
%%  spawn(fun()->bhive_visualiser:b_error(E,CM) end).

alert(A,BH)->
  cm:alert(A,BH).

component_error(E,BH)->
  cm:component_error(E,BH).

%% @doc shuts down a BASE safely, calling all Plugins's "checkout" function
shut_down(BH)->
  cm:shut_down(BH).
%%  bhive_visualiser:b_shutdown(CM).

%% @doc restarts the BASE. @todo check if this works with instance-type relationship
restart(BH)->
  cm:restart(BH).




