-module(snmp2x).

-export([main/1]).

main(Args) ->
    Options = [
        {engine_id, "engine"},
        {community, "public"},
        {version, v2},
        {address, "localhost"},
        {timeout, 2000}
    ],
    start_manager(),
    ok = snmpm:register_agent(snmp_user, "localhost", Options),
    Cfg = snmp2x_config:get(),
    orddict:fold(fun(_, OIDs, _) -> query(OIDs) end, 0, Cfg).

start_manager() ->
    try snmpm:start() of
        _ -> ok
        catch
            error:_ -> ok
    end,
    case snmpm:which_agents(snmp_user) of
        [] -> ok;
        _ -> snmpm:unregister_agent(snmp_user, "localhost")
    end,
    snmpm:register_user(snmp_user, snmp_user, undefined).

query(Args) ->
    case snmpm:async_get(snmp_user, "localhost", Args) of
        {ok, ReqId} -> ReqId;
        {error, Reason} -> throw(snmpm:format_reason(Reason))
    end.
    
