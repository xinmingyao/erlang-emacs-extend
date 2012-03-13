-module(extend_ct_tool_SUITE).
-compile(export_all).
-include_lib("common_test/include/ct.hrl").

init_per_suite(Config)->
    Config.
end_per_suite(Config)->
    Config.

init_per_testcase(_A,Config)->

    Config.
end_per_testcase(Config)->
    Config.
    
all()->
    [error1].

e1(_Config)->
    fortest:error1().
error1(_Config)->
    {failed,_,_,_}=extend_ct_tool:run_ct("/home/erlang/mos/erlang-emacs-extend/test","extend_ct_tool_SUITE.erl","e1").
