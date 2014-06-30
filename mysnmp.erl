-module(mysnmp).

-export([main/1]).

% 1.3.6.1.2.1.1.3.0
query(Args) ->
    ok = snmpm:async_get(snmp_user, "localhost", ".1.3.6.1.2.1.1.3.0").
    
main(Args) ->
	Options = [
        {engine_id, "engine"},
        {community, "public"},
        {version, v2c},
        {address, "localhost"},
        {timeout, 2000}
    ],
    snmpm:start(),
    snmpm:register_user(snmp_user, snmp_user, undefined),
    snmpm:register_agent(snmp_user, "localhost", Options),
    query(string:tokens(Args," ")).
