%%% ====================================================================================== %%%
%%% ====================================================================================== %%%
%%% @copyright (C) 2023, Cybarete Pty Ltd
%%% @doc
%%% The base_attributes module defines the api for the attribute sector
%%% of an BASE agent.
%%% @end
%%% ====================================================================================== %%%
%%% ====================================================================================== %%%

-module(base_attributes).
-include("../base_terms.hrl").
-export([backup/1, wipe_page/2, write/4, read/3, wipe/3, read_page/2, write_page/3]).

%%% ====================================================================================== %%%
%%%                                 EXTERNAL FUNCTIONS
%%% ====================================================================================== %%%

%% @doc write a variable to the attribute sector.
%% provide the page and variable
-spec write(Page :: binary(), Key :: binary(), Value :: term(), BH :: base_handle()) -> ok.
write(Page, Key, Value, BH) ->
  a:write(Page, Key, Value, BH).

%% @doc write a entire page to the attribute sector
%% provide the entire page map
-spec write_page(Page::binary(),Data::map(),BH::base_handle())-> ok.
write_page(Page,Data,BH)->
  a:write_page(Page,Data,BH).

%% @doc read a variable from the attribute sector.
%% provide the page and variable
-spec read(Page::binary(),Key::binary(),BH::base_handle())-> Attribute::term() | no_entry.
read(Page,Key,BH)->
  a:read(Page,Key,BH).

%% @doc read a page from the attribute sector
%% provide the page name
-spec read_page(PageName::binary(),BH::base_handle())-> Page::map() | no_entry.
read_page(PageName,BH)->
  a:read_page(PageName,BH).

%% @doc delete a variable from the attribute sector
%% provide the page and variable name
-spec wipe(Page::binary(),Key::binary(),BH::base_handle())-> ok.
wipe(Page,Key,BH)->
  a:wipe(Page,Key,BH).

%% @doc delete a page from the attribute sector
%% provide the page name
-spec wipe_page(Page::binary(),BH::base_handle())-> ok.
wipe_page(Page,BH)->
  a:wipe_page(Page,BH).

-spec backup(BH::base_handle())-> ok.
backup(BH)->
  a:backup(BH).