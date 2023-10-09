-module(bason).
-include("base_terms.hrl").

-export([json_to_map/1, map_to_json/1, base_record_from_map/2, base_term_to_map/1, read_json_file/1]).

read_json_file(FILE)->
  case file:read_file(FILE) of
    {error,Reason}->
      {error,Reason};
    {ok,JSON}->
      case try_decode_json(JSON) of
        {ok,MAP}->
          MAP;
        {ok,MAP,REST}->
          MAP;
        _E->
          {error,_E}
      end
  end.

try_decode_json(JSON_STR)->
  jsone:try_decode(JSON_STR).

json_to_map(JSON)->
  case try_decode_json(JSON) of
    {ok,MAP}->
      MAP;
    {ok,MAP,REST}->
      MAP;
    _E->
      {error,_E}
  end.


map_to_json(MAP)->
  jsone:try_encode(MAP).

base_record_from_map(<<"base_discovery_query">>,BDQ_MAP)->
  case maps:find(<<"id">>,BDQ_MAP) of
    {ok,ID}->
      ID;
    _->
      ID = null
  end,
  case maps:find(<<"name">>,BDQ_MAP) of
    {ok,NAME}->
      NAME;
    _->
      NAME = null
  end,
  case maps:find(<<"capabilities">>,BDQ_MAP) of
    {ok,CAPAS}->
      CAPAS;
    _->
      CAPAS = null
  end,
  case maps:find(<<"responsibilities">>,BDQ_MAP) of
    {ok,REPS}->
      REPS;
    _->
      REPS = null
  end,
  #base_discover_query{id = ID,name = NAME,capabilities = CAPAS,responsibilities = REPS};

base_record_from_map(<<"base_beam_plugin">>,BDQ_MAP)->
  {error,not_implemented}. %% TODO
%%  #base_beam_plugin{id = ID,name = NAME,capabilities = CAPAS,responsibilities = REPS}.

base_term_to_map(#business_card{identity = IDENT,capabilities = CAPAS, responsibilities = REPS, addresses = ADDR})->
  IDENTITY_MAP = base_term_to_map(IDENT),
  ADDRESSES_MAP = base_term_to_map(ADDR),
  #{<<"identity">>=>IDENTITY_MAP,<<"capabilities">>=>CAPAS,<<"responsibilities">>=>REPS, <<"addresses">>=>ADDRESSES_MAP};
base_term_to_map(#identity{name = NAME,id = ID,taxonomy = TAXONOMY})->
  ARTICLASS = TAXONOMY#base_taxonomy.arti_class,
  TYPECODE = TAXONOMY#base_taxonomy.base_type_code,
  #{<<"name">>=>NAME,<<"id">>=>ID,<<"taxonomy">>=>#{<<"arti_class">>=>ARTICLASS,<<"btype_code">>=>TYPECODE}};
base_term_to_map(_E)->
  <<"unknown_term">>.


