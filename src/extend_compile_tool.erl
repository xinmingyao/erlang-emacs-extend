-module(extend_compile_tool).
-export([compile_file/4]).
compile_file(Name,Include,OutDir,Opts)->
    Base=filename:dirname(Include),
     Dep=filename:join([Base,"deps"]),
    {ok,Dirs}=file:list_dir(Dep),
    Includes=lists:map(fun(A)->
			       Pa= filename:join([Dep,A,"include"]),			       
			       {i,Pa}
		       end ,Dirs),
    CompileOpts=[{outdir,OutDir},{i,Include},{d,'TEST'}]++Opts,
    R=compile:file(Name,lists:merge(CompileOpts,Includes)),
    Mod=erlang:list_to_atom(string:substr(Name,string:rchr(Name,$/)+1)),
    code:purge(Mod),
    code:load_file(Mod),
    R.


