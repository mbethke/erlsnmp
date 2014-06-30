-module(mysnmp).

-export([main/1]).

% 1.3.6.1.2.1.1.3.0
query([]) ->
    query([".1.3.6.1.2.1.1.3.0"]);
query(Args) ->
    case snmpm:async_get(snmp_user, "localhost", Args) of
        {ok, ReqId} -> ReqId;
        {error, Reason} -> throw(Reason)
    end.
    
main(Args) ->
	Options = [
        {engine_id, "engine"},
        {community, "public"},
        {version, v2c},
        {address, "localhost"},
        {timeout, 2000}
    ],
    try snmpm:start() of
        _ -> ok
        catch
        error:Error -> ok
    end,
    snmpm:register_user(snmp_user, snmp_user, undefined),
    snmpm:register_agent(snmp_user, "localhost", Options),
    query(string:tokens(Args," ")).
