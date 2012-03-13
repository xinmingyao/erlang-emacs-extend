-module(extend_ct_tool).
-export([run_ct/3]).
-include("extend.hrl").


run_ct(TestPath,Name,Fun)->
    Pid=self(),
    erlang:group_leader(whereis(init),self()),
    Para=#ct_request{from=Pid,replyas=run_ct},
    EventHandler={event_handler,[extend_ct_event_handler]},
    Name2=string:substr(Name,1,string:len(Name)-4),
    N2=list_to_atom(Name2),
   try  erlang:register(N2,self()) of
	A->A
   catch
       _:_ ->erlang:unregister(N2),erlang:register(N2,self())
   end,
%    EventHandler={event_handler_init,[{extend_ct_event_handler,[Para]}]},
%    ct:stop_interactive(),    
    ct:run_test([{auto_compile,false},{dir,TestPath},{suite,Name},{testcase,[list_to_atom(Fun)]},EventHandler]),

    Re=receive
	#ct_reply{result=Result}->
	     %  error_logger:info_msg("~w",[Result]),
	    case Result of
		{failed,{error,{RuntimeError,StackTrance}}}->
		    {FileName,LineNo}=get_stack_info(StackTrance),
		    {failed,FileName,LineNo,RuntimeError};
		{failed,FailReason}->
		    {failed,FailReason};
		_->ok
	    end
			
    after 3000
	      -> ok
    end ,
    catch erlang:unregister(N2),
    %error_logger:info_msg("~w",[Re]),
    Re.


get_stack_info(Stack)->
    Location=get_location(Stack),
    [{_file,File}|T]=Location,
    [{_lineno,LineNo}|_]=T,
    {File,LineNo}.

get_location([])->
    throw(error);
get_location([{_Mod,_Fun,_Arity,[]}|T]) ->
    get_location(T);
get_location([{_Mod,_Fun,_Arity,Location}|_T]) ->
    Location.


    
 % Info= extend_ct_msg:get_fail_info(erlang:list_to_atom(Name)),
 %error_logger:info_msg("~w",[Info]),
  %Info.


% [{fortest,error1,0,a
%                              [{file,"/home/erlang/mos/erlang-emacs-extend/src/fortest.erl"},
%                               {line,34}]},
%                     {test_server,ts_tc,3,
%                                  [{file,"test_server.erl"},{line,1635}]},
    
%{failed,{error,{undef,[{gen_c,call,[],[]},{fortest,error1,0,[{file,[47,104,111,109,101,47,101,114,108,97,110,103,47,109,111,115,47,101,114,108,97,110,103,45,101,109,97,99,115,45,1
