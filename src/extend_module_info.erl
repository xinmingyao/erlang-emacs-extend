%%%-------------------------------------------------------------------
%%% @author  <>
%%% @copyright (C) 2012, 
%%% @doc
%%%
%%% @end
%%% Created :  1 Mar 2012 by  <>
%%%-------------------------------------------------------------------
-module(extend_module_info).
-behaviour(gen_server).
%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([create_mod/2,get_macro/3,get_records/3,get_record_name/3]).

-define(SERVER, ?MODULE). 
   
-record(mods,{name,epp,macros,records}).
-record(test2,{name,value}).


-record(state, {mods}).
-include("extend.hrl").


%{attribute,4,record,
% {test1,[{record_field,4,{atom,4,name}},
%	 {record_field,4,{atom,4,value}}]}},
%%%===================================================================
%%% API
%%%=================================================================== 
-spec create_mod(Mod::string(),BasePath::string())->					       ok.
create_mod(Mod,BasePath)->
    start(),
    gen_server:call(?MODULE,{create_mod,Mod,BasePath}).
get_macro(Mod,Name,BasePath)->
    start(),
    is_mod_exist(Mod,BasePath),
    gen_server:call(?MODULE,{get_macro,Mod,Name}).
get_records(Mod,Name,BasePath)->
    start(),
    is_mod_exist(Mod,BasePath),
    gen_server:call(?MODULE,{get_records,Mod,Name}).
get_record_name(Mod,Name,BasePath)->
    start(),
    is_mod_exist(Mod,BasePath),
    gen_server:call(?MODULE,{get_record_name,Mod,Name}).
is_mod_exist(Mod,BasePath)->
    case gen_server:call(?MODULE,{is_exist,Mod}) of
	true->
	    donothing;
	false ->
	    create_mod(Mod,BasePath)
    end.
	 
start()->
    case whereis(?MODULE) of 
	undefined->
	    start_link();
	_ ->ok
    end
	.
				 
%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @spec start_link() -> {ok, Pid} | ignore | {error, Error}
%% @end
%%--------------------------------------------------------------------
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
init([]) ->
    Ets=ets:new(?MODULE,[{keypos,2}]),
    {ok, #state{mods=Ets}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @spec handle_call(Request, From, State) ->
%%                                   {reply, Reply, State} |
%%                                   {reply, Reply, State, Timeout} |
%%                                   {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, Reply, State} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------


handle_call({is_exist,Mod}, _From, State=#state{mods=Mods}) ->
    case ets:lookup(Mods,Mod) of
	[]->
	    {reply,false,State};
	_-> {reply,true,State} 
    end;

handle_call({get_macro,Mod,Name}, _From, State=#state{mods=Mods}) ->
    [Macs|_]=ets:lookup(Mods,Mod),
    L1=lists:filter(fun(A)->
			 case re:run(A,"^"++Name) of
			     {match,_}->
				 true;
			     _ ->false end end,Macs#mods.macros),
    Reply={ok,L1},
    {reply, Reply, State};


handle_call({get_records,Mod,Name}, _From, State=#state{mods=Mods}) ->
    [Macs|_]=ets:lookup(Mods,Mod),
    L1=lists:map(fun({attribute,_,record,{N,_}})->
			 atom_to_list(N) end,Macs#mods.records),
    L2=lists:filter(fun(A)->
			 case re:run(A,"^"++Name) of
			     {match,_}->
				 true;
			     _ ->false end end,L1),
    Reply={ok,L2},
    {reply, Reply, State};

handle_call({get_record_name,Mod,Name}, _From, State=#state{mods=Mods}) ->
    Reply= case ets:lookup(Mods,Mod) of
	       []->[];
	       V->Macs=lists:nth(1,V),
		    L1=lists:map(fun({attribute,_,record,{N,Fields}})->
					 {atom_to_list(N),Fields} end,Macs#mods.records),
		    L2=lists:filter(fun({A,_Fs})->
					    if A=:=Name ->
						    true;
					       true->false
					    end end,L1),
		    case L2 of
			[]->[];
			_->{_,L3}=lists:nth(1,L2),lists:map(fun({record_field,_,{_,_,Tn}})->
								    atom_to_list(Tn);
							        ({record_field,_,{_,_,Tn},_})->
								    atom_to_list(Tn)
							    end ,L3)
		    end
	   end,
    {reply, {ok,Reply}, State};
 

handle_call({create_mod,Mod,BasePath}, _From, State=#state{mods=Mods}) ->
    {ok,Epp}=epp:open(BasePath++get_test_or_src(Mod)++Mod,[BasePath++"/include"]),
    Att=epp:parse_file(Epp),
    Recs=lists:filter(fun({attribute,_,record,_})->
			      true;
			 (_)->false end ,Att),
    L=epp:macro_defs(Epp),
%    L1=lists:filter(fun({{_,A},_})->
%			 case re:run(atom_to_list(A),"^"++Pref) of
%			     {match,_}->
%				 true;
%			     _ ->false end end,L),
    Mac= lists:map(fun({{_,A},_})->
		      atom_to_list(A) end ,L),
    Reply = Mac,
%    error_logger:info_msg("~w~n",[Mac]),
    M1=#mods{name=Mod,epp=Epp,macros=Mac,records=Recs},
    
    ets:insert(Mods,M1),
    {reply, Reply, State};
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @spec handle_cast(Msg, State) -> {noreply, State} |
%%                                  {noreply, State, Timeout} |
%%                                  {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================

get_test_or_src(Name)->
   case re:run(Name,"SUITE") of
	{match,_}->
	    "test/";
	_ ->"src/"
    end
.
