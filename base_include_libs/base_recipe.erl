-module(base_recipe).
-export([get_disk_base/1, get_taxonomy/1, get_cookie/1, get_bc/1, from_file/1, get_type_sn/1, get_plugins/1]).
-include("base_terms.hrl").

get_disk_base(#{<<"disk_base">>:=DISK_DIR})->
  DISK_DIR;
get_disk_base(_)->
  {error,bad_brecipe}.

get_taxonomy(#{<<"bc">>:=BC})->
  BC2 = base_business_card:map_to_record(BC),
  TAX = base_business_card:get_taxonomy(BC2).

get_cookie(#{<<"cookie">>:=C})->
  C.
get_bc(#{<<"bc">>:=BC})->
  base_business_card:map_to_record(BC);
get_bc(E)->
  {error,{bad_bc,E}}.

get_plugins(#{<<"plugins">>:=PLUGS})->
  PLUGS.

from_file(FILE_NAME)->
  case file:read_file(FILE_NAME) of
    {error,Reason}->
      {error,Reason};
    {ok,FILE}->
      {ok,BRECIPE} = bason:json_to_map(FILE),
      case verify_brecipe(BRECIPE) of
        ok->
          BRECIPE;
        E->
          {error,E}
      end
  end.

verify_brecipe(BR)->
  ok.

%% TODO THIS SHOULD BE DESIGNED FURTHER
get_type_sn(BR)->
  ID = base_business_card:get_id(get_bc(BR)).


%%%% RECIPE STRUCTURE

%%  {
%%  "plugins": [{"library":"lib", "name":"default","parameters":[]],
%%  "bc":{
%%  "identity":
%%  {
%%    "id":"01",
%%    "name":"BQUEEN",
%%    "taxonomy":{"arti_class":"resource-type","base_type":"bhive_queen"}
%%  },
%%  "capabilities":["base_spawn","service_discovery"],
%%  "responsibilities":["hive_justice"],
%%  "addresses":{},
%%  "meta":{}
%%
%%  },
%%  "disk_base":"D:/BASE_CORE_0.6/BHIVE/BQUEEN/BASE",
%%  "cookie":"BB"
%% }

%% PLUGIN:: {"plugin_name":"...", "plugin_dir":"default"|"...","parameters":[],"plugin_type":"beam"|"lua","task_tags":["..."]}