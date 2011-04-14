-module(erlftclientlogin).
-export([authorize/2]).

-define(LOGIN_URL, "https://www.google.com/accounts/ClientLogin").


%takes username and password and returns an authorization cookie if ok
authorize(Email, Password) ->
    Tfun = fun(X) ->
		   case re:run(X, "Auth=(.*)\n$", [{capture, [1], list}]) of
		       {match, [Cookie]} ->
			   {ok, Cookie};
		       _ -> {error, "Could not find cookie"}
		   end
	   end,

    erlftutils:http_request(Tfun, post, {?LOGIN_URL, [], "application/x-www-form-urlencoded", erlftutils:url_encode([{"Email", Email}, {"Passwd", Password}, {"service", "fusiontables"}, {"accountType", "HOSTED_OR_GOOGLE"}])}, [{ssl, [{verify,0}] }, {autoredirect, false} ], []).
