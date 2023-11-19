%%% ====================================================================================== %%%
%%% ====================================================================================== %%%
%%% @copyright (C) 2023, Cybarete Pty Ltd
%%% @doc
%%% The reflection plugin behaviour module defines the callbacks for the
%%% reflection and provides external functions to use in a custom reflection
%%% plugin module.
%%% @end
%%% ====================================================================================== %%%
%%% ====================================================================================== %%%

-module(base_task_rp).
-export([get_schedule_data/2, get_execution_data/2, get_reflection_data/2, write_reflection_data/3, get_shell/1]).
-include("../base_terms.hrl").

%%% ====================================================================================== %%%
%%%                                 CALLBACK FUNCTIONS
%%% ====================================================================================== %%%

%% @doc this function is called when the plugin is first initialised.
-callback init(Pars::term(),BH::term())->
    ok.

%% @doc this function is called when the plugin is removed from the system.
-callback stop(BH::term())->
    ok.

%% @doc this function is called when an executing task has ended with an option for
%% reflection.
-callback request_reflection(ReflectorHandle::term(),BH::term())->
    {start_reflection, PluginState::term()}
    |cancel_reflection.

%% @doc this function is called when the reflection has started.
-callback start_reflection(PluginState::term(), ReflectorHandle::term(),BH::term())->
    ok.

%%% ====================================================================================== %%%
%%%                                 EXTERNAL FUNCTIONS
%%% ====================================================================================== %%%

get_shell(ReflectorHandle)->
    reflector:get_shell(ReflectorHandle).

write_reflection_data(Data3, ReflectorHandle, BH)->
    reflector:write_data3(Data3, ReflectorHandle, BH).

get_schedule_data(ReflectorHandle,BH)->
    reflector:get_data1(ReflectorHandle, BH).

get_execution_data(ReflectorHandle,BH)->
    reflector:get_data2(ReflectorHandle, BH).

get_reflection_data(ReflectorHandle,BH)->
    reflector:get_data3(ReflectorHandle, BH).