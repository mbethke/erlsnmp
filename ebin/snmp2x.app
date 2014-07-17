{application, snmp2x, [
{description, "An SNMP collector that can output to Graphite and other backends"},
{vsn, "0.0.1"},
{modules, [snmp2x, snmp2x_config]},
{registered, [snmp2x]},
{mod, {snmp2x, []}},
{env, [
{host_config, "hosts-fin.cfg"},
{class_config, "classes.cfg"},
]
]}.
