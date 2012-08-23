-module(extend_eunit_tool).
-export([run_test/2,leader_proxy/2]).

leader_proxy(Old,Parent)->
    receive
	stop->ok;
	A->
	    Old!A,
	    case A of
		{io_request,_,_,{put_chars,unicode,io_lib,format,
                           ["*failed*\n::~s",
                            [B]]}}
		
		->
		    %{_,P}=process_info(whereis(init),group_leader),
		    %io:format(P,"ddddddddddddd",[]),
		    %Parent!A,
		    Parent!get_info(B),
		    %Parent!ok,
		    leader_proxy(Old,Parent)
			;
		_->leader_proxy(Old,Parent)
	    end
    end.
get_info(B)->
    _S0="{assertion_failed,[{module,ebert-c},\n{line,140},\n                   {expression,\"1 == 2\"},\n                   {expected,true},\n                   {value,false}]}\n",
    S=erlang:binary_to_list(erlang:iolist_to_binary(B)),
    S1=re:replace(S,"\n","",[{return,list}]),

    Re="assertion_failed,.*module,([a-zA-Z0-9_\-]*).*line,([0-9]*)",
    case re:run(S1,Re,[]) of
	{match,[_,{B1,E1},{B2,E2}]}->
	    {error,string:substr(S1,B1+1,E1),erlang:list_to_integer(string:substr(S1,B2+1,E2)),S1};
	A ->
	    A
    end.
	
run_test(Mod,Fun)->
    {_,P}=process_info(whereis(init),group_leader),
    Me=self(),
    Proxy=erlang:spawn(?MODULE,leader_proxy,[P,Me]),
    erlang:group_leader(Proxy,self()),
    %io:format("mod:~p,fun:~p ~n",[Mod,Fun]),
   case eunit:test({Mod,Fun}) of
       ok->ok;
       error->
	   receive 
	       A->erlang:send_after(5,Proxy,stop),A
	   after 3000
		     ->error 
			   
	   end
   end
    .

%-ifndef(TEST).
-compile([export_all]).
-include_lib("eunit/include/eunit.hrl").
base_test()->
    ?assert(1==2).
%-endif.



