{smcl}
{* November 5, 2025 @ 18:33:19}{...}
{title:ddplot}

{p 4 4 2}
{cmd:ddplot} creates plots of dynamic difference-in-differences estimates 
from a regression of the form: {cmd:reg y i.treat##i.year}

{title:Syntax}

{p 8 8 2}
{cmd:ddplot} [{cmd:,} options]

{title:Options}

{p 4 8 2}
{cmd:treat(varname)}        treatment indicator variable 
(default: {it:treat})

{p 4 8 2}
{cmd:year(varname)}         time indicator variable 
(default: {it:year})

{p 4 8 2}
{cmd:rspike}                show confidence intervals using 
{cmd: rspike} bars instead of a shaded {cmd:rarea}

{p 4 8 2}
{cmd:[no]label}             use value labels on the x-axis 
(default: {cmd:label})

{p 4 8 2}
Any other options are passed directly to the underlying 
{helpb twoway} graph command (e.g. {cmd:xtitle()}, {cmd:ytitle()}, 
{cmd:title()}, {cmd:subtitle()}, etc.)

{title:Notes}

{p 4 4 2}• Expects active regression results ({cmd:e(b)}) from 
{cmd:reg y i.treat##i.year}

{p 4 4 2}• Plots all interaction terms of the form 
{cmd:1.treat#i.year}

{title:Example}

{p 8 8 2}
{cmd:. reg y i.treat##i.year}{break}
{cmd:. ddplot, xtitle(Years since reform) title(Event study)}

{title:Stored results}

{p 4 4 2}
{cmd:ddplot} stores the following in {cmd:r()}:

{col 8}{cmd:r(cmd)}{col 20}twoway command used to produce the graph

{title:Author}

{p 4 4 2}Michael Smart — Version 1.0
