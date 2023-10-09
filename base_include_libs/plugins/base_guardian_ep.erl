-module(base_guardian_ep).
-include("../base_terms.hrl").
-compile(export_all).

%%%===================================================================
%%%                     Callback Functions
%%%===================================================================

%% @doc this function is called when the plugin is first initialised.
-callback init(Pars::term(),BH::base_handle())->
    ok | {error,Desc::term()}.

%% @doc this function is called when the plugin is removed from the system.
-callback stop(BH::base_handle())->
    ok  | {error,Desc::term()}.

%% @doc this function is called when the scheduled instance spawn wants to start.
-callback request_spawn_instance(GuardianHandle::agent_handle(),BH::base_handle())->
    {spawn_instance, State::term()} | {await_spawn, State::term()} | {cancel_spawn,Reason::term()}.

%% @doc this function is called when a spawn is cancelled
-callback spawn_cancelled(Reason::term(),State::term(),GuardianHandle::term(),BH::base_handle())->
    ok.

%% @doc this function is called when the instance is to be started.
%% it provides opportunity to upload attributes to the instance.
-callback request_start_instance(State::term(),GuardianHandle::agent_handle(),BH::base_handle())->
    {start_instance,NewState::term()} | {await_start, NewState::term()} |{cancel_start,Reason::term()}.

%% @doc this function is called when the instance has started up and is running.
-callback instance_started(State::term(),GuardianHandle::agent_handle(),BH::base_handle())->
    {ok,NewState::term()} | {end_instance,NewState::term()}.

%% @doc this function is called after a system restart when a previously executing instance
%% wants to request to spawn.
-callback request_respawn_instance(GuardianHandle::agent_handle(),BH::base_handle())->
    {respawn_instance,NewState::term()}| {await_respawn, NewState::term()} | {cancel_respawn,Reason::term()}.

%% @doc this function is called after a system restart when an instance has been respawned and
%% wants to resume execution.
-callback request_resume_instance(State::term(),GuardianHandle::agent_handle(),BH::base_handle())->
    {resume_instance,NewState::term()}|{await_start,NewState::term()} | {cancel_resume,Reason::term()}.

%% @doc this function is called when the instance has resumed execution.
-callback instance_resumed(State::term(),GuardianHandle::agent_handle(),BH::base_handle())->
    {ok,NewState::term()} | {end_instance,NewState::term()}.

%% @doc this function is called when the instance has ended.
-callback instance_end(State::term(),GuardianHandle::agent_handle(),BH::base_handle())->
    {ok, LB::term()}.

%% @doc this function is called when the BASE type receives a call from the instance it is managing.
-callback handle_instance_call(Call::term(),State::term(),GuardianHandle::agent_handle(),BH::base_handle())->
    {reply,Reply::term(),NewState::term()}|{ok,NewState::term()}.


%%%===================================================================
%%%                     Built-in Functions
%%%===================================================================

%% @doc trigger the spawn of an instance which is waiting on the origio.
-spec spawn_instance(GaurdianHandle::agent_handle(),BH::base_handle())-> ok|{error,Reason::term()}.
spawn_instance(GaurdianHandle,BH)->
    base_guardian:spawn_instance(GaurdianHandle,BH).

%% @doc trigger the start of an instance that is waiting.
-spec start_instance(GaurdianHandle::agent_handle(),BH::base_handle())-> ok|{error,Reason::term()}.
start_instance(GaurdianHandle,BH)->
    base_guardian:start_instance(GaurdianHandle,BH).

-spec resume_instance(GaurdianHandle::agent_handle(),BH::base_handle())->ok|{error,Reason::term()}.
resume_instance(GaurdianHandle,BH)->
    base_guardian:resume_instance(GaurdianHandle,BH).

-spec install_plugins(GH::agent_handle(),EPs::list(),BH::base_handle())-> ok.
install_plugins(GH,EPs,BH)->
    base_guardian:install_plugins(GH,EPs,BH).

%% @doc write to the attributes of an instance
%% will write to a specified page in the attributes
-spec write_instance_attribute(PAGE::binary(), KEY::binary(), VAL::term(), GH::agent_handle(), BH::term())->ok.
write_instance_attribute(PAGE,KEY,VAL,GH,BH)->
    base_guardian:write_instance_attribute(PAGE,KEY,VAL,GH,BH).

%% @doc write to the attributes of an instance
%% will write a whole page to the attributes
-spec write_instance_attribute_page(PAGE_NAME::binary(), DATA::map(), GH::agent_handle(), BH::term())->ok.
write_instance_attribute_page(PAGE_NAME,DATA,GH,BH)->
    base_guardian:write_instance_attribute_page(PAGE_NAME,DATA,GH,BH).

-spec archive_instance(GH::agent_handle(), BH::term())->ok.
archive_instance(GH,BH)->
    base_guardian:archive_instance(GH,BH).

-spec migrate_instance(GH::agent_handle(),DestGH::agent_handle(), BH::base_handle())->ok.
migrate_instance(GH,DestGH,BH)->
    base_guardian:migrate_instance(GH,DestGH,BH).

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




