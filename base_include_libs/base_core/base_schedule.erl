-module(base_schedule).
-include("../base_terms.hrl").
-export([backup/1, take_task/2, get_task_meta/2, set_task_meta/3, get_task/2, get_task_data/2, get_all_tasks/1, get_backup/1, query_task_shells/2, get_scheduler_handle/2]).

%% @doc Get the schedule data of the task
-spec get_task_data(Shell :: any(), BH :: base_handle()) -> TaskData::term()|no_entry.
get_task_data(Shell, BH) ->
  s:get_task_data(Shell, BH).

%% @doc get the full base_task with te given shell from Schedule
-spec get_task(Shell :: any(), BH :: base_handle()) -> BaseTask::base_task()|no_entry.
get_task(Shell, BH) ->
  s:get_task(Shell, BH).

%% @doc get the full base_task with te given shell from Schedule and erase it from Schedule
-spec take_task(Shell :: any(), BH :: base_handle()) -> BaseTask::base_task()|no_entry.
take_task(Shell, BH) ->
  s:take_task(Shell, BH).

%% @doc Back up the sector to the Type on the current BHive
-spec backup(BH :: base_handle()) -> ok.
backup(BH) ->
  s:backup(BH).


-spec get_all_tasks(BH :: base_handle()) -> any().
%% @doc Returns a list of all tasks in the Biography
get_all_tasks(BH) ->
  s:get_all_tasks(BH).

%% @doc Get the last backup of this instance saved to the type on its current BHive
-spec get_backup(BH::base_handle())-> Backup::map().
get_backup(BH) ->
  s:get_backup(BH).

-spec query_task_shells(SQ :: any(), BH :: base_handle()) -> Shells::list().
%% @doc Given a shell query, the BASE will return a list of currently executing shells that match the shell query.
query_task_shells(SQ, BH) ->
  s:query_task_shells(SQ, BH).
%------------------------------------------------------------------------
%% @doc Gets the executor handle of a task IF it is in execution otherwise it returns not_in_execution
-spec get_scheduler_handle(Shell::term(),BH::term()) -> ExH::term()|dormant_task|no_entry.
get_scheduler_handle(Shell,BH)->
  s:get_scheduler_handle(Shell,BH).

-spec get_task_meta(Shell :: any(), BH :: base_handle()) -> META::term().
get_task_meta(Shell, BH) ->
  s:get_task_meta(Shell, BH).

-spec set_task_meta(Shell :: any(), Meta :: any(), BH :: base_handle()) -> ok.
set_task_meta(Shell, Meta, BH) ->
  s:set_task_meta(Shell, Meta, BH).
