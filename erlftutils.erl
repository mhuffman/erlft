-module(erlftutils).
-export([http_request/5, url_encode/1]).


%checks and forces ssl service to be started, this is required for fusion tables
ssl_is_started() ->
    case ssl:start() of
	ok -> {ok, ""};
	{error,{already_started,ssl}} -> {ok, ""};
	_ -> {error, "can't start ssl service"}
    end.

%checks and forces inets to have started and have httpc in it.
inets_is_started() ->

    case ssl_is_started() of
	{ok, _} ->
	    HasHttpcFun = fun(X) ->
			  case X of
			      {httpc, _} -> true;
			      _AnyThingElse -> false
			  end
	    end,
	    case inets:services() of
		{error,inets_not_started} ->
		    inets:start(),
		    inets_is_started();
		ServicesList ->
		    case lists:any(HasHttpcFun, ServicesList) of
			false -> {error, "inets is started but without httpc"}; %TODO: dynamically start httpc service here
			true -> {ok, ""}
		    end
	    end;
	{error, ErrorMsg} ->
	    {error, ErrorMsg}

    end.

http_request(BodyFun, Method, Request, HTTPOptions, OtherOptions) ->
    case inets_is_started() of
	{ok, []} ->
	    case httpc:request(Method, Request, HTTPOptions, OtherOptions) of
		{ok, {{_, Code, _}, _, Body}} ->
		    case Code of
			200 -> BodyFun(Body);
			_ -> {error, "Response from http_request was other than 200"}
		    end;
		OtherResponse ->
		    OtherResponse,
		    {error, "Response from http_request was unknown"}
	    end;
	    
	{error, ErrorMsg} ->
	    {error, ErrorMsg}
    end.



%%takes proplist and returns encoded query string
url_encode(Data) -> 
    url_encode(Data,""). 

url_encode([],Acc) -> 
    Acc; 

url_encode([{Key,Value}|R],"") -> 
    url_encode(R, edoc_lib:escape_uri(Key) ++ "=" ++ 
edoc_lib:escape_uri(Value)); 

url_encode([{Key,Value}|R],Acc) -> 
    url_encode(R, Acc ++ "&" ++ edoc_lib:escape_uri(Key) ++ "=" ++ 
edoc_lib:escape_uri(Value)). 
