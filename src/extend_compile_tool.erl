-module(extend_compile_tool).
-export([compile_file/4]).
compile_file(Name,Include,OutDir,Opts)->
    CompileOpts=[{outdir,OutDir},{i,Include},{d,'TEST'}]++Opts,
    R=compile:file(Name,CompileOpts),
    Mod=erlang:list_to_atom(string:substr(Name,string:rchr(Name,$/)+1)),
    code:purge(Mod),
    code:load_file(Mod),
    R.


