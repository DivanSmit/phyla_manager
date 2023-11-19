%%% ====================================================================================== %%%
%%% ====================================================================================== %%%
%%% @copyright (C) 2023, Cybarete Pty Ltd
%%% @doc
%%% The base_variables module defines the api for the state blackboard
%%% of an BASE agent.
%%% @end
%%% ====================================================================================== %%%
%%% ====================================================================================== %%%

-module(base_variables).
-include("../base_terms.hrl").

-export([ wipe_page/2,
  subscribe/4, unsubscribe/4,
  write/4, read/3, wipe/3, read_page/2, write_page/3]).

%%% ====================================================================================== %%%
%%%                                 EXTERNAL FUNCTIONS
%%% ====================================================================================== %%%

%% @doc write a variable to the state sector
-spec write(Page::binary(),Key::binary(),Value::term(),BH::base_handle())-> ok.
write(Page,Key,Value,BH)->
  sbb:write(Page,Key,Value,BH).

%% @doc write a page to the state sector.
%% the data must be a key-value map
-spec write_page(PageName::binary(),Data::map(),BH::base_handle())-> ok.
write_page(PageName,P2,BH)->
  sbb:write_page(PageName,P2,BH).

%% @doc read a variable from the state sector
-spec read(Page::binary(),Key::binary(),BH::base_handle())-> Value::term() | no_entry.
read(Page,Key,BH)->
  sbb:read(Page,Key,BH).

%% @doc read a variable page from the state sector
-spec read_page(PageName::binary(),BH::base_handle())-> Page::map() | no_entry.
read_page(PageName,BH)->
  sbb:read_page(PageName,BH).

%% @doc delete a variable from the state sector
-spec wipe(Page::binary(),Key::binary(),BH::base_handle())-> ok.
wipe(Page,Key,BH)->
  sbb:wipe(Page,Key,BH).

%% @doc delete a page from the state sector
-spec wipe_page(Page::binary(),BH::base_handle())-> ok.
wipe_page(Page,BH)->
  sbb:wipe_page(Page,BH).

%% @doc subscribe to a variable on the state sector.
-spec subscribe(Page::binary(),Key::binary(),Subscriber::pid(),BH::base_handle())-> Value::term().
subscribe(Page,Key,Subscriber,BH)->
  sbb:add_var_listener(Page,Key,Subscriber,BH).

%% @doc unsubscribe from a variable on the state sector.
-spec unsubscribe(Page::binary(),Key::binary(),Subscriber::pid(),BH::base_handle())-> ok.
unsubscribe(Page,Key,Subscriber,BH)->
  sbb:remove_var_listener(Page,Key,Subscriber,BH).
