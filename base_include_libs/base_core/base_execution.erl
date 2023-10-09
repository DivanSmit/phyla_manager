-module(base_execution).
-include("../base_terms.hrl").

-export([get_task/2, get_all_tasks/1, backup/1, get_task_schedule_data/2, put_task_data/3,
  put_task/2, take_task/2, get_task_meta/2,
  set_task_meta/3, query_task_shells/2, get_executor_handle/2, get_pending_task_shells/1, is_executing/2, get_backup/1, get_task_execution_data/2]).

%% @doc Get the data stored during the schedule phase of the task with the given shell
-spec get_task_schedule_data(Shell :: any(), BH :: base_handle()) -> TaskData::term()|no_entry.
get_task_schedule_data(Shell,BH) ->
  e:get_task_schedule_data(Shell, BH) .

%% @doc Get the data stored during the execution phase of the task with the given shell
-spec get_task_execution_data(Shell :: any(), BH :: base_handle()) -> TaskData::term()|no_entry.
get_task_execution_data(Shell,BH) ->
  e:get_task_execution_data(Shell, BH) .

%% @doc Put data into the execution phase of the task with the given shell
-spec put_task_data(Shell::task_shell(),Data::term(), BH :: base_handle()) -> ok.
put_task_data(Shell,Data,BH) ->
  e:put_task_data(Shell,Data,BH) .

-spec put_task(Task::base_task(),BH::base_handle()) -> ok.
put_task(Task,BH) ->
  e:put_task(Task,BH) .

-spec get_task(Shell :: any(), BH :: base_handle()) -> BaseTask::base_task()|no_entry.
get_task(Shell,BH) ->
  e:get_task(Shell,BH) .

-spec take_task(Shell :: any(), BH :: base_handle()) -> BaseTask::base_task()|no_entry.
take_task(Shell,BH) ->
  e:take_task(Shell,BH) .

-spec get_task_meta(Shell::task_shell(),BH :: base_handle()) -> Meta::term().
get_task_meta(Shell,BH) ->
  e:get_task_meta(Shell,BH) .

-spec set_task_meta(Shell::task_shell(),Meta::term(), BH :: base_handle()) -> ok.
set_task_meta(Shell,Meta,BH) ->
  e:set_task_meta(Shell,Meta,BH) .

-spec get_all_tasks(BH :: base_handle()) -> any().
get_all_tasks(BH)->
  e:get_all_tasks(BH).


%% @doc Given a shell query, the BASE will return a list of currently executing shells that match the shell query.
-spec query_task_shells(SQ::term() , BH :: base_handle())-> Shells::list().
query_task_shells(SQ ,BH)->
  e:query_task_shells(SQ,BH).

-spec backup(BH :: base_handle()) -> any().
backup(BH)->
  e:backup(BH).
%% @doc Get the last backup of this instance saved to the type on its current BHive
-spec get_backup(BH::base_handle())-> Backup::map().
get_backup(BH) ->
  e:get_backup(BH).
%------------------------------------------------------------------------
%% @doc Gets the executor handle of a task IF it is in execution otherwise it returns not_in_execution
-spec get_executor_handle(Shell::term(), BH :: base_handle()) -> ExH::term()|not_in_execution.
get_executor_handle(Shell,BH)->
  e:get_executor_handle(Shell,BH).

-spec get_pending_task_shells(BH :: base_handle())-> Shells::list().
get_pending_task_shells(BH)->
  e:get_pending_task_shells(BH).

%% @doc Checks of there is an activity in Execution with the given shell
-spec is_executing(Shell :: task_shell(),BH :: base_handle())-> ok.
is_executing(Shell,BH)->
  e:is_executing(Shell,BH).
