-module(extend_module_tool).
-export([get_fun/2,start/0,test_type/1]).
get_fun(Module,Line)->
    try get_fun1(Module,Line) of
	R->{ok,R}
    catch
	_:Reason ->{error,Reason}
		  
    end.

get_fun1(Module,Line)->
    {ok,{_,[{abstract_code,{raw_abstract_v1,Atr}}]}}=beam_lib:chunks(Module,[abstract_code]),
    L1=lists:filter(fun({function,_,_,_,_})->
			 true;
		    (_)->
			 false end ,Atr),
    L2=lists:reverse(L1),
    get(Line,L2).

test_type(Module)->
    {ok,{_,[{abstract_code,{raw_abstract_v1,Atr}}]}}=beam_lib:chunks(Module,[abstract_code]),
    L1=lists:filter(fun({_,_,file,_})->
			 true;
		    (_)->
			 false end ,Atr),
    Ct=lists:filter(fun({_,_,_,{FileName,_}})->
			    case re:run(FileName,"ct.hrl") of
				{match,_}->true;
				_->false
			    end
			    end,L1),
    case Ct of 
	_ when length(Ct)>0 ->
	    ct;
	_ ->
	    Eunit=lists:filter(fun({_,_,_,{FileName,_}})->
			    case re:run(FileName,"eunit.hrl") of
				{match,_}->true;
				_->false
			    end
			       end,L1),
	    case Eunit of
		_ when length(Eunit)>0->
		    eunit;
		_ ->other
	    end
    end
	 .

%{attribute,21,file,
%                      {"/usr/local/lib/erlang/lib/common_test-1.6/include/ct.hrl",
%                       21}}
get(_Line,[])->
    "nofun";
get(Line,[H|T]) ->
    {_,Num,Name,_,_}=H,
    if 
	Line > Num ->
	    atom_to_list(Name);
	true->get(Line,T)
    end.



    
start()->
    ok.


-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-endif.
