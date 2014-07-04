-module(snmp2x_config).

-export([get/1]).

-record(host, { address, class=switch }).
-record(class, { name, oids=[] }).
-record(config, { hosts=[], classes=[] }).

% Generate an expanded config that uses orddicts
get(File) ->
    C = #config{
        hosts=
               read_host_config(File) 
            %#host{address="localhost", class=computer},
            %#host{address="10.0.0.16", class=switch}
        ,
        classes=[
            #class{name=computer, oids=[".1.3.6.1.2.1.1.3.0"]},
            #class{name=switch48, oids=[".1.3.6.1.2.1.2.2.1.10.1",
                                        ".1.3.6.1.2.1.2.2.1.10.2",
                                        ".1.3.6.1.2.1.2.2.1.10.3"
                                       ]
                  }
        ]
    },
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

read_host_config(File) ->
    {ok, Bin} = file:read_file(File),
    parse_file(binary_to_list(Bin)).
 
parse_file(Str) when is_list(Str) ->
    [line_to_host_record(Line) || Line <- string:tokens(Str,"\n")].

line_to_host_record(Line) ->
    T = string:tokens(Line, " \t"),
    #host{address=hd(T), class=list_to_atom(hd(tl(T)))}.
