%%% ====================================================================================== %%%
%%% ====================================================================================== %%%
%%% @copyright (C) 2023, Cybarete Pty Ltd
%%% @doc
%%% The base_schedule module defines the api for the schedule sector
%%% of an BASE agent.
%%% @end
%%% ====================================================================================== %%%
%%% ====================================================================================== %%%

-module(base_schedule).
-include("../base_terms.hrl").
-export([backup/1, take_task/2, get_task_meta/2, set_task_meta/3, get_task/2,
  get_task_data/2, get_all_tasks/1, get_backup/1, query_task_shells/2]).

%%% ====================================================================================== %%%
%%%                                 EXTERNAL FUNCTIONS
%%% ====================================================================================== %%%

%% @doc given a shell query, the BASE will return a list of currently scheduled shells that match the shell query.
-spec query_task_shells(SQ :: any(), BH :: base_handle()) -> Shells::list().
query_task_shells(SQ, BH) ->
  s:query_task_shells(SQ, BH).

%% @doc get the data1 from the given task shell from the schedule sector
-spec get_task_data(Shell :: any(), BH :: base_handle()) -> TaskData::term() | no_entry.
get_task_data(Shell, BH) ->
  s:get_task_data(Shell, BH).

%% @doc get the full base task for the given shell from the schedule sector
-spec get_task(Shell :: any(), BH :: base_handle()) -> BaseTask::base_task() | no_entry.
get_task(Shell, BH) ->
  s:get_task(Shell, BH).

%% @doc get all the base tasks currently on the schedule
-spec get_all_tasks(BH :: base_handle()) -> BaseTasks::list().
get_all_tasks(BH) ->
  s:get_all_tasks(BH).

%% @doc get the full base task for the given shell and delete it from the schedule sector
-spec take_task(Shell :: any(), BH :: base_handle()) -> BaseTask::base_task()|no_entry.
take_task(Shell, BH) ->
  s:take_task(Shell, BH).

%% @doc get the meta data of a task on the schedule sector
-spec get_task_meta(Shell :: any(), BH :: base_handle()) -> META::term().
get_task_meta(Shell, BH) ->
  s:get_task_meta(Shell, BH).

%% @doc set the meta data of a task on the schedule sector
-spec set_task_meta(Shell :: any(), Meta :: any(), BH :: base_handle()) -> ok.
set_task_meta(Shell, Meta, BH) ->
  s:set_task_meta(Shell, Meta, BH).

%% @doc back up the sector to the Type on the current BHive
-spec backup(BH :: base_handle()) -> ok.
backup(BH) ->
  s:backup(BH).

%% @doc get the last backup of this instance saved to the type on its current BHive
-spec get_backup(BH::base_handle())-> Backup::map().
get_backup(BH) ->
  s:get_backup(BH).

