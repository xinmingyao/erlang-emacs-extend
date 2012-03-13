-module(extend_module_tool).
-export([get_fun/2,start/0]).
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


