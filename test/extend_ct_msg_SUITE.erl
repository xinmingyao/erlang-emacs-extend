-module(extend_ct_msg_SUITE).
-compile(export_all).
-include_lib("common_test/include/ct.hrl").

init_per_suite(Config)->
    Config.
end_per_suite(Config)->

    Config.

init_per_testcase(_A,Config)->
    extend_ct_msg:start_link(),
    Config.
end_per_testcase(Config)->

    Config.
    
all()->
    [save].

save(_Config)->
    extend_ct_msg:save_fail_info("test1","msg"),
    {ok,"msg"}=extend_ct_msg:get_fail_info("test1"),
    no_info=extend_ct_msg:get_fail_info("test22").
