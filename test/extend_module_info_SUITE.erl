-module(extend_module_info_SUITE).
-compile(export_all).
-include_lib("common_test/include/ct.hrl").
-include("extend.hrl").
init_per_suite(Config)->
    Config.
end_per_suite(Config)->

    Config.

init_per_testcase(_A,Config)->
    {ok,_Pid}=extend_module_info:start_link(),
    Config.
end_per_testcase(Config)->
    gen_server:call(extend_module_info,stop),
    Config.
    
all()->
    [create1,get].

create1(Config)->
     
    extend_module_info:create_mod("extend_module_info.erl",test_help:get_base_dir(Config)).

get(Config)->
    extend_module_info:create_mod("extend_module_info.erl",test_help:get_base_dir(Config)),
    extend_module_info:create_mod("extend_module_info.erl",test_help:get_base_dir(Config)),
    {ok,["LINE"]}=extend_module_info:get_macro("extend_module_info.erl","LINE",test_help:get_base_dir(Config)),
    {ok,["MYTEST1"]}=extend_module_info:get_macro("extend_module_info.erl","MYTEST1",test_help:get_base_dir(Config)),
    {ok,["mods"]}=extend_module_info:get_records("extend_module_info.erl","mods",test_help:get_base_dir(Config)),
{ok,["name","value"]}=extend_module_info:get_record_name("extend_module_info.erl","test2",test_help:get_base_dir(Config)).
    
    
    

