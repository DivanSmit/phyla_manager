%%% ====================================================================================== %%%
%%% ====================================================================================== %%%
%%% @copyright (C) 2023, Cybarete Pty Ltd
%%% @doc
%%% The bhive module defines the api for base discovery.
%%% @end
%%% ====================================================================================== %%%
%%% ====================================================================================== %%%

-module(bhive).
-include("base_terms.hrl").
-export([discover_bases/2, discover_global_bases/2, get_bqueen_bc/0, get_hive_dir/1, get_hive_info/0, get_disk_bases_dir/0, find_base_with_id/2, find_base_with_name/2, find_instances_of_type/2]).

%%% ====================================================================================== %%%
%%%                                 EXTERNAL FUNCTIONS
%%% ====================================================================================== %%%

%% @doc find services in the hive for the given service tag
discover_bases(DR = #base_discover_query{},BH)->
  base_signal:emit_request(get_bqueen_bc(),<<"BHIVE_BASE_DISCOVERY">>,DR,BH).

%% @doc find bases in any connected bhives for the given service tag
discover_global_bases(DR = #base_discover_query{},BH)->
  base_signal:emit_request(get_bqueen_bc(),?BASE_DISCOVERY,DR,BH).

find_base_with_id(ID,BH)->
  BDQ = #base_discover_query{id = ID},
  case discover_bases(BDQ,BH) of
    [BC|NO]->
      BC;
    _->
      no_base
  end.

find_base_with_name(ID,BH)->
  BDQ = #base_discover_query{id = ID},
  discover_bases(BDQ,BH).

find_instances_of_type(TYPECODE,BH)->
  BDQ = #base_discover_query{type = TYPECODE},
  discover_bases(BDQ,BH).

get_bqueen_bc()->
  gen_server:call(bhive, get_bqueen_bc).

get_hive_info()->
  gen_server:call(bhive,get_bhive_info).

get_hive_dir(#{<<"root_dir">>:=Root})->
  binary_to_list(Root).

get_disk_bases_dir()->
  gen_server:call(bhive,get_disk_bases_dir).