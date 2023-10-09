
-module(base_link_master_sp).

%%%===================================================================
%%%                     Callback Functions
%%%===================================================================

%% @doc this function is called when the plugin is first initialised
-callback init(Pars::term(),BH::term())->
  ok | {error,Desc::term()}.

%% @doc this function is called when the plugin is removed from the system
-callback stop(BH::term())->
  ok  | {error,Desc::term()}.

%% @doc this function is called when the link negotiation is started.
%% The deadline format deadline epoch time in milliseconds.
-callback generate_requirements(Pars::term(),NegH::term(),BH::term()) ->
  {requirements, Requirements::term(), Deadline::integer(), NewPluginState::term()}
  |{error}. % will cancel the negotiation

%% @doc This function is called when a master_link agent is initialised. It must retain either one or
%% a list of candidate BC's. If there is only one BC it can be passed as is or enclosed in a list.
-callback get_candidates(Requirements::term(),PluginState::term(),NegH::term(),BH::term()) ->
  {candidates ,CandidateBCs::list(), NewPluginState::term()}
  |{error}.

%% @doc This function is called when a proposal is received
-callback evaluate_proposal(Proposal::term(),PluginState::term(),NegH::term(),BH::term()) ->
{ok, NewPluginState::term()} % will store the proposal for later evaluation
|{accept, NewPluginState::term()} % will accept the proposal and notify the service provider
|{reject, Reason::term(), NewPluginState::term()}. % will reject the proposal and notify the service provider

%% @doc This function is called when all remaining proposals have been received
%% The ProposalMaps is a list of #{CandidateBC => Proposal}
-callback all_proposals_received(ProposalMaps::term(),PluginState::term(),NegH::term(), BH::term()) ->
  {ok,AcceptedCandidates::list(),NewPluginState::term()}.

%% @doc This function is called when the makes a promise to the master
-callback promise_received(Promise::term(),PluginState::term(),NegH::term(),BH::term()) ->
  {ok,LinkID::binary(),Data1::term()}.


-callback negotiations_end(PromisesMade::map(),PluginState::term(), NegH::term(),BH::term()) ->
  ok.


%%%===================================================================
%%%                     External Functions
%%%===================================================================

-export([start_link_negotiation/3]).

start_link_negotiation(Pars,TaskTag,BH)->
  s:start_link_negotiation(Pars,TaskTag,BH).