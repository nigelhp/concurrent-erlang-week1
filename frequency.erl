%% Based on code from 
%%   Erlang Programming
%%   Francecso Cesarini and Simon Thompson
%%   O'Reilly, 2008
%%   http://oreilly.com/catalog/9780596518189/
%%   http://www.erlangprogramming.org/
%%   (c) Francesco Cesarini and Simon Thompson

-module(frequency).
-export([start/0,allocate/0,deallocate/1,stop/0]).
-export([init/0]).

%% These are the start functions used to create and
%% initialize the server.

start() ->
    register(frequency,
	     spawn(frequency, init, [])).

init() ->
  Frequencies = {get_frequencies(), []},
  loop(Frequencies).

% Hard Coded
get_frequencies() -> [10,11,12,13,14,15].

%% The Main Loop

loop(Frequencies) ->
  receive
    {request, Pid, allocate} ->
      {NewFrequencies, Reply} = allocate(Frequencies, Pid),
      Pid ! {reply, Reply},
      loop(NewFrequencies);
    {request, Pid , {deallocate, Freq}} ->
      NewFrequencies = deallocate(Frequencies, Freq),
      Pid ! {reply, ok},
      loop(NewFrequencies);
    {request, Pid, stop} ->
      Pid ! {reply, stopped}
  end.

%% Functional interface
%%
%% Note the assumption here that the client will never receive a message
%% matching the pattern {reply, ...} from anything other than the frequency
%% server.
%% One approach discussed in the lectures was for the server to include its
%% PID in replies, so that clients could include the target server PID in
%% the pattern-match when awaiting a reply.  However, the use of a named
%% process here seemed to be to intentionally move us away from knowledge 
%% of a specific PID.
%%
%% The client will receive a timeout error if it does not receive a prompt 
%% reply from the server to an allocate / deallocate request.  However, a 
%% server reply may still be delivered to the mailbox (albeit late).  We
%% therefore explicitly clear the client mailbox before making requests of
%% the server, in order to attempt to prevent receive blocks from picking-up
%% old replies.  However, this still seems subject to a race condition - a
%% late response could still be received after clear has completed.  Also
%% note that in the case of successful replies that are delivered late, we
%% now have an inconsistent view of state.  The client received an error,
%% but the server has actually allocated a frequency to that client.  If the
%% client simply retries, we potentially have unused allocated frequencies
%% - not good when frequencies are a limited resource.
allocate() ->
    clear(),
    frequency ! {request, self(), allocate},
    receive 
	    {reply, Reply} -> Reply
    after 500 ->
            {reply, {error, timeout}}
    end.

deallocate(Freq) ->
    clear(),
    frequency ! {request, self(), {deallocate, Freq}},
    receive 
	    {reply, Reply} -> Reply
    after 500 ->
            {reply, {error, timeout}}
    end.

stop() -> 
    clear(),
    frequency ! {request, self(), stop},
    receive 
	    {reply, Reply} -> Reply
    end.

%% Flush the client mailbox (simply draining any messages without action)
clear() ->
    receive
        Msg -> io:format("dropping message: ~p~n", [Msg]),
               clear()
    after 0 ->
            ok
    end.

%% The Internal Help Functions used to allocate and
%% deallocate frequencies.

allocate({[], Allocated}, _Pid) ->
  {{[], Allocated}, {error, no_frequency}};
allocate({[Freq|Free], Allocated}, Pid) ->
  {{Free, [{Freq, Pid}|Allocated]}, {ok, Freq}}.

deallocate({Free, Allocated}, Freq) ->
  NewAllocated=lists:keydelete(Freq, 1, Allocated),
  {[Freq|Free],  NewAllocated}.
