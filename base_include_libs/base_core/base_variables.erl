-module(base_variables).
-include("../base_terms.hrl").

%% API
-export([merge_page/3, wipe_page/2, write_pages/2, read_pages/2,
  subscribe/4, unsubscribe/4,
  write/4, read/3, merge/4, wipe/3, take/3, read_page/2, write_page/3]).
%% @doc write an attribute to a specific attributes page.
-spec write(Page::binary(),Key::binary(),Value::term(),BH::base_handle())-> ok.
write(Page,Key,Value,BH)->
  sbb:write(Page,Key,Value,BH).

%% @doc read an attribute from a specific page
-spec read(Page::binary(),Key::binary(),BH::base_handle())-> Attribute::term()|no_entry.
read(Page,Key,BH)->
  sbb:read(Page,Key,BH).

%% @doc try to merge an attribute that is a map with another map.
%% Useful for updating map type attributes without having to read, put write.
-spec merge(Page::binary(),Key::binary(),Map::map(),BH::base_handle())-> ok.
merge(Page,Key,Map,BH)->
  sbb:merge(Page,Key,Map,BH).

%% @doc try to merge an attribute page with another map.
-spec merge_page(Page::binary(),Data::map(),BH::base_handle())-> ok.
merge_page(Page,P2,BH)->
  sbb:merge_page(Page,P2,BH).

%% @doc remove a page from attributes. This removes all entries along with the page.
-spec wipe_page(Page::binary(),BH::base_handle())-> ok.
wipe_page(Page,BH)->
  sbb:wipe_page(Page,BH).

%% @doc remove an attribute from a Page with Key
-spec wipe(Page::binary(),Key::binary(),BH::base_handle())-> ok.
wipe(Page,Key,BH)->
  sbb:wipe(Page,Key,BH).

%% @doc Get an attribute from a Page with Key and wipe it
-spec take(Page::binary(),Key::binary(),BH::base_handle())-> Attribute::term()|no_entry.
take(Page,Key,BH)->
  sbb:take(Page,Key,BH).

%% @doc write an entire page to state blackboard. This MUST be a key-value map.
-spec write_page(PageName::binary(),Data::map(),BH::base_handle())-> ok.
write_page(PageName,P2,BH)->
  sbb:write_page(PageName,P2,BH).

%% @doc Write multiple pages given as a map of maps.
-spec write_pages(Pages::map(),BH::base_handle())-> ok.
write_pages(Pages,BH)->
  sbb:write_pages(Pages,BH).

%% @doc Read multiple pages
-spec read_pages(PageNames::list(),BH::base_handle())-> Pages::list().
read_pages(PageNames,BH)->
  sbb:read_pages(PageNames,BH).

%% @doc Read a variable page
-spec read_page(PageName::binary(),BH::base_handle())-> Page::map()|no_entry.
read_page(PageName,BH)->
  sbb:read_page(PageName,BH).

%% @doc Subscribe to a variable on a Page with either a module, PID, or AgentHandle.
%% The module needs to export var_update(Page,Key,Value,BH)
%% the process with PID will receive a message of #base_var_update{}
%% The agent will call the handle_message() callback of the plugin for it.
-spec subscribe(Page::binary(),Key::binary(),Subscriber::pid()|module()|agent_handle(),BH::base_handle())-> CurrentValue::term().
subscribe(Page,Key,Subscriber,BH)->
  sbb:add_var_listener(Page,Key,Subscriber,BH).

%% @doc unsubscribe from a variable on the SBB
-spec unsubscribe(Page::binary(),Key::binary(),Subscriber::pid()|module()|agent_handle(),BH::base_handle())-> ok.
unsubscribe(Page,Key,Subscriber,BH)->
  sbb:remove_var_listener(Page,Key,Subscriber,BH).
