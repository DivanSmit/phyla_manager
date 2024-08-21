%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 16. Aug 2024 15:05
%%%-------------------------------------------------------------------
-module(log).
-author("LENOVO").
-export([message/3, event/2]).

-define(LOG_FILE_MESSAGE, "C:/Users/LENOVO/Desktop/base-getting-started/phyla_manager_BASE/plugin_libraries/supplementary_modules/src/message.txt").
-define(LOG_FILE_EVENT, "C:/Users/LENOVO/Desktop/base-getting-started/phyla_manager_BASE/plugin_libraries/supplementary_modules/src/events.txt").

message(From, To, Message) ->
  FilePath = ?LOG_FILE_MESSAGE,
  LogEntry = io_lib:format("~p,~s,~s,~s~n",
    [base:get_origo(), binary_to_list(From), binary_to_list(To), binary_to_list(Message)]),
  LogBinary = list_to_binary(LogEntry),
  case file:open(FilePath, [append, binary, {encoding, utf8}]) of
    {ok, File} ->
      ok = file:write(File, LogBinary),
      file:close(File);
    {error, Reason} ->
      io:format("Failed to open file for appending: ~p~n", [Reason])
  end.

event(Name, Event) ->
  FilePath = ?LOG_FILE_EVENT,
  LogEntry = io_lib:format("~p,~s,~s~n", [base:get_origo(), binary_to_list(Name), binary_to_list(Event)]),
  LogBinary = list_to_binary(LogEntry),
  case file:open(FilePath, [append, binary, {encoding, utf8}]) of
    {ok, File} ->
      ok = file:write(File, LogBinary),
      file:close(File);
    {error, Reason} ->
      io:format("Failed to open file for appending: ~p~n", [Reason])
  end.
