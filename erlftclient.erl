-module(erlftclient).


%%-export([]).
-compile(export_all).

-define(API_URL, "https://www.google.com/fusiontables/api/query").

%delegates to erlfeclientlogin:authorize and returns an error or cookie
client_login(Email, Password) ->
    erlftclientlogin:authorize(Email, Password).



%returns a list of {table_id, table_name} tuples of any found tables
show_tables(Cookie) ->
    Cfun = fun(Y) ->
		   {match, [TableID, TableName]} = re:run(Y, "(\\d+),(.+)", [{capture, [1,2], list}]),
		   {TableID, TableName}
	   end,
    Tfun = fun(X) ->
		   [_ | TItems] = re:split(X, "\n"),
		   [_| Items] = lists:reverse(TItems),
		   {ok, lists:map(Cfun, lists:reverse(Items))}
	   end,
    ft_query(Tfun, Cookie, "SHOW TABLES").


%returns a list of {column_id, column_name, column_type} tuples of table columns
describe_table(Cookie, TableID) ->
    Cfun = fun(Y) ->
		   {match, [ColID, ColName, ColType]} = re:run(Y, "(.+),(.+),(.+)", [{capture, [1,2,3], list}]),
		   {ColID, ColName, ColType}
	   end,
    Tfun = fun(X) ->
		   [_ | TItems] = re:split(X, "\n"),
		   [_| Items] = lists:reverse(TItems),
		   {ok, lists:map(Cfun, lists:reverse(Items))}
	   end,
    ft_query(Tfun, Cookie, "DESCRIBE " ++ TableID).
    

ft_query(Callback, Cookie, FTQuery, BreakLines) ->
    Tfun = fun(X) ->
		   [_ | TItems] = re:split(X, "\n"),
		   [_| Items] = lists:reverse(TItems),
		   lists:reverse(Items)
	   end,
    case BreakLines of
	true -> 
	    Tdata = erlftutils:http_request(Tfun, post, {?API_URL, [{"Authorization", "GoogleLogin auth=" ++ Cookie}], "application/x-www-form-urlencoded", erlftutils:url_encode([{"sql", FTQuery}])}, [{ssl, [{verify,0}] }, {autoredirect, false} ], []),
	    Callback(Tdata);
	false ->
	    erlftutils:http_request(Callback, post, {?API_URL, [{"Authorization", "GoogleLogin auth=" ++ Cookie}], "application/x-www-form-urlencoded", erlftutils:url_encode([{"sql", FTQuery}])}, [{ssl, [{verify,0}] }, {autoredirect, false} ], [])

    end.

ft_query(Callback, Cookie, FTQuery) ->
    ft_query(Callback, Cookie, FTQuery, false).
