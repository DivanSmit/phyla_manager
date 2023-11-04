-module(http_session_gen_server).
-behaviour(gen_server).

-include("../../../base_include_libs/base_terms.hrl").
-define(INTERFACE_SERVER_TASK,<<"HTTP_INTERFACE_SERVER">>).
-define(HTTP_CONNECTOR_PAGE,<<"HTTP_CONNECTOR_PAGE">>).
-record(http_session,{user_details::term(),session_pid::pid(),last_active::number()}).
-record(user_request,{session_id::term(),content::term(), request_pid::pid()}).
-record(user_reply,{session_id::term(),content::term()}).
-record(http_state_management,{base_handle::term(),
  server_dir::term(),
  port::term(),
  task_executor_pid::term()}).

-export([init/1, handle_call/3, handle_cast/2, start_server/4, fetchdata/3]).

start_server(ServerDir,Port,ExecutorPID,BH)->
  gen_server:start_link(?MODULE,[#http_state_management{server_dir = ServerDir, port = Port, task_executor_pid =  ExecutorPID,base_handle = BH}],[]).

init([#http_state_management{server_dir = ServerDir, port = Port, task_executor_pid =  ExecutorPID,base_handle = BH}]) ->
  GenServerPID = self(),
  HttpServerPID = spawn_link(fun()-> start_http_server(ServerDir,Port,GenServerPID) end),
  State = #http_state_management{server_dir = ServerDir, port = Port, task_executor_pid =  ExecutorPID, base_handle = BH},
  {ok, State}.

handle_call({http_request,MSG}, From, State) ->
  io:format("HTTP request recieved from: ~p~n",[MSG]),
  BH = State#http_state_management.base_handle,
  Query = maps:get(<<"queryParam">>,MSG),
  Tag = maps:get(<<"tag">>,MSG),
  Reply1 = case Query of
             <<"INFO">>->

               case bhive:discover_bases(#base_discover_query{capabilities = Tag},BH) of
                 []->
                   io:format("No INSTANCE found~n"),
                   {ok, []};
                 List->
                   ListResult = lists:foldl(fun(Elem, Acc)->
                     Reply = base_signal:emit_request(Elem,Query,Query,BH),
                     [Reply|Acc]
                                            end, [],List),

                   {ok, ListResult}
               end;

             <<"SPAWN">> ->
               Name = maps:get(<<"name">>, MSG),
               ID = rand:uniform(1000),
               Init = #{<<"name">>=>Name,<<"id">>=><<ID>>},
               TargetBC = bhive:discover_bases(#base_discover_query{capabilities = Tag}, BH),
               case TargetBC of
                 [] ->
                   {error, no_instances};
                 _ ->
                   ReplyOfSpawn = base_signal:emit_request(TargetBC, Tag, Init, BH),
                   {ok, ReplyOfSpawn}
               end;
             _ -> {error, no_match}
           end,
  gen_server:reply(From,Reply1),
  io:format("Reply: ~p~n",[Reply1]),
  {noreply,State};

handle_call(Request, From, State) ->
  erlang:error(not_implemented).

handle_cast(Request, State) ->
  erlang:error(not_implemented).

%% ============================================================================================%%
%%                                    INETS SERVER SETUP
%% ============================================================================================%%

start_http_server(SERVER_DIR,PORT,EXPID)->
  inets:start(),
  io:format("start_http_server-------------------------------~n"),
  {ok, Pid} = inets:start(httpd, [{port, PORT},
    {modules, [
      mod_alias,
      mod_actions,
      mod_esi,
      mod_dir,
      mod_log,
      mod_disk_log
    ]},
    {server_name,pid_to_list(EXPID)},
    {server_root,SERVER_DIR},
    {script_alias, {"/erl/", SERVER_DIR}},
    {erl_script_alias, {"/erl", [http_session_gen_server]}},
    {document_root,SERVER_DIR}, {bind_address, any},{error_log, "./errors.log"}]),
  io:format("~n [INFO] HTTP SERVER STARTED ON PORT ~p ~n",[PORT]).

%% ============================================================================================%%
%%                                    ROUTING
%% ============================================================================================%%

fetchdata(SessionID, ENV, Input) ->
  Request = httpd:parse_query(Input),
  ExHPID = get_exh_pid(ENV),
  case extract_message(Request) of
    {ok,MSG}->
      relay_to_server(ExHPID,MSG,ENV,SessionID);
    {error,_E}->
      io:format("~n [ERROR] Extracting the HTTP Request: ~p ~n",[_E]),
      ok
  end.

%% ============================================================================================%%
%%                                    INTERNAL FUNCTIONS
%% ============================================================================================%%

get_exh_pid(ENV)->
  PID_STR = proplists:get_value(server_name,ENV),
  list_to_pid(PID_STR).

relay_to_server(ExHPID,MSG,ENV,SessionID)->
  Resp = case  gen_server:call(ExHPID,{http_request,MSG}) of
           {ok,Content}->
             #{<<"subject">>=><<"ok">>,<<"content">>=>Content};
           {error,Desc}->
             #{<<"subject">>=><<"error">>,<<"reason">>=>Desc};
           _E->
             #{<<"subject">>=><<"error">>,<<"reason">>=>_E}
         end,
  deliver(Resp,ENV,SessionID).

extract_message(Request)->
  case lists:keyfind("MSG",1,Request) of
    {"MSG",Content}->
      BIN = list_to_binary(Content),
      case bason:json_to_map(BIN) of
        {error,MSG}->
          {error,<<"bad_json">>};
        MSG->
          {ok,MSG}
      end;
    _E->
      {error,<<"bad_request">>}
  end.

deliver(RESPONSE,ENV,SessionID)->
  case bason:map_to_json(RESPONSE) of
    {ok,JSON}->
      JSON;
    _->
      JSON = <<"{'code':'json_error'}">>
  end,
  Headers = "Content-Type: application/json \r\n Access-Control-Allow-Origin: * \r\n\r\n",
  mod_esi:deliver(SessionID, Headers),  %Headers must be a string.
  mod_esi:deliver(SessionID, [JSON]).