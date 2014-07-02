-module(mysnmp).

-export([main/1]).

query(Args) ->
    case snmpm:async_get(snmp_user, "localhost", Args) of
        {ok, ReqId} -> ReqId;
        {error, Reason} -> throw(snmpm:format_reason(Reason))
    end.
    
main(Args) ->
	Options = [
        {engine_id, "engine"},
        {community, "public"},
        {version, v2},
        {address, "localhost"},
        {timeout, 2000}
    ],
    try snmpm:start() of
        _ -> ok
        catch
        error:Error -> ok
    end,
    case snmpm:which_agents(snmp_user) of
        [] -> ok;
        _ -> snmpm:unregister_agent(snmp_user, "localhost")
    end,
    snmpm:register_user(snmp_user, snmp_user, undefined),
    ok = snmpm:register_agent(snmp_user, "localhost", Options),
    %query([1,3,6,1,2,1,1,3,0]).
    query(lists:map(
            fun(Arg) -> [list_to_integer(N) || N <- string:tokens(Arg, ".")] end,
            string:tokens(Args," ")
        )
    ).
