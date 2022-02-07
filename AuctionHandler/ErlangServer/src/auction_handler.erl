%%%-------------------------------------------------------------------
%%% @author fraie
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. gen 2022 13:04
%%%-------------------------------------------------------------------
-module(auction_handler).
-author("fraie").

%% API
-export([init_auction_handler/2]).
%%-record(offers, {user, offer_amount}).

init_auction_handler(AuctionName, AuctionDuration) ->
  %%create_offers_db(),
  %%start_mnesia_offer_db(),
  erlang:send_after(1000, self(), {clock}),
  auction_loop({AuctionName, [],AuctionDuration, []}).


auction_loop({AuctionName, AuctionUsers, RemainingTime, OfferList}) ->
  receive
    {Client, new_offer, MessageMap} ->
      io:format(" [AUCTION HANDLER] New Bid: ~p~n", [MessageMap]),
      %%Res = add_offer(maps:get("username", MessageMap), maps:get("bid", MessageMap)),
      NewOfferList = OfferList ++ [{maps:get("username", MessageMap), maps:get("bid", MessageMap)}],
      %%io:format(" [AUCTION HANDLER] Offer Added - result: ~p~n", [Res]),
      %%{atomic, Offers} = get_offers(),
      ToSend = {ok, AuctionName, RemainingTime, AuctionUsers, NewOfferList, false},
      io:format(" [AUCTION HANDLER] Sending state: ~p~n", [ToSend]),
      Client ! {self(), ToSend},
      {mbox, listener@localhost} ! {self(), update_auction_state, ToSend},
      auction_loop({AuctionName, AuctionUsers, RemainingTime, NewOfferList});
    {Client, new_user, MessageMap} ->
      io:format(" [AUCTION HANDLER] Received new_user message~n"),
      NewAuctionListUsers = AuctionUsers ++ [maps:get("username", MessageMap)],
      %%{atomic, Offers} = get_offers(),
      ToSend = {ok, AuctionName, RemainingTime, NewAuctionListUsers, OfferList, false},
      Client ! {self(), ToSend},
      {mbox, listener@localhost} ! {self(), update_auction_state, ToSend},
      io:format(" [AUCTION HANDLER] User added to auction user list - New list: ~p~n",[NewAuctionListUsers]),
      auction_loop({AuctionName, NewAuctionListUsers, RemainingTime, OfferList});
    {Client, del_user, MessageMap} ->
      DisconnectedUser = maps:get("username", MessageMap),
      NewList = lists:delete(DisconnectedUser, AuctionUsers),
      Client ! {self(), {ok}},
      %% {atomic, Offers} = get_offers(),
      ToSend = {ok, AuctionName, RemainingTime, NewList, OfferList, false},
      {mbox, listener@localhost} ! {self(), update_auction_state, ToSend},
      io:format(" [AUCTION HANDLER] User deleted from auction user list - New list: ~p~n",[NewList]),
      auction_loop({AuctionName, NewList, RemainingTime, OfferList});
    {Client, get_auction_state} ->
      io:format(" [AUCTION HANDLER] Requested auction state ~n"),
      %%{atomic, Offers} = get_offers(),
      ToSend = {ok, AuctionName, RemainingTime, AuctionUsers, OfferList, false},
      io:format(" [AUCTION HANDLER] Sending state: ~p~n", [ToSend]),
      Client ! {self(), ToSend},
      auction_loop({AuctionName, AuctionUsers, RemainingTime, OfferList});
    {kill_auction_exists} ->
      io:format(" [AUCTION HANDLER] Suicide: ~p killed...~n", [self()]);
    {clock} ->
      io:format(" [AUCTION HANDLER] Timer Updated: 1 second passed ~n"),
      NewTime = RemainingTime - 1,
      io:format(" [AUCTION HANDLER] Remaining ~p ~n",[NewTime]),
      if
        NewTime == 0 -> winner(AuctionName, RemainingTime, AuctionUsers, OfferList);
        NewTime > 0 -> erlang:send_after(1000, self(), {clock});
        true -> io:format("CRITICAL ERROR")
      end,
      auction_loop({AuctionName, AuctionUsers, NewTime, OfferList});
    _ ->
      io:format(" [AUCTION HANDLER] Unrecognized message arrived, skipping... ~n"),
      auction_loop({AuctionName, AuctionUsers, RemainingTime, OfferList})
  end.


winner(AuctionName, RemainingTime, AuctionUsers, OfferList) ->
  io:format(" [AUCTION HANDLER] Deciding the winner ~n"),
  FinalOffersAmount = get_offers_amount(OfferList),
  FinalOffersUsers = get_offers_users(OfferList),
  io:format(" [AUCTION HANDLER] Final Offers Amount ~p~n", [FinalOffersAmount]),
  io:format(" [AUCTION HANDLER] Final Offers Users ~p~n", [FinalOffersUsers]),
  Max = lists:max(FinalOffersAmount),
  MaxIndex = find_index_of_max(Max, FinalOffersAmount),
  io:format(" [AUCTION HANDLER] The Winner is in position ~p~n",[MaxIndex]),
  Winner = lists:nth(MaxIndex+1, FinalOffersUsers),
  WinningBid = lists:nth(MaxIndex+1, FinalOffersAmount),
  io:format(" [AUCTION HANDLER] Among the users ~p the winner is ~p~n", [FinalOffersUsers, Winner]),
  io:format(" [AUCTION HANDLER] Among the offers ~p the winning bid is ~p~n", [FinalOffersAmount, WinningBid]),
  %%{atomic, Offers} = get_offers(),
  ToSend = {ok, AuctionName, RemainingTime, AuctionUsers, OfferList, true, [Winner, WinningBid]},
  {mbox, listener@localhost} ! {self(), update_auction_state, ToSend},
  MainServerPid = whereis(main_server_endpoint),
  io:format(" [AUCTION HANDLER] Sending update request to ~p ~n", [MainServerPid]),
  MainServerPid ! {update_win, AuctionName, Winner}.

find_index_of_max(Max, FinalOffersAmount) ->
  find_index_of_max(Max, FinalOffersAmount, 0).
find_index_of_max(Max, [H|T], Counter) ->
  if
    H == Max -> Counter;
    true -> find_index_of_max(Max, T, Counter+1)
  end;
find_index_of_max(Max, [], _Counter) ->
  Error = -1,
  Error.

get_offers_amount(OfferList) ->
  OffersAmountList = [Amount || {User, Amount} <- OfferList],
  io:format(" OffersAmountList: ~p",[OffersAmountList]),
  OffersAmountList.

get_offers_users(OfferList) ->
  OffersUsersList = [User || {User, Amount} <- OfferList],
  io:format(" OffersUserList: ~p",[OffersUsersList]),
  OffersUsersList.


%% SUPPORT DB
%%create_offers_db() ->
%%  mnesia:create_schema([node()]),
%%   application:start(mnesia),
%%   io:format("Test debug: Offer DB started ~n"),
%%   mnesia:create_table(offers, [
%%     {attributes, record_info(fields, offers)}, {disc_copies, [node()]}]).

%% @doc This function start an already existing mnesia server
%% start_mnesia_offer_db() ->
%%  application:start(mnesia).

%% @doc This function a running instance of the mnesia server (the
%% information are maintained on the disk).
%% stop_mnesia_offer_db() ->
%%  application:stop(mnesia).

%% add_offer(Username, Amount) ->
%%   F = fun() -> mnesia:write(#offers{user = Username, offer_amount = Amount}) end,
%%   mnesia:transaction(F).

%% get_offers() ->
%%   R = fun() ->
%%     io:format("Retrieving offers ~n"),
%%     User = #offers{user = '$1', offer_amount = '$2', _ = '_'},
%%    mnesia:select(offers, [{User, [], [['$1', '$2']]}])
%%      end,
%%  mnesia:transaction(R).




