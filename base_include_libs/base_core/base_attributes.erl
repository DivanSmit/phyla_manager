-module(base_attributes).
-include("../base_terms.hrl").

%% Exported functions
-export([backup/1, merge_page/3, wipe_page/2, write_pages/2, read_pages/2, write/4, read/3, merge/4, wipe/3, take/3, read_page/2, write_page/3]).

%%--------------------------------------------------------------------
%% Function: write/4
%% @doc Writes an attribute to a specific attributes page.
%%
%% This function writes an attribute with the given Key and Value to the Page specified. The BH parameter is a base handle that identifies the backend where the attribute will be written.
%% @spec write(Page, Key, Value, BH) -> ok
%% Page = binary()
%% Key = binary()
%% Value = term()
%% BH = base_handle()
%%
%% @param Page The binary representing the specific attributes page to write to.
%% @param Key The binary key for the attribute to write.
%% @param Value The value to write for the attribute.
%% @param BH The base handle that identifies the backend where the attribute will be written.
%%
%% @returns Returns ok if the write operation is successful, otherwise an error tuple.
%% @index
%%--------------------------------------------------------------------
-spec write(Page :: binary(), Key :: binary(), Value :: term(), BH :: base_handle()) -> ok.
write(Page, Key, Value, BH) ->
  a:write(Page, Key, Value, BH).

%%--------------------------------------------------------------------
%% Function: write_page/3
%% @doc Writes an entire page to attributes. This MUST be a key-value map.
%%
%% This function writes an entire Data map to the specified Page. The BH parameter is a base handle that identifies the backend where the attribute will be written.
%%
%% @spec write_page(Page, Data, BH) -> ok()
%%
%% @param Page The binary representing the specific attributes page to write to.
%% @param Data The key-value map to write to the page.
%% @param BH The base handle that identifies the backend where the attribute will be written.
%%
%% @returns Returns ok if the write operation is successful, otherwise an error tuple.
%%
%%--------------------------------------------------------------------
-spec write_page(Page::binary(),Data::term(),BH::base_handle())-> ok.
write_page(Page,Data,BH)->
  a:write_page(Page,Data,BH).

%%--------------------------------------------------------------------
%% @doc read an attribute from a specific page
-spec read(Page::binary(),Key::binary(),BH::base_handle())-> Attribute::term()|no_entry.
read(Page,Key,BH)->
  a:read(Page,Key,BH).

%% @doc try to merge an attribute that is a map with another map.
%% Useful for updating map type attributes without having to read, put write.
-spec merge(Page::binary(),Key::binary(),Map::map(),BH::base_handle())-> ok.
merge(Page,Key,Map,BH)->
  a:merge(Page,Key,Map,BH).

%% @doc try to merge an attribute page with another map.
-spec merge_page(Page::binary(),Data::term(),BH::base_handle())-> ok.
merge_page(Page,Data,BH)->
  a:merge_page(Page,Data,BH).

%% @doc remove a page from attributes. This removes all entries along with the page.
-spec wipe_page(Page::binary(),BH::base_handle())-> ok.
wipe_page(Page,BH)->
  a:wipe_page(Page,BH).

%% @doc remove an attribute from a Page with Key
-spec wipe(Page::binary(),Key::binary(),BH::base_handle())-> ok.
wipe(Page,Key,BH)->
  a:wipe(Page,Key,BH).

%% @doc Get an attribute from a Page with Key and wipe it
-spec take(Page::binary(),Key::binary(),BH::base_handle())-> Attribute::term()|no_entry.
take(Page,Key,BH)->
  a:take(Page,Key,BH).

%% @doc Write multiple pages given as a map of maps.
-spec write_pages(Pages::map(),BH::base_handle())-> ok.
write_pages(Pages,BH)->
  a:write_pages(Pages,BH).

%% @doc Read multiple pages
-spec read_pages(PageNames::list(),BH::base_handle())-> Pages::list().
read_pages(PageNames,BH)->
  a:read_pages(PageNames,BH).

%% @doc Read an attribute page
-spec read_page(PageName::binary(),BH::base_handle())-> Page::map()|no_entry.
read_page(PageName,BH)->
  a:read_page(PageName,BH).
%% @doc Backup the attributes sector. Only used for a BASE instance wanting to save A to its type in case of a restart.
-spec backup(BH::base_handle())-> ok.
backup(BH)->
  a:backup(BH).





