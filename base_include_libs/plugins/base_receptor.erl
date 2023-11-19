%%% ====================================================================================== %%%
%%% ====================================================================================== %%%
%%% @copyright (C) 2023, Cybarete Pty Ltd
%%% @doc
%%% The receptor behaviour module defines the callbacks for the
%%% receptor plugin.
%%% @end
%%% ====================================================================================== %%%
%%% ====================================================================================== %%%

-module(base_receptor).
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

%% @doc this function is called when the base instance receives an external signal with a matching tag.
-callback handle_signal(Tag::binary(),Signal::term(),BH::term())->
  ok.

%% @doc this function is called when the instance receives an external request with a matching tag.
-callback handle_request(Tag::binary(),Signal::term(),From::term(),BH::term())->
  ok
  |{reply,Reply::term()}
  |{error,Reason::term()}.

%%% ====================================================================================== %%%
%%%                                 EXTERNAL FUNCTIONS
%%% ====================================================================================== %%%

