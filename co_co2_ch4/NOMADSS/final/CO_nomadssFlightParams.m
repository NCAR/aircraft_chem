function [CalLimit,CalMax,ch4calLow,ch4calMax,cavPLow,cavPMax,ZeroLimit,co2calLow,co2calMax,o3Low,before,...
    after,DataAfterCal,ptsToAvg,tankCon,co2tankCon,toffset,badCals,picBadCals1301,picBadCals2311,badZs,...
    tOrd2,tSlope,tInt,tShift1301,tShift2311,tShiftHold1301,tShiftHold2311,negTime]=CO_nomadssFlightParams(Flight)
%
%CO_nomadssFlightParams
%
%Dialog box assigns Flight dependent variables:
%	*minimum concentration for CO calibration
%	*Enter maximum concentration for CO zero
%	*number of points before change in calibration status to remove
%	*number of points after change in calibration status to remove
%	*number of data points to remove after calibration
%
%The last three items flag removed data with '-99'
%
%Version 2: 6/06/12 Updated through flight rf08 and added O3Low, Carolyn
%Farris

prompt  = {'Enter minimum counts for CO calibration:',...
      'Enter maximum counts for CO calibration:',...
      'Enter maximum counts for CO zero:',...
      'Enter number of points before change in calibration status to remove',...
      'Enter number of points after change in calibration status to remove',...
      'Enter number of data points to remove after calibration',...
      'Enter number of data points to average for calibration curve fitting',...
      'Enter calibration gas concentration (ppbv)',...
      'Enter time offset in seconds (positive value moves CO earlier):'};
title   = 'Inputs for CO status calculation';
lines= 1;
            o3Low = 5; 
            before = 20;
            after = 20;
            DataAfterCal = 30;
            ptsToAvg = 10;
             tankCon = 71; % nominal CO acc SMI analyses IFP May-Jul, 2013
%              co2tankCon = 382; % ditto for CO2; methane anal 1.7  Value
%              used for archived Field data
             co2tankCon = 383.94; % Analyzed working standard conc (pre and post cals); 
%              CH4 wkg analyzed to be 1701 ppbv in June and July, 2013
%              measmts.  TLC

                switch char(Flight)
                    case 'tf01'
                        CalLimit= 13000;
                        CalMax = 18000;
                        ch4calLow = 1.64;
                        ch4calMax = 1.74;
                        co2calLow = 379;
                        co2calMax = 384;
                        cavPLow = 139.45;           %Need to see if cavP is different between the picarros
                        cavPMax = 140.35;
                        ZeroLimit = 8000;
                        toffset = 0; 
                        badCals = [];
                        picBadCals1301 = [];
                        picBadCals2311 = [];
                        badZs = [];
                        tOrd2=0;
                        tSlope=1.000;
                        tInt=0;
                        % All below this line for raw Picarro data processing
                        tShift1301 = 0; %Time in sec to shift raw picarro data to align with RAF data system time
                        tShift2311 = 0;
                        tShiftHold1301 = 0; %Set to 1 when tShift variable should not be modified further
                        tShiftHold2311 = 0;
                        negTime = 0;    %For 1301 only (as far as we know), MatLab will error out trying to interpolate if negTime exists
                                                %- 'not sequenced in strict monotonic order'
                    case 'tf02'
                        CalLimit= 13000;
                        CalMax = 18000;
                        ch4calLow = 1.64;
                        ch4calMax = 1.74;                        
                        co2calLow = 379;
                        co2calMax = 384;
                        cavPLow = 139.45;
                        cavPMax = 140.35;
                        ZeroLimit = 8000;
                        toffset = 0; 
                        badCals = [];
                        picBadCals1301 = [];
                        picBadCals2311 = [];
                        badZs = [];
                        tOrd2=0;
                        tSlope=1.000;
                        tInt=0;
                        % 
                        tShift1301 = 0; 
                        tShiftHold1301 = 0;
                        tShift2311 = 0; 
                        tShiftHold2311 = 0;
                        negTime = 0; 
                    case 'ff01'
                        CalLimit= 13000;
                        CalMax = 18000;
                        ch4calLow = 1.64;
                        ch4calMax = 1.74;                        
                        co2calLow = 379;
                        co2calMax = 384;
                        cavPLow = 139.45;
                        cavPMax = 140.35;
                        ZeroLimit = 8000;
                        toffset = 0; 
                        badCals = [];
                        picBadCals1301 = [];
                        picBadCals2311 = [];
                        badZs = [];
                        tOrd2=0;
                        tSlope=1.000;
                        tInt=0;
                        % 
                        tShift1301 = 0; 
                        tShiftHold1301 = 0;
                        tShift2311 = 0; 
                        tShiftHold2311 = 0;
                        negTime = 0;
                    case 'rf01'
                        CalLimit= 13000;
                        CalMax = 18000;
                        ch4calLow = 1.64;
                        ch4calMax = 1.74;                        
                        co2calLow = 379;
                        co2calMax = 384;
                        cavPLow = 139.45;
                        cavPMax = 140.35;
                        ZeroLimit = 8000;
                        toffset = 0; 
                        badCals = [];
                        picBadCals1301 = [];
                        picBadCals2311 = [];
                        badZs = [];
                        tOrd2=0;
                        tSlope=1.000;
                        tInt=0;
                        % 
                        tShift1301 = 0; 
                        tShiftHold1301 = 0;
                        tShift2311 = 0; 
                        tShiftHold2311 = 0;
                        negTime = 0;
                    case 'rf02'
                        CalLimit= 13000;
                        CalMax = 20000;
                        ch4calLow = 1.64;
                        ch4calMax = 1.74;                        
                        co2calLow = 379;
                        co2calMax = 384;
                        cavPLow = 139.45;
                        cavPMax = 140.35;
                        ZeroLimit = 8000;
                        toffset = 0; 
                        badCals = [];
                        picBadCals1301 = [];
                        picBadCals2311 = [];
                        badZs = [];
                        tOrd2=0;
                        tSlope=1.000;
                        tInt=0;
                        % 
                        tShift1301 = 0; 
                        tShiftHold1301 = 0;
                        tShift2311 = 0; 
                        tShiftHold2311 = 0;
                        negTime = 0;
                    case 'rf03'
                        CalLimit= 13000;
                        CalMax = 20000;
                        ch4calLow = 1.64;
                        ch4calMax = 1.74;                        
                        co2calLow = 379;
                        co2calMax = 384;
                        cavPLow = 139.45;
                        cavPMax = 140.35;
                        ZeroLimit = 8000;
                        toffset = 0; 
                        badCals = [];
                        picBadCals1301 = [];
                        picBadCals2311 = [];
                        badZs = [];
                        tOrd2=0;
                        tSlope=1.000;
                        tInt=0;
                        % 
                        tShift1301 = 0; 
                        tShiftHold1301 = 0;
                        tShift2311 = 0; 
                        tShiftHold2311 = 0;
                        negTime = 0;
                    case 'rf04'             
                        CalLimit= 13000;
                        CalMax = 20000;
                        ch4calLow = 1.64;
                        ch4calMax = 1.74;                        
                        co2calLow = 379;
                        co2calMax = 384;
                        cavPLow = 139.45;
                        cavPMax = 140.35;
                        ZeroLimit = 8000;
                        toffset = 0; 
                        badCals = [];
                        picBadCals1301 = [];
                        picBadCals2311 = [];
                        badZs = [];
                        tOrd2=0;
                        tSlope=1.000;
                        tInt=0;
                        % 
                        tShift1301 = 0; 
                        tShiftHold1301 = 0;
                        tShift2311 = 0; 
                        tShiftHold2311 = 0;
                        negTime = 0;
                    case 'rf05'
                        CalLimit= 0;
                        CalMax = 20000;
                        ch4calLow = 1.64;
                        ch4calMax = 1.74;                        
                        co2calLow = 379;
                        co2calMax = 384;
                        cavPLow = 139.45;
                        cavPMax = 140.35;
                        ZeroLimit = 8000;
                        toffset = 0; 
                        badCals = [];
                        picBadCals1301 = [];
                        picBadCals2311 = [];
                        badZs = [];
                        tOrd2=0;
                        tSlope=1.000;
                        tInt=0;
                        % 
                        tShift1301 = 0; 
                        tShiftHold1301 = 0;
                        tShift2311 = -125; 
                        tShiftHold2311 = 0;
                        negTime = 0;
                    case 'rf06'
                        CalLimit= 9500;
                        CalMax = 12000;
                        ch4calLow = 1.64;
                        ch4calMax = 1.74;                        
                        co2calLow = 365;
                        co2calMax = 384;
                        cavPLow = 139.45;
                        cavPMax = 140.35;
                        ZeroLimit = 8000;
                        toffset = 0; 
                        badCals = [];
                        picBadCals1301 = [4,5];
                        picBadCals2311 = [];
                        badZs = [];
                        tOrd2=0;
                        tSlope=1.000;
                        tInt=0;
                        % 
                        tShift1301 = 0; 
                        tShiftHold1301 = 0;
                        tShift2311 = 0; 
                        tShiftHold2311 = 0;
                        negTime = 1;
                    case 'rf07'
                        CalLimit= 9500;
                        CalMax = 15000;
                        ch4calLow = 1.64;
                        ch4calMax = 1.74;                        
                        co2calLow = 379;
                        co2calMax = 384;
                        cavPLow = 139.45;
                        cavPMax = 140.35;
                        ZeroLimit = 8000;
                        toffset = 0; 
                        badCals = [];
                        picBadCals1301 = [];
                        picBadCals2311 = [];
                        badZs = [];
                        tOrd2=0;
                        tSlope=1.000;
                        tInt=0;
                        % 
                        tShift1301 = 0; 
                        tShiftHold1301 = 0;
                        tShift2311 = 0; 
                        tShiftHold2311 = 0;
                        negTime = 0;
                    case 'rf08'
                        CalLimit= 9500;
                        CalMax = 16000;
                        ch4calLow = 1.64;
                        ch4calMax = 1.74;                        
                        co2calLow = 379;
                        co2calMax = 384;
                        cavPLow = 139.45;
                        cavPMax = 140.35;
                        ZeroLimit = 8000;
                        toffset = 0; 
                        badCals = [];
                        picBadCals1301 = [];
                        picBadCals2311 = [];
                        badZs = [];
                        tOrd2=0;
                        tSlope=1.000;
                        tInt=0;
                        % 
                        tShift1301 = 0; 
                        tShiftHold1301 = 0;
                        tShift2311 = 0; 
                        tShiftHold2311 = 0;
                        negTime = 0;
                    case 'rf09'
                        CalLimit= 9500;
                        CalMax = 18000;
                        ch4calLow = 1.64;
                        ch4calMax = 1.74;                        
                        co2calLow = 379;
                        co2calMax = 384;
                        cavPLow = 139.45;
                        cavPMax = 140.35;
                        ZeroLimit = 8000;
                        toffset = 0; 
                        badCals = [];
                        picBadCals1301 = [];
                        picBadCals2311 = [];
                        badZs = [];
                        tOrd2=0;
                        tSlope=1.000;
                        tInt=0;
                        % 
                        tShift1301 = 0; 
                        tShiftHold1301 = 0;
                        tShift2311 = 0; 
                        tShiftHold2311 = 0;
                        negTime = 0;
                    case 'rf10'
                        CalLimit= 11000;
                        CalMax = 13500;
                        ch4calLow = 1.69;
                        ch4calMax = 1.71;                        
                        co2calLow = 379;
                        co2calMax = 384;
                        cavPLow = 139.45;
                        cavPMax = 140.35;
                        ZeroLimit = 8000;
                        toffset = 0; 
                        badCals = [];
                        picBadCals1301 = [];
                        picBadCals2311 = [];
                        badZs = [];
                        tOrd2=0;
                        tSlope=1.000;
                        tInt=0;
                        % 
                        tShift1301 = 5; 
                        tShiftHold1301 = 1;
                        tShift2311 = 3; 
                        tShiftHold2311 = 1;
                        negTime = 1;
                    case 'rf11'
                        CalLimit= 13000;
                        CalMax = 20000;
                        ch4calLow = 1.69;
                        ch4calMax = 1.71;                        
                        co2calLow = 379;
                        co2calMax = 384;
                        cavPLow = 139.45;
                        cavPMax = 140.35;
                        ZeroLimit = 8000;
                        toffset = 0; 
                        badCals = [];
                        picBadCals1301 = [];
                        picBadCals2311 = [];
                        badZs = [];
                        tOrd2=0;
                        tSlope=1.000;
                        tInt=0;
                        % 
                        tShift1301 = 3; 
                        tShiftHold1301 = 1;
                        tShift2311 = 2; 
                        tShiftHold2311 = 1;
                        negTime = 1;
                    case 'rf12'
                        CalLimit= 13000;
                        CalMax = 20000;
                        ch4calLow = 1.69;
                        ch4calMax = 1.71;                        
                        co2calLow = 379;
                        co2calMax = 384;
                        cavPLow = 139.45;
                        cavPMax = 140.35;
                        ZeroLimit = 8000;
                        toffset = 0; 
                        badCals = [];
                        picBadCals1301 = [];
                        picBadCals2311 = [];
                        badZs = [];
                        tOrd2=0;
                        tSlope=1.000;
                        tInt=0;
                        % 
                        tShift1301 = 3; 
                        tShiftHold1301 = 1;
                        tShift2311 = 2; 
                        tShiftHold2311 = 1;
                        negTime = 1;    
                    case 'rf13'
                        CalLimit= 13000;
                        CalMax = 20000;
                        ch4calLow = 1.69;
                        ch4calMax = 1.71;                        
                        co2calLow = 379;
                        co2calMax = 384;
                        cavPLow = 139.45;
                        cavPMax = 140.35;
                        ZeroLimit = 8000;
                        toffset = 0; 
                        badCals = [];
                        picBadCals1301 = [1];
                        picBadCals2311 = [];
                        badZs = [];
                        tOrd2=0;
                        tSlope=1.000;
                        tInt=0;
                        % 
                        tShift1301 = 3; 
                        tShiftHold1301 = 1;
                        tShift2311 = 2; 
                        tShiftHold2311 = 1;
                        negTime = 0;
                    case 'rf14'
                        CalLimit= 13000;
                        CalMax = 20000;
                        ch4calLow = 1.69;
                        ch4calMax = 1.71;                        
                        co2calLow = 379;
                        co2calMax = 384;
                        cavPLow = 139.45;
                        cavPMax = 140.35;
                        ZeroLimit = 8000;
                        toffset = 0; 
                        badCals = [];
                        picBadCals1301 = [];
                        picBadCals2311 = [];
                        badZs = [7];
                        tOrd2=0;
                        tSlope=1.000;
                        tInt=0;
                        % 
                        tShift1301 = 3; 
                        tShiftHold1301 = 1;
                        tShift2311 = 3; 
                        tShiftHold2311 = 1;
                        negTime = 1;
                    case 'rf15'
                        CalLimit= 13000;
                        CalMax = 20000;
                        ch4calLow = 1.69;
                        ch4calMax = 1.71;                        
                        co2calLow = 379;
                        co2calMax = 384;
                        cavPLow = 139.45;
                        cavPMax = 140.35;
                        ZeroLimit = 8000;
                        toffset = 0; 
                        badCals = [];
                        picBadCals1301 = [];
                        picBadCals2311 = [];
                        badZs = [];
                        tOrd2=0;
                        tSlope=1.000;
                        tInt=0;
                        % 
                        tShift1301 = 4; 
                        tShiftHold1301 = 1;
                        tShift2311 = 3; 
                        tShiftHold2311 = 1;
                        negTime = 1;
                    case 'rf16'
                        CalLimit= 13000;
                        CalMax = 20000;
                        ch4calLow = 1.69;
                        ch4calMax = 1.71;                        
                        co2calLow = 379;
                        co2calMax = 384;
                        cavPLow = 139.45;
                        cavPMax = 140.35;
                        ZeroLimit = 8000;
                        toffset = 0; 
                        badCals = [];
                        picBadCals1301 = [];
                        picBadCals2311 = [];
                        badZs = [];
                        tOrd2=0;
                        tSlope=1.000;
                        tInt=0;
                        % 
                        tShift1301 = 3; 
                        tShiftHold1301 = 1;
                        tShift2311 = 3; 
                        tShiftHold2311 = 1;
                        negTime = 1;
                    case 'rf17'
                        CalLimit= 13000;
                        CalMax = 20000;
                        ch4calLow = 1.69;
                        ch4calMax = 1.71;                        
                        co2calLow = 379;
                        co2calMax = 384;
                        cavPLow = 139.45;
                        cavPMax = 140.35;
                        ZeroLimit = 8000;
                        toffset = 0; 
                        badCals = [];
                        picBadCals1301 = [];
                        picBadCals2311 = [];
                        badZs = [];
                        tOrd2=0;
                        tSlope=1.000;
                        tInt=0;
                        % 
                        tShift1301 = 3; 
                        tShiftHold1301 = 1;
                        tShift2311 = 3; 
                        tShiftHold2311 = 1;
                        negTime = 1;
                    case 'rf18'
                        CalLimit= 13000;
                        CalMax = 20000;
                        ch4calLow = 1.69;
                        ch4calMax = 1.71;                        
                        co2calLow = 379;
                        co2calMax = 384;
                        cavPLow = 139.45;
                        cavPMax = 140.35;
                        ZeroLimit = 8000;
                        toffset = 0; 
                        badCals = [];
                        picBadCals1301 = [];
                        picBadCals2311 = [];
                        badZs = [];
                        tOrd2=0;
                        tSlope=1.000;
                        tInt=0;
                        % 
                        tShift1301 = 3; 
                        tShiftHold1301 = 1;
                        tShift2311 = 3; 
                        tShiftHold2311 = 1;
                        negTime = 1;
                    case 'rf19'
                        CalLimit= 13000;
                        CalMax = 20000;
                        ch4calLow = 1.69;
                        ch4calMax = 1.71;                        
                        co2calLow = 379;
                        co2calMax = 384;
                        cavPLow = 139.45;
                        cavPMax = 140.35;
                        ZeroLimit = 8000;
                        toffset = 0; 
                        badCals = [];
                        picBadCals1301 = [];
                        picBadCals2311 = [];
                        badZs = [];
                        tOrd2=0;
                        tSlope=1.000;
                        tInt=0;
                        % 
                        tShift1301 = 3; 
                        tShiftHold1301 = 1;
                        tShift2311 = 3; 
                        tShiftHold2311 = 1;
                        negTime = 1;
                    otherwise
                        CalLimit= 13000;
                        CalMax = 20000;
                        ch4calLow = 1.69;
                        ch4calMax = 1.71;                        
                        co2calLow = 379;
                        co2calMax = 384;
                        cavPLow = 139.45;
                        cavPMax = 140.35;
                        ZeroLimit = 8000;
                        toffset = 0; 
                        badCals = [];
                        picBadCals1301 = [];
                        picBadCals2311 = [];
                        badZs = [];
                        tOrd2=0;
                        tSlope=1.000;
                        tInt=0;
                        % 
                        tShift1301 = 0; 
                        tShiftHold1301 = 0;
                        tShift2311 = 0; 
                        tShiftHold2311 = 0;
                        negTime = 0;
                end
end
             
