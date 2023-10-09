-module(base_task_ep).
-include("../base_terms.hrl").
-compile(export_all).


-callback init(Parameters::term(),BH::term())->
    ok | {error,Desc::term()}.

-callback stop(BH::term())->
    ok | {error,Desc::term()}.

-callback request_start(ExecutorHandle::term(),BH::term())->

    {start_task,NewState::term()}|{await_start,NewState::term()}|{cancel_task,Reason::term()} | {error,Desc::term()}.

-callback start_task_error(Reason::term(), ExecutorHandle::term(),BH::term())->
    ok.

%% @doc This function is called when a task is resumed after a BASE comes back online
-callback request_resume(ExecutorHandle::term(),BH::term())->
    {await_resume,NewState::term()}|{resume_task,NewState::term()}|{end_task, LB::term() ,NewState::term()} | {error,Desc::term()}.

-callback resume_task(TaskState::term(),ExecutorHandle::term(),BH::term())->
    {ok,NewState::binary()}|{end_task,LB::term(),NewState::term()} | {error,Desc::term()}.

-callback start_task(TaskState::term(),ExecutorHandle::term(),BH::term())->

    {ok,NewState::binary()}|{end_task, LB::term() ,NewState::term()} | {error,Desc::term()}.

-callback end_task(TaskState::term(),ExecutorHandle::term(),BH::term())->
    ok | error.

-callback handle_request(Tag::term(),Payload::term(),BH::term())->{reply,REPLY::term()}|ok.

-callback handle_signal(Tag::term(),Payload::term(),BH::term())->ok.


%%%===================================================================
%%%                     External Functions
%%%===================================================================

request_start(ExH,BH)->
    base_task_executor:request_start(ExH,BH).
request_resume(ExH,BH)->
    base_task_executor:request_resume(ExH,BH).
start_task(ExecutorHandle,BH)->
    base_task_executor:start_task(ExecutorHandle,BH).

resume_task(ExecutorHandle,BH)->
    base_task_executor:resume_task(ExecutorHandle,BH).

end_task(ExH, LB, BH)->
    base_task_executor:end_task(ExH, LB, BH).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
send_request(Shell,Request,BH)->
    base_task_executor:call(Shell,Request,BH).
send_signal(Shell,Payload,BH)->
    base_task_executor:cast(Shell,Payload,BH).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
call(ExecutorHandle,Request,BH)->
    base_task_executor:call(ExecutorHandle,Request,BH).

cast(ExPID,Payload,BH)->
    base_task_executor:cast(ExPID,Payload,BH).

get_shell(ExH)->
    base_task_executor:get_shell(ExH).

%% @doc if the task is not yet started (its requested to start) then get the data from schedule.
get_schedule_data(ExH,BH)->
    base_task_executor:get_data1(ExH,BH).

get_execution_data(ExH,BH)->
    base_task_executor:get_data2(ExH,BH).

write_data2(Key,Data,Shell,BH)->
    base_task_executor:write_data2(Key,Data,Shell,BH).



