-module(extend_compile_tool).
-export([compile_file/4]).
compile_file(Name,Include,OutDir,Opts)->
    CompileOpts=[{outdir,OutDir},{i,Include}]++Opts,
    compile:file(Name,CompileOpts).

