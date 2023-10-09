-module(base_guardian_sp).
-compile(export_all).
-include("../base_terms.hrl").

%%%===================================================================
%%%                     Callback Functions
%%%===================================================================

%% @doc this function is called when the plugin is first initialised.
-callback init(Pars::term(),BH::term())->
  ok | {error,Desc::term()}.

%% @doc this function is called when the plugin is removed from the system.
-callback stop(BH::term())->
  ok  | {error,Desc::term()}.

%% @doc this callback is not mandatory, but rather aids as a plugin template.
-callback instance_spawn_request(Pars::term(),BH::term())->
  ok|{error,Desc::term()}.

%% @doc this callback is not mandatory, but rather aids as a plugin template.
-callback generate_instance_recipe(Pars::term(),BH::term())->
  {ok,Recipe::term()} | {error,Desc::term()}.

%%%===================================================================
%%%                     Built-in Functions
%%%===================================================================

%% @doc this function is used to schedule the creation of a BASE instance.
-spec schedule_instance_guardian(Tsched::integer(),Recipe::map(),Data1::term(),BH::base_handle())-> ok.
schedule_instance_guardian(Tsched,Recipe,Data1,BH)->
  base_guardian:schedule_instance_guardian(Tsched,Recipe,Data1,BH).