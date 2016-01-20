%% -*- mode: erlang; tab-width: 4; indent-tabs-mode: 1; st-rulers: [70] -*-
%% vim: ts=4 sw=4 ft=erlang noet
%%%-------------------------------------------------------------------
%%% @author Andrew Bennett <andrew@pixid.com>
%%% @copyright 2015-2016, Andrew Bennett
%%% @doc
%%%
%%% @end
%%% Created :  20 Jan 2016 by Andrew Bennett <andrew@pixid.com>
%%%-------------------------------------------------------------------
-module(keccakf1600).

-include("keccakf1600.hrl").

%% API
-export([start/0]).
-export([call/2]).
-export([call/3]).
-export([call/4]).
-export([open/0]).
-export([close/1]).

-define(MAYBE_START_KECCAKF1600(F), try
	F
catch
	_:_ ->
		_ = keccakf1600:start(),
		F
end).

%%%===================================================================
%%% API
%%%===================================================================

start() ->
	application:ensure_all_started(?MODULE).

call(Namespace, Function)
		when is_atom(Namespace)
		andalso is_atom(Function) ->
	?MAYBE_START_KECCAKF1600(call(Namespace, Function, {})).

call(Namespace, Function, Arguments)
		when is_atom(Namespace)
		andalso is_atom(Function)
		andalso is_tuple(Arguments) ->
	?MAYBE_START_KECCAKF1600(call(erlang:whereis(?KECCAKF1600_DRIVER_ATOM), Namespace, Function, Arguments)).

call(Port, Namespace, Function, Arguments)
		when is_port(Port)
		andalso is_atom(Namespace)
		andalso is_atom(Function)
		andalso is_tuple(Arguments) ->
	driver_call(Port, ?KECCAKF1600_ASYNC_CALL, Namespace, Function, Arguments).

open() ->
	erlang:open_port({spawn_driver, ?KECCAKF1600_DRIVER_NAME}, [binary]).

close(P) ->
	try
		true = erlang:port_close(P),
		receive
			{'EXIT', P, _} ->
				ok
		after
			0 ->
				ok
		end
	catch
		_:_ ->
			erlang:error(badarg)
	end.

%%%-------------------------------------------------------------------
%%% Internal functions
%%%-------------------------------------------------------------------

%% @private
driver_call(Port, Command, Namespace, Function, Arguments) ->
	Tag = erlang:make_ref(),
	case erlang:port_call(Port, Command, {Tag, Namespace, Function, Arguments}) of
		Tag ->
			receive
				{Tag, Reply} ->
					Reply
			end;
		{Tag, Error} ->
			Error
	end.