
-module(base_link_servant_sp).

%%%===================================================================
%%%                     Callback Functions
%%%===================================================================

%% @doc This function is called when the plugin is first initialised
-callback init(Pars::term(),BH::term())->
  ok | {error,Desc::term()}.

%% @doc This function is called when the plugin is removed from the system
-callback stop(BH::term())->
  ok  | {error,Desc::term()}.

%% @doc This callback is triggered when the service provider is contacted
-callback request_start_negotiation(MasterBC::term(),NegH::term(), BH::term()) ->
  {start,NewPluginState::term()}
  |{refuse,Reason::term()}
  |{error, Description::term()}.

%% @doc This callback is triggered when the service provider receives the requirements from the client.
-callback generate_proposal(Requirements::term(), PluginState::term(), NegH::term(), BH::term()) ->
  {proposal,Proposal::term(),NewPluginState::term()}|
  {error,Desc::term()}|
  {refuse,Reason::term()}.

%% @doc This callback is triggered when the proposal is accepted by the client
-callback proposal_accepted(PluginState::term(), NegH::term(), BH::term()) ->
  {promise, Tsched::integer(), LinkID::binary(), Data1::term(), NewPluginState::term()}
  |{error, Description::term()}
  |{refuse, Reason::term()}.

%%%===================================================================
%%%                     External Functions
%%%===================================================================

