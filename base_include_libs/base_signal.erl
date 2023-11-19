%%% ====================================================================================== %%%
%%% ====================================================================================== %%%
%%% @copyright (C) 2023, Cybarete Pty Ltd
%%% @doc
%%% The base_signal module defines the api sending and handling signals
%%% and requests.
%%% @end
%%% ====================================================================================== %%%
%%% ====================================================================================== %%%

-module(base_signal).
-include("base_terms.hrl").
-export([emit_request/4, emit_signal/4, emit_hive_signal/3, reply/3]).

%%% ====================================================================================== %%%
%%%                                 EXTERNAL FUNCTIONS
%%% ====================================================================================== %%%

emit_request(TargetBCs, Tag,Payload,BH)->
  base_receptor_internal:emit_request(TargetBCs, Tag,Payload,BH).

emit_signal(TargetBCs, Tag,Payload,BH) ->
  base_receptor_internal:emit_signal(TargetBCs, Tag,Payload,BH).

emit_hive_signal(Tag,Payload,BH) ->
  base_receptor_internal:emit_hive_signal(Tag,Payload,BH).

reply(FROM,REPLY,BH)->
  base_receptor_internal:reply(FROM,REPLY,BH).