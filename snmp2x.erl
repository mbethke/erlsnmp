-module(snmp2x).

-export([main/1, host_process/1]).

main(Args) ->
    start_manager(),
    Cfg = snmp2x_config:get(Args),
    register_snmp_agents(Cfg),
    run_queries(Cfg),
    ok.

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

run_queries(Cfg) ->
    orddict:fold(fun(Host, OIDs, _) -> spawn_host_proc(Host, OIDs) end, 0, Cfg).

spawn_host_proc(Host, OIDs) ->
    spawn_link(?MODULE, host_process, [{Host, OIDs}]).

host_process(S={Host,OIDs}) ->
    query(Host, OIDs),
    timer:sleep(3000),
    host_process(S).

query(Host, OIDs) ->
    case snmpm:async_get(snmp_user, Host, OIDs) of
        {ok, ReqId} -> ReqId;
        {error, Reason} -> throw(snmpm:format_reason(Reason))
    end.
    
register_snmp_agents(Cfg) ->
    orddict:fold(fun(Host, _, _) -> register_snmp_agent(Host) end, 0, Cfg).

register_snmp_agent(Host) ->
    Options = [
        {engine_id, "engine"},
        {community, "public"},
        {version, v2},
        {address, Host},
        {timeout, 2000}
    ],
    snmpm:register_agent(snmp_user, Host, Options).

