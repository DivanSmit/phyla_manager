%%% ====================================================================================== %%%
%%% ====================================================================================== %%%
%%% @copyright (C) 2023, Cybarete Pty Ltd
%%% @doc
%%% The base_biography module defines the api for the biography sector
%%% of an BASE agent.
%%% @end
%%% ====================================================================================== %%%
%%% ====================================================================================== %%%

-module(base_biography).
-include("../base_terms.hrl").
-export([get_task/2, take_task/2, get_task_meta/2, set_task_meta/3,
  get_all_tasks/1, query_task_shells/2, backup/1, get_task_schedule_data/2, get_task_execution_data/2, get_task_reflection_data/2, put_task/2]).

%%% ====================================================================================== %%%
%%%                                 EXTERNAL FUNCTIONS
%%% ====================================================================================== %%%

%% @doc get a list of all tasks in the Biography
-spec get_all_tasks(BH :: base_handle()) -> any().
%% @doc Returns a list of all tasks in the Biography
get_all_tasks(BH) ->
  b:get_all_tasks(BH).

-spec query_task_shells(SQ :: any(), BH :: base_handle()) -> Shells::list().
%% @doc Given a shell query, the BASE will return a list of currently executing shells that match the shell query.
query_task_shells(SQ, BH) ->
  b:query_task_shells(SQ, BH).

%% @doc get the schedule data of the task with the given shell
-spec get_task_schedule_data(Shell :: any(), BH :: base_handle()) -> TaskData::term()|no_entry.
get_task_schedule_data(Shell,  BH) ->
  b:get_task_schedule_data(Shell, BH).

%% @doc get the execution data of the task with the given shell
-spec get_task_execution_data(Shell :: any(),  BH :: base_handle()) -> TaskData::term()|no_entry.
get_task_execution_data(Shell,  BH) ->
  b:get_task_execution_data(Shell,BH).

%% @doc get the reflection data of the task with the given shell
-spec get_task_reflection_data(Shell :: any(),  BH :: base_handle()) -> TaskData::term()|no_entry.
get_task_reflection_data(Shell,  BH) ->
  b:get_task_reflection_data(Shell,  BH).

%% @doc get the full base_task with te given shell from Biography
-spec get_task(Shell :: any(), BH :: base_handle()) -> BaseTask::base_task()|no_entry.
get_task(Shell, BH) ->
  b:get_task(Shell, BH).

%% @doc get the full base_task with the given shell from biography and erase it from biography
-spec take_task(Shell :: any(), BH :: base_handle()) -> BaseTask::base_task()|no_entry.
take_task(Shell, BH) ->
  b:take_task(Shell, BH).

put_task(Task, BH) ->
  b:put_task(Task, BH).

%% @doc Back up the sector to the Type on the current BHive
-spec backup(BH :: base_handle()) -> any().
backup(BH) ->
  b:backup(BH).

-spec get_task_meta(Shell :: any(), BH :: base_handle()) -> META::term().
get_task_meta(Shell, BH) ->
  b:get_task_meta(Shell, BH).

-spec set_task_meta(Shell :: any(), Meta :: any(), BH :: base_handle()) -> ok.
set_task_meta(Shell, Meta, BH) ->
  b:set_task_meta(Shell, Meta, BH).

