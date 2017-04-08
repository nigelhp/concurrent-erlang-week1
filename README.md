##### FutureLearn / University of Kent: Concurrent Programming in Erlang
### Week 1 Assignment

#### Flushing the mailbox
Suppose that we want to ensure that any messages that happen to be in a mailbox are
removed. We might think that we could remove them all like this:

    clear() ->
      receive
        _Msg -> clear()
    end.
    
But this has two problems. First, it will block if no messages are present, and, second, it will
never terminate. The way to ensure that it only processes messages that are already in the
mailbox, and terminates once they are removed, is to use a timeout of zero. 

Modify the definition of clear/0 to include this.

#### Adding timeouts to the client code
Suppose that the frequency server is heavily loaded. In this case it could make sense to
add timeouts to the client code that asks to allocate or deallocate a frequency. Add
these to the code.

One possibility when a receive times out is that a message is subsequently delivered
into the mailbox of the receiving process, but not processed as it should be. It can then
become necessary to clear the mailbox periodically: where would you add these calls to
clear/0?

You can simulate the frequency server being overloaded by adding calls to
timer:sleep/1 to the frequency server. If these delays are larger than the timeouts
chosen for the client code, you will be able to observe the late delivery of messages by
modifying clear/0 to print messages as they are cleared from the mailbox. Define a
modified version of clear/0 to do this, and test it with your “overloaded” server.
