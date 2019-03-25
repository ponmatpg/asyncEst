\l random.q
\l util.q

.asyncE.p.genDT:{[date;START_TIME_F;nrowsDay;MILLISECONDS_PER_DAY] 
		asc date + `time$START_TIME_F + nrowsDay?MILLISECONDS_PER_DAY
	};

.asyncE.p.midGeneratorDate:{[dateData;dataName;timeOptions;options]
	MILLISECONDS_PER_DAY: `float$(`time$timeOptions[`maxTime] - timeOptions[`minTime]);
	START_TIME_F: `float$`time$timeOptions[`minTime];
	
	date: dateData[0];
	P0: dateData[1];
	normalSampling: dateData[2];

	// generate list of dateTimes
	dateTimes: .asyncE.p.genDT[date;START_TIME_F;timeOptions[`nrowsDay];MILLISECONDS_PER_DAY];

	// create table, sorting on dateTimes
	timeDeltasSeconds: (`float$ deltas dateTimes - dateTimes[0]) % 1e9; 

	// generate data series 
	volSeconds: options[`volSeconds];
	driftSeconds: options[`driftSeconds];

	gbm: timeDeltasSeconds .random.gbm[volSeconds;driftSeconds;;]' normalSampling;
	dataSeries: P0 * prds gbm;
	(`ts,enlist dataName) xcol ([] ts:dateTimes; data:dataSeries)
	};

.asyncE.midGenerator:{[dataName;normalSamples;timeOptions;options]
	MILLISECONDS_PER_DAY: `float$(`time$timeOptions[`maxTime] - timeOptions[`minTime]);

	// generate list of distinct dates
	dates: .util.weekdays timeOptions[`minD] + til (timeOptions[`maxD] - timeOptions[`minD]);

	// generate starting values for each date 
	normalSampling: .random.normal[0;1;count dates];
	volSeconds: options[`volSeconds];
	driftSeconds: options[`driftSeconds];

	normalSamplingStartValues: (count dates)#normalSamples[0];
	gbm: ((count dates)#(MILLISECONDS_PER_DAY % 1e3)) .random.gbm[volSeconds;driftSeconds;;]' normalSamplingStartValues;
	startValues: options[`P0] * prds gbm;
	dateDataList: flip (dates;startValues;normalSamples);

	:raze .asyncE.p.midGeneratorDate[;dataName;timeOptions;options] each dateDataList; 
	};	

.asyncE.corrMidGenerator:{[dataName1;dataName2;timeOptions;options1;options2;corr]
	// generate correlated samples
	dates: .util.weekdays timeOptions[`minD] + til (timeOptions[`maxD] - timeOptions[`minD]);

	normalSamples: flip .random.corrNormal[0;1;;corr] each (count dates)#timeOptions[`nrowsDay];
	
	output1: .asyncE.midGenerator[dataName1;normalSamples[0];timeOptions;options1]; 
	output2: .asyncE.midGenerator[dataName2;normalSamples[1];timeOptions;options2]; 

	:(output1;output2);
	};	

.asyncE.priceData:{[symName;options;spreadOptions]
	tbl: .asyncE.midGenerator[`m;options];
	// generate random spreads to construct bid-offer from mid-prices in tbl
	spread: (count tbl)?`float$(spreadOptions[`maxS] - spreadOptions[`minS]);

	/ add spread column to table 
	tbl: update s: spread from tbl;

	/ add bid-offer columns to table 
	tbl: update b: m - 0.5 * s, o: m + 0.5 * s from tbl;

	/ sort columns 
	`ts`b`m`o`s xcols tbl
	};

// shifts data by "shift" number of rows 
.asyncE.dataShift:{[tbl;dataCol;shift]
	/shift data, ts
	shifted_ts: shift xprev ?[tbl;();();`ts];
	shifted_data: shift xprev ?[tbl;();();dataCol];
	
	tbl: ![tbl;();0b;(`shift_ts,dataCol)!((enlist shifted_ts),enlist shifted_data)];

	/ remove any data that was shifted across dates
	tbl: select from tbl where (shift_ts.date=ts.date) or (shift_ts=0n);

	delete shift_ts from tbl
	};

// shifts data by "shiftSeconds"  number of seconds
.asyncE.dataShiftSeconds:{[tbl;dataCol;shiftSeconds]
	/shift data, ts by shiftSeconds
	shifted_ts: ?[tbl;();();`ts] + `timespan$ 1e9 * shiftSeconds;
	shifted_data_tbl: ?[tbl;();0b;(`ts`shift_ts,dataCol)!((enlist shifted_ts), (enlist shifted_ts),enlist dataCol)];

	/ asof-join data with shifted ts back into table
	tbl: aj[(,)`ts; ![tbl;();0b;enlist dataCol] ;shifted_data_tbl];

	/ remove any data that was shifted across dates
	tbl: select from tbl where (shift_ts.date=ts.date) or (shift_ts=0n);

	delete shift_ts from tbl
	};

.asyncE.addReturns:{[tbl;dataCol;rType]
	getColName:{[rType;dataCol] `$"r_", string[rType], "_" ,string[dataCol]};
	colName: getColName[rType;dataCol];

	$[rType=`log;
			returnFunction: .util.log_r;
		rType=`simple;
			returnFunction: .util.simple_r;
		rType=`delta;
			returnFunction: .util.delta_r;
			returnFunction: {x}; // defaults to identity function
		];

	tbl:?[tbl;();0b;(`ts;colName)!(`ts;(returnFunction;dataCol))];

	// remove entries where returns where added across dates
	tbl: update prevts: prev[ts] from tbl;
	:delete prevts from select from tbl where ts.date=prevts.date;
	};

.asyncE.HYest:{[data1;data2]
	// data should be of the format ts, dataCol
	cols1: enlist[`ts], cols[data1] except `ts;
	cols2: enlist[`ts], cols[data2] except `ts;

	/ sort columns in both tables as ts, dataCol
	data1: cols1 xcols data1;
	data2: cols2 xcols data2;

	/ replace dataCol names with standardized 
	data1: `ts1`col1 xcol data1;
	data2: `ts2`col2 xcol data2;

	// union join the data, create a combined ts col from ts1 and ts1 and sort
	// on that column. The function fills only fills forward (and we want a backwards fill) so we sort descending
	// then fill, and then reverse order of the rows to get an ascending sort
	// with a backwards fill 
	data: reverse fills `ts xdesc update ts: ?[ts1=0n;ts2;ts1] from data1 uj data2;
	
	covar: exec sum col1 * col2 from data;
	var1: exec sum col1 * col1 from data;
	var2: exec sum col2 * col2 from data; 

	:covar % sqrt[var1 * var2];
	};







 