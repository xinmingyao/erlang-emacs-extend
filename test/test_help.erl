-module(test_help).
-export([get_test_path/1,get_ebin_path/1]).
-export([get_base_dir/1]).


-include_lib("common_test/include/ct.hrl").
-define(TEST_PATH,"test").
-define(TEST_LEN,string:len(?TEST_PATH)+1).
-define(EBIN_PATH,"ebin").


get_base_dir(Config)->
    DataDir=?config(data_dir,Config),
    case re:run(DataDir,"test") of
	{match,[{Start,_End}]}->
	    string:substr(DataDir,1,Start);
	_ ->"error"
    end.

get_ebin_path(Config)->
    get_base_dir(Config)++"/"++?EBIN_PATH++"/".
get_test_path(Config)->
    get_base_dir(Config)++"/"++?TEST_PATH++"/".
   % Index=string:rchr(DataDir,$/),
   % string:substr(DataDir,1,Index).


