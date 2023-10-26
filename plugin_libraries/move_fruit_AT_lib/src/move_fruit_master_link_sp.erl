%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. Oct 2023 15:14
%%%-------------------------------------------------------------------
-module(move_fruit_master_link_sp).
-author("LENOVO").
-behaviour(base_link_master_sp).
-include("../../../base_include_libs/base_terms.hrl").
%% API
-export([init/2, stop/1, generate_requirements/3, get_candidates/4, evaluate_proposal/4, all_proposals_received/4, promise_received/4, negotiations_end/4]).


init(Pars, BH) ->
%%  timer:sleep(1000),
  base_link_master_sp:start_link_negotiation(#{<<"AVAILABILITY">>=>any},<<"search">>,BH),
  ok.

stop(BH) ->
  erlang:error(not_implemented).

generate_requirements(Pars, NegH, BH) ->
  % the Pars parameter must be a list of maps per resource or just one map if there is only one resource requirement
  if
    is_list(Pars)->{requirements, Pars, base:get_origo() + 5000, nostate};
    is_map(Pars)->{requirements, [Pars], base:get_origo() + 5000, nostate};
    true-> {error, unknown}
  end.

get_candidates(Requirements, PluginState, NegH, BH) ->
  % search for all planets as candidates and let the planets decide.receive
  DR = #base_discover_query{capabilities = <<"MoveFruit">>},
  CandidateBCs = bhive:discover_bases(DR,BH),
  {candidates,CandidateBCs, nostate}.

evaluate_proposal(Proposal, PluginState, NegH, BH) ->
  {ok,nostate}.

all_proposals_received(ProposalList, PluginState, NegH, BH) ->
  %% proposal evaluation logic
  io:format("Proposal list: ~p~n",[ProposalList]),
  WinningMap = maps:fold(fun(CandidateBC, Proposal, Acc)->
    #{<<"TIME">>:=CandidateTime} = Proposal,

    if
      Acc == null ->
        % it is the first proposal being evaluated
        #{<<"Time">>=>CandidateTime,<<"proposal">>=>Proposal,<<"candidateBC">>=>CandidateBC};
      true->
        % it is not the first proposal being evaluated
        PreviousTime = maps:get(<<"Time">>, Acc), % get the current best proposal
        if
          CandidateTime < PreviousTime ->
            % the latest proposal is better, update the current best proposal
            #{<<"Time">>=>CandidateTime,<<"proposal">>=>Proposal,<<"candidateBC">>=>CandidateBC};
          true ->
            % the latest proposal is not better, keep the old proposal
            Acc
        end
    end
                         end, null, ProposalList),

  %% Convert time to normal time
  {{_,_,_},{Hour,Min,Sec}} = calendar:system_time_to_universal_time(maps:get(<<"Time">>, WinningMap), 1000),
    io:format("The best time is: ~p:~p:~p~n", [Hour,Min,Sec]),

  % retrieve the winning BC
  CandidateBC = if
                  is_map(WinningMap)->
                    % if the winning proposal is a map, then get the winning candidateBC
                    maps:get(<<"candidateBC">>, WinningMap);
                  true ->
                    []
                end,
  {ok, [CandidateBC], nostate}.

promise_received(Promise, PluginState, NegH, BH) ->
  io:format("Master recieved promise: ~p~n",[Promise]),
  LinkID = list_to_binary(ref_to_list(make_ref())),
  Data1 = #{},
  {ok,LinkID,Data1}.

negotiations_end(PromisesMade, PluginState, NegH, BH) ->
  {ok, deadline}.
