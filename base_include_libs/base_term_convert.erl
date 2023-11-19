%%% ====================================================================================== %%%
%%% ====================================================================================== %%%
%%% @copyright (C) 2023, Cybarete Pty Ltd
%%% @doc
%%% The base_term_convert module defines the functions for term manipulation
%%% @end
%%% ====================================================================================== %%%
%%% ====================================================================================== %%%

-module(base_term_convert).
-include("base_terms.hrl").
-export([task_shell_to_map/1, task_shells_to_maps/1, base_term_to_map/1]).

%%% ====================================================================================== %%%
%%%                                 EXTERNAL FUNCTIONS
%%% ====================================================================================== %%%

%% @doc convert a Shell record to a map representation. useful for JSON formatting
task_shell_to_map(#task_shell{type=Type, id=Id, tsched=Tsched, tstart=Tstart, tend=Tend, stage=Stage})->
  #{type=>Type,
    id=>Id,
    tsched=>Tsched,
    tstart=>Tstart,
    tend=>Tend,
    stage=>Stage}.

%% @doc convert a list of Shell records to a list of map representations. useful for JSON formatting
task_shells_to_maps(Shells)->
  lists:foldl(fun(Shell,Acc)->
    [task_shell_to_map(Shell)|Acc]
              end,[],Shells).


base_term_to_map(Shell) when is_record(Shell, task_shell)->
  task_shell_to_map(Shell);

base_term_to_map(PID) when is_pid(PID)->
  pid_to_list(PID);

base_term_to_map(TASK) when is_record(TASK,base_task)->
  unknown_term.