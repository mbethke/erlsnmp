-module(mysnmp).

-export([main/1]).

-record(host, { address, class=switch }).
-record(class, { name, oids=[] }).
-record(config, { hosts=[], classes=[] }).

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
    Config = #config{
        hosts=[
            #host{address="localhost", class=computer},
            #host{address="10.0.0.16", class=switch}
        ],
        classes=[
            #class{name=computer, oids=[".1.3.6.1.2.1.1.3.0"]},
            #class{name=switch, oids=[".1.3.6.1.2.1", ".1.2.3"]}
        ]
    },
    start_manager(),
    ok = snmpm:register_agent(snmp_user, "localhost", Options),
    Cfg = expand_config(Config),
    orddict:fold(fun(_, OIDs, _) -> query(OIDs) end, 0, Cfg).

% Generate an expanded config that uses orddicts
expand_config(C) ->
    Classes = lists:foldl(
        fun(Cls, Acc) -> orddict:store(Cls#class.name, Cls#class.oids, Acc) end,
        orddict:new(),
        C#config.classes
    ),
    lists:foldl(
        fun(H, Acc) -> orddict:store(H#host.address, get_host_oids(H, Classes), Acc) end,
        orddict:new(),
        C#config.hosts
    ).
    
get_host_oids(H=#host{}, Classes) ->
    case orddict:find(H#host.class, Classes) of
        {ok, Oids} -> oids_to_int(Oids);
        error -> throw(invalid_config)
    end.

oids_to_int(OIDs) ->
    lists:map(
        fun(Arg) -> [ list_to_integer(N) || N <- string:tokens(Arg, ".") ] end,
        OIDs
    ).

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

