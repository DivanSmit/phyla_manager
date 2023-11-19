%%% ====================================================================================== %%%
%%% ====================================================================================== %%%
%%% @copyright (C) 2023, Cybarete Pty Ltd
%%% @doc
%%% The base_recipe module defines the functions for handling a base recipe
%%% @end
%%% ====================================================================================== %%%
%%% ====================================================================================== %%%

-module(base_recipe).
-export([get_disk_base/1, get_taxonomy/1, get_cookie/1, get_bc/1, from_file/1, get_type_sn/1, get_plugins/1]).
-include("base_terms.hrl").

%%% ====================================================================================== %%%
%%%                                 EXTERNAL FUNCTIONS
%%% ====================================================================================== %%%

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

get_type_sn(BR)->
  ID = base_business_card:get_id(get_bc(BR)).