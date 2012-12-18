-module(extend_module_tool_SUITE).
-compile(export_all).
-include_lib("common_test/include/ct.hrl").
-include("extend.hrl").
init_per_suite(Config)->
    Config.
end_per_suite(Config)->

    Config.

init_per_testcase(_A,Config)->

    Config.
end_per_testcase(Config)->

    Config.
    
all()->
    [get,test_type_ct,test_type_eunit].



get(Config)->
    Name=atom_to_list(?MODULE),
    File=test_help:get_test_path(Config)++Name,
    %ct:fail(5),
 %   error_logger:info_msg("~s~n",[File]),
    {ok,"get"}=extend_module_tool:get_fun(File,25).
    
 test_type_ct(Config)->   
    Name=atom_to_list(?MODULE),
    File=test_help:get_test_path(Config)++Name,
    ct=extend_module_tool:test_type(File).

 test_type_eunit(Config)->   
    Name=atom_to_list(extend_module_tool),
    File=test_help:get_ebin_path(Config)++Name,
    error_logger:info_msg("~s~n",[File]),
    eunit=extend_module_tool:test_type(File).
