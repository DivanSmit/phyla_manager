-module(base_business_card).
-include("base_terms.hrl").

%% TODO Consider adding spawnpoint to the identity for if the base goes to a hive where someone has the same ID as it
%% TODO taxonomy should be something like : {<<"car_door">>,resource,instance}
%% TODO for now its just {<<"BASE_TYPE">>,resource|activity,instance|type}
%% API
-compile(export_all).

%A business card has the following structure:
% |=========================================
% |identity: {name: <<"some_binary">>, id:<<"somebinary">>}
% |address: [{type: gen_server/ipv4/web_socket/rest, ip:/pid:/url:}]}
% |protocols: [{commsxml,[json/erl_gen_serv/erl_tuple
% |---------------------------------------
% |purpose: responsibilities, capabilities
% |=========================================

record_to_map(#business_card{addresses = Addresses,identity = Identity, responsibilities = Reses, capabilities = Capas, meta = Meta})->
  #{<<"addresses">>=> Addresses,
    <<"identity">>=> Identity,
    <<"capabilities">> => Capas,
    <<"responsibilities">>=>Reses,
    <<"meta">>=>Meta}.

map_to_record(#{<<"addresses">> := Addresses,
  <<"identity">>:= IdentityMap,
  <<"capabilities">> := Capas,
  <<"responsibilities">>:=Reses,
  <<"meta">>:=Meta})->
  Identity = identity_map_to_record(IdentityMap),
  #business_card{addresses = Addresses,identity = Identity, responsibilities = Reses, capabilities = Capas, meta = Meta}.

identity_map_to_record(#{<<"id">>:=ID,<<"taxonomy">>:=TAXMAP,<<"name">>:=Name})->
  TAX = taxonomy_map_to_record(TAXMAP),
  #identity{id = ID,taxonomy = TAX,name = Name}.

taxonomy_map_to_record(#{<<"base_type">>:=BT,<<"arti_class">>:=AC})->
  case AC of
    <<"resource-instance">>->
      #base_taxonomy{arti_class = {resource,instance},base_type_code = BT};
    <<"resource-type">>->
      #base_taxonomy{arti_class = {resource,type},base_type_code  = BT};
    <<"activity-instance">>->
      #base_taxonomy{arti_class = {activity,instance},base_type_code  = BT};
    <<"activity-type">>->
      #base_taxonomy{arti_class = {activity,type},base_type_code  = BT}
  end.

create_identity(Name,ID)->
   #{<<"name">> => Name, <<"id">> => ID}.

create_ipv4_address(IP,Port) when is_list(IP) ->
  create_ipv4_address(list_to_binary(IP),Port);
create_ipv4_address(ADR,Port) ->
  #{<<"address">> => ADR,<<"port">> => Port}.

validate_addresses(BC)->
  {HasAddress,_Address} = maps:find(addresses,BC),
  HasAddress.

create_bhive_address(PID,GPID,HIVE_ID)->
  #bhive_address{global_pid = GPID,hive_id = HIVE_ID,hive_pid = PID}.

address_type_valid(AdT)->
  case AdT of
    base->
      true;
    erl_pid->
      true;
    ipv4->
      true;
    web_socket->
      true;
    url->
      true;
    _->
      false
  end.


add_bhive_address(HiveAddress,BC) when is_record(HiveAddress,bhive_address)->
  Addresses = BC#business_card.addresses,
  NewAddresses = maps:put(<<"bhive_address">>,HiveAddress,Addresses),
  BC#business_card{addresses = NewAddresses}.

address_value_valid(AddrType,AddrVal)->
  case AddrType of
    base->
      is_pid(AddrVal);
    ipv4->
      is_list(AddrVal);
    web_socket->
      is_list(AddrVal);
    url->
      is_list(AddrVal)
  end.

%% TODO what whas my thinking behind this? -- 2022-08-31 I still don't know
get_bhive_id_tuple(BC)->
  ID = get_id(BC),
  Name = get_name(BC),
  Taxonomy = get_taxonomy(BC),
  {Taxonomy,ID,Name}.

add_responsibility(R,BC)->
   BC#business_card{responsibilities = [R,BC#business_card.responsibilities]}.

add_capability(R,BC)->
  BC#business_card{capabilities = [R,BC#business_card.capabilities]}.


get_taxonomy(#business_card{identity = ID})->
  ID#identity.taxonomy.

get_bhive_address(BC)->
  Addrs = BC#business_card.addresses,
  case maps:find(<<"bhive_address">>,Addrs) of
    {ok,BhiveAddr}->
      BhiveAddr;
    _->
      no_entry
  end.

get_id(#business_card{identity = ID})->
  ID#identity.id.

get_name(#business_card{identity = ID})->
  ID#identity.name.

get_bhive_pid(BC)->
  case base_business_card:get_bhive_address(BC) of
    no_entry->
      {error,no_entry};
    HiveAddress->
      HiveAddress#bhive_address.hive_pid
  end.

get_identity(BC)->
  BC#business_card.identity.

get_global_base_pid(BC)->
  case base_business_card:get_bhive_address(BC) of
    no_entry->
      {error,no_entry};
    HiveAddress->
      HiveAddress#bhive_address.global_pid
  end.

get_responsibilities(BC)->
 BC#business_card.responsibilities.

get_capabilities(BC)->
  BC#business_card.capabilities.

%% @doc Checks if any of the given capabilities are listed in the given BC
has_capabilities(CAPS,BC) when is_list(CAPS)->
  BC_CAPS = get_capabilities(BC),
  lists:foldl(fun(FILTER_CAP,Acc)->
    case lists:member(FILTER_CAP,BC_CAPS) of
      true->
        true;
      _->
        Acc
    end
              end,false,CAPS);

%% @doc matches to this func if given capabilities was singular not list
has_capabilities(CAP,BC) when is_binary(CAP)->
  BC_CAPS = get_capabilities(BC),
  lists:member(CAP,BC_CAPS);
has_capabilities(_CAP,_BC)->
  false.

%% @doc Checks if any of the given capabilities are listed in the given BC
has_responsibilities(REPS,BC) when is_list(REPS)->
  BC_REPS = get_responsibilities(BC),
  lists:foldl(fun(FILTER_REP,Acc)->
    case lists:member(FILTER_REP,BC_REPS) of
      true->
        true;
      _->
        Acc
    end
              end,false,REPS);

%% @doc matches to this func if given capabilities was singular not list
has_responsibilities(RESP,BC) when is_binary(RESP)->
  BC_REPS = get_responsibilities(BC),
  lists:member(RESP,BC_REPS);
has_responsibilities(_,_BC)->
  false.

has_id(ID,BC) when is_binary(ID)->
  case get_id(BC) of
    ID->
      true;
    _->
      false
  end;
has_id(_ID,_BC)->
  false.
has_name(ID,BC) when is_binary(ID)->
  case get_name(BC) of
    ID->
      true;
    _->
      false
  end;
has_name(_,_BC)->
  false.

%% @doc a function that checks if a BC matches a BASE query
discovery_query_match( #base_discover_query{name = all},BC)->
  true;
discovery_query_match( #base_discover_query{capabilities = Caps,id = ID, name = NAME},BC)->
  MATCHLIST = [has_id(ID,BC),has_name(NAME,BC),has_capabilities(Caps,BC)],
  case MATCHLIST of
    [false,false,false]->
      false;
    _->
      true
  end.
