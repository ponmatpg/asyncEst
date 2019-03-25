\l asyncEst.q 

timeOptions:(`minD`maxD`minTime`maxTime`nrowsDay)!(2018.01.01;2018.01.31;09:30;16:00;`int$5e2);
SECONDSPERDAY: `second$(timeOptions[`maxTime] - timeOptions[`minTime]);

options1: (`P0`volSeconds`driftSeconds)!(2500;(0.25%250) % SECONDSPERDAY;(0.2%250) % SECONDSPERDAY);
options2: (`P0`volSeconds`driftSeconds)!(70;(0.3%250) % SECONDSPERDAY;(0.1%250) % SECONDSPERDAY)


show options1[`driftSeconds];

spreadOptions: (`minS`maxS)!(0;.5);
corr:0.8;

output: .asyncE.corrMidGenerator[`SPX;`HG;timeOptions;options1;options2;corr]
show select last SPX by ts.date from output[0];
show select last HG by ts.date from output[1];

data1: .asyncE.addReturns[output[0];`SPX;`delta];
data2: .asyncE.addReturns[output[1];`HG;`delta];

show " ";
show count each (data1;data2);
show " ";
show (exec r_delta_SPX from data1) cor (exec r_delta_HG from data2);
/show (exec r_log_SPX from data1) cor (exec r_log_HG from data2);
show " ";
HYest: .asyncE.HYest[data1;data2];
show HYest;





