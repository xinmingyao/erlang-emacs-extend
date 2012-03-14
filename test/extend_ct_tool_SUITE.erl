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
    [].

e1(_Config)->
    fortest:error1().
error1(Config)->
    extend_ct_tool:run_ct(test_help:get_test_path(Config),"extend_ct_tool_SUITE.erl","e1").
