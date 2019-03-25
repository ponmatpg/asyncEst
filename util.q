
// filters a list of dates for weekdays 
.util.weekdays:{[dates]
	if[-14h <> type dates;
		dates: `date$dates;
		];
	
	dates where not (dates mod 7) in 0 1
	};

.util.log_r: {100 * log[x%prev[x]]};
.util.simple_r: {100 * (x - prev[x]) % prev[x]};
.util.delta_r: {deltas x};


