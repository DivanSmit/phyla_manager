%%% ====================================================================================== %%%
%%% ====================================================================================== %%%
%%% @copyright (C) 2023, Cybarete Pty Ltd
%%% @doc
%%% The guardian execution behaviour module defines the callbacks for the
%%% execution of a guardian task and provides external functions to use.
%%% @end
%%% ====================================================================================== %%%
%%% ====================================================================================== %%%

-module(base_guardian_ep).
-compile(export_all).
-include("../base_terms.hrl").

%%% ====================================================================================== %%%
%%%                                 CALLBACK FUNCTIONS
%%% ====================================================================================== %%%

%% @doc this function is called when the plugin is first initialised
-callback init(Pars::term(),BH::term())->
    ok.

%% @doc this function is called when the plugin is removed from the system
-callback stop(BH::term())->
    ok.

%% @doc this function is called when the scheduled spawn wants to start
-callback request_spawn_instance(GuardianHandle::agent_handle(),BH::base_handle())->
    {spawn_instance, State::term()}
    |{await_spawn, State::term()}
    |{cancel_spawn,Reason::term(),State::term()}.

%% @doc this function is called when a spawn is cancelled
-callback spawn_cancelled(Reason::term(),State::term(),ManagerHandle::term(),BH::base_handle())->
    ok.

%% @doc this function is called when a schedule guardian task is ready to start executing
-callback request_start_instance(State::term(),GuardianHandle::agent_handle(),BH::base_handle())->
    {start_instance,NewState::term()}
    |{await_start, NewState::term()}
    |{cancel_start,Reason::term()}.

%% @doc this function ic called when an instance has started
-callback instance_started(State::term(),GuardianHandle::agent_handle(),BH::base_handle())->
    {ok,NewState::term()}
    |{end_instance,NewState::term()}.

%% @doc this function is called when an instance is ready to respawn
-callback request_respawn_instance(GuardianHandle::agent_handle(),BH::base_handle())->
    {respawn_instance,NewState::term()}
    |{await_respawn, NewState::term()}
    |{cancel_respawn,Reason::term(),State::term()}.

%% @doc this function is called when an instance is ready to resume
-callback request_resume_instance(State::term(),GuardianHandle::agent_handle(),BH::base_handle())->
    {resume_instance,NewState::term()}
    |{await_start,NewState::term()}
    |{cancel_resume,Reason::term()}.

%% @doc this function is called when an instance has resumed
-callback instance_resumed(State::term(),GuardianHandle::agent_handle(),BH::base_handle())->
    {ok,NewState::term()} | {end_instance,NewState::term()}.

%% @doc this function is called when an instance has ended
-callback instance_end(State::term(),GuardianHandle::agent_handle(),BH::base_handle())->
    {ok,LB::term()}.

%% @doc this function is called when the type receives a call from the instance
-callback handle_instance_call(Call::term(),State::term(),GuardianHandle::agent_handle(),BH::base_handle())->
    {reply,Reply::term(),NewState::term()}
    |{ok,NewState::term()}.

%% @doc this function is called when the state variable subscription receives an update
-callback base_variable_update({VarPageName::term(), VarKey::term(), VarValue::term()},State::term(),GuardianHandle::agent_handle(),BH::term())->
    {ok,NewState::term()}
    |{end_instance,NewState::term()}.

%%% ====================================================================================== %%%
%%%                                 EXTERNAL FUNCTIONS
%%% ====================================================================================== %%%

%% @doc write a variable to the attribute sector of the instance
-spec write_instance_attribute(PAGE::binary(), KEY::binary(), VAL::term(), GH::agent_handle(), BH::term())-> ok.
write_instance_attribute(PAGE,KEY,VAL,GH,BH)->
    base_guardian:write_instance_attribute(PAGE,KEY,VAL,GH,BH).

%% @doc write a page to the attribute sector of the instance
-spec write_instance_attribute_page(PAGE_NAME::binary(), DATA::map(), GH::agent_handle(), BH::term())-> ok.
write_instance_attribute_page(PAGE_NAME,DATA,GH,BH)->
    base_guardian:write_instance_attribute_page(PAGE_NAME,DATA,GH,BH).

-spec spawn_instance(GaurdianHandle::agent_handle(),BH::base_handle())-> ok | {error,Reason::term()}.
spawn_instance(GaurdianHandle,BH)->
    base_guardian:spawn_instance(GaurdianHandle,BH).

-spec start_instance(GaurdianHandle::agent_handle(),BH::base_handle())-> ok | {error,Reason::term()}.
start_instance(GaurdianHandle,BH)->
    base_guardian:start_instance(GaurdianHandle,BH).

-spec resume_instance(GaurdianHandle::agent_handle(),BH::base_handle())-> ok |{ error,Reason::term()}.
resume_instance(GaurdianHandle,BH)->
    base_guardian:resume_instance(GaurdianHandle,BH).

-spec install_plugins(GH::agent_handle(),EPs::list(),BH::base_handle())-> ok.
install_plugins(GH,EPs,BH)->
    base_guardian:install_plugins(GH,EPs,BH).

-spec end_instance(GH::agent_handle(), BH::base_handle())-> ok.
end_instance(GH,BH)->
    base_guardian:end_instance(GH,BH).

-spec get_active_guardians(BH::base_handle())->Guardians::list().
get_active_guardians(BH)->
    base_guardian:get_active_guardians(BH).

-spec get_all_instance_bcs(BH::base_handle())-> BCs::list().
get_all_instance_bcs(BH)->
    base_guardian:get_all_instance_bcs(BH).

-spec get_instance_bc(GH::agent_handle(),BH::base_handle())->BC::term().
get_instance_bc(GH,BH)->
    base_guardian:get_instance_bc(GH,BH).

-spec get_guardian_of_id(ID::binary(),BH::base_handle())->Guardian::agent_handle().
get_guardian_of_id(ID,BH)->
    base_guardian:get_guardian_of_id(ID,BH).

-spec get_guardian_of_name(ID::binary(),BH::base_handle())->Guardian::agent_handle().
get_guardian_of_name(ID,BH)->
    base_guardian:get_guardian_of_name(ID,BH).

-spec request_instance(GH::agent_handle(),TAG::binary(),Payload::term(),BH::base_handle())-> REPLY::term().
request_instance(GH,TAG,Payload,BH)->
    base_guardian:request_instance(GH,TAG,Payload,BH).

-spec signal_instance(GH::agent_handle(),TAG::binary(),Payload::term(),BH::base_handle())-> REPLY::term().
signal_instance(GH,TAG,Payload,BH)->
    base_guardian:signal_instance(GH,TAG,Payload,BH).