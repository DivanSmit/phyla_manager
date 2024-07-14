%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 26. Apr 2024 17:08
%%%-------------------------------------------------------------------
-module(tp_info_handler_ep).
-author("LENOVO").
-behaviour(base_receptor).
%% API
-export([init/2, stop/1, handle_signal/3, handle_request/4]).


init(Pars, BH) ->
  ok.

stop(BH) ->
  ok.

handle_signal(<<"processScheduled">>, Payload, BH) ->
  base_variables:write(<<"process">>, <<"newStart">>, Payload,BH);

handle_signal(<<"StartTask">>,ID, BH)->
  % Remember to update .json file of any changes to the subject
  ok.

handle_request(<<"INFO">>,<<"INFO">>, FROM ,BH)->
  MyBC = base:get_my_bc(BH),
  MyName = base_business_card:get_name(MyBC),
  Reply = #{},
  {reply, Reply};

handle_request(<<"Update">>, {From, Value}, _, BH) ->
  case Value of
    query ->
      PredList = base_variables:read(<<"predecessors">>, From, BH),
      io:format("Predecessor for ~p: ~p~n", [From, PredList]),
      case length(PredList) of
        0 ->
          {reply, ready};
        _ ->
          CompletedTasksShells = base_biography:get_all_tasks(BH),
          CompletedTasks = case is_map(CompletedTasksShells) of
                             true ->
                               [];
                             _ ->
                               lists:foldl(fun(Elem, Acc) ->
                                 maps:keys(Elem) ++ Acc
                                           end, [], CompletedTasksShells)
                           end,

          case lists:member(lists:nth(1, PredList), CompletedTasks) of
            true ->
              {reply, ready};
            false ->
              {reply, not_ready}
          end
      end;
    _->
      {reply, not_ready}
  end.


