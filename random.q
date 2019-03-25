

// WARN: USES SUM OF UNIFORM APPROXIMATIONS
// WILL BE REPLACED WITH SOMETHING MORE ROBUST
.random.normal:{[mu;sigma;size]
	mu + sigma * raze {sum[12?1f] - 6f} each til size
	};

.random.gbm:{[vol;mu;dt;z]
	exp ((dt * mu - 0.5 * vol * vol) + vol * z * sqrt dt)
	};

.random.corrNormal:{[mu;sigma;size;corr]
	z1: .random.normal[mu;sigma;size];
	z2: .random.normal[mu;sigma;size];

	z2: (corr * z1) + (sqrt[1 - corr * corr] * z2);
	:(z1;z2);
	};


// test normal
/
mu: 0;
sigma: 1;
size:10000000;
corr: 0.9;

show (.random.normal[mu;sigma;size]) cor (.random.normal[mu;sigma;size]);
corrsampling: .random.corrNormal[mu;sigma;size;corr];
show corrsampling[0] cor corrsampling[1];

\
