%%% ====================================================================================== %%%
%%% ====================================================================================== %%%
%%% @copyright (C) 2023, Cybarete Pty Ltd
%%% @doc
%%% The Link Task behaviour for an execution plugin.
%%% @end
%%% ====================================================================================== %%%
%%% ====================================================================================== %%%

-module(base_link_ep).
-export([get_partner_bc/1, start_link/1, signal_partner/3, get_shell/1, end_link/2, call_partner/3]).
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

%% @doc This is called to ask whether the link should start or wait for the partner to start it first.
-callback request_start_link(PluginState::term(),ExH::term(),BH::term())->
    {start,NewPluginState::term()} % will send a partner ready message to the partner agent
    |{wait,NewPluginState::term()}  % will wait for the partner ready message or external start trigger before doing anything
    |{cancel,Reason::term()}.  %will cancel the link task

%% @doc This function is called when the system startups and the link task is found backed in execution
-callback request_resume_link(PluginState::term(),ExH::term(),BH::term())->
    {resume,NewPluginState::term()} % will resume the link task
    |{wait,NewPluginState::term()} % this holon will wait for an external trigger before starting
    |{cancel,Reason::term()}.

%% @doc This is called by a Service Executor when a Service is set up, moved to Execution, and the first execution step can be done
-callback link_start(PluginState::term(),ExH::term(),BH::term())->
    {ok,NewPluginState::term()} % task will continue
    |{end_link,Reason::term()}. % the end_link callback will be triggered and the partner will be informed

%% @doc This is called by a Service Executor when a Service was in Execution and has been given the
%% go-ahead to resume by both the client and service BASE Holons
-callback link_resume(PluginState::term(),ExH::term(),BH::term())->
    {ok,NewPluginState::term()} % will continue normally
    |{end_link,Reason::term()}. % will trigger the end_link callback and inform the link partner

%% @doc Called when the partner BASE calls this BASE
-callback partner_call({Tag::term(),Payload::term()}, PluginState::term(),ExH::term(),BH::term())->
    {reply, Reply::term(), NewPluginState::term()} % will send a reply to the partner then continue normally
    |{reply_end, Reply::term(), Reason::term(), NewPluginState::term()} % will send a reply to the partner then end the link
    |{end_link, Reason::term(), NewPluginState::term()}. % will not send a reply to the partner then end the link

%% @doc Called when the partner BASE casts this BASE
-callback partner_signal({Tag::term(), Payload::term()}, PluginState::term(),ExH::term(),BH::term())->
    {ok, NewState::term()} % will continue normally
    |{end_link, Reason::term(), NewPluginState::term()}. % will trigger the end_link callback and inform the link partner

%% @doc Called when the Service Executor is ending the link task
-callback link_end(Reason::term(),PluginState::term(),ExH::term(),BH::term())->
    reflect | discard | archive.

%% @doc Called when the executor was subscribed to a state variable and the state variable is updated
-callback base_variable_update({Page::term(), Key::term(), Value::term()}, PluginState::term(), ExH::term(), BH::term())->
    {ok, NewPluginState::term()} % will continue normally
    |{end_link, Reason::term(), NewPluginState::term()}. % will trigger the end_link callback and inform the link partner

%%% ====================================================================================== %%%
%%%                                 EXTERNAL FUNCTIONS
%%% ====================================================================================== %%%

% This function will return the task shell for this link task.
-spec get_shell(ExH::agent_handle())-> Shell::term().
get_shell(ExH)->
    base_link_executor:get_shell(ExH).

% This function sends a message to the link partner and waits for a reply.
-spec call_partner(Tag::term(), Payload::term(), ExH::term()) -> Reply::term().
call_partner(Tag, Payload, ExH)->
    base_link_executor:call_partner(Tag, Payload, ExH).

% This function send a one directional message to the link partner and does
% not expect a reply.
-spec signal_partner(Tag::term(),Payload::term(),ExH::term()) -> ok.
signal_partner(Tag,Payload,ExH)->
    base_link_executor:signal_partner(Tag,Payload,ExH).

% This function allow you start the link task after it has previously been set to waiting.
% It will consequentially inform the link partner of the start trigger.
-spec start_link(ExH::agent_handle()) -> ok | {error, agent_is_dead}.
start_link(ExH)->
    base_link_executor:start_link(ExH).

% This function will return the BC of the link partner as a record.
-spec get_partner_bc(ExH::agent_handle())-> BC::term().
get_partner_bc(ExH)->
    base_link_executor:get_partner_bc(ExH).

% This function will either abort the link (if it has not started yet) or end the link (if it has started).
% Aborting the link will immediately discard the link task off the schedule.
% Ending the link will result in the end_link callback as well as for the link partner.
-spec end_link(ExH::term(), Reason::term()) -> ok.
end_link(ExecutorHandle, Reason)->
    base_link_executor:end_link(ExecutorHandle, Reason).



