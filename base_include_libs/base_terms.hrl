%%% ====================================================================================== %%%
%%% ====================================================================================== %%%
%%% @copyright (C) 2023, Cybarete Pty Ltd
%%% @doc
%%% The base_terms header file defines the records to be use in the base platform
%%% @end
%%% ====================================================================================== %%%
%%% ====================================================================================== %%%

%% @doc sector codes are often used to refer to a specific BASE sector
-export_type([sector_code/0, agent_handle/0, base_handle/0, base_task/0, task_shell/0]).


%% AGENT is a generalisation of Negotators, Executors, Reflectors, Analysers.
-record(agent_handle,{agent_pid::pid(),cookie::term(),plugin::term(),shell::term(),instance_handle::term(),link_handle::term()}).

%% @doc This record is for INTERNAL BASE use only. Its the functional token BASE processes use to access their own BASE.
-record(base_handle,{cm::pid(),cookie::binary(),'B'::pid(),'A'::pid(),'S'::pid(),'E'::pid(),sbb::pid()}).

-record(base_task, {task_shell::term(),meta::term(),data1=#{},data2=#{},data3=#{}}).

%% A shell is the outermost visible part of a task. Like it's packaging label that can be used to identify, sort, and control
-record(task_shell,{tsched::integer(),tstart::integer(),tend::integer(),id::term(),type::term(),class::task|link|guardian,stage::1|2|3}).

-type sector_code()::'B'|'A'|'S'|'E'.
-type agent_handle()::#agent_handle{}.
-type base_handle()::#base_handle{}.
-type base_task()::#base_task{}.
-type task_shell()::#task_shell{}.

%% @doc The following section contains common keys used in BASE data sectors.
%% try to stick to them as much as possible for inter plugin compatibility

%% @doc a flag set internally by a BASE that indicates it's ready to run.
-define(READY_KEY,<<"BASE_READY">>).
-define(BASE_PAGE,<<"BASE">>).
-define(INSTALL_DIR,<<"INSTALL_DIR">>).
-define(DISK_BASE,<<"DISK_BASE">>).
-define(HIVE_PAGE,<<"HIVE_ID">>).
-define(HIVE_ID_KEY,<<"HIVE_ID">>).
-define(INSTANCE_GUARDIAN,<<"INSTANCE_GUARDIAN">>).
-define(BASE_INFO,<<"BASE_INFO">>).

%% standard base signal tags
-define(CREATE_INSTANCE,<<"CREATE_INSTANCE">>).

%% @doc This tag is used for any signal catching EP that handles BASE discovery.
%% By default the base_directory ep in a type will catch this but in the BQueen
%% case the type_manager_ep will catch it
-define(BASE_DISCOVERY,<<"BASE_DISCOVERY">>).
%% @doc the first level of differentiation of a BASE is its taxonomy. Resource, Activity, Instance, Type and the BASE_TYPE_CODE
-record(base_taxonomy,{arti_class::{resource,type}|{activity,type}|{resource,instance}|{activity,instance},base_type_code::binary()}).

%% @doc a base_guardianship is metadata indicating his task is about managing an instance of a BASE
-record(link_promise,{shell::term(),
  bc::term(),
  cookie::term(),
  signature::term()}).

%% A record used to specify a query to look up shells in a sector
-record(task_shell_query,{field::tstart|tend|tsched|id|type,range::{number(),number()}|term()}).

%% BASE TASK META DATA:
%% @doc a base_contract is metadata to a task indicating this task is linked to another task aggreed on by a partner BASE
-record(base_contract,
{
  servant_promise::term(),
  master_promise::term(),
  requirements::term(),
  proposal::term(),
  state:: pending | negotiating | refused | rejected | accepted,
  my_role::client|service,
  master_bc::term(),
  servant_bc::term()
}).

%%%%%%%%%%%%%%%%%% BASE PLUGIN AGENTS AND DATA STRUCTS %%%%%%%%%%%%%%%%%%%%

%% @doc identity is the same as BC identity, purpose same as BC purpose, location tbd
-record(base_discover_query,{id::term(),responsibilities::list(),capabilities::list(),location::term(),name::term(),type::term()}).
-record(bhive_address,{hive_id::binary(),hive_pid::pid(),global_pid::pid()}).
-record(guardian_handle,{pid::pid(),token::binary(),instance_cm}).

%% @doc the record structure of a BASE BC as used by an erlang BASE
%% |---------------  BASE PURPOSE --------------|
-record(identity,{taxonomy::term(),name::binary(),id::binary()}).
-record(business_card,{addresses::term(),identity::term(),protocols::term(),responsibilities::term(), capabilities::term(), meta::term()}).
-record(base_startup_signal,{base_handle::term()}).
-record(base_type_directive,{command::term(),gaurdian_handle::term()}).
-record(base_error,{severity::term(), sector::term(), description ::term()}).
-record(base_warning,{severity::term(), sector::term(), description ::term()}).

