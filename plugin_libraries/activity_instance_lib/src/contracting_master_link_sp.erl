%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. Jun 2024 09:46
%%%-------------------------------------------------------------------
-module(contracting_master_link_sp).
-author("LENOVO").
-behaviour(base_link_master_sp).
-include("../../../base_include_libs/base_terms.hrl").
%% API
-export([init/2, stop/1, generate_requirements/3, get_candidates/4, evaluate_proposal/4, all_proposals_received/4, promise_received/4, negotiations_end/4]).


init(Pars, BH) ->

  io:format("Contract Master installed~n"),
  FSM = base_attributes:read(<<"meta">>,<<"FSM_Schedule">>,BH),
  FSM_Data = #{
    <<"BH">>=>BH,
    <<"children">>=>base_attributes:read(<<"meta">>,<<"children">>,BH)
  },
  {ok, StateMachinePID} = gen_statem:start_link({global, base_business_card:get_id(base:get_my_bc(BH))}, FSM, FSM_Data, []),

  base_variables:write(<<"FSM_INFO">>, <<"FSM_PID">>, StateMachinePID, BH),
  base_variables:write(<<"FSM_INFO">>,<<"FSM_Count">>, 0,BH),
  base_variables:write(<<"FSM_INFO">>,<<"FSM_Ready">>, 0,BH),

  ok.

stop(BH) ->
  ok.

generate_requirements(Pars, NegH, BH) ->
  % the Pars parameter must be a list of maps per resource or just one map if there is only one resource requirement
  if
    is_list(Pars)->{requirements, Pars, base:get_origo() + 600000, nostate};
    is_map(Pars)->{requirements, [Pars], base:get_origo() + 600000, nostate};
    true-> {error, unknown}
  end.

get_candidates(Requirements, PluginState, NegH, BH) ->
  TypeOfRequirements = maps:get(<<"type">>,Requirements),
  case TypeOfRequirements of
      activity->
        Name = maps:get(<<"name">>,Requirements),
        DR = #base_discover_query{name = Name},
        CandidateBCs = bhive:discover_bases(DR,BH),
        {candidates,CandidateBCs, activity};
    resource->
      DR = #base_discover_query{capabilities = <<"TAKE_MEASUREMENT">>},
      CandidateBCs = bhive:discover_bases(DR,BH),
      case CandidateBCs of
        [] ->
          FSM_PID = base_variables:read(<<"FSM_INFO">>, <<"FSM_PID">>, BH),
          gen_statem:cast(FSM_PID, no_operator),
          base_variables:write(<<"FSM_INFO">>, <<"FSM_status">>, no_operator, BH),
          {candidates, CandidateBCs, resource}
        ;
        _ ->
          {candidates, CandidateBCs, resource}
      end
end.

evaluate_proposal(Proposal, PluginState, NegH, BH) ->
  {ok,PluginState}.


all_proposals_received(ProposalList, PluginState, NegH, BH) ->

  case PluginState of
    activity ->
      CandidateBC = maps:keys(ProposalList),
      {ok, CandidateBC, nostate};
    resource ->
      case ProposalList of
        [] ->
          {ok, [], nostate};
        _ ->
          WinningMap = maps:fold(fun(CandidateBC, Proposal, Acc) ->
            #{<<"TIME">> := CandidateTime} = Proposal,

            if
              Acc == null ->
                % it is the first proposal being evaluated
                #{<<"Time">> => CandidateTime, <<"proposal">> => Proposal, <<"candidateBC">> => CandidateBC};
              true ->
                % it is not the first proposal being evaluated
                PreviousTime = maps:get(<<"Time">>, Acc), % get the current best proposal
                if
                  CandidateTime < PreviousTime ->
                    % the latest proposal is better, update the current best proposal
                    #{<<"Time">> => CandidateTime, <<"proposal">> => Proposal, <<"candidateBC">> => CandidateBC};
                  true ->
                    % the latest proposal is not better, keep the old proposal
                    Acc
                end
            end
                                 end, null, ProposalList),
          % retrieve the winning BC
          CandidateBC = if
                          is_map(WinningMap) ->
                            % if the winning proposal is a map, then get the winning candidateBC
                            maps:get(<<"candidateBC">>, WinningMap);
                          true ->
                            []
                        end,

          {ok, [CandidateBC], nostate}
      end
  end.



promise_received(Promise, PluginState, NegH, BH) ->
  FSM_PID = base_variables:read(<<"FSM_INFO">>,<<"FSM_PID">>,BH),
  gen_statem:cast(FSM_PID,contracted),
  Count = base_variables:read(<<"FSM_INFO">>,<<"FSM_Count">>,BH),
  base_variables:write(<<"FSM_INFO">>,<<"FSM_Count">>, Count+1,BH),

  LinkID = list_to_binary(ref_to_list(make_ref())),
  Data1 = #{},
  {ok,LinkID,Data1}.

negotiations_end(PromisesMade, PluginState, NegH, BH) ->
  {ok, deadline}.