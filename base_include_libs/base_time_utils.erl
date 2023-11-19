%%% ====================================================================================== %%%
%%% ====================================================================================== %%%
%%% @copyright (C) 2023, Cybarete Pty Ltd
%%% @doc
%%% The base_time_utils module defines the functions for time manipulation.
%%% @end
%%% ====================================================================================== %%%
%%% ====================================================================================== %%%

-module(base_time_utils).
-export([get_today_at_0am/0,
  get_today_at/1,
  is_weekend/1,
  unix_to_erlang_timestamp/1,
  test_module/0,
  is_between_times/3,
  get_time_in_hours/1,
  get_time/1,
  get_day_name/1,
  get_day_names/0,
  is_between_times/2,
  get_date_str/0,
  get_day_of_week/0]).

%%% ====================================================================================== %%%
%%%                                 EXTERNAL FUNCTIONS
%%% ====================================================================================== %%%

get_day_name(WeekDay) when WeekDay < 8, WeekDay > 0 ->
  lists:nth(WeekDay,get_day_names()).

get_day_names()->
  [<<"Mon">>,<<"Tue">>,<<"Wed">>,<<"Thu">>,<<"Fri">>,<<"Sat">>,<<"Sun">>].

get_day_of_week()->
  calendar:day_of_the_week(date()).

get_date_str()->
  {{Ya,Ma,Da},{H,Min,Sec}} = calendar:now_to_local_time(erlang:timestamp()),
  Y = integer_to_list(Ya),
  M = integer_to_list(Ma),
  D = integer_to_list(Da),
  Y++"_"++M++"_"++D.

%% @doc Gives the Unix millis timestamp at 00:00 of today
get_today_at_0am()->

  {{Ya,Ma,Da},{H,Min,Sec}} = calendar:now_to_local_time(erlang:timestamp()),
  Y = integer_to_binary(Ya),
  if
    Ma<10 ->
      Mb = integer_to_binary(Ma),
      M = <<"0",Mb/binary>>;
    true ->
      M = integer_to_binary(Ma)
  end,
  if
    Da<10 ->
      Db = integer_to_binary(Da),
      D = <<"0",Db/binary>>;
    true ->
      D = integer_to_binary(Da)
  end,
  STRING = binary_to_list(<<Y/binary,"-",M/binary,"-",D/binary,"T00:00:00+02:00">>),
  NEWSTAMP = calendar:rfc3339_to_system_time(STRING,[{unit,millisecond}]).

%% @doc Gives the Unix timestamp at the given hour today the hours is given as decimal (i.e. 6:3- = 6.5)
get_today_at(H)->
  get_today_at_0am() + (H*60*60*1000).

is_weekend(NOW)->
  {{Year,Month,Day},_} = calendar:system_time_to_universal_time(NOW,1000),
  case calendar:day_of_the_week({Year,Month,Day}) of
    6->
      true;
    7->
      true;
    _->
      false
  end.

%% GIVes is in {megasec,sec,microsecs}
unix_to_erlang_timestamp(MS)->
  M = 1000000,
  {MS div M div M, MS div M rem M, MS rem M}.

test_module()->
  NOW = erlang:system_time(seconds),
  IS_NOW_WEEKEND = is_weekend(NOW),
  D1 = 1646633935000, % NOT WEEKEND
  IS_D1_WEEKEND = is_weekend(D1),
  D2 = 1640067535000, %IS WEEKEND,
  WEEKENDRESULT = [NOW,D1,D2].

%% @doc Gets the current time of day from ms epoch as decimal hours  (6:30 - 6.5)
get_time_in_hours(MS)->
  {{Ya,Ma,Da},{H,Min,Sec}} = calendar:now_to_local_time(erlang:timestamp()),
  H+(Min/60)+(Sec/60/60).

%% @doc Gets the current time of day in {h,min,sec} tuple
get_time(MS)->
  {{Ya,Ma,Da},{H,Min,Sec}} = calendar:now_to_local_time(erlang:timestamp()),
  {H,Min,Sec}.

%% @doc Checks if a time is between two times given in UNIX millis.
is_between_times(T,T1,T2)->
  if
    T>T1,T<T2 ->
      true;
    true ->
      false
  end.

%% @doc Checks if a time is between two times given in UNIX millis.
is_between_times(T1,T2)->
  NOW = base:get_origo(),
  HR = get_time_in_hours(NOW),
  if
    HR>T1,HR<T2 ->
      true;
    true ->
      false
  end.


epoch() ->
  now_to_seconds(now())
.

epoch_hires() ->
  now_to_seconds_hires(now())
.

now_to_seconds({Mega, Sec, _}) ->
  (Mega * 1000000) + Sec
.

now_to_milliseconds({Mega, Sec, Micro}) ->
  now_to_seconds({Mega, Sec, Micro}) * 1000
.

now_to_seconds_hires({Mega, Sec, Micro}) ->
  now_to_seconds({Mega, Sec, Micro}) + (Micro / 1000000)
.

now_to_milliseconds_hires({Mega, Sec, Micro}) ->
  now_to_seconds_hires({Mega, Sec, Micro}) * 1000
.

epoch_gregorian_seconds() ->
  calendar:datetime_to_gregorian_seconds({{1970,1,1}, {0,0,0}})
.

now_to_gregorian_seconds() ->
  epoch_to_gregorian_seconds(now())
.

epoch_to_gregorian_seconds({Mega, Sec, Micro}) ->
  epoch_to_gregorian_seconds(now_to_seconds({Mega, Sec, Micro}));
epoch_to_gregorian_seconds(Now) ->
  EpochSecs = epoch_gregorian_seconds()
  , Now + EpochSecs
.

gregorian_seconds_to_epoch(Secs) ->
  EpochSecs = epoch_gregorian_seconds()
  , Secs - EpochSecs
.

date_to_epoch(Date) ->
  datetime_to_epoch({Date, {0,0,0} })
.

datetime_to_epoch({Date, Time}) ->
  gregorian_seconds_to_epoch(
    calendar:datetime_to_gregorian_seconds({Date, Time}))
.

is_older_by(T1, T2, {days, N}) ->
  N1 = day_difference(T1, T2)
  , case N1 of
      N2 when (-N < N2) ->
        true;
      _ ->
        false
    end
.

is_sooner_by(T1, T2, {days, N}) ->
  case day_difference(T1, T2) of
    N1 when N > N1 ->
      true;
    _ ->
      false
  end
.

is_time_older_than({Date, Time}, Mark) ->
  is_time_older_than(calendar:datetime_to_gregorian_seconds({Date, Time})
    , Mark);
is_time_older_than(Time, {DateMark, TimeMark}) ->
  is_time_older_than(Time
    , calendar:datetime_to_gregorian_seconds({DateMark, TimeMark}));
is_time_older_than(Time, Mark)  when is_integer(Time), is_integer(Mark) ->
  Time < Mark
.

day_difference({D1, _}, D2) ->
  day_difference(D1, D2);
day_difference(D1, {D2, _}) ->
  day_difference(D1, D2);
day_difference(D1, D2) ->
  Days1 = calendar:date_to_gregorian_days(D1)
  , Days2 = calendar:date_to_gregorian_days(D2)
  , Days1 - Days2.

is_time_sooner_than({Date, Time}, Mark) ->
  is_time_sooner_than(calendar:datetime_to_gregorian_seconds({Date, Time})
    , Mark);

is_time_sooner_than(Time, {DateMark, TimeMark}) ->
  is_time_sooner_than(Time,calendar:datetime_to_gregorian_seconds({DateMark, TimeMark}));

is_time_sooner_than(Time, Mark)  when is_integer(Time), is_integer(Mark) ->
  Time > Mark.

subtract(Date, {days, N}) ->
  New = calendar:date_to_gregorian_days(Date) - N
  , calendar:gregorian_days_to_date(New).

add(Date, {days, N}) ->
  New = calendar:date_to_gregorian_days(Date) + N
  , calendar:gregorian_days_to_date(New).