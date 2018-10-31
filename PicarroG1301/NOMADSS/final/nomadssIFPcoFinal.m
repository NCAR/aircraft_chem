% nomadssIFPco.m
%  Procedure to produce preliminary CO data from GV VUV instrument and
%  Pic1301 co2 and methane analyzer
%  Dependencies:
%     CO_nomadssFlightParams.m
%     RAF data ingestion, dependent on which file format available at the time of processing:
%         if merge file is available, this file is preferred, but has variable arrangement of var columns, acc to data availability
%             Note: files of this type are automatically read into memory by the procedure
%         if only RAF data is available, ascii format was produced with consistent var positioning
%             Note: files of this type must be imported manually using the import wizard (from inside Workspace menu)
% Before running this procedure, edit source code to assign flight specific values:
%   Booleans: mrg, crossesMidnite, Flight date
% Also make sure data are stored in the expected directories and that the directory names have the expected syntax.
% Code usually requires a second pass after editing CO_hippoFlightParams.m as necessary to appropriately define the following vars:
%     toffset, badCals, badZs, tSlope, tInt
%     Flag vars (located in CO_nomadssFlightParams.m):
%
% Written by Teresa Campos, evolved from original code by Samuel R. Hall.  Copyright UCAR 2009, all rights reserved.
% Version 2: 6/06/12 Updated flights through rf08 and added O3 check for cals, Carolyn Farris

cd%Load CO files and add status variable
tic
% cleart
slash = '/'; % unix, mac convention
% slash = '\'; % PC convention

BDF=-99999;
hkHdrLns=160;
alHdrLns=69;
rafHdrLns=64;

UseConstPicSens = 0;
UseConstPicOffset = 0;
UseLinPicCoeffs = 1;
picCO2offset = 2.265;
picCH4offset = 0.034;
picCO2slope = 0.99595;
picCO2int = 3.7786;
% Set default vaules of these Booleans to choose Pic 2311 data for
% processing.  Note: Up through RF04, these values will be toggled to force
% the use of netCDF data from Pic 1301 for processing.  Water vapor
% correction also applied in these instances.  2/20/14 TLC.
outNC = 0;
out2311 = 1;

processNC=1;
processGV=0;

processRaw1301=0;
recreateRaw1301=0;
writeIgor1301=0;
rewriteIgor1301=0;

processRawUser2311=1;
recreateRawUser2311=0;
writeIgorUsr2311=0;
rewriteIgorUsr=0;

processRawPrivate2311=0;
recreateRawPrivate2311=0;
writeIgorPriv2311=0;
rewriteIgorPriv=0;

writeIgorRAFexplore=0;

despike=1;
zaTrim=0;

% disp('Be sure to edit the variable named processingDateString!');
% processingDateString='2012, 05, 30';
processingDateString = datestr(now, 'yyyy, mm, dd');    % current date
% if using aeros generated ascii files, set mrg boolean (in switch/case) to
% TRUE and program will use jereload to pull in housekeeping variables.

%Choose the flight directory
%StartPath='c:\Chemdata\2004OceanWaves\Hal\';
%  StartPath='c:\Chemdata\2004ACME\Hal\';
%  StartPath='d:\Chemdata\2004RICO\Hal\';
%  StartPath='e:\ChemData\2004ACME\Hal\';
% StartPath='/Users/campos/chemData/2006trex/Hal/';
% StartPath='/Users/campos/chemData/2006impex/hal/';
% StartPath='/Users/campos/chemData/2005ProgSci/Hal/';

% Teresa's Mac directory structure:
% StartPath='/Users/ffl/Documents/data/DC3/RAFdata/';
% StartPath='/Users/campos/Documents/macbak/campos/chemData/2013nomadss/ifpRAF/';

% eol-wwhd directory structure:
% StartPath='c:\Data\pase2k7\co\';
% Dan's dir structure:
% StartPath='d:\chemData\2013nomadss\ifpRAF';
% picPath1301='d:\chemData\2013nomadss\picarro-1301';
% picPath2311='d:\chemData\2013nomadss\picarro-2311';
% picPathPrivate2311='d:\chemData\2013nomadss\picarro-2311\private';
% Carolyn's dir structure:
% StartPath='/Users/farrislocal/Documents/RAFdata/2012dc3/ifpRAF/'
% Teresa's dir structure:
StartPath='/Users/campos/Documents/macbak/campos/chemData/2013nomadss/ifpRAF/';
picPath1301=[StartPath(1:end-7), 'picarro1301'];
picPath2311=[StartPath(1:end-7), 'picarro2311'];
picPathPrivate2311=[StartPath(1:end-7), 'picarro2311', slash, 'private', slash];
prodPath = '/Users/campos/Documents/macbak/campos/chemData/2013nomadss/prodData/';
rafPath = StartPath;

if processRaw1301
    cd(picPath1301);
    DirectoryInfo = dir(picPath1301);
    Directories={DirectoryInfo.name};
    [s]=listdlg('SelectionMode','single','ListString',Directories);
    FlightDir = Directories(s);
    flight = FlightDir{1};
    
    cd([picPath1301 slash flight]);
    fileList_unsort = dir('*.dat');
    fileList1301 = sort({fileList_unsort.name});
    fileCount1301 = length(fileList1301);
end

if processRawUser2311
    cd(picPath2311);
    DirectoryInfo = dir(picPath2311);
    Directories={DirectoryInfo.name};
    [s]=listdlg('SelectionMode','single','ListString',Directories);
    FlightDir = Directories(s);
    flight = FlightDir{1};
    
    cd([picPath2311 slash flight]);
    fileList_unsort = dir('*.dat');
    fileListUser2311 = sort({fileList_unsort.name});
    fileCountUser2311 = length(fileListUser2311);
end

if processRawPrivate2311
    cd(picPathPrivate2311);
    DirectoryInfo = dir(picPathPrivate2311);
    Directories={DirectoryInfo.name};
    [s]=listdlg('SelectionMode','single','ListString',Directories);
    FlightDir = Directories(s);
    flight = FlightDir{1};
    
    cd([picPathPrivate2311 slash flight]);
    fileList_unsort = dir('*.dat');
    fileListPrivate2311 = sort({fileList_unsort.name});
    fileCountPrivate2311 = length(fileListPrivate2311);
end

cd(StartPath);
% DirectoryInfo = dir(StartPath);
% Directories={DirectoryInfo.name};
% [s,v]=listdlg('SelectionMode','single','ListString',Directories);
% FlightDir = Directories(s);
% cd([StartPath, char(Flight)]);

% proj='NOMADSS';
% ncFile=[StartPath, proj, fltnoLC, '.nc'] ;
% FltDate=Flight{1}(1:6)
coON=1;
picON=1;

switch char(flight)
    case 'tf01'
        fltno = 'TF01';
        fltnoLC = 'tf01';
        FltDate= '130522';
        Flight=[FltDate fltno];
        crossesMidnite=0;
        mrg=0;
        mrgVer='v0';
        outNC = 1;
        out2311 = 0;
    case 'ff01'
        fltno = 'FF01';
        fltnoLC = 'ff01';
        FltDate = '130530';
        Flight=[FltDate fltno];
        crossesMidnite=0;
        mrg=0;
        mrgVer='v0';
        outNC = 1;
        out2311 = 0;
    case 'rf01'
        fltno = 'RF01';
        fltnoLC = 'rf01';
        FltDate = '130603';
        Flight=[FltDate fltno];
        crossesMidnite=0;
        mrg=0;
        mrgVer='v0';
        despike=1;
        outNC = 1;
        out2311 = 0;
    case 'rf02'
        fltno = 'RF02';
        fltnoLC = 'rf02';
        FltDate = '130605';
        Flight=[FltDate fltno];
        crossesMidnite=0;
        mrg=0;
        mrgVer='v0';
        outNC = 1;
        out2311 = 0;
    case 'rf03'
        fltno = 'RF03';
        fltnoLC = 'rf03';
        FltDate = '130608';
        Flight=[FltDate fltno];
        crossesMidnite=0;
        mrg=0;
        mrgVer='v0';
        outNC = 1;
        out2311 = 0;
    case 'rf04'
        fltno = 'RF04';
        fltnoLC = 'rf04';
        FltDate = '130612';
        Flight=[FltDate fltno];
        crossesMidnite=0;
        mrg=0;
        mrgVer='v0';
        outNC = 1;
        out2311 = 0;
    case 'rf05'
        fltno = 'RF05';
        fltnoLC = 'rf05';
        FltDate = '130614';
        Flight=[FltDate fltno];
        crossesMidnite=0;
        mrg=0;
        mrgVer='v0';
        coON=0;
    case 'rf06'
        fltno = 'RF06';
        fltnoLC = 'rf06';
        FltDate = '130619';
        Flight=[FltDate fltno];
        crossesMidnite=0;
        mrg=0;
        mrgVer='v0';
    case 'rf07'
        fltno = 'RF07';
        fltnoLC = 'rf07';
        FltDate = '130620';
        Flight=[FltDate fltno];
        crossesMidnite=0;
        mrg=0;
        mrgVer='v0';
        zaTrim=1;
    case 'rf08'
        fltno = 'RF08';
        fltnoLC = 'rf08';
        FltDate = '130622';
        Flight=[FltDate fltno];
        crossesMidnite=0;
        mrg=0;
        mrgVer='v0';
        zaTrim=1;
    case 'rf09'
        fltno = 'RF09';
        fltnoLC = 'rf09';
        FltDate = '130624';
        Flight=[FltDate fltno];
        crossesMidnite=0;
        mrg=0;
        mrgVer='v0';
    case 'rf10'
        fltno = 'RF10';
        fltnoLC = 'rf10';
        FltDate = '130627';
        Flight=[FltDate fltno];
        crossesMidnite=0;
        mrg=0;
        mrgVer='v0';
    case 'rf11'
        fltno = 'RF11';
        fltnoLC = 'rf11';
        FltDate = '130629';
        Flight=[FltDate fltno];
        crossesMidnite=0;
        mrg=0;
        mrgVer='v0';
    case 'rf12'
        fltno = 'RF12';
        fltnoLC = 'rf12';
        FltDate = '130701';
        Flight=[FltDate fltno];
        mrg=0;
        crossesMidnite=0;
        mrgVer='v0';
    case 'rf13'
        fltno = 'RF13';
        fltnoLC = 'rf13';
        FltDate = '130704';
        Flight=[FltDate fltno];
        mrg=0;
        crossesMidnite=0;
        mrgVer='v0';
    case 'rf14'
        fltno = 'RF14';
        fltnoLC = 'rf14';
        FltDate = '130705';
        Flight=[FltDate fltno];
        mrg=0;
        crossesMidnite=0;
        mrgVer='v0';
    case 'rf15'
        fltno = 'RF15';
        fltnoLC = 'rf15';
        FltDate = '130707';
        Flight=[FltDate fltno];
        mrg=0;
        crossesMidnite=0;
        mrgVer='v0';
    case 'rf16'
        fltno = 'RF16';
        fltnoLC = 'rf16';
        FltDate = '130708';
        Flight=[FltDate fltno];
        mrg=0;
        crossesMidnite=0;
        mrgVer='v0';
    case 'rf17'
        fltno = 'RF17';
        fltnoLC = 'rf17';
        FltDate = '130711';
        Flight=[FltDate fltno];
        mrg=0;
        crossesMidnite=0;
        mrgVer='v0';
    case 'rf18'
        fltno = 'RF18';
        fltnoLC = 'rf18';
        FltDate = '130712';
        Flight=[FltDate fltno];
        mrg=0;
        crossesMidnite=1;
        mrgVer='v0';
    case 'rf19'
        fltno = 'RF19';
        fltnoLC = 'rf19';
        FltDate = '130714';
        Flight=[FltDate fltno];
        mrg=0;
        crossesMidnite=0;
        mrgVer='v0';
    otherwise
        crossesMidnite=0;
        mrg=0;
        mrgVer='v0';
end

proj='NOMADSS';
ncFile=[rafPath, proj, fltnoLC, '.nc'] ;
prodFile=[prodPath, proj, fltnoLC, '.nc'] ;

if( exist([pwd slash fltnoLC],'dir')==0)
    mkdir(fltnoLC);
end

cd([StartPath slash fltnoLC]);

if( exist([pwd slash 'pix'],'dir')==0)
    mkdir('pix');
end

% hkFile = [StartPath,char(Flight),slash, 'A', char(FltDate),'0.DAT'];
% rafFile = ['../rafDat/503',char(Flight),'.nc']
% rafFile = ['../ifpRAF/502',char(Flight),'.nc']
% rafFile = ['../ifpRAF/506',char(fltno),'.nc'] % PACDEX 2007 proj

% Disable this if-statement during the HIPPO IFP (no RAF prelim data will
% be mailed home).  1/10/09 tc
if (fltnoLC(1)=='g'||fltnoLC(1)=='t') %| fltno=='RF11'
    FlightData=0;
else
    FlightData=1;
end
% FlightData=0;

% Teresa's Mac directory structure:
% rafFile = ['../ifpRAF/',char(proj),char(fltno),'.nc'] % HIPPO 2007 proj
% rafFile = ['../ifpRAF/GV_20',char(FltDate),'_',char(fltno),'.txt'] % HIPPO 2007 proj
% ncFile=[char(FltDate),char(fltnoLC),slash,'HIPPO3',char(fltnoLC),'.nc'];
% rafFile = ['../ifpRAF/GV_20',char(FltDate),'_',char(fltno),'.txt'] % HIPPO 2007 proj
% mrgFile = [StartPath,char(Flight),slash, 'gv_20',char(FltDate),'_',char(fltnoLC),'merge_',mrgVer,'mod.tbl'] % HIPPO-2 2009 proj

rafFile=ncFile;


% eol-wwhd directory structure:
% rafFile = ['..\ifpRAF\',char(proj),char(fltno),'.nc'] % PASE 2007 proj


corrSlope=1;
corrInt=0;

%Set calibration and zero limits
[coCalLow,coCalMax,ch4CalLow,ch4CalMax,cavPLow,cavPMax,coZeroLimit,co2CalLow,co2CalMax,o3Low,...
    before,after,DataAfterCal,ptsToAvg,tankCon,co2tankCon,toffset,badCals,picBadCals1301,...
    picBadCals2301,badZs,tOrd2,tSlope,tInt,...
    tShift1301,tShift2311,tShiftHold1301,tShiftHold2311,negTime]=CO_nomadssFlightParams(fltnoLC);
ZeroMin=1000;

%Start Picarro 1301 Raw
if (processRaw1301)
    
    cd([picPath1301 slash flight]);
    
    % Will re-import raw data from original data files if the matfile does not exist, or if user-specified
    if (recreateRaw1301||~exist([StartPath slash char(fltnoLC) slash '20' FltDate '_' char(fltno) '_rawPic1301.mat'],'file'))
        dTotal1301 = [];
        
        for i=1:fileCount1301(1)
            fprintf('Loading file %d of %d...\n',i,fileCount1301);
            importfile(char(fileList1301(i)));      % Be certain to remove incomplete rows in first
            dTotal1301 = [dTotal1301;data];             % (and maybe second) data file before running
        end
        
        epochTime1301=dTotal1301(:,1);
        alarmStat1301=dTotal1301(:,2);
        calEnabled1301=dTotal1301(:,3);
        cavPres1301=dTotal1301(:,4);
        cavTemp1301=dTotal1301(:,5);
        ch4LaserF1301=dTotal1301(:,6);
        ch4_raw1301=dTotal1301(:,7);
        ch4_concPrecal1301=dTotal1301(:,8);
        ch4_concRaw1301=dTotal1301(:,9);
        ch4_fittime1301=dTotal1301(:,10);
        ch4_interval1301=dTotal1301(:,11);
        ch4Peak1301=dTotal1301(:,12);
        ch4_res1301=dTotal1301(:,13);
        ch4Shift1301=dTotal1301(:,14);
        ch4y1301=dTotal1301(:,15);
        co2LaserF1301=dTotal1301(:,16);
        co2base1301=dTotal1301(:,17);
        co2_raw1301=dTotal1301(:,18);
        co2_concPrecal1301=dTotal1301(:,19);
        co2fit1301=dTotal1301(:,20);
        co2Peak1301=dTotal1301(:,21);
        co2res1301=dTotal1301(:,22);
        co2Shift1301=dTotal1301(:,23);
        co2str1301=dTotal1301(:,24);
        co2y1301=dTotal1301(:,25);
        co2yraw1301=dTotal1301(:,26);
        dasT1301=dTotal1301(:,27);
        etalonT1301=dTotal1301(:,28);
        heaterCurrent1301=dTotal1301(:,29);
        inletP1301=dTotal1301(:,30);
        inletValvPos1301=dTotal1301(:,31);
        outletValvPos1301=dTotal1301(:,32);
        solenoidValves1301=dTotal1301(:,33);
        species1301=dTotal1301(:,34);
        spectrumId1301=dTotal1301(:,35);
        str89_1301=dTotal1301(:,36);
        wlm1Offset1301=dTotal1301(:,37);
        wlm2Offset1301=dTotal1301(:,38);
        
        
        save([StartPath slash char(fltnoLC) slash '20' FltDate '_' char(fltno) '_rawPic1301.mat'],...
            'epochTime1301','alarmStat1301','calEnabled1301','cavPres1301','cavTemp1301','ch4LaserF1301','ch4_raw1301',...
            'ch4_concPrecal1301','ch4_concRaw1301','ch4_fittime1301','ch4_interval1301','ch4Peak1301','ch4_res1301',...
            'ch4Shift1301','ch4y1301','co2LaserF1301','co2base1301','co2_raw1301','co2_concPrecal1301','co2fit1301',...
            'co2Peak1301','co2res1301','co2Shift1301','co2str1301','co2y1301','co2yraw1301','dasT1301','etalonT1301',...
            'heaterCurrent1301','inletP1301','inletValvPos1301','outletValvPos1301','solenoidValves1301',...
            'species1301','spectrumId1301','str89_1301','wlm1Offset1301','wlm2Offset1301','dTotal1301');
    else
        load([StartPath slash char(fltnoLC) slash '20' FltDate '_' char(fltno) '_rawPic1301.mat']);
    end
    
    % Fixes issue seen in DC3 RF01/05/08/09/17 where Picarro had negative time adjustments
    if negTime
        dTotalOrig1301=dTotal1301;
        dTotal1301=unique(dTotal1301,'rows','stable');
        deltaT1301=diff(dTotal1301(:,1));
        negIx1301=find(deltaT1301<=0);
        
        epochTime1301=dTotal1301(:,1);
        epochTime1301(negIx1301)=[];
        ch4_raw1301=dTotal1301(:,7);
        ch4_raw1301(negIx1301)=[];
        co2_raw1301=dTotal1301(:,18);
        co2_raw1301(negIx1301)=[];
        cavPres1301=dTotal1301(:,4);
        cavPres1301(negIx1301)=[];
        
        while ~isempty(negIx1301)
            epochTime1301(negIx1301)=[];
            ch4_raw1301(negIx1301)=[];
            co2_raw1301(negIx1301)=[];
            cavPres1301(negIx1301)=[];
            deltaT1301=diff(epochTime1301);
            negIx1301=find(deltaT1301<=0);
        end
    end
    
    [yearP1301,monthP1301,dayP1301,hourP1301,minuteP1301,secP1301]=unixsecs2date(epochTime1301);
    
    if crossesMidnite
        
        if str2num(FltDate(end-1:end))<9
            day2=['0' num2str(str2num(FltDate(end-1:end))+1)];
        else
            day2=num2str(str2num(FltDate(end-1:end))+1);
        end
        firstSecP1301 = secP1301(1)+60.*minuteP1301(1)+3600.*hourP1301(1);
        picTime1301=hms2sec(hourP1301,minuteP1301,secP1301);
        tempIx = find(picTime1301 < (firstSecP1301));
        if tempIx
            picTime1301(tempIx) = picTime1301(tempIx)+86400;
        end
    else
        picTime1301=hms2sec(hourP1301,minuteP1301,secP1301);
    end
    
    if writeIgor1301
        if(rewriteIgor1301||~exist([StartPath slash char(fltnoLC) slash 'nomadss-1301picHiRateAll_20' FltDate '_IG.txt'],'file'))
            outfile97=[StartPath slash char(fltnoLC) slash 'nomadss-1301picHiRateAll_20' FltDate '_IG.txt'];
            delete(outfile97);
            fid97=fopen(outfile97,'a');
            
            
            fprintf(fid97,'%s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\n',...
                'Time1301','alarmStat1301','calEnabled1301','cavPres1301','cavTemp1301','ch4LaserF1301',...
                'ch4_raw1301','ch4_concPrecal1301','ch4_concRaw1301','ch4_fittime1301','ch4_interval1301',...
                'ch4Peak1301','ch4_res1301','ch4Shift1301','ch4y1301','co2LaserF1301','co2base1301',...
                'co2_raw1301','co2_concPrecal1301','co2fit1301','co2Peak1301','co2res1301','co2Shift1301',...
                'co2str1301','co2y1301','co2yraw1301','dasT1301','etalonT1301','heaterCurrent1301',...
                'inletP1301','inletValvPos1301','outletValvPos1301','solenoidValves1301','species1301',...
                'spectrumId1301','str89_1301','wlm1Offset1301','wlm2Offset1301');
            
            for ix=1:length(picTime1301)
                fprintf(fid97,'%.2f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\n',...
                    picTime1301(ix),alarmStat1301(ix),calEnabled1301(ix),cavPres1301(ix),cavTemp1301(ix),ch4LaserF1301(ix),...
                    ch4_raw1301(ix),ch4_concPrecal1301(ix),ch4_concRaw1301(ix),ch4_fittime1301(ix),ch4_interval1301(ix),...
                    ch4Peak1301(ix),ch4_res1301(ix),ch4Shift1301(ix),ch4y1301(ix),co2LaserF1301(ix),co2base1301(ix),...
                    co2_raw1301(ix),co2_concPrecal1301(ix),co2fit1301(ix),co2Peak1301(ix),co2res1301(ix),co2Shift1301(ix),...
                    co2str1301(ix),co2y1301(ix),co2yraw1301(ix),dasT1301(ix),etalonT1301(ix),heaterCurrent1301(ix),...
                    inletP1301(ix),inletValvPos1301(ix),outletValvPos1301(ix),solenoidValves1301(ix),species1301(ix),...
                    spectrumId1301(ix),str89_1301(ix),wlm1Offset1301(ix),wlm2Offset1301(ix));
            end
            fclose(fid97);
        end
    end
    
end
%End raw Picarro 1301 processing

%Start raw Picarro User 2311 processing
if (processRawUser2311)
    
    cd([picPath2311 slash flight]);
    
    % Will re-import raw data from original data files if the matfile does not exist, or if user-specified
    if (recreateRawUser2311||~exist([StartPath slash char(fltnoLC) slash '20' FltDate '_' char(fltno) '_rawPic2311User.mat'],'file'))
        dTotal2311User = [];
        
        for i=1:fileCountUser2311(1)
            fprintf('Loading file %d of %d...\n',i,fileCountUser2311);
            importfile2311(char(fileListUser2311(i)));
            dTotal2311User = [dTotal2311User;data];
        end
        
        %Deals with a single row of data in rf10 and rf14 that was all NaN's -DS 7-10-13
        switch fltnoLC
            case 'rf10'
                dTotal2311User(118491,:)=[];
            case 'rf14'
                dTotal2311User(76370,:)=[];
        end
        
        UsrEpochTime2311=dTotal2311User(:,4);
        UsrAlarmStat=dTotal2311User(:,5);
        UsrInst_stat=dTotal2311User(:,6);
        UsrCh4_raw2311=dTotal2311User(:,7);
        UsrCh4_dry2311=dTotal2311User(:,8);
        UsrCo2_raw2311=dTotal2311User(:,9);
        UsrCo2_dry2311=dTotal2311User(:,10);
        UsrDasT=dTotal2311User(:,11);
        UsrH2o=dTotal2311User(:,12);
        UsrMPVposition=dTotal2311User(:,13);
        UsrCavPres2311=dTotal2311User(:,14);
        UsrSolenoidValves=dTotal2311User(:,15);
        UsrSpecies=dTotal2311User(:,16);
        
        
        save([StartPath slash char(fltnoLC) slash '20' FltDate '_' char(fltno) '_rawPic2311User.mat'],...
            'UsrEpochTime2311','UsrAlarmStat','UsrInst_stat','UsrCh4_raw2311','UsrCh4_dry2311','UsrCo2_raw2311',...
            'UsrCo2_dry2311','UsrDasT','UsrH2o','UsrMPVposition','UsrCavPres2311','UsrSolenoidValves',...
            'UsrSpecies','dTotal2311User');
    else
        load([StartPath slash char(fltnoLC) slash '20' FltDate '_' char(fltno) '_rawPic2311User.mat']);
    end
    
    [yearUsr2311,monthUsr2311,dayUsr2311,hourUsr2311,minuteUsr2311,secUsr2311]=unixsecs2date(UsrEpochTime2311);
    
    if crossesMidnite
        firstSecUsr2311 = secUsr2311(1)+60.*minuteUsr2311(1)+3600.*hourUsr2311(1);
        picTimeUsr2311=hms2sec(hourUsr2311,minuteUsr2311,secUsr2311);
        tempIx = find(picTimeUsr2311 < (firstSecUsr2311));
        if tempIx
            picTimeUsr2311(tempIx) = picTimeUsr2311(tempIx)+86400;
        end
    else
        picTimeUsr2311=hms2sec(hourUsr2311,minuteUsr2311,secUsr2311);
    end
    
    if writeIgorUsr2311
        if(rewriteIgorUsr||~exist([StartPath slash char(fltnoLC) slash 'nomadss-2311picHiRateUser_20' FltDate '_IG.txt'],'file'))
            outfile98=[StartPath slash char(fltnoLC) slash 'nomadss-2311picHiRateUser_20' FltDate '_IG.txt'];
            delete(outfile98);
            fid98=fopen(outfile98,'a');
            
            
            fprintf(fid98,'%s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\n',...
                'Time2311_Usr','UsrAlarmStat','UsrInst_stat','UsrCh4_raw2311','UsrCh4_dry2311','UsrCo2_raw2311',...
                'UsrCo2_dry2311','UsrDasT','UsrH2o','UsrMPVposition','UsrCavPres2311','UsrSolenoidValves',...
                'UsrSpecies');
            
            for ix=1:length(picTimeUsr2311)
                fprintf(fid98,'%.2f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\n',...
                    picTimeUsr2311(ix),UsrAlarmStat(ix),UsrInst_stat(ix),UsrCh4_raw2311(ix),UsrCh4_dry2311(ix),UsrCo2_raw2311(ix),...
                    UsrCo2_dry2311(ix),UsrDasT(ix),UsrH2o(ix),UsrMPVposition(ix),UsrCavPres2311(ix),UsrSolenoidValves(ix),UsrSpecies(ix));
            end
            fclose(fid98);
        end
        
    end
    
end
%End raw Picarro User 2311 processing

%Start raw Picarro Private 2311 Processing
if processRawPrivate2311
    
    cd([picPathPrivate2311 slash flight]);
    
    % Will re-import raw data from original data files if the matfile does not exist, or if user-specified
    if (recreateRawPrivate2311||~exist([StartPath slash char(fltnoLC) slash '20' FltDate '_' char(fltno) '_rawPic2311Private.mat'],'file'))
        dTotal2311Private = [];
        
        for i=1:fileCountPrivate2311(1)
            fprintf('Loading file %d of %d...\n',i,fileCountPrivate2311);
            importfile2311(char(fileListPrivate2311(i)));
            dTotal2311Private = [dTotal2311Private;data];
        end
        
        PrivAlarmStat=dTotal2311Private(:,1);
        PrivAmbPres=dTotal2311Private(:,2);
        PrivCh4_2311=dTotal2311Private(:,3);
        PrivCh4_dry=dTotal2311Private(:,4);
        PrivCo2_2311=dTotal2311Private(:,5);
        PrivCo2_dry=dTotal2311Private(:,6);
        PrivCavityPressure=dTotal2311Private(:,7);
        PrivCavityTemp=dTotal2311Private(:,8);
        PrivDasTemp=dTotal2311Private(:,9);
        PrivDataRate=dTotal2311Private(:,10);
        PrivEtalon1=dTotal2311Private(:,11);
        PrivEtalon2=dTotal2311Private(:,12);
        PrivEtalonTemp=dTotal2311Private(:,13);
        PrivFrac_days_since_jan1=dTotal2311Private(:,14);
        PrivFrac_hours_since_jan1=dTotal2311Private(:,15);
        PrivFanState=dTotal2311Private(:,16);
        PrivFlow1=dTotal2311Private(:,17);
        PrivH2o=dTotal2311Private(:,18);
        PrivHotBoxHeater=dTotal2311Private(:,19);
        PrivHotBoxHeatsinkTemp=dTotal2311Private(:,20);
        PrivHotBoxTec=dTotal2311Private(:,21);
        PrivInst_status=dTotal2311Private(:,22);
        PrivInletValve=dTotal2311Private(:,23);
        PrivJulian_days=dTotal2311Private(:,24);
        PrivLaser1current=dTotal2311Private(:,25);
        PrivLaser1tec=dTotal2311Private(:,26);
        PrivLaser1temp=dTotal2311Private(:,27);
        PrivLaser2current=dTotal2311Private(:,28);
        PrivLaser2tec=dTotal2311Private(:,29);
        PrivLaser2temp=dTotal2311Private(:,30);
        PrivLaser3current=dTotal2311Private(:,31);
        PrivLaser3tec=dTotal2311Private(:,32);
        PrivLaser3temp=dTotal2311Private(:,33);
        PrivLaser4current=dTotal2311Private(:,34);
        PrivLaser4tec=dTotal2311Private(:,35);
        PrivLaser4temp=dTotal2311Private(:,36);
        PrivMPVposition=dTotal2311Private(:,37);
        PrivOutletValve=dTotal2311Private(:,38);
        PrivProcessedLoss1=dTotal2311Private(:,39);
        PrivProcessedLoss2=dTotal2311Private(:,40);
        PrivProcessedLoss3=dTotal2311Private(:,41);
        PrivProcessedLoss4=dTotal2311Private(:,42);
        PrivRatio1=dTotal2311Private(:,43);
        PrivRatio2=dTotal2311Private(:,44);
        PrivReference1=dTotal2311Private(:,45);
        PrivReference2=dTotal2311Private(:,46);
        PrivSchemeTable=dTotal2311Private(:,47);
        PrivSchemeVersion=dTotal2311Private(:,48);
        PrivSpectrumID=dTotal2311Private(:,49);
        PrivValveMask=dTotal2311Private(:,50);
        PrivWarmBoxHeatsinkTemp=dTotal2311Private(:,51);
        PrivWarmBoxTec=dTotal2311Private(:,52);
        PrivWarmBoxTemp=dTotal2311Private(:,53);
        PrivCal_enabled=dTotal2311Private(:,54);
        PrivCavity_pressure=dTotal2311Private(:,55);
        PrivCavity_temperature=dTotal2311Private(:,56);
        PrivCh4_10pt_amp=dTotal2311Private(:,57);
        PrivCh4_adjust=dTotal2311Private(:,58);
        PrivCh4_amp=dTotal2311Private(:,59);
        PrivCh4_baseline_avg=dTotal2311Private(:,60);
        PrivCh4_conc_peak=dTotal2311Private(:,61);
        PrivCh4_conc_precal=dTotal2311Private(:,62);
        PrivCh4_conc_raw=dTotal2311Private(:,63);
        PrivCh4_fit_time=dTotal2311Private(:,64);
        PrivCh4_pzt_mean=dTotal2311Private(:,65);
        PrivCh4_pzt_std=dTotal2311Private(:,66);
        PrivCh4_res=dTotal2311Private(:,67);
        PrivCh4_shift=dTotal2311Private(:,68);
        PrivCh4_tuner_mean=dTotal2311Private(:,69);
        PrivCh4_tune_std=dTotal2311Private(:,70);
        PrivCh4_y=dTotal2311Private(:,71);
        PrivCo2_9ptbase=dTotal2311Private(:,72);
        PrivCo2_9ptpeak=dTotal2311Private(:,73);
        PrivCo2_adjust=dTotal2311Private(:,74);
        PrivCo2_base=dTotal2311Private(:,75);
        PrivCo2_base_avg=dTotal2311Private(:,76);
        PrivCo2_baseline=dTotal2311Private(:,77);
        PrivCo2_conc_precal=dTotal2311Private(:,78);
        PrivCo2_fittime=dTotal2311Private(:,79);
        PrivCo2_peak=dTotal2311Private(:,80);
        PrivCo2_pzt_mean=dTotal2311Private(:,81);
        PrivCo2_pzt_std=dTotal2311Private(:,82);
        PrivCo2_res=dTotal2311Private(:,83);
        PrivCo2_shift=dTotal2311Private(:,84);
        PrivCo2_str=dTotal2311Private(:,85);
        PrivCo2_tuner_mean=dTotal2311Private(:,86);
        PrivCo2_tuner_std=dTotal2311Private(:,87);
        PrivCo2_y=dTotal2311Private(:,88);
        PrivCo2_y_avg=dTotal2311Private(:,89);
        PrivDatagroups=dTotal2311Private(:,90);
        PrivDm_latency=dTotal2311Private(:,91);
        PrivFit_flag=dTotal2311Private(:,92);
        PrivH2o_9ptpeak=dTotal2311Private(:,93);
        PrivH2o_adjust=dTotal2311Private(:,94);
        PrivH2o_conc_precal=dTotal2311Private(:,95);
        PrivH2o_fittime=dTotal2311Private(:,96);
        PrivH2o_peak=dTotal2311Private(:,97);
        PrivH2o_pzt_mean=dTotal2311Private(:,98);
        PrivH2o_reported=dTotal2311Private(:,99);
        PrivH2o_res=dTotal2311Private(:,100);
        PrivH2o_shift=dTotal2311Private(:,101);
        PrivH2o_tuner_mean=dTotal2311Private(:,102);
        PrivH2o_y_avg=dTotal2311Private(:,103);
        PrivMax_fitter_latency=dTotal2311Private(:,104);
        PrivPeak10_9pt=dTotal2311Private(:,105);
        PrivPeak_10=dTotal2311Private(:,106);
        PrivRingdowns=dTotal2311Private(:,107);
        PrivSolenoid_valves=dTotal2311Private(:,108);
        PrivSpecies=dTotal2311Private(:,109);
        PrivSpect_latency=dTotal2311Private(:,110);
        PrivEpochTime2311=dTotal2311Private(:,111);
        PrivWlm1_offset=dTotal2311Private(:,112);
        PrivWlm2_offset=dTotal2311Private(:,113);
        PrivWlm3_offset=dTotal2311Private(:,114);
        
        
        save([StartPath slash char(fltnoLC) slash '20' FltDate '_' char(fltno) '_rawPic2311Private.mat'],...
            'PrivAlarmStat','PrivAmbPres','PrivCh4_2311','PrivCh4_dry','PrivCo2_2311','PrivCo2_dry','PrivCavityPressure','PrivCavityTemp',...
            'PrivDasTemp','PrivDataRate','PrivEtalon1','PrivEtalon2','PrivEtalonTemp','PrivFrac_days_since_jan1','PrivFrac_hours_since_jan1',...
            'PrivFanState','PrivFlow1','PrivH2o','PrivHotBoxHeater','PrivHotBoxHeatsinkTemp','PrivHotBoxTec','PrivInst_status','PrivInletValve',...
            'PrivJulian_days','PrivLaser1current','PrivLaser1tec','PrivLaser1temp','PrivLaser2current','PrivLaser2tec','PrivLaser2temp',...
            'PrivLaser3current','PrivLaser3tec','PrivLaser3temp','PrivLaser4current','PrivLaser4tec','PrivLaser4temp','PrivMPVposition',...
            'PrivOutletValve','PrivProcessedLoss1','PrivProcessedLoss2','PrivProcessedLoss3','PrivProcessedLoss4','PrivRatio1','PrivRatio2',...
            'PrivReference1','PrivReference2','PrivSchemeTable','PrivSchemeVersion','PrivSpectrumID','PrivValveMask','PrivWarmBoxHeatsinkTemp',...
            'PrivWarmBoxTec','PrivWarmBoxTemp','PrivCal_enabled','PrivCavity_pressure','PrivCavity_temperature','PrivCh4_10pt_amp',...
            'PrivCh4_adjust','PrivCh4_amp','PrivCh4_baseline_avg','PrivCh4_conc_peak','PrivCh4_conc_precal','PrivCh4_conc_raw',...
            'PrivCh4_fit_time','PrivCh4_pzt_mean','PrivCh4_pzt_std','PrivCh4_res','PrivCh4_shift','PrivCh4_tuner_mean','PrivCh4_tune_std',...
            'PrivCh4_y','PrivCo2_9ptbase','PrivCo2_9ptpeak','PrivCo2_adjust','PrivCo2_base','PrivCo2_base_avg','PrivCo2_baseline','PrivCo2_conc_precal',...
            'PrivCo2_fittime','PrivCo2_peak','PrivCo2_pzt_mean','PrivCo2_pzt_std','PrivCo2_res','PrivCo2_shift','PrivCo2_str','PrivCo2_tuner_mean',...
            'PrivCo2_tuner_std','PrivCo2_y','PrivCo2_y_avg','PrivDatagroups','PrivDm_latency','PrivFit_flag','PrivH2o_9ptpeak','PrivH2o_adjust',...
            'PrivH2o_conc_precal','PrivH2o_fittime','PrivH2o_peak','PrivH2o_pzt_mean','PrivH2o_reported','PrivH2o_res','PrivH2o_shift','PrivH2o_tuner_mean',...
            'PrivH2o_y_avg','PrivMax_fitter_latency','PrivPeak10_9pt','PrivPeak_10','PrivRingdowns','PrivSolenoid_valves','PrivSpecies','PrivSpect_latency',...
            'PrivEpochTime2311','PrivWlm1_offset','PrivWlm2_offset','PrivWlm3_offset','dTotal2311Private');
        
    else
        load([StartPath slash char(fltnoLC) slash '20' FltDate '_' char(fltno) '_rawPic2311Private.mat']);
    end
    
    [yearPriv2311,monthPriv2311,dayPriv2311,hourPriv2311,minutePriv2311,secPriv2311]=unixsecs2date(PrivEpochTime2311);
    
    if crossesMidnite
        firstSecPriv2311 = secPriv2311(1)+60.*minutePriv2311(1)+3600.*hourPriv2311(1);
        picTimePriv2311=hms2sec(hourPriv2311,minutePriv2311,secPriv2311);
        tempIx = find(picTimePriv2311 < (firstSecPriv2311));
        if tempIx
            picTimePriv2311(tempIx) = picTimePriv2311(tempIx)+86400;
        end
    else
        picTimePriv2311=hms2sec(hourPriv2311,minutePriv2311,secPriv2311);
    end
    
    if writeIgorPriv2311
        if(rewriteIgorPriv||~exist([StartPath slash char(fltnoLC) slash 'nomadss-2311picHiRatePrivate_20' FltDate '_IG.txt'],'file'))
            outfile99=[StartPath slash char(fltnoLC) slash 'nomadss-2311picHiRatePrivate_20' FltDate '_IG.txt'];
            delete(outfile99);
            fid99=fopen(outfile99,'a');
            
            
            fprintf(fid99,'%s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\n',...
                'Time2311_Priv','PrivAlarmStat','PrivAmbPres','PrivCh4_2311','PrivCh4_dry','PrivCo2_2311','PrivCo2_dry','PrivCavityPressure','PrivCavityTemp',...
                'PrivDasTemp','PrivDataRate','PrivEtalon1','PrivEtalon2','PrivEtalonTemp','PrivFrac_days_since_jan1','PrivFrac_hours_since_jan1',...
                'PrivFanState','PrivFlow1','PrivH2o','PrivHotBoxHeater','PrivHotBoxHeatsinkTemp','PrivHotBoxTec','PrivInst_status','PrivInletValve',...
                'PrivJulian_days','PrivLaser1current','PrivLaser1tec','PrivLaser1temp','PrivLaser2current','PrivLaser2tec','PrivLaser2temp',...
                'PrivLaser3current','PrivLaser3tec','PrivLaser3temp','PrivLaser4current','PrivLaser4tec','PrivLaser4temp','PrivMPVposition',...
                'PrivOutletValve','PrivProcessedLoss1','PrivProcessedLoss2','PrivProcessedLoss3','PrivProcessedLoss4','PrivRatio1','PrivRatio2',...
                'PrivReference1','PrivReference2','PrivSchemeTable','PrivSchemeVersion','PrivSpectrumID','PrivValveMask','PrivWarmBoxHeatsinkTemp',...
                'PrivWarmBoxTec','PrivWarmBoxTemp','PrivCal_enabled','PrivCavity_pressure','PrivCavity_temperature','PrivCh4_10pt_amp',...
                'PrivCh4_adjust','PrivCh4_amp','PrivCh4_baseline_avg','PrivCh4_conc_peak','PrivCh4_conc_precal','PrivCh4_conc_raw',...
                'PrivCh4_fit_time','PrivCh4_pzt_mean','PrivCh4_pzt_std','PrivCh4_res','PrivCh4_shift','PrivCh4_tuner_mean','PrivCh4_tune_std',...
                'PrivCh4_y','PrivCo2_9ptbase','PrivCo2_9ptpeak','PrivCo2_adjust','PrivCo2_base','PrivCo2_base_avg','PrivCo2_baseline','PrivCo2_conc_precal',...
                'PrivCo2_fittime','PrivCo2_peak','PrivCo2_pzt_mean','PrivCo2_pzt_std','PrivCo2_res','PrivCo2_shift','PrivCo2_str','PrivCo2_tuner_mean',...
                'PrivCo2_tuner_std','PrivCo2_y','PrivCo2_y_avg','PrivDatagroups','PrivDm_latency','PrivFit_flag','PrivH2o_9ptpeak','PrivH2o_adjust',...
                'PrivH2o_conc_precal','PrivH2o_fittime','PrivH2o_peak','PrivH2o_pzt_mean','PrivH2o_reported','PrivH2o_res','PrivH2o_shift','PrivH2o_tuner_mean',...
                'PrivH2o_y_avg','PrivMax_fitter_latency','PrivPeak10_9pt','PrivPeak_10','PrivRingdowns','PrivSolenoid_valves','PrivSpecies','PrivSpect_latency',...
                'PrivWlm1_offset','PrivWlm2_offset','PrivWlm3_offset');
            
            for ix=1:length(picTimePriv2311)
                fprintf(fid99,'%.2f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\n',...
                    picTimePriv2311(ix),PrivAlarmStat(ix),PrivAmbPres(ix),PrivCh4_2311(ix),PrivCh4_dry(ix),PrivCo2_2311(ix),PrivCo2_dry(ix),PrivCavityPressure(ix),PrivCavityTemp(ix),...
                    PrivDasTemp(ix),PrivDataRate(ix),PrivEtalon1(ix),PrivEtalon2(ix),PrivEtalonTemp(ix),PrivFrac_days_since_jan1(ix),PrivFrac_hours_since_jan1(ix),...
                    PrivFanState(ix),PrivFlow1(ix),PrivH2o(ix),PrivHotBoxHeater(ix),PrivHotBoxHeatsinkTemp(ix),PrivHotBoxTec(ix),PrivInst_status(ix),PrivInletValve(ix),...
                    PrivJulian_days(ix),PrivLaser1current(ix),PrivLaser1tec(ix),PrivLaser1temp(ix),PrivLaser2current(ix),PrivLaser2tec(ix),PrivLaser2temp(ix),...
                    PrivLaser3current(ix),PrivLaser3tec(ix),PrivLaser3temp(ix),PrivLaser4current(ix),PrivLaser4tec(ix),PrivLaser4temp(ix),PrivMPVposition(ix),...
                    PrivOutletValve(ix),PrivProcessedLoss1(ix),PrivProcessedLoss2(ix),PrivProcessedLoss3(ix),PrivProcessedLoss4(ix),PrivRatio1(ix),PrivRatio2(ix),...
                    PrivReference1(ix),PrivReference2(ix),PrivSchemeTable(ix),PrivSchemeVersion(ix),PrivSpectrumID(ix),PrivValveMask(ix),PrivWarmBoxHeatsinkTemp(ix),...
                    PrivWarmBoxTec(ix),PrivWarmBoxTemp(ix),PrivCal_enabled(ix),PrivCavity_pressure(ix),PrivCavity_temperature(ix),PrivCh4_10pt_amp(ix),...
                    PrivCh4_adjust(ix),PrivCh4_amp(ix),PrivCh4_baseline_avg(ix),PrivCh4_conc_peak(ix),PrivCh4_conc_precal(ix),PrivCh4_conc_raw(ix),...
                    PrivCh4_fit_time(ix),PrivCh4_pzt_mean(ix),PrivCh4_pzt_std(ix),PrivCh4_res(ix),PrivCh4_shift(ix),PrivCh4_tuner_mean(ix),PrivCh4_tune_std(ix),...
                    PrivCh4_y(ix),PrivCo2_9ptbase(ix),PrivCo2_9ptpeak(ix),PrivCo2_adjust(ix),PrivCo2_base(ix),PrivCo2_base_avg(ix),PrivCo2_baseline(ix),PrivCo2_conc_precal(ix),...
                    PrivCo2_fittime(ix),PrivCo2_peak(ix),PrivCo2_pzt_mean(ix),PrivCo2_pzt_std(ix),PrivCo2_res(ix),PrivCo2_shift(ix),PrivCo2_str(ix),PrivCo2_tuner_mean(ix),...
                    PrivCo2_tuner_std(ix),PrivCo2_y(ix),PrivCo2_y_avg(ix),PrivDatagroups(ix),PrivDm_latency(ix),PrivFit_flag(ix),PrivH2o_9ptpeak(ix),PrivH2o_adjust(ix),...
                    PrivH2o_conc_precal(ix),PrivH2o_fittime(ix),PrivH2o_peak(ix),PrivH2o_pzt_mean(ix),PrivH2o_reported(ix),PrivH2o_res(ix),PrivH2o_shift(ix),PrivH2o_tuner_mean(ix),...
                    PrivH2o_y_avg(ix),PrivMax_fitter_latency(ix),PrivPeak10_9pt(ix),PrivPeak_10(ix),PrivRingdowns(ix),PrivSolenoid_valves(ix),PrivSpecies(ix),PrivSpect_latency(ix),...
                    PrivWlm1_offset(ix),PrivWlm2_offset(ix),PrivWlm3_offset(ix));
            end
            fclose(fid99);
        end
        
    end
    
end
%End raw Picarro Private 2311 Processing


if processNC==1 || processGV==1
    year= FltDate(1:2);
    month= FltDate(3:4);
    day= FltDate(5:6);
    YY=zero_pad(year);
    MM=zero_pad(month);
    DD=zero_pad(day);
    %         HH(i,:)=zero_pad(hr);
    %         mm(i,:)=zero_pad(minute);
    %         ss(i,:)=zero_pad(second);
    
    if processNC
        rafInterval=nc_attget(ncFile,nc_global,'TimeInterval');
        rafMissionT=nc_varget(ncFile,'Time');
        rafHrBeg=rafInterval(1:2);
        rafMnBeg=rafInterval(4:5);
        rafScBeg=rafInterval(7:8);
        rafHrEnd=rafInterval(10:11);
        rafMnEnd=rafInterval(13:14);
        rafScEnd=rafInterval(16:17);
        rafStartT=str2num(rafHrBeg).*3600+str2num(rafMnBeg).*60+str2num(rafScBeg);
        rafEndT=str2num(rafHrEnd).*3600+str2num(rafMnEnd).*60+str2num(rafScEnd);
        if crossesMidnite
            rafEndT=rafEndT+86400;
        end
        rafTime=double(rafMissionT);

        if coON
        counter=nc_varget(ncFile,'CORAW_AL');
        else
            counter=ones(size(rafTime)).*BDF;
        end
        rafP=nc_varget(ncFile,'PSXC'); %#ok<*NASGU>
        rafAlt=nc_varget(ncFile,'GGALT');
        co2=nc_varget(ncFile,'CO2_PIC1301');
        ch4=nc_varget(ncFile,'CH4_PIC1301');
        o3=nc_varget(ncFile,'FO3_ACD');
        no=nc_varget(ncFile,'NO_ACD');
        no2=nc_varget(ncFile,'NO2_ACD');
        co2pic2=nc_varget(ncFile,'CO2_PIC2311');
        ch4pic2=nc_varget(ncFile,'CH4_PIC2311');
        h2opic2=nc_varget(ncFile,'H2O_PIC2311');
        co2raf=co2;
        rafMR = nc_varget(prodFile, 'MR_UVH');
        mrCR2 = nc_varget(ncFile,'MR_CR2');
        mrDP = nc_varget(ncFile,'MR');
        mrUVH = rafMR;
        
    else
        counter=CORAW_AL;
        rafP=PSXC;
        rafAlt=GGALT;
    end
    hrCellP=ones(size(counter)).*4.1;
    concentration=(counter-8000)./(36000).*200;
    if outNC
        wvVolPercent = rafMR.*0.1608.*0.938144988909724 + 0.021335578655422; % coeffs from lin reg of rafMRppm vs h2oOut rf05 2/20/14 tlc
        picCO2offset = 0.92;
        picCH4offset = 0;
        UseConstPicSens = 0;
        UseConstPicOffset = 1;
        UseLinPicCoeffs = 0;
        wvCoeff1 = - 0.013924; % empirical coeffs from RF05
        wvCoeff2 = - 0.00035614;
% Rella coeffs from 1301 paper:
%         wvCoeff1 = - 0.01200; 
%         wvCoeff2 = - 0.0002674;
        wvCorrArray = 1 + wvCoeff1.*wvVolPercent + (wvCoeff2.*(wvVolPercent.^2));
        co2corr = co2raf./wvCorrArray;
        
    end
        %Begin raw picarro 1301
    if (processRaw1301)
        
        if ~negTime
            co2_rawAdj1301=interp1(picTime1301,co2_raw1301,rafTime);
            ch4_rawAdj1301=interp1(picTime1301,ch4_raw1301,rafTime);
            cavPresAdj1301=interp1(picTime1301,cavPres1301,rafTime);
        else
            picTimeOrig1301=picTime1301;
            picTime1301=picTimeOrig1301(1):0.08:picTimeOrig1301(end);
            
            co2_rawIP1301=interp1(picTimeOrig1301,co2_raw1301,picTime1301);
            ch4_rawIP1301=interp1(picTimeOrig1301,ch4_raw1301,picTime1301);
            cavPresIP1301=interp1(picTimeOrig1301,cavPres1301,picTime1301);
            
            co2_rawAdj1301=interp1(picTime1301,co2_rawIP1301,rafTime);
            ch4_rawAdj1301=interp1(picTime1301,ch4_rawIP1301,rafTime);
            cavPresAdj1301=interp1(picTime1301,cavPresIP1301,rafTime);
        end
        
        co2_rawOut1301=circshift(co2_rawAdj1301,tShift1301);
        ch4_rawOut1301=circshift(ch4_rawAdj1301,tShift1301);
        cavPresOut1301=circshift(cavPresAdj1301,tShift1301);
        
        figure(100);
        %Black plot is from netcdf, red is from picarro. Use to determine time
        %shift between the two and confirm through iteration
        plot(rafTime,co2,'k.',rafTime,co2_rawOut1301,'r.');title([proj '  ' char(fltno)  '  ' char(FltDate) ' Raw Picarro Time Adj CO_2 1301'],'FontSize',14);grid
        legend('RAF CO_2','Pic CO_2 1301');
        
        prompt1 = 'Enter a time shift in seconds: ';
        prompt2 = 'Are you are satisfied with alignment? Y/N [Y]: ';
        
        while (tShiftHold1301==0)
            contPrmpt=input(prompt2,'s');
            
            if (isempty(contPrmpt)||contPrmpt=='y'||contPrmpt=='Y')
                tShiftHold1301=1;
                'Be sure to edit tShift and tShiftHold accordingly for future runs!' %#ok<*NOPTS>
                break
            end
            
            tShift1301=input(prompt1)
            co2_rawOut1301=circshift(co2_rawOut1301,tShift1301);
            ch4_rawOut1301=circshift(ch4_rawOut1301,tShift1301);
            cavPresOut1301=circshift(cavPresOut1301,tShift1301);
            
            figure(101);
            plot(rafTime,co2,'k.',rafTime,co2_rawOut1301,'r.');title([proj '  ' char(fltno)  '  ' char(FltDate) ' Raw Picarro Time Adj CO_2 1301'],'FontSize',14);grid
            legend('RAF CO_2','Pic CO_2 1301');
        end
        
        cavPBadIx1301=find(cavPresOut1301<cavPLow | cavPresOut1301>cavPMax);
        
    end
    % End raw Picarro 1301
    
    %Begin raw picarro User 2311
    if (processRawUser2311)
        
        co2_dryAdj2311=interp1(picTimeUsr2311,UsrCo2_dry2311,rafTime);
        co2_rawAdj2311=interp1(picTimeUsr2311,UsrCo2_raw2311,rafTime);
        ch4_dryAdj2311=interp1(picTimeUsr2311,UsrCh4_dry2311,rafTime);
        h2o_Adj2311=interp1(picTimeUsr2311,UsrH2o,rafTime);
        cavPresAdj2311=interp1(picTimeUsr2311,UsrCavPres2311,rafTime);
        
        co2raw_Out2311=circshift(co2_rawAdj2311,tShift2311);
        co2_Out2311=circshift(co2_dryAdj2311,tShift2311);
        ch4_Out2311=circshift(ch4_dryAdj2311,tShift2311);
        h2o_Out2311=circshift(h2o_Adj2311,tShift2311);
        cavPresOut2311=circshift(cavPresAdj2311,tShift2311);
        
        figure(102);
        %Black plot is from netcdf, red is from picarro. Use to determine time
        %shift between the two and confirm through iteration
        plot(rafTime,co2raf,'k.',rafTime,co2_Out2311,'r.');title([proj '  ' char(fltno)  '  ' char(FltDate) ' Raw Picarro Time Adj CO_2 2311'],'FontSize',14);grid
        legend('RAF CO_2','Pic CO_2 2311');
        
        prompt1 = 'Enter a time shift in seconds: ';
        prompt2 = 'Are you are satisfied with alignment? Y/N [Y]: ';
        
        while (tShiftHold2311==0)
            contPrmpt=input(prompt2,'s');
            
            if (isempty(contPrmpt)||contPrmpt=='y'||contPrmpt=='Y')
                tShiftHold2311=1;
                'Be sure to edit tShift and tShiftHold accordingly for future runs!'
                break
            end
            
            tShift2311=input(prompt1)
            co2_Out2311=circshift(co2_Out2311,tShift2311);
            ch4_Out2311=circshift(ch4_Out2311,tShift2311);
            h2o_Out2311=circshift(h2o_Adj2311,tShift2311);
            cavPresOut2311=circshift(cavPresOut2311,tShift2311);
            
            figure(103);
            plot(rafTime,co2,'k.',rafTime,co2_Out2311,'r.');title([proj '  ' char(fltno)  '  ' char(FltDate) ' Raw Picarro Time Adj CO_2 2311'],'FontSize',14);grid;
            legend('RAF CO_2','Pic CO_2 2311');
        end
        
        if out2311
            co2=co2_Out2311;
            ch4=ch4_Out2311;
        end
        h2oadj = h2o_Out2311;
        cavPBadIx2311=find(cavPresOut2311<cavPLow | cavPresOut2311>cavPMax);
        
    end
    % End raw Picarro User 2311
    
    %  if (str2num(fltno)>3&str2num(fltno)<13)
    %      cal=and(gt(counter,coCalLow),lt(counter,coCalMax));
    %  else
    
    %We could implement an additional check for cal here using 2311 picarro data - DS 7/3/13
    cal = zeros(size(counter));
    zcal = zeros(size(counter));
    %         cix = find(counter>coCalLow & counter<coCalMax & ((ch4>ch4CalLow & ch4<ch4CalMax & co2>co2CalLow & co2<co2CalMax) | o3<o3Low));
    if coON
        if picON
            cix = find(counter>coCalLow & counter<coCalMax & ((ch4>ch4CalLow & ch4<ch4CalMax & co2>co2CalLow & co2<co2CalMax)));
            zcix = find(counter>ZeroMin & counter<coZeroLimit & ch4>ch4CalLow & ch4<ch4CalMax & co2>co2CalLow & co2<co2CalMax);
        else
            cix = find( counter>coCalLow & counter<coCalMax);
            zcix = find(counter>ZeroMin & counter<coZeroLimit & ch4>ch4CalLow & ch4<ch4CalMax & co2>co2CalLow & co2<co2CalMax);
            
        end
    end
    if ~coON
        cix = find( ((ch4>ch4CalLow & ch4<ch4CalMax & co2>co2CalLow & co2<co2CalMax)));
         zcix = 1;
    end
    
    cal(cix)=1;
    zcal(zcix)=1;
    %         cal1=and(gt(counter,coCalLow),lt(counter,coCalMax));
    %         cal2=and(cal1,gt(ch4,ch4CalLow));
    %         cal=and(cal2,lt(ch4,ch4CalMax));
    %  end
    zero = zeros(size(counter));
    
    
    %Commented out 7/3/13 to accomadate switch below - DS
    %         if coON
    %             zero=and(gt(counter,ZeroMin),lt(counter,coZeroLimit));
    %             status=max(cal*2,zero*1);
    %         else
    %             zero = ones(size(counter));
    %             status = BDF.*zero;
    %         end
    %
    %         picStatus=max(cal*2,zcal*1);
    
    switch fltnoLC
        %         case 'tf03'
        %         cal=and(gt(counter,coCalLow),lt(counter,coCalMax));
        %         zero=and(gt(counter,ZeroMin),lt(counter,coZeroLimit));
        %         earlyCalThreshold=73000;
        %         earlyIx=find(time<earlyCalThreshold);
        %         cal(earlyIx)=and(gt(counter(earlyIx),24000),lt(counter(earlyIx),coCalMax));
        % status=max(cal*2,zero*1);
        %         case 'rf02'
        %         cal=and(gt(counter,coCalLow),lt(counter,coCalMax));
        %         zero=and(gt(counter,ZeroMin),lt(counter,coZeroLimit));
        %         earlyCalThreshold=66000;
        %         earlyIx=find(time<earlyCalThreshold);
        %         cal(earlyIx)=0;
        %         earlyCalIx=find((time>cal1beg&time<cal1end)|(time>cal2beg&time<cal2end)|(time>cal3beg&time<cal3end));
        %         cal(earlyCalIx)=1;
        % status=max(cal*2,zero*1);
        % editStatusIx=find((rafTime>57900&rafTime<58000));
        % status(editStatusIx)=0;
        %         case 'rf03'
        %         cal=and(gt(counter,coCalLow),lt(counter,coCalMax));
        %         zero=and(gt(counter,ZeroMin),lt(counter,coZeroLimit));
        %         earlyCalThreshold=65000;
        %         earlyIx=find(time<earlyCalThreshold);
        %         cal(earlyIx)=0;
        %         cal1beg=64770;
        %         cal1end=64785;
        %         earlyCalIx=find((time>cal1beg&time<cal1end));
        %         cal(earlyCalIx)=1;
        % status=max(cal*2,zero*1);
        % editStatusIx=find((time>84600&time<86220)|(time>86330&time<88000)|...
        %     (time>88900&time<89700)|(time>93300&time<93380)|(time>93500&time<94500));
        % status(editStatusIx)=0;
        %          case 'rf04'
        %          coDown=75830;
        %          coUp=79860;
        %          earlyIx=find(rafTime<coUp&rafTime>coDown);
        %          status(earlyIx)=BDF;
        %          picStatus(earlyIx)=0;
        %          picCal=(gt(co2,co2CalLow) & lt(co2,co2CalMax)& gt(ch4,ch4CalLow)& lt(ch4,ch4CalMax));
        %          cal1beg=77400;
        %          cal1end=77520;
        %          cal2beg=79200;
        %          cal2end=7932;
        %          earlyCalIx=find((rafTime>cal1beg&rafTime<cal1end)|(rafTime>cal2beg&rafTime<cal2end));
        %          picStatus(earlyCalIx)=2;
        % editStatusIx=find((time>75400&time<75600)|(time>76700&time<78200)|...
        %     (time>79400&time<79800));
        % status(editStatusIx)=0;
        %         case 'rf07'
        %         cal=and(gt(counter,coCalLow),lt(counter,coCalMax));
        %         zero=and(gt(counter,ZeroMin),lt(counter,coZeroLimit));
        %         earlyCalThreshold=79500;
        %         earlyIx=find(time<earlyCalThreshold);
        %         cal(earlyIx)=0;
        %         cal1beg=79218;
        %         cal1end=79260;
        %         earlyCalIx=find((time>cal1beg&time<cal1end));
        %         cal(earlyCalIx)=1;
        % status=max(cal*2,zero*1);
        % % editStatusIx=find((time>67400&time<67940)|(time>64000&time<66000)|...
        % %     (time>79000&time<79500)|(time>93500&time<95000)|(time>76000&time<76500));
        % % status(editStatusIx)=0;
        %         case 'rf08'
        %         cal=and(gt(counter,coCalLow),lt(counter,coCalMax));
        %         zero=and(gt(counter,ZeroMin),lt(counter,coZeroLimit));
        %         earlyCalThreshold=75500;
        %         earlyIx=find(time<earlyCalThreshold);
        %         cal(earlyIx)=0;
        % %         cal1beg=79218;
        % %         cal1end=79260;
        % %         earlyCalIx=find((time>cal1beg&time<cal1end));
        % %         cal(earlyCalIx)=1;
        % status=max(cal*2,zero*1);
        % editStatusIx=find((time>93150&time<93250)|(time>96830&time<97600)|...
        %     (time>97780&time<98550)|(time>98750&time<10000));
        % status(editStatusIx)=0;
        %         otherwise
        %         cal=and(gt(counter,coCalLow),lt(counter,coCalMax));
        %         zero=and(gt(counter,ZeroMin),lt(counter,coZeroLimit));
        % status=max(cal*2,zero*1);
    end % case status needs to be edited to add back in some ambient data, or if cal thresholds=f(t)
    
    switch fltnoLC
        case 'rf10'
            numCints=7; %Number of cals that need to be added/modified
            numRCints=0; %Number of falsely classified cals to remove
            numBDFints=0; %Number of intervals to label with BDF
            numZints=0; %Number of zeroes that need to be added/modified
            
            addCBegT=[55802 59401 63009 66609 70202 73801 77401]; %Array of begin times for cix to add
            addCEndT=[55919 59519 63119 66719 70319 73919 77519]; %Array of end times for cix to add
            
            remCBegT=[]; %Array of start times for cix to reset to 0
            remCEndT=[]; %Array of end times for cix to reset to 0
            
            bdfBegT=[]; %Array of start times for BDF status
            bdfEndT=[]; %Array of end times for BDF status
            
            addZBegT=[]; %Array of start times for zero to add
            addZEndT=[]; %Array of end times for zero to add
            
            if numCints~=0
                for ic=1:numCints
                    addCix=find(rafTime>=addCBegT(ic)&rafTime<=addCEndT(ic));
                    cal(addCix)=1;
                end
            end
            
            if numRCints~=0
                for iRc=1:numRCints
                    removeCIx=find(rafTime>=remCBegT(iRc)&rafTime<=remCEndT(iRc));
                    cal(removeCIx)=0;
                end
            end
            
            if coON
                zero=and(gt(counter,ZeroMin),lt(counter,coZeroLimit));
                status=max(cal*2,zero*1);
            else
                zero = ones(size(counter));
                status = BDF.*zero;
            end
            picStatus=max(cal*2,zcal*2);
            
            %Modify this if statement to control which dataset (picarro or CO) status is being modified
            if numBDFints~=0
                for iBDF=1:numBDFints
                    setBDF=find(rafTime>=bdfBegT(iBDF)&rafTime<=bdfEndT(iBDF));
                    status(setBDF)=BDF;
                    %                 picStatus(setBDF)=BDF;
                end
            end
            
            if numZints~=0
                for iz=1:numZints
                    addZix=find(rafTime>=addZBegT(iz)&rafTime<=addZEndT(iz));
                    status(addZix)=1;
                end
            end
            
        case 'rf11'
            numCints=0;
            numRCints=0;
            numBDFints=2;
            numZints=0;
            
            addCBegT=[];
            addCEndT=[];
            
            remCBegT=[];
            remCEndT=[];
            
            bdfBegT=[59405 59507];
            bdfEndT=[59437 59528];
            
            addZBegT=[];
            addZEndT=[];
            
            if numCints~=0
                for ic=1:numCints
                    addCix=find(rafTime>=addCBegT(ic)&rafTime<=addCEndT(ic));
                    cal(addCix)=1;
                end
            end
            
            if numRCints~=0
                for iRc=1:numRCints
                    removeCIx=find(rafTime>=remCBegT(iRc)&rafTime<=remCEndT(iRc));
                    cal(removeCIx)=0;
                end
            end
            
            if coON
                zero=and(gt(counter,ZeroMin),lt(counter,coZeroLimit));
                status=max(cal*2,zero*1);
            else
                zero = ones(size(counter));
                status = BDF.*zero;
            end
            picStatus=max(cal*2,zcal*2);
            
            %Modify this if statement to control which dataset (picarro or CO) status is being modified
            if numBDFints~=0
                for iBDF=1:numBDFints
                    setBDF=find(rafTime>=bdfBegT(iBDF)&rafTime<=bdfEndT(iBDF));
                    status(setBDF)=BDF;
                    %                 picStatus(setBDF)=BDF;
                end
            end
            
            if numZints~=0
                for iz=1:numZints
                    addZix=find(rafTime>=addZBegT(iz)&rafTime<=addZEndT(iz));
                    status(addZix)=1;
                end
            end
            
        case 'rf12'
            numCints=7;
            numRCints=0;
            numBDFints=0;
            numZints=0;
            
            addCBegT=[52206 55806 59406 63006 66606 70206 73805];
            addCEndT=[52324 55924 59524 63124 66724 70323 73924];
            
            remCBegT=[];
            remCEndT=[];
            
            bdfBegT=[];
            bdfEndT=[];
            
            addZBegT=[];
            addZEndT=[];
            
            if numCints~=0
                for ic=1:numCints
                    addCix=find(rafTime>=addCBegT(ic)&rafTime<=addCEndT(ic));
                    cal(addCix)=1;
                end
            end
            
            if numRCints~=0
                for iRc=1:numRCints
                    removeCIx=find(rafTime>=remCBegT(iRc)&rafTime<=remCEndT(iRc));
                    cal(removeCIx)=0;
                end
            end
            
            if coON
                zero=and(gt(counter,ZeroMin),lt(counter,coZeroLimit));
                status=max(cal*2,zero*1);
            else
                zero = ones(size(counter));
                status = BDF.*zero;
            end
            picStatus=max(cal*2,zcal*2);
            
            %Modify this if statement to control which dataset (picarro or CO) status is being modified
            if numBDFints~=0
                for iBDF=1:numBDFints
                    setBDF=find(rafTime>=bdfBegT(iBDF)&rafTime<=bdfEndT(iBDF));
                    status(setBDF)=BDF;
                    %                 picStatus(setBDF)=BDF;
                end
            end
            
            if numZints~=0
                for iz=1:numZints
                    addZix=find(rafTime>=addZBegT(iz)&rafTime<=addZEndT(iz));
                    status(addZix)=1;
                end
            end
            
        case 'rf13'
            numCints=0;
            numRCints=0;
            numBDFints=1;
            numZints=0;
            
            addCBegT=[];
            addCEndT=[];
            
            remCBegT=[];
            remCEndT=[];
            
            bdfBegT=[55806];
            bdfEndT=[55827];
            
            addZBegT=[];
            addZEndT=[];
            
            if numCints~=0
                for ic=1:numCints
                    addCix=find(rafTime>=addCBegT(ic)&rafTime<=addCEndT(ic));
                    cal(addCix)=1;
                end
            end
            
            if numRCints~=0
                for iRc=1:numRCints
                    removeCIx=find(rafTime>=remCBegT(iRc)&rafTime<=remCEndT(iRc));
                    cal(removeCIx)=0;
                end
            end
            
            if coON
                zero=and(gt(counter,ZeroMin),lt(counter,coZeroLimit));
                status=max(cal*2,zero*1);
            else
                zero = ones(size(counter));
                status = BDF.*zero;
            end
            picStatus=max(cal*2,zcal*2);
            
            %Modify this if statement to control which dataset (picarro or CO) status is being modified
            if numBDFints~=0
                for iBDF=1:numBDFints
                    setBDF=find(rafTime>=bdfBegT(iBDF)&rafTime<=bdfEndT(iBDF));
                    %                     status(setBDF)=BDF;
                    picStatus(setBDF)=BDF;
                end
            end
            
            if numZints~=0
                for iz=1:numZints
                    addZix=find(rafTime>=addZBegT(iz)&rafTime<=addZEndT(iz));
                    status(addZix)=1;
                end
            end
            
        case 'rf14'
            numCints=0;
            numRCints=0;
            numBDFints=0;
            numZints=1;
            
            addCBegT=[];
            addCEndT=[];
            
            remCBegT=[];
            remCEndT=[];
            
            bdfBegT=[];
            bdfEndT=[];
            
            addZBegT=[74108];
            addZEndT=[74178];
            
            if numCints~=0
                for ic=1:numCints
                    addCix=find(rafTime>=addCBegT(ic)&rafTime<=addCEndT(ic));
                    cal(addCix)=1;
                end
            end
            
            if numRCints~=0
                for iRc=1:numRCints
                    removeCIx=find(rafTime>=remCBegT(iRc)&rafTime<=remCEndT(iRc));
                    cal(removeCIx)=0;
                end
            end
            
            if coON
                zero=and(gt(counter,ZeroMin),lt(counter,coZeroLimit));
                status=max(cal*2,zero*1);
            else
                zero = ones(size(counter));
                status = BDF.*zero;
            end
            picStatus=max(cal*2,zcal*2);
            
            %Modify this if statement to control which dataset (picarro or CO) status is being modified
            if numBDFints~=0
                for iBDF=1:numBDFints
                    setBDF=find(rafTime>=bdfBegT(iBDF)&rafTime<=bdfEndT(iBDF));
                    %                     status(setBDF)=BDF;
                    picStatus(setBDF)=BDF;
                end
            end
            
            if numZints~=0
                for iz=1:numZints
                    addZix=find(rafTime>=addZBegT(iz)&rafTime<=addZEndT(iz));
                    status(addZix)=1;
                end
            end
            
        case 'rf15'
            numCints=1;
            numRCints=0;
            numBDFints=0;
            numZints=1;
            
            addCBegT=[77406];
            addCEndT=[77525];
            
            remCBegT=[];
            remCEndT=[];
            
            bdfBegT=[];
            bdfEndT=[];
            
            addZBegT=[77472];
            addZEndT=[77540];
            
            if numCints~=0
                for ic=1:numCints
                    addCix=find(rafTime>=addCBegT(ic)&rafTime<=addCEndT(ic));
                    cal(addCix)=1;
                end
            end
            
            if numRCints~=0
                for iRc=1:numRCints
                    removeCIx=find(rafTime>=remCBegT(iRc)&rafTime<=remCEndT(iRc));
                    cal(removeCIx)=0;
                end
            end
            
            if coON
                zero=and(gt(counter,ZeroMin),lt(counter,coZeroLimit));
                status=max(cal*2,zero*1);
            else
                zero = ones(size(counter));
                status = BDF.*zero;
            end
            picStatus=max(cal*2,zcal*2);
            
            %Modify this if statement to control which dataset (picarro or CO) status is being modified
            if numBDFints~=0
                for iBDF=1:numBDFints
                    setBDF=find(rafTime>=bdfBegT(iBDF)&rafTime<=bdfEndT(iBDF));
                    %                     status(setBDF)=BDF;
                    picStatus(setBDF)=BDF;
                end
            end
            
            if numZints~=0
                for iz=1:numZints
                    addZix=find(rafTime>=addZBegT(iz)&rafTime<=addZEndT(iz));
                    status(addZix)=1;
                end
            end
            
        case 'rf16'
            numCints=7;
            numRCints=0;
            numBDFints=0;
            numZints=0;
            
            addCBegT=[55806 59406 63005 66609 70207 73806 77406];
            addCEndT=[55924 59524 63124 66725 70326 73924 77524];
            
            remCBegT=[];
            remCEndT=[];
            
            bdfBegT=[];
            bdfEndT=[];
            
            addZBegT=[];
            addZEndT=[];
            
            if numCints~=0
                for ic=1:numCints
                    addCix=find(rafTime>=addCBegT(ic)&rafTime<=addCEndT(ic));
                    cal(addCix)=1;
                end
            end
            
            if numRCints~=0
                for iRc=1:numRCints
                    removeCIx=find(rafTime>=remCBegT(iRc)&rafTime<=remCEndT(iRc));
                    cal(removeCIx)=0;
                end
            end
            
            if coON
                zero=and(gt(counter,ZeroMin),lt(counter,coZeroLimit));
                status=max(cal*2,zero*1);
            else
                zero = ones(size(counter));
                status = BDF.*zero;
            end
            picStatus=max(cal*2,zcal*2);
            
            %Modify this if statement to control which dataset (picarro or CO) status is being modified
            if numBDFints~=0
                for iBDF=1:numBDFints
                    setBDF=find(rafTime>=bdfBegT(iBDF)&rafTime<=bdfEndT(iBDF));
                    %                     status(setBDF)=BDF;
                    picStatus(setBDF)=BDF;
                end
            end
            
            if numZints~=0
                for iz=1:numZints
                    addZix=find(rafTime>=addZBegT(iz)&rafTime<=addZEndT(iz));
                    status(addZix)=1;
                end
            end
            
        case 'rf17'
            numCints=1;
            numRCints=0;
            numBDFints=2;
            numZints=0;
            
            addCBegT=[55806];
            addCEndT=[55924];
            
            remCBegT=[];
            remCEndT=[];
            
            bdfBegT=[68570 75465];
            bdfEndT=[68570 75465];
            
            addZBegT=[];
            addZEndT=[];
            
            if numCints~=0
                for ic=1:numCints
                    addCix=find(rafTime>=addCBegT(ic)&rafTime<=addCEndT(ic));
                    cal(addCix)=1;
                end
            end
            
            if numRCints~=0
                for iRc=1:numRCints
                    removeCIx=find(rafTime>=remCBegT(iRc)&rafTime<=remCEndT(iRc));
                    cal(removeCIx)=0;
                end
            end
            
            if coON
                zero=and(gt(counter,ZeroMin),lt(counter,coZeroLimit));
                status=max(cal*2,zero*1);
            else
                zero = ones(size(counter));
                status = BDF.*zero;
            end
            picStatus=max(cal*2,zcal*2);
            
            %Modify this if statement to control which dataset (picarro or CO) status is being modified
            if numBDFints~=0
                for iBDF=1:numBDFints
                    setBDF=find(rafTime>=bdfBegT(iBDF)&rafTime<=bdfEndT(iBDF));
                    status(setBDF)=BDF;
                    %                     picStatus(setBDF)=BDF;
                end
            end
            
            if numZints~=0
                for iz=1:numZints
                    addZix=find(rafTime>=addZBegT(iz)&rafTime<=addZEndT(iz));
                    status(addZix)=1;
                end
            end
            
        case 'rf18'
            numCints=2;
            numRCints=0;
            numBDFints=2;
            numZints=1;
            
            addCBegT=[88205 91805];
            addCEndT=[88323 91923];
            
            remCBegT=[];
            remCEndT=[];
            
            bdfBegT=[73920 88204];
            bdfEndT=[73923 88323];
            
            addZBegT=[88241];
            addZEndT=[88308];
            
            if numCints~=0
                for ic=1:numCints
                    addCix=find(rafTime>=addCBegT(ic)&rafTime<=addCEndT(ic));
                    cal(addCix)=1;
                end
            end
            
            if numRCints~=0
                for iRc=1:numRCints
                    removeCIx=find(rafTime>=remCBegT(iRc)&rafTime<=remCEndT(iRc));
                    cal(removeCIx)=0;
                end
            end
            
            if coON
                zero=and(gt(counter,ZeroMin),lt(counter,coZeroLimit));
                status=max(cal*2,zero*1);
            else
                zero = ones(size(counter));
                status = BDF.*zero;
            end
            picStatus=max(cal*2,zcal*2);
            
            %Modify this if statement to control which dataset (picarro or CO) status is being modified
            if numBDFints~=0
                for iBDF=1:numBDFints
                    setBDF=find(rafTime>=bdfBegT(iBDF)&rafTime<=bdfEndT(iBDF));
                    status(setBDF)=BDF;
                    %                     picStatus(setBDF)=BDF;
                end
            end
            
            if numZints~=0
                for iz=1:numZints
                    addZix=find(rafTime>=addZBegT(iz)&rafTime<=addZEndT(iz));
                    status(addZix)=1;
                end
            end
            
        case 'rf19'
            numCints=5;
            numRCints=0;
            numBDFints=1;
            numZints=1;
            
            addCBegT=[59410 63010 66609 70206 73806];
            addCEndT=[59524 63125 66724 70324 73924];
            
            remCBegT=[];
            remCEndT=[];
            
            bdfBegT=[73806];
            bdfEndT=[73924];
            
            addZBegT=[73833];
            addZEndT=[73901];
            
            if numCints~=0
                for ic=1:numCints
                    addCix=find(rafTime>=addCBegT(ic)&rafTime<=addCEndT(ic));
                    cal(addCix)=1;
                end
            end
            
            if numRCints~=0
                for iRc=1:numRCints
                    removeCIx=find(rafTime>=remCBegT(iRc)&rafTime<=remCEndT(iRc));
                    cal(removeCIx)=0;
                end
            end
            
            if coON
                zero=and(gt(counter,ZeroMin),lt(counter,coZeroLimit));
                status=max(cal*2,zero*1);
            else
                zero = ones(size(counter));
                status = BDF.*zero;
            end
            picStatus=max(cal*2,zcal*2);
            
            %Modify this if statement to control which dataset (picarro or CO) status is being modified
            if numBDFints~=0
                for iBDF=1:numBDFints
                    setBDF=find(rafTime>=bdfBegT(iBDF)&rafTime<=bdfEndT(iBDF));
                    status(setBDF)=BDF;
                    %                     picStatus(setBDF)=BDF;
                end
            end
            
            if numZints~=0
                for iz=1:numZints
                    addZix=find(rafTime>=addZBegT(iz)&rafTime<=addZEndT(iz));
                    status(addZix)=1;
                end
            end
            
        otherwise
            if coON
                zero=and(gt(counter,ZeroMin),lt(counter,coZeroLimit));
                status=max(cal*2,zero*1);
            picStatus=max(cal*2,zcal*2);
            else
                zero = ones(size(counter));
                status = BDF.*zero;
            picStatus=cal*2;
            end
    end
    
    %Below switch/if statements are used to interpolate over NaN gaps within cals ONLY (or any user-defined space)
    switch fltnoLC
        case 'rf10'
            picNumCals=7;
            begCalT=[55802 59401 63009 66609 70202 73801 77401];
            endCalT=[55919 59519 63119 66719 70319 73919 77519];
        case 'rf12'
            picNumCals=7;
            begCalT=[52206 55806 59406 63006 66606 70206 73805];
            endCalT=[52324 55924 59524 63124 66724 70323 73924];
        case 'rf16'
            picNumCals=7;
            begCalT=[55806 59406 63005 66609 70207 73806 77406];
            endCalT=[55924 59524 63124 66725 70326 73924 77524];
        case 'rf19'
            picNumCals=5;
            begCalT=[59410 63010 66609 70206 73806];
            endCalT=[59524 63125 66724 70324 73924];
            
    end
    
    %Only executes cal NaN gap filling if a flight has manually defined cal ranges in the switch above
    if exist('begCalT','var')
        co2BeforeNewCal=co2;
        ch4BeforeNewCal=ch4;
        
        for ix=1:picNumCals
            calSpanT=(begCalT(ix):endCalT(ix));
            begCalIx=find(rafTime==begCalT(ix));
            endCalIx=find(rafTime==endCalT(ix));
            calSpanIx=(begCalIx:endCalIx);
            picNewco2Cal=co2(calSpanIx);
            picNewch4Cal=ch4(calSpanIx);
            picNewCalIx=find(~isnan(picNewco2Cal));
            gdCo2Cal=picNewco2Cal(picNewCalIx);
            gdCh4Cal=picNewch4Cal(picNewCalIx);
            gdNewCalT=calSpanT(picNewCalIx);
            
            finalNewCo2Cal=interp1(gdNewCalT,gdCo2Cal,calSpanT,'nearest');
            finalNewCh4Cal=interp1(gdNewCalT,gdCh4Cal,calSpanT,'nearest');
            
            for iix=1:length(calSpanT)
                co2(calSpanIx(iix))=finalNewCo2Cal(iix);
                ch4(calSpanIx(iix))=finalNewCh4Cal(iix);
                picStatus(calSpanIx(iix))=2;
            end
        end
    end
    
%***
    picStatIx=find(picStatus==2);
    figure(104);plot(rafTime,co2,'k.',rafTime(picStatIx),co2(picStatIx),'r.');
    title(['NOMADSS  ' char(fltno)  '  ' char(FltDate) '  1301 with status'],'FontSize',14);grid;
    
    figure(105);plot(rafTime,co2pic2,'k.',rafTime(picStatIx),co2pic2(picStatIx),'r.');grid
    title(['NOMADSS  ' char(fltno)  '  ' char(FltDate) '  2311 with status'],'FontSize',14);grid;
    
    statZIx=find(status==1);
    statIx=find(status==2);
    if coON
    figure(106);plot(rafTime,counter,'k.',rafTime(statZIx),counter(statZIx),'g.',rafTime(statIx),counter(statIx),'r.');grid;
    end
        
    
    cd([StartPath slash fltnoLC]);
    
    if processNC
        rafAlt=nc_varget(ncFile,'GGALT');
        rafP=nc_varget(ncFile,'PSXC');
        rafPcab=nc_varget(ncFile,'PCAB');
        mrgP=rafP;
        wic=nc_varget(ncFile,'WIC');
        rafCO=concentration;
        %         theta=rafDat3(:,5);
        atx=nc_varget(ncFile,'ATX');
        %       o3_csd=nc_varget(ncFile,'O3_CSD');
        %     vxlNumDen=nc_varget(ncFile,'CONC_H2O_VXL');
        %     vxlmr=vxlNumDen./(6.02214.*(10.^17)).*82.0575.*(atx+273.15)./(psxc./1013.25);
%         rafMR=nc_varget(ncFile,'MR');
        %     co_qcl=nc_varget(ncFile,'CO_QLIVE');

        if coON
        figure(99),plot(rafTime,counter,'r.');
        title(['NOMADSS  ' char(fltno)  '  ' char(FltDate)],'FontSize',14);
        %ylim([0 700000]);
        saveas(gcf,[ 'pix' slash char(Flight) '.rawMedFilt.fig'],'fig');
        saveas(gcf,[ 'pix' slash char(Flight) '.rawMedFilt.jpg'],'jpg');
        end
    else
        rafTime=UTC; %#ok<*UNRCH>
        rafAlt=GGALT;
        rafP=PSXC;
        rafPcab=PCAB;
        mrgP=rafP;
        wic=WIC;
        rafCO=concentration;
        atx=ATX;
        %         vxlNumDen=CONC_H2O_VXL;
        %         vxlmr=vxlNumDen./(6.02214.*(10.^17)).*82.0575.*(atx+273.15)./(rafP./1013.25);
        %         co_qcl=CO_QLIVE;
    end
    time=double(rafTime);
end

counterIntermed=counter;

if FlightData && processGV==0
    
% else if FlightData
        
        %         fid3=fopen(rafFile,'r');
        %         for ix=1:rafHdrLns
        %             rafHdr=fgetl(fid3);
        %         end
        %         aryIx=0;
        %         rafDat1=[];
        %         rafDat2=[];
        %         rafDat3=[];
        %         while ~feof(fid3)
        %             %         aryIx=aryIx+1;
        % %             rafDat1=fscanf(fid3,...
        % %                 '%d %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f\n %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f\n %f %f %f %f\n',[45,inf]);
        %             rafDat1=[rafDat1, fscanf(fid3,'%d %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f\n',[21,1])];
        %             rafDat2=[rafDat2, fscanf(fid3,' %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f\n',[20,1])];
        %             rafDat3=[rafDat3, fscanf(fid3,' %f %f %f %f %f\n',[5,1])];
        %         end
        %         fclose(fid3);
        % Format changed from HIPPO_1
        %         rafDat1=data(1:3:end-2,:);
        %         rafDat2=data(2:3:end-1,:);
        %         rafDat3=data(3:3:end,:);
        
        %             rafTime=data(:,1);
        %             mrgTime=rafTime;
        %             comr_al=data(:,14);
        %             rafAlt=data(:,17);
        %             rafP=data(:,3);
        %             wic=data(:,11);
        %             rafCO=comr_al;
        %             %         theta=rafDat3(:,5);
        %             atx=data(:,2);
        %             o3_csd=data(:,36);
        %             switch fltnoLC %HIPPO-1 code:
        %                 %             case'rf09'
        %                 %                 qclsT=mrgTime;
        %                 %                 co_qcls=BDF.*ones(size(mrgTime));
        %                 %             case'rf10'
        %                 %                 qclsT=mrgTime;
        %                 %                 co_qcls=BDF.*ones(size(mrgTime));
        %                 %             case'rf11'
        %                 %                 qclsT=mrgTime;
        %                 %                 co_qcls=BDF.*ones(size(mrgTime));
        %                 otherwise
        %             end
        %     end
        
%     end
    
    %     [rafInterval,status]=nc_attget(rafFile,nc_global,'TimeInterval');
    %     rafMissionT=nc_varget(rafFile,'Time');
    %     rafHrBeg=rafInterval(1:2);
    %     rafMnBeg=rafInterval(4:5);
    %     rafScBeg=rafInterval(7:8);
    %     rafHrEnd=rafInterval(10:11);
    %     rafMnEnd=rafInterval(13:14);
    %     rafScEnd=rafInterval(16:17);
    %     rafStartT=str2num(rafHrBeg).*3600+str2num(rafMnBeg).*60+str2num(rafScBeg);
    %     rafTime=rafMissionT + rafStartT;
    %     rafEndT=str2num(rafHrEnd).*3600+str2num(rafMnEnd).*60+str2num(rafScEnd);
    %
    %     rafAlt=nc_varget(rafFile,'GGALT');
    %     rafP=nc_varget(rafFile,'PSXC');
    %     rafTheta=nc_varget(rafFile,'THETA');
    %     rafThetaE=nc_varget(rafFile,'THETAE');
    %     rafThetaV=nc_varget(rafFile,'THETAV');
    %     mr=nc_varget(rafFile,'MR');
    
    altIx=find(isnan(rafAlt)==0|rafAlt==BDF);
    if processNC==0
        mrgAlt=interp1(rafTime(altIx),rafAlt(altIx),time);
        pIx=find(isnan(rafP)==0);
        mrgP=interp1(rafTime(pIx),rafP(pIx),time);
    else
        mrgAlt=rafAlt;
        mrgP=rafP;
    end
    %     thetaIx=find(isnan(rafTheta)==0);
    %     mrgTheta=interp1(rafTime(thetaIx),rafTheta(thetaIx),time);
    %     thetaEix=find(isnan(rafThetaE)==0);
    %     mrgThetaE=interp1(rafTime(thetaEix),rafThetaE(thetaEix),time);
    %     thetaVix=find(isnan(rafThetaV)==0);
    %     mrgThetaV=interp1(rafTime(thetaVix),rafThetaV(thetaVix),time);
    %     mrIx=find(isnan(mr)==0);
    %     mrgMR=interp1(rafTime(mrIx),mr(mrIx),time);
    
    %     figure(8);
    %     plot(mrgMR,mrgTheta);title(['HIPPO  ' char(fltno)  '  ' char(FltDate)],'FontSize',14);
    %     saveas(gcf,[char(Flight) slash 'pix' slash char(Flight) '.mr.vs.theta.fig'],'fig');
    %     saveas(gcf,[char(Flight) slash 'pix' slash char(Flight) '.mr.vs.theta.jpg'],'jpg');
    %     pTorr=mrgP./1013*760;
    %     % for HIPPO-Global Phase 1 mission, correct data for altitude dependent
    %     % sensitivity.
    %     % dCts=2.868843e-3.*exp(2.156909e-2.*pTorr-1.2941451);
    %     corrFactor=1+(7.174285e-8.*exp(2.156909e-2.*pTorr-0.3230352));
    %     % counter=counter.*corrFactor;
    %     corrIx=find(pTorr>400);
    %     hiPix=find(pTorr>700);
    %     corrFactor(hiPix)=1.19;
    %     % counter=counter.*corrFactor;
    % counter(corrIx)=counter(corrIx).*corrFactor(corrIx);
    % counter(corrIx)=counter(corrIx)-dCts(corrIx);
    % counter=counter.*hrCellP;
    
    %comrCorr=(counter+dCts-zFit)./(sens2 - zFit).*tankCon;
end % if FlightData?

%vars for interpolation of NaNs
coOrig = counter;
co2orig = co2;                      %original CO2 array from raw data
co2origTime = rafTime;
co2goodix = find(isnan(co2) == 0);
co2good = co2(co2goodix);           %non-NaN CO2
co2time = rafTime(co2goodix);
ch4orig = ch4;                      %original ch4 array from raw data
ch4good = ch4(co2goodix);
ch4time = rafTime(co2goodix);       %non-NaN CH4

co2pic2orig = co2pic2;
ch4pic2orig = ch4pic2;
h2opic2orig = h2opic2;

if despike
    co2 = medfilt1(co2,3);
    ch4 = medfilt1(ch4,3);
    counter = medfilt1(counter,3);
    co2pic2 = medfilt1(co2pic2,3);
    ch4pic2 = medfilt1(ch4pic2,3);
    h2opic2 = medfilt1(h2opic2,3);
end

if processRaw1301
    co2(cavPBadIx1301)=BDF;
    ch4(cavPBadIx1301)=BDF;
    
    figure(107);
    plot(rafTime,co2orig,'r.',rafTime,co2,'k.');title([proj '  ' char(fltno)  '  ' char(FltDate) ' Picarro 1031 cavPres determined CO2 BDF'],'FontSize',14);grid
    legend('Orig CO_2 1301','Adj CO_2 1301');
    
    
    figure(108);
    plot(rafTime,ch4orig,'r.',rafTime,ch4,'k.');title([proj '  ' char(fltno)  '  ' char(FltDate) ' Picarro 1031 cavPres determined CH4 BDF'],'FontSize',14);grid
    legend('Orig CH_4 1301','Adj CH_4 1301');
end

if processRawUser2311
    co2pic2(cavPBadIx2311)=BDF;
    ch4pic2(cavPBadIx2311)=BDF;
    h2opic2(cavPBadIx2311)=BDF;
    
    figure(109);
    plot(rafTime,co2pic2orig,'r.',rafTime,co2pic2,'k.');title([proj '  ' char(fltno)  '  ' char(FltDate) ' Picarro 2311 cavPres determined CO2 BDF'],'FontSize',14);grid
    legend('Orig CO_2 2311','Adj CO_2 2311');
    
    
    figure(110);
    plot(rafTime,ch4pic2orig,'r.',rafTime,ch4pic2,'k.');title([proj '  ' char(fltno)  '  ' char(FltDate) ' Picarro 2311 cavPres determined CH4 BDF'],'FontSize',14);grid
    legend('Orig CH_4 2311','Adj CH_4 2311');
end


%interpolate NaN gaps when data dropouts (from neg dtime) occur during cals
%6/21/12 move this code into a flight specific case statement, below
% co2=medfilt1(co2,3);
%  co2 = interp1(co2time, co2good, rafTime);
%  ch4 = interp1(ch4time, ch4good, rafTime);
%co2 = co2good;
%rafTime = co2time;
%ch4 = ch4good;

% switch fltnoLC %dc-3 hardwired edits
%     case 'rf08'
%  co2 = interp1(co2time, co2good, rafTime);
%  ch4 = interp1(ch4time, ch4good, rafTime);
%         tmpix = find(rafTime >= 84685 & rafTime <= 84706);
%         status(tmpix) = 2;
%         picStatus(tmpix) = 2;
%         tmpix = find(rafTime >= 84728 & rafTime <= 84761);
%         status(tmpix) = 0;
%         picStatus(tmpix) = 0;
%         tmpix = find(rafTime >= 84762 & rafTime <= 84780);
%         status(tmpix) = BDF;
%         picStatus(tmpix) = BDF;
%     case 'rf09'
%  co2 = interp1(co2time, co2good, rafTime);
%  ch4 = interp1(ch4time, ch4good, rafTime);
%         tmpix = find(rafTime >= 77521 & rafTime <= 77534);
%         status(tmpix) = 2;
%         picStatus(tmpix) = 2;
%         tmpix = find(rafTime <= 77582 & rafTime >= 77535);
%         status(tmpix) = 0;
%         picStatus(tmpix) = 0;
%     case 'rf10'
%         tmpix = find(rafTime >= 73806 & rafTime <= 73827);
%         status(tmpix) = 2;
%         picStatus(tmpix) = 2;
%         tmpix = find(rafTime >= 75605 & rafTime <= 75726);
%         status(tmpix) = 2;
%         tmpix = find(rafTime >= 84607 & rafTime <= 84727);
% %         status(tmpix) = 2;
% %         picStatus(tmpix) = 2;
%     case 'rf12'
%         co2orig=co2;
%  co2 = interp1(co2time, co2good, rafTime);
%  ch4 = interp1(ch4time, ch4good, rafTime);
% co2smth=medfilt1(co2,5);
% co2=co2smth;
%
% end

if coON
figure(3),plot(time,counter,'b.',time,status.*10000,'r.');
title([proj '  ' char(fltno)  '  ' char(FltDate)],'FontSize',14);
saveas(gcf,[ 'pix' slash char(Flight) '.rawWstatus.fig'],'fig');
saveas(gcf,[ 'pix' slash char(Flight) '.rawWstatus.jpg'],'jpg');
figure(31), plot(time, co2, 'b.', time, status.*200, 'r.');
end


figure(35),plot(time,co2,'b.',time,picStatus.*196.5,'r.');
title([proj '  ' char(fltno)  '  ' char(FltDate) ' CO_2'],'FontSize',14);
saveas(gcf,[ 'pix' slash char(Flight) '.PICrawWstatus.fig'],'fig');
saveas(gcf,[ 'pix' slash char(Flight) '.PICrawWstatus.jpg'],'jpg');



%Flag cal cycle borders with BDF
ADJstatus=status;  %adjusted status to add BDF's
ADJpicStatus=picStatus;

for ii=2:length(cal)
    if status(ii)-status(ii-1)~=0
        %Flag data after cal (up to DataAfterCal) with BDF
        %NOTE: The second part of the if statement below eliminates data flagged as
        % zero between the cal and the zero
        if (ii+after) <= length(status)
            tempvar=sort(ii+after,length(status));
        else tempvar=sort(length(status),length(status));
        end
        if status(ii)==0 && status(tempvar(1))==0
            ADJstatus(ii:ii+DataAfterCal)=BDF;
        end
        if ii>before
            ADJstatus(ii-before:ii+after)=BDF;
        else
            ADJstatus(1:before)=BDF;
        end
    end
    if picStatus(ii)-picStatus(ii-1)~=0
        %Flag data after cal (up to DataAfterCal) with BDF
        %NOTE: The second part of the if statement below eliminates data flagged as
        % zero between the cal and the zero
        if (ii+after) <= length(picStatus)
            tempvar=sort(ii+after,length(picStatus));
        else tempvar=sort(length(picStatus),length(picStatus));
        end
        if picStatus(ii)==0 && picStatus(tempvar(1))==0
            ADJpicStatus(ii:ii+DataAfterCal)=BDF;
        end
        if ii>before
            ADJpicStatus(ii-before:ii+after)=BDF;
        else
            ADJpicStatus(1:before)=BDF;
        end
    end
end

%Truncate extra BDF values at end of ADJstatus
ADJstatus=ADJstatus(1:length(status));
ADJpicStatus=ADJpicStatus(1:length(picStatus));

%Set cal status using ADJstatus
calindex=find(ADJstatus==2);
zeroindex=find(ADJstatus==1);
baddataindex=find(ADJstatus==BDF);


picCalindex=find(ADJpicStatus==2 & co2~=BDF); %Added the co2~=BDF 7/5/13 by DS
picBaddataindex=find(ADJpicStatus==BDF);


%Create new variables containing only good data of types ambient, cal and
%zero.
ambindex=find(ADJstatus==0);
calTime=time(calindex);
zTime=time(zeroindex);
ambTime=time(ambindex);
calDat=counter(calindex);
zDat=counter(zeroindex);
ambDat=counter(ambindex);
zPdat=hrCellP(zeroindex);
calPdat=hrCellP(calindex);
if FlightData && processGV==0
    calAltdat=mrgAlt(calindex);
    zAltDat=mrgAlt(zeroindex);
end
if coON
    dCalTime=diff(calTime);
    dZtime=diff(zTime);
    calChangeIx=find(dCalTime>1);
    zChangeIx=find(dZtime>1);
    
    calEndIx=calChangeIx;
    zEndIx=zChangeIx;
    
    calStartIx=calEndIx+1;
    zStartIx=zEndIx+1;
    calStartIx=[1; calStartIx];
    zStartIx=[1; zStartIx];
    
    calEndIx=[calEndIx; length(calTime)];
    zEndIx=[zEndIx; length(zTime)];
    
    calStartTimes=calTime(calStartIx);
    zStartTimes=zTime(zStartIx);
    calEndTimes=calTime(calEndIx);
    zEndTimes=zTime(zEndIx);
    
    numCals=length(calStartIx);
    numZeroes=length(zStartIx);
end

picAmbindex=find(ADJpicStatus==0);
picCalTime=time(picCalindex);
picAmbTime=time(picAmbindex);
picCalDat=co2(picCalindex);
picAmbDat=co2(picAmbindex);
if FlightData && processGV==0
    picCalAltdat=mrgAlt(picCalindex);
end

picdCalTime=diff(picCalTime);
picCalChangeIx=find(picdCalTime>1);

picCalEndIx=picCalChangeIx;

picCalStartIx=picCalEndIx+1;
picCalStartIx=[1; picCalStartIx];

picCalEndIx=[picCalEndIx; length(picCalTime)];

picCalStartTimes=picCalTime(picCalStartIx);
picCalEndTimes=picCalTime(picCalEndIx);

picNumCals=length(picCalStartIx);



% insert code to allow removal of bad or non-cals
if coON
    calIxAvg=[];
    zIxAvg=[];
    tCalAvg=[];
    calAvg=[];
    tZavg=[];
    zAvg=[];
    zeroPavg=[];
    ambNearZ=[];
    calPavg=[];
    
    zAltavg=[];
    calAltavg=[];
    for ix=1:numCals
        badAlert=find(badCals==ix);
        
        if isempty(badAlert)
            calIxAvg=[calIxAvg; (calStartIx(ix)+calEndIx(ix))./2];
            tCalAvg=[tCalAvg; mean(calStartTimes(ix):calEndTimes(ix))];
            calAvg=[calAvg; mean(calDat(calStartIx(ix):calEndIx(ix)))];
            calPavg=[calPavg; mean(calPdat(calStartIx(ix):calEndIx(ix)))];
            if FlightData && processGV==0
                calAltavg=[calAltavg; mean(calAltdat(calStartIx(ix):calEndIx(ix)))];
            end
        end
        if ~isempty(badAlert)
            for subix=1:length(badCals)
                if ix==badCals(subix)
                    resetAmbIx=find(rafTime>(calStartTimes(ix)-before)&rafTime<(calEndTimes(ix)+after));
                    ADJstatus(resetAmbIx)=BDF;
                end
            end
        end
    end
    
    
    for ix=1:numZeroes
        zIxAvg=[zIxAvg (zStartIx(ix)+zEndIx(ix))./2];
        zAvg=[zAvg; min(zDat(zStartIx(ix):zEndIx(ix)))+100];
        %     zAvg=[zAvg; mean(zDat(zStartIx(ix):zEndIx(ix)))];
        tZavg=[tZavg; mean(zTime(zStartIx(ix):zEndIx(ix)))];
        zeroPavg=[zeroPavg; mean(zPdat(zStartIx(ix):zEndIx(ix)))];
        if FlightData && processGV==0
            zAltavg=[zAltavg; mean(zAltDat(zStartIx(ix):zEndIx(ix)))];
        end
        %     ambNearZ=[ambNearZ; mean(counter(zStartIx(ix)-180),counter(zStartIx(ix)+60))];
    end
end

picCalIxAvg=[];
picTCalAvg=[];
picCalAvg=[];
picTZavg=[];
picCalAltavg=[];
for ix=1:picNumCals
    picBadAlert=find(picBadCals1301==ix);
    
    if isempty(picBadAlert)
        picCalIxAvg=[picCalIxAvg; (picCalStartIx(ix)+picCalEndIx(ix))./2];
        picTCalAvg=[picTCalAvg; mean(picCalStartTimes(ix):picCalEndTimes(ix))];
        picCalAvg=[picCalAvg; mean(picCalDat(picCalStartIx(ix):picCalEndIx(ix)))];
        if FlightData && processGV==0
            picCalAltavg=[picCalAltavg; mean(picCalAltdat(picCalStartIx(ix):picCalEndIx(ix)))];
        end
    end
    if ~isempty(picBadAlert)
        for subix=1:length(picBadCals1301)
            if ix==picBadCals1301(subix)
                picResetAmbIx=find(rafTime>(picCalStartTimes(ix)-before)&rafTime<(picCalEndTimes(ix)+after));  %Do before and after vars need new pic versions?
                ADJpicStatus(picResetAmbIx)=BDF;
            end
        end
    end
end


if coON
    figure(4);
    plot(time,counter,'k.',tCalAvg,calAvg,'b.',tZavg,zAvg,'r.');title([proj '  ' char(fltno)  '  ' char(FltDate)],'FontSize',14);
    saveas(gcf,[ 'pix' slash char(Flight) '.co.raw.fig'],'fig');
    saveas(gcf,[ 'pix' slash char(Flight) '.co.raw.jpg'],'jpg');
end


figure(45);
plot(time,co2,'b.',picTCalAvg,picCalAvg,'y.');title([proj '  ' char(fltno)  '  ' char(FltDate) ' CO_2'],'FontSize',14);
saveas(gcf,[ 'pix' slash char(Flight) '.co2.raw.fig'],'fig');
saveas(gcf,[ 'pix' slash char(Flight) '.co2.raw.jpg'],'jpg');



figure(46);
plot(time,ch4,'b.',picTCalAvg,picCalAvg,'y.');title([proj '  ' char(fltno)  '  ' char(FltDate) ' CH_4'],'FontSize',14);
%ylim([ 1.6 2]);
saveas(gcf,[ 'pix' slash char(Flight) '.ch4.raw.fig'],'fig');
saveas(gcf,[ 'pix' slash char(Flight) '.ch4.raw.jpg'],'jpg');


% [badCals,badZs]=editCOcals_dialog_box(tCalAvg,calAvg,tZavg,zAvg,numCals,numZeroes);


% calStartTime(1)=calTime(1)
if coON
    numBadCals=length(badCals);
    numBadZs=length(badZs);
    
    alltCalAvg=tCalAvg;
    allCalAvg=calAvg;
    allCalPavg=calPavg;
    allCalAltavg=calAltavg;
    alltZavg=tZavg;
    allZavg=zAvg;
    allZaltavg=zAltavg;
    allZpavg=zeroPavg;
    
    
    tCalAvg(badCals)=BDF;
    gdCalIx=find(tCalAvg>0);
    bdCalIx=find(tCalAvg<0);
    
    tZavg(badZs)=BDF;
    gdZIx=find(tZavg>0);
    
    badTcalAvg=tCalAvg(bdCalIx);
    
    tCalAvg=tCalAvg(gdCalIx);
    calAvg=calAvg(gdCalIx);
    calPavg=calPavg(gdCalIx);
    if FlightData && processGV==0
        calAltavg=calAltavg(gdCalIx);
        zAltavg=zAltavg(gdZIx);
    end
    
    tZavg=tZavg(gdZIx);
    zAvg=zAvg(gdZIx);
    zeroPavg=zeroPavg(gdZIx);
end


picNumBadCals=length(picBadCals1301);

picAlltCalAvg=picTCalAvg;
picAllCalAvg=picCalAvg;
picAllCalAltavg=picCalAltavg;


picTCalAvg(picBadCals1301)=BDF;
picGdCalIx=find(picTCalAvg>0);
picBdCalIx=find(picTCalAvg<0);

picBadTcalAvg=picTCalAvg(picBdCalIx);

picTCalAvg=picTCalAvg(picGdCalIx);
picCalAvg=picCalAvg(picGdCalIx);
if FlightData && processGV==0
    picCalAltavg=picCalAltavg(picGdCalIx);
end

if coON
    figure(5);
    plot(time,counter,'b.',tCalAvg,calAvg,'k.',tZavg,zAvg,'r.');title([proj '  ' char(fltno)  '  ' char(FltDate)],'FontSize',14);
    % plot(time,counter,'b.',tCalAvg(gdCalIx),calAvg(gdCalIx),'k.',tZavg(gdZIx),zAvg(gdZIx),'r.');title([proj '  ' char(fltno)  '  ' char(FltDate)],'FontSize',14);
end

figure(55);
plot(time,co2,'b.',picTCalAvg,picCalAvg,'y.');title([proj '  ' char(fltno)  '  ' char(FltDate) ' CO_2'],'FontSize',14);

%     if (isempty(tCalAvg) || length(tCalAvg)==1)
%         'CO sensitivity will not be calculated as there are either no cals/zeros classified or only one. Check to ensure cal/zero max/min are correct.'
%     else
if coON
    sens=[];
    midCalIx=find(and(time>=tCalAvg(1), time<=tCalAvg(end)));
    sens=interp1(tCalAvg,calAvg,time(midCalIx));
    earlyCalIx=find(time<tCalAvg(1));
    lateCalIx=find(time > tCalAvg(end));
    earlySens=ones(size(earlyCalIx)).*sens(1);
    lateSens=ones(size(lateCalIx)).*sens(end);
    % sens=[ones(calIxAvg(1)).*sens(1); sens; ones(lateCalIx).*sens(end)];
    sens2=[earlySens; sens; lateSens];
    
    zFit=[];
    midZix=find(and(time>=tZavg(1),time<=tZavg(end)));
    if length(zAvg)>1
        zFit=interp1(tZavg,zAvg,time(midZix));
    else zFit=zAvg.*ones(size(time(midZix)));
    end
    earlyZix=find(time<tZavg(1));
    lateZix=find(time>tZavg(end));
    earlyZ=ones(size(earlyZix)).*zFit(1);
    lateZ=ones(size(lateZix)).*zFit(end);
    zFit=[earlyZ; zFit; lateZ];
end
%     end

if (isempty(picTCalAvg) || length(picTCalAvg)==1 ) %Arbitrarily chose picTCalAvg here - any number of others would produce same result
    'Picarro sensitivity will not be calculated as there are either no cals classified or only one. Check to ensure cal max/min are correct.'
else
    picSens=[];
    picMidCalIx=find(and(time>=picTCalAvg(1), time<=picTCalAvg(end)));
    picSens=interp1(picTCalAvg,picCalAvg,time(picMidCalIx));
    picEarlyCalIx=find(time<picTCalAvg(1));
    picLateCalIx=find(time > picTCalAvg(end));
    picEarlySens=ones(size(picEarlyCalIx));
    picLateSens=ones(size(picLateCalIx));
    if UseConstPicSens
        avgSens = mean(picCalAvg);
        picEarlySens = picEarlySens.*avgSens;
        picLateSens = picLateSens.*avgSens;
        picSens = ones(size(picSens)).* avgSens;
    else
        picEarlySens = picEarlySens.*picSens(1);
        picLateSens = picLateSens.*picSens(end);
    end
    picSens2=[picEarlySens; picSens; picLateSens];
end

%% HIPPO-1 correction algorithm. Retained for reference convenience.
% switch fltno
%     case 'RF06'
%         zFitUncorr=zFit;
%         zFitCorr=zFit;
%         zCorrIx=find(time>tZavg(3));
%     case 'RF04'
%
%         zFit=[];
% midZix=find(and(time>=tZavg(1),time<=tZavg(end)));
% if length(zAvg)>1
% zFit=interp1(tZavg,zAvg,time(midZix));
% else zFit=zAvg.*ones(size(time(midZix)));
% end
% earlyZix=find(time<tZavg(1));
% lateZix=find(time>tZavg(end));
% earlyZ=ones(size(earlyZix)).*zFit(1);
% lateZ=ones(size(lateZix)).*zFit(end);
% zFit=[earlyZ; zFit; lateZ];
%
% %         modIx=find(time==tZavg(1));
% %         zOrig=zFit;
% %         zFit=sens2./sens2(modIx).*zAvg(1);
% %         zFitUncorr=zFit;
% %         zCorrIx=modIx;
%         % Following are zCorrections from Hippo-1:
% %         zCorrIx=find(time>77400);
% %         zFitCorr(zCorrIx)=(mrgAlt(zCorrIx)-93385)./-11.409; % <-zFit alt
% %         adjustment when no corrFactor applied to counter.
% % Use eqn below when corrFactor adjustment is applied:
% %         zFitCorr(zCorrIx)=(mrgAlt(zCorrIx)-59861)./-6.8318;
% %          zFit=zFitCorr;
%     otherwise
%         zFitUncorr=zFit;
%         zFitCorr=zFit;
%         zCorrIx=find(time>tZavg(1));
% %         zFitCorr(zCorrIx)=(mrgAlt(zCorrIx)-59861)./-6.8318;
% % if FlightData
% %         zFitCorr(zCorrIx)=(mrgAlt(zCorrIx)-93385)./-11.409;
% % end
% %         figure(15);plot(time,zFitUncorr,'b.',time,zFitCorr,'r.');
% %         zFit=zFitCorr;
%
% end
%%
if coON
    figure(6);
    plotyy(time,sens2,time,zFit);title([proj '  ' char(fltno)  '  ' char(FltDate) '  CO Sens and Bkg'],'FontSize',14);
    saveas(gcf,[ 'pix' slash char(Flight) '.co.fitparms.fig'],'fig');
    saveas(gcf,[ 'pix' slash char(Flight) '.co.fitparms.jpg'],'jpg');
end

figure(65);
plot(time,picSens2,'k.',picTCalAvg,picCalAvg,'y.');title([proj '  ' char(fltno)  '  ' char(FltDate) ' CO_2 Sens'],'FontSize',14);
saveas(gcf,[ 'pix' slash char(Flight) '.co2.fitparms.fig'],'fig');
saveas(gcf,[ 'pix' slash char(Flight) '.co2.fitparms.jpg'],'jpg');

figure(67),plot(rafTime,rafAlt,'y.');title([proj '  ' char(fltno)  '  ' char(FltDate) '  Altitude (m)'],'FontSize',14);
saveas(gcf,[ 'pix' slash char(Flight) '.alt.tseries.fig'],'fig');
saveas(gcf,[ 'pix' slash char(Flight) '.alt.tseries.jpg'],'jpg');


% badIx = 1;
% if badCals(1) > 1
%     modTCalAvg=[modTCalAvg; tCalAvg(1:badCal(1))];
% end
%
% if badIx > 0
%     for idx=1:numCals
%         if badCals(badIx) ~= idx && badIx <= length(numCals)
%             modTCalAvg=[modTCalAvg; tCalAvg(idx)];
%             badIx = badIx + 1;
%         end
%     end
% end

% sensCoefs = polyfit(calTime,calDat,2);
% zCoefs = polyfit(zTime,zDat,2);
%
% sensFit = sensCoefs(1) + sensCoefs(2).*time + sensCoefs(3).*time.*time;
% zFit = zCoefs(1) + zCoefs(2).*time + zCoefs(3).*time.*time;

% comr = (counter - zFitUncorr)./(sens2 - zFitUncorr).*tankCon;

% rafTime = co2origTime; %Not really sure why these were here as they negate all modifications prior to this -DS 7/4/13
% co2 = co2orig;
% ch4 = ch4orig;

if (coON && exist('sens2','var'))
    comr = (counter - zFit)./(sens2 - zFit).*tankCon;
else
    comr=BDF.*ones(size(counter));
end
%  Calibration algorithm used for NOMADSS IFP only; chgd 2/20/14 by TLC
%     if exist('picSens2','var')
%         co2adj = co2./picSens2.*co2tankCon;
%     else
%         co2adj=co2;
%     end

if UseConstPicSens
    co2adj = co2./picSens2.*co2tankCon;
else
    co2adj=co2;
end
if UseConstPicOffset
    co2adj = co2 + picCO2offset;
end
if UseLinPicCoeffs
    co2adj = co2 .* picCO2slope + picCO2int;
end

ch4adj = ch4 + picCH4offset;

% correct for early flights' non-unity compressor effy
% comr = (comr - corrInt)./corrSlope;
% coUncorr=(counterIntermed - zFitUncorr)./(sens2 - zFitUncorr).*tankCon;
coUncorr=comr;
% corrIx=find(pTorr>400);
% hiPix=find(pTorr>700);
% corrFactor(hiPix)=1.19;
% comr(corrIx)=comr(corrIx).*corrFactor(corrIx);



%Plot every 100th point (plotting all the points is very slow
if coON
    n=1;
    for i=1:5:length(time)
        ptime(n)=time(i); %#ok<*SAGROW>
        pcounter(n)=counter(i);
        pconcentration(n)=concentration(i);
        n=n+1;
    end
    n=1;
    for i=1:5:length(calindex)
        pcalindex(n)=calindex(i);
        n=n+1;
    end
    n=1;
    for i=1:5:length(zeroindex)
        pzeroindex(n)=zeroindex(i);
        n=n+1;
    end
    n=1;
    for i=1:5:length(baddataindex)
        pbaddataindex(n)=baddataindex(i);
        n=n+1;
    end
end


n=1;
for i=1:5:length(time)
    picPtime(n)=time(i);
    picPco2(n)=co2(i);
    n=n+1;
end
n=1;
for i=1:5:length(picCalindex)
    picPcalindex(n)=picCalindex(i);
    n=n+1;
end
n=1;
for i=1:5:length(picBaddataindex)
    picPbaddataindex(n)=picBaddataindex(i);
    n=n+1;
end


if length(calindex)>1 && length(zeroindex)>1 && length(baddataindex)>1
    %Plot all concentration data
    %   plot(time,concentration,'b.',time(calindex),concentration(calindex),'r.',...
    %      time(zeroindex),concentration(zeroindex),'g.',time(baddataindex),...
    %      concentration(baddataindex),'k.');
    %Plot partial concentration data
    %   plot(ptime,pconcentration,'b.',time(pcalindex),concentration(pcalindex),'r.',...
    %      time(pzeroindex),concentration(pzeroindex),'g.',time(pbaddataindex),...
    %      concentration(pbaddataindex),'k.');
    %Plot partial counter data
    
    figure(9);
    %     plot(ptime,pcounter,'b.',time(pcalindex),counter(pcalindex),'r.',...
    %        time(pzeroindex),counter(pzeroindex),'g.',time(pbaddataindex),...
    %        counter(pbaddataindex),'k.');
    plot(ptime,pcounter,'b.',time(pbaddataindex),counter(pbaddataindex),'k.',...
        tCalAvg,calAvg,'r.',tZavg,zAvg,'g.');
    title([proj '  ' char(fltno)  '  ' char(FltDate)],'FontSize',14);
    %ylim([0 1000000]);
    saveas(gcf,[ 'pix' slash char(Flight) '.co.raw.filtrd.fig'],'fig');
    saveas(gcf,[ 'pix' slash char(Flight) '.co.raw.filtrd.jpg'],'jpg');
    
else
    Message='No plot displayed as no calibration or no zero occurred in the period examined'
end


if length(picCalindex)>1 && length(picBaddataindex)>1
    figure(95);
    plot(picPtime,picPco2,'b.',time(picPbaddataindex),co2(picPbaddataindex),'k.',...
        picTCalAvg,picCalAvg,'r.');
    title([proj '  ' char(fltno)  '  ' char(FltDate) ' CO_2'],'FontSize',14);
    %ylim([0 1000000]);
    saveas(gcf,[ 'pix' slash char(Flight) '.co2.raw.filtrd.fig'],'fig');
    saveas(gcf,[ 'pix' slash char(Flight) '.co2.raw.filtrd.jpg'],'jpg');
    
else
    Message='No plot displayed as no calibration or no zero occurred in the period examined'
end


%Delete any previous output files
% warning off;
% for i=1:NumFiles(1)
%    outfile=[YY(i,:) MM(i,:) DD(i,:) '_' HH(i,:) '_CO.dat'];
%    delete([StartPath,char(Flight),slash,outfile]);
% end
% warning on;


hourcheck='99';

if(FlightData && processGV==0)
    outfile=['gv_' YY(1,:) MM(1,:) DD(1,:) '_CO.dat'];
    delete([StartPath,char(Flight), slash,outfile]);
    % outfile2=['RAFCO_20' YY(1,:) MM(1,:) DD(1,:) '_' char(fltno) '.txt'];
end
if(processNC && ~processGV)
    year= FltDate(1:2);
    month= FltDate(3:4);
    day= FltDate(5:6);
    outfile=['gv_' year month day '_CO.dat'];
end
%Not sure why below code was enabled... Can reenable if necessary - DS                                                  %

% % if (~FlightData & ~processNC & ~processGV)
% %     switch fltno
% %         case 'tf02'
% %             bad=find(isnan(counter)==1 | status ~= 0 | time < 65000);
% %         otherwise
% %             bad=find(isnan(counter)==1 | status ~= 0 | comr < 0);
% %     end
% %     outtime=time;outtime(bad)=BDF;
% %     outco=comr;outco(bad)=BDF;
% %     outStatus=ADJstatus; outStatus(bad)=BDF;
% %     outCts=counter; outCts(bad)=BDF;
% %     outSens=sens2; outZ=zFit;
% %
% %     for i=1:length(time)
% %         fprintf(fid2,'%d\t%f\n',time(i),outco(i));
% %         %         fprintf(fid2,'%d\t%f\t%d\t%f\t%f\t%f\n',time(i),outco(i),outStatus(i),outCts(i),outSens(i),outZ(i));
% %     end
% %     fclose(fid2);
% % %     for i=1:length(time)
% % %         fprintf(fid3,'%d\t%f\n',time(i),outco(i));
% % %     end
% % %     fclose(fid3);
% % end
%    outday=[];
%    outyear=[];
%    outhour=[];
%    outminute=[];
%    outsecond=[];
%    outtics=[];
%    outcounter=[];
%    outconcentration=[];
%    outstatus=[];
%    outmr=[];
%    outsens=[];
%    outz=[];

% for i=1:NumFiles(1)
%    outfile=[YY(i,:) MM(i,:) DD(i,:) '_' HH(i,:) '_CO.dat']
%    fid2=fopen([StartPath,char(Flight),slash,outfile],'a');

%    outmonth=dmonth(filerows(i):filerows(i+1));

%tic
%outmonthS(1:length(outmonth),1)='0';
%toc
%for j=1:length(outmonth)
%   outmonthS(j,:)=zero_pad(outmonth(j));
%end
%toc

windowSize=18;
smoothCounter = filter(ones(1,windowSize)/windowSize,1,counter); %running average algorithm
%     smoothTime = filter(ones(1,windowSize)/windowSize,1,time);

%    outday=dday(filerows(i):filerows(i+1));
%    outyear=dyear(filerows(i):filerows(i+1));
%    outhour=dhour(filerows(i):filerows(i+1));
%    outminute=dminute(filerows(i):filerows(i+1));
%    outsecond=dsecond(filerows(i):filerows(i+1));
%    outtics=tics(filerows(i):filerows(i+1));
%    outcounter=smoothCounter(filerows(i):filerows(i+1));
%    outconcentration=concentration(filerows(i):filerows(i+1));
%    outstatus=ADJstatus(filerows(i):filerows(i+1));
%    outmr=comr(filerows(i):filerows(i+1));
%    outsens=sens2(filerows(i):filerows(i+1));
%    outz=zFit(filerows(i):filerows(i+1));
% outTime=time-toffset;  for constant lag only
% Apply alt-dependent time lag:
if FlightData==0 && processNC==0 && processGV==0
    lagT=ones(size(counter)).*1;
else
    %     lagT=0.5344.*mrgP.*6./0.2./1013;
    % From 53.44 cc inletvol*0.4slm*p/1013*60s-min^-1/10^3 (TREX)
    %     lagT=0.00594.*mrgP.*6./0.2./1013;  % From .59 cc inlet vol*0.4slm*p/1013*60s-min^-1/1000
    badP=find(isnan(mrgP)==1);
    % %     lagT(badP)=6;
    %     lagT=ones(size(counter)).*8;
    lagT = 0;
    
end
if tSlope==1.000
    %     adjTime=time-toffset;
    %         adjTime=time-toffset+8-lagT;
    adjTime=time-toffset-lagT;
else
    adjTime=time.^2.*tOrd2+time.*tSlope+tInt;
    %   may need also to subtract lagT.  Check before implementing. 1/15/09 tc.
end
adjCOmr=comr;
adjStatus=ADJstatus;
overlap=diff(adjTime);
uniqueT=find(overlap~=0);
redundantT=find(overlap==0);
% if (length(redundantT))
%     Message='Eliminating redundant time stamps'
%     for ii=1:length(redundantT)
%         adjTime(redundantT(ii)+1)=0.5.*(adjTime(redundantT(ii))+adjTime(redundantT(ii)+1));
%         adjCOmr(redundantT(ii)+1)=0.5.*(comr(redundantT(ii))+comr(redundantT(ii)+1));
%         adjStatus(redundantT(ii)+1)=max(ADJstatus(redundantT(ii):redundantT(ii)+1));
%     end
%     outTime=[adjTime(uniqueT); adjTime(end)];
%     adjCOmr=[adjCOmr(uniqueT); adjCOmr(end)];
%     adjStatus=[adjStatus(uniqueT); adjStatus(end)];
%     % else
%     % adjCOmr=comr;
%     % adjStatus=ADJstatus;
% end;

outTime=adjTime;

dT=diff(outTime);
dT=[dT; 1];
tempvar2=sort(dT);
if tempvar2(1)==0
    Message='Repairing Hal"s repeating time stamps...'
    zeroTix=find(dT==0);
    outTime(zeroTix+1)=outTime(zeroTix)+1;
end
% timeIx=find(isnan(outTime)==1|outTime<-30);
% outTime(timeIx)=BDF;
warning off

if (FlightData && ~processGV && ~processNC)
    outday=interp1q(outTime,dday,rafTime);
    dayIx=find(isnan(outday)==1|outday<-30);
    outday(dayIx)=BDF;
    outmonth=interp1q(outTime,dmonth,rafTime);
    monthIx=find(isnan(outmonth)==1|outmonth<-30);
    outmonth(monthIx)=BDF;
    outyear=interp1q(outTime,dyear,rafTime);
    yrIx=find(isnan(outyear)==1|outyear<-30);
    outyear(yrIx)=BDF;
    
    outtics=interp1q(outTime,tics,rafTime);
    ticsIx=find(isnan(outtics)==1|outtics<-30);
    outtics(ticsIx)=BDF;
    outcounter=interp1q(outTime,smoothCounter,rafTime);
    ctrIx=find(isnan(outcounter)==1|outcounter<-30);
    outcounter(ctrIx)=BDF;
    outconcentration=interp1q(outTime,concentration,rafTime);
    concIx=find(isnan(outconcentration)==1|outconcentration<-30);
    outconcentration(concIx)=BDF;
    outstatus=interp1(outTime,ADJstatus,rafTime);
    statIx=find(isnan(outstatus)==1|outstatus<-30);
    outstatus(statIx)=BDF;
    outmr=interp1(outTime,comr,rafTime);
    mrIx=find(isnan(outmr)==1|outmr<-30);
    outmr(mrIx)=BDF;
    outsens=interp1q(outTime,sens2,rafTime);
    sensIx=find(isnan(outsens)==1|outsens<-30);
    outsens(sensIx)=BDF;
    outz=interp1q(outTime,zFit,rafTime);
    zeroIx=find(isnan(outz)==1|outz<-30);
    outz(zeroIx)=BDF;
    outCellP=interp1q(outTime,hrCellP,rafTime);
    pCellIx=find(isnan(outCellP)==1|outCellP<-30);
    outCellP(pCellIx)=BDF;
    badAlt=find(isnan(mrgAlt)==1|mrgAlt<-30);
    mrgAlt(badAlt)=BDF;
    %     badTheta=find(isnan(mrgTheta)==1|mrgTheta<-30);
    %     mrgTheta(badTheta)=BDF;
    %     badThetaE=find(isnan(mrgThetaE)==1|mrgThetaE<-30);
    %     mrgThetaE(badThetaE)=BDF;
    %     badThetaV=find(isnan(mrgThetaV)==1|mrgThetaV<-30);
    %     mrgThetaV(badThetaV)=BDF;
    %     badMR=find(isnan(mrgMR)==1|mrgMR<-30);
    %     mrgMR(badMR)=BDF;
    
    warning on
    
    %     rafCO=nc_varget(rafFile,'COMR_AL');
    
    % % %    outputdata=[outday,outmonth,outyear,outhour,outminute,outsecond,outconcentration]';
    % outputdata=[outday,outmonth,outyear,rafTime,outtics,...
    %     outcounter,outconcentration,outstatus,outmr,outsens,outz]';
    % outputdata2=[hrCellP,mrgAlt,mrgTheta,mrgThetaE,mrgThetaV,mrgMR]';
    % %    %Print header at start of combined hour file
    % %    if strcmp(hourcheck,HH(i,:))==0
    % % %       fprintf(fid2,'%s\n','#FltDate Time Concentration ');
    % %       fprintf(fid2,'%s\n','#Date Time Tics Counter Concentration Status ');
    % %    end
    % %
    % % %    fprintf(fid2,'%02d.%02d.%02d %02d:%02d:%02d %f\n',outputdata);
    % % for ix=1:length(outTime)
    % for ix=1:length(outTime)
    %
    %
    %     fprintf(fid2,'%02d.%02d.%02d %d %d %d %f %d %f %f %f ',outputdata(:,ix));
    %     fprintf(fid2,'%f %f %f %f %f %f\n',outputdata2(:,ix));
    %     if (dT(ix)>1)
    %         for ixx=1:dT(ix)-1
    %             fprintf(fid2,'%02d.%02d.%02d %d -999 -999 -999 -999 -999 -999 -999 ',...
    %                 outday(ix),outmonth(ix),outyear(ix),outTime(ix)+ixx);
    %             fprintf(fid2,'-999 -999 -999 -999 -999 -999\n');
    %         end
    %     end
    % end
    % %    hourcheck=HH(i,:);
    % %    fclose(fid2);
    % % end
    %
    % %    outputdata=[outday,outmonth,outyear,outhour,outminute,outsecond,outtics,...
    % %          outcounter,outconcentration,outstatus,outmr,outsens,outz]';
    %
    % %    fprintf(fid2,'%02d.%02d.%02d %02d:%02d:%02d %f\n',outputdata);
    % %    fprintf(fid2,'%02d.%02d.%02d %02d:%02d:%02d %d %d %f %d %f %f %f\n',outputdata);
    % %    hourcheck=HH(i,:);
    % fclose(fid2);
    
    outfile=['CO_RAF_20' YY(1,:) MM(1,:) DD(1,:) '_' char(fltno) '_v01.txt'];
    delete([StartPath,char(Flight), slash,outfile]);
    outfile2=['20' YY(1,:) MM(1,:) DD(1,:) '_' char(fltno) 'CO_RAF_v01.GV'];
    %     outfile=['gv_' YY(1,:) MM(1,:) DD(1,:) '.CO.prelim.dat'];
    %     delete([StartPath,char(Flight), slash,outfile]);
    %     outfile=['gv_' YY(1,:) MM(1,:) DD(1,:) '.CO.prelim.dat']
    prelimIx=find(outstatus~=0);
    %    prelimTix=find(outTime>rafStartT&outTime<rafEndT);
    %    prelimT=outTime(prelimTix);
    if length(rafTime)>length(outmr)  % fill time gaps if necessary
        gap=diff(outTime);
        gix=find(gap~=1);
        prelimT=outTime(1:gix(1));
        prelimMR=outmr(1:gix(1));
        prelimStat=outstatus(1:gix(1));
        for ix=1:length(gix)-1
            ixx=gap(gix(ix));
            prelimT=[prelimT; (outTime(gix(ix))+1:outTime(gix(ix))+ixx-1)'];
            prleimT=[prelimT; (outTime(gix(ix))+ixx:outTime(gix(ix+1)))'];
            prleimMR=[prelimMR; (BDF*ones(size(1:ixx-1)))'];
            prelimMR=[prelimMR; outmr(gix(ix)+1:gix(ix+1))];
            prelimStat=[prelimStat; (BDF*ones(size(1:ixx-1)))'];
            prelimStat=[prelimStat; outstatus(gix(ix)+1:gix(ix+1))];
        end
        
        finalTout=[prelimT; (outTime(gix(end))+1:outTime(gix(end))+gap(gix(end))-1)'];
        finalTout=[finalTout; outTime(gix(end)+1:end)];
        finalMRout=[prelimMR; (BDF*ones(size(1:gap(gix(end))-1)))'];
        finalMRout=[finalMRout; outmr(gix(end)+1:end)];
        finalStatOut=[prelimStat; (BDF*ones(size(1:gap(gix(end))-1)))'];
        finalStatOut=[finalStatOut; outstatus(gix(end)+1:end)];
        
        % assumes rafT begins earlier and ends later than CO time (not always
        % true).
        if rafTime(1) <= finalTout(1)
            begCOout=find(rafTime==finalTout(1));
            begBDF=BDF*ones(size(rafTime(1:begCOout-1)));
            finalTout=[rafTime(1:begCOout-1); finalTout];
            finalMRout=[begBDF; finalMRout];
            finalStatOut=[begBDF; finalStatOut];
        end
        
        if rafTime(end) >= finalTout(end)
            lastHalT=find(rafTime==finalTout(end));
            endBDF=BDF*ones(size(rafTime(lastHalT+1:end)));
            finalTout=[finalTout; rafTime(lastHalT+1:end)];
            finalMRout=[finalMRout; endBDF];
            finalStatOut=[finalStatOut; endBDF];
        end
        
        if rafTime(1) > finalTout(1)
            print('RAF data system turnon later than Hal\n');
        end
        
        if rafTime(end) < finalTout(end)
            print('RAF data system turned off earlier than Hal\n');
        end
    end % if length(rafTime)>length(outmr)
    if length(rafTime)==length(outmr)
        finalMRout=outmr;
        finalTout=rafTime;
        finalStatOut=outstatus;
    end % if length(rafTime)==length(outmr)
    length(rafTime)
    length(finalTout)
    length(finalMRout)
    length(finalStatOut)
    
    switch char(fltnoLC)
        case 'tf01'
            %             badix=find(time<65000);
            badix=1;
            %         case 'ff03'
            %             badix=find((rafTime>67500&rafTime<68500)|(rafTime>72500&rafTime<73000));
            %         case 'rf01'
            %             badix=find((rafTime>59000&rafTime<61000)|(rafTime>64000&rafTime<64300));
            %         case 'rf02'
            %             badix=find((rafTime>60000&rafTime<62000)|(rafTime>67500&rafTime<68000));
            %         case 'rf03'
            %             badix=find((rafTime>58500&rafTime<60000)|(rafTime>64000&rafTime<64700));
            %                     case 'rf04'
            %                         badix=find((rafTime>70000)|(finalMReditd<20));
            %         case 'rf05'
            %             badix=find((rafTime>63500&rafTime<64500)|(rafTime>65450&rafTime<65520));
            %                     case 'RF06'
            %                         badix=find((rafTime>81069&rafTime<81150)|(rafTime>79246&rafTime<79248)|(rafTime>90056&rafTime<90058)|...
            %                             (rafTime>81076&rafTime<81078));
        case 'rf07'
            badix= find(finalMRout<0 );
        case 'rf08'
            badix= find(finalMRout<0 );
        case 'rf09'
            badix= find(finalMRout<0 );
        case 'rf10'
            %             coRTadd=find(finalTout>79728&finalTout<83056);
            %             coRAFend=find(rafTime>79728&rafTime<83056);
            %             finalMRout(coRTadd)=rafCO(coRAFend)+3;
            %             finalStatOut(coRTadd)=0;
            %             badix=find(finalMRout<0 | (finalTout > 80404 & finalTout < 80518));
        otherwise
            badix= find(finalMRout<0);
    end
    
    stripBDF=find(finalStatOut~=0);
    finalMReditd=finalMRout;
    finalMReditd(stripBDF)=BDF;
    finalMReditd(badix)=BDF;
    figure(10);plot(adjTime,adjCOmr,'g.',rafTime,rafCO,'r.',finalTout,finalMReditd,'b.');title([proj '  ' char(fltno)  '  ' char(FltDate) ' CO ppbv'],'FontSize',14);grid
    saveas(gcf,[ 'pix' slash char(Flight) '.co.timelag.fig'],'fig');
    saveas(gcf,[ 'pix' slash char(Flight) '.co.timelag.jpg'],'jpg');
    
    %         if exist('co_qcls','var')
    %             figure(7);
    %             plot(mrgTime,finalMReditd,'b.',mrgTime,rafCO,'r.',qclsT,co_qcls,'g.');title([proj '  ' char(fltno)  '  ' char(FltDate)],'FontSize',14);
    %             %ylim([-100 600]);
    %             saveas(gcf,['pix' slash char(Flight) '.comr.tseries.fig'],'fig');
    %             saveas(gcf,['pix' slash char(Flight) '.comr.tseries.jpg'],'jpg');
    %
    %             if length(co_qcls)==length(finalMReditd)
    %                 dCO=co_qcls-finalMReditd;
    %                 % figure(10);plot(adjTime,adjCOmr,'g.',mrgTime,comr_al,'r.');title([proj '  ' char(fltno)  '  ' char(FltDate)],'FontSize',14);
    %                 % ylim([0 200]);grid
    %                 figure(12),plot(rafTime,dCO,'b.');
    %                 grid;ylim([-100 100]);
    %                 title([proj '  ' char(fltno)  '  ' char(FltDate)],'FontSize',14);
    %                 saveas(gcf,[ 'pix' slash char(Flight) '.dCO.tseries.fig'],'fig');
    %                 saveas(gcf,[ 'pix' slash char(Flight) '.dCO.tseries.jpg'],'jpg');
    %             end
    %         end
    %    prelimMR(prelimIx)=BDF;
    %    prelimMR=prelimMR(prelimTix);
    %    prelimOut=[prelimT,prelimMR]';
    prelimOut=[finalTout,finalMReditd]';
    %    dPrelimT=diff(prelimT);
    %    dPrelimT=[dPrelimT; 1];
    
    fid4=fopen([StartPath,char(Flight), slash,outfile],'a');
    
    fprintf(fid4,'%s\n','UTC CO_RAF');
    
    for ix=1:length(finalTout)
        %       for ix=1:length(prelimT)
        %           if(outTime(ix)>rafStartT&&outTime(ix)<rafEndT)
        fprintf(fid4,'%d %d\n',prelimOut(:,ix));
        %               if (dPrelimT(ix)>1)
        %                   for ixx=1:dPrelimT(ix)-1
        %                       fprintf(fid4,'%d -999\n',prelimT(ix)+ixx);
        %                   end
        %               end
        %           end
    end
    fclose(fid4);
    
    %       writeStatus=nc_varput([char(Flight) slash rafFile(11:end) ] ,'COMR_AL',finalMReditd)
    % mrl=nc_varget(rafFile,'XRAWMRL_MC');
    % theta=nc_varget(rafFile,'THETA');
    % atx=nc_varget(rafFile,'ATX');
    %     Flight
    %     figure(11);plot(finalMReditd,theta,'b.'); xlim([0 300]);title([proj '  ' char(fltno)  '  ' char(FltDate)],'FontSize',14);
    %     saveas(gcf,[char(Flight) slash 'pix' slash char(Flight) '.co.vs.theta.fig'],'fig');
    %     saveas(gcf,[char(Flight) slash 'pix' slash char(Flight) '.co.vs.theta.jpg'],'jpg');
    %     zoom
end % if(FlightData)

if (processNC || processGV)
    if length(rafTime)==length(comr)
        finalMRout=comr;
        finalTout=adjTime;
        finalStatOut=adjStatus;
    end % if length(rafTime)==length(outmr)
    switch char(fltnoLC)
        case 'gn01'
            badix=1;
            
        case 'tf01'
            badix=find(finalMRout<=0|isnan(finalMRout)==1);
            badixCO2=find(finalTout<0);
            badixCH4=find(finalTout<0);
            
        case 'rf01'
            badix=find((finalMRout<=0|isnan(finalMRout)==1));
            badixCO2=find(finalTout<0 | isnan(co2adj) == 1);
            badixCH4=find(finalTout<0 | isnan(ch4adj) == 1);
            
        case 'rf02'
            badix=find((finalMRout<=0|isnan(finalMRout)==1));
            badixCO2=find(finalTout<0 | isnan(co2adj) == 1);
            badixCH4=find(finalTout<0 | isnan(ch4adj) == 1);
            
        case 'rf03'
            badix=find((finalMRout<=0|isnan(finalMRout)==1));
            badixCO2=find(finalTout<0 | isnan(co2adj) == 1);
            badixCH4=find(finalTout<0 | isnan(ch4adj) == 1);
            
        case 'rf07'
            badix=find(finalMRout<=0|isnan(finalMRout)==1 | ...
                (finalTout>52200&finalTout<52220)|(finalTout>55800&finalTout<55820)|...
                (finalTout>59400&finalTout<59420)|(finalTout>63000&finalTout<63020)|...
                (finalTout>66600&finalTout<66620)|(finalTout>70200&finalTout<70220)|...
                (finalTout>73800&finalTout<73820)|(finalTout>77400&finalTout<77420)|...
                (finalTout>81000&finalTout<81020)|(finalTout>84600&finalTout<84620));
            badixCO2=find(isnan(co2adj) == 1| co2adj<=0 | ...
                (finalTout>52200&finalTout<52220)|(finalTout>55800&finalTout<55820)|...
                (finalTout>59400&finalTout<59420)|(finalTout>63000&finalTout<63020)|...
                (finalTout>66600&finalTout<66620)|(finalTout>70200&finalTout<70220)|...
                (finalTout>73800&finalTout<73820)|(finalTout>77400&finalTout<77420)|...
                (finalTout>81000&finalTout<81020)|(finalTout>84600&finalTout<84620));
            badixCH4=find(isnan(ch4adj) == 1| ch4adj<=0 | ...
                (finalTout>52200&finalTout<52220)|(finalTout>55800&finalTout<55820)|...
                (finalTout>59400&finalTout<59420)|(finalTout>63000&finalTout<63020)|...
                (finalTout>66600&finalTout<66620)|(finalTout>70200&finalTout<70220)|...
                (finalTout>73800&finalTout<73820)|(finalTout>77400&finalTout<77420)|...
                (finalTout>81000&finalTout<81020)|(finalTout>84600&finalTout<84620));
            
        case 'rf08'
            badix=find(finalMRout<=0|isnan(finalMRout)==1| ...
                (finalTout>52200&finalTout<52220)|(finalTout>55800&finalTout<55820)|...
                (finalTout>59400&finalTout<59420)|(finalTout>63000&finalTout<63020)|...
                (finalTout>66600&finalTout<66620)|(finalTout>70200&finalTout<70220)|...
                (finalTout>73800&finalTout<73820)|(finalTout>77400&finalTout<77420)|...
                (finalTout>81000&finalTout<81020)|(finalTout>84600&finalTout<84620));
            badixCO2=find(isnan(co2adj) == 1| co2adj<=0 | ...
                (finalTout>52200&finalTout<52220)|(finalTout>55800&finalTout<55820)|...
                (finalTout>59400&finalTout<59420)|(finalTout>63000&finalTout<63020)|...
                (finalTout>66600&finalTout<66620)|(finalTout>70200&finalTout<70220)|...
                (finalTout>73800&finalTout<73820)|(finalTout>77400&finalTout<77420)|...
                (finalTout>81000&finalTout<81020)|(finalTout>84600&finalTout<84620));
            badixCH4=find(isnan(ch4adj) == 1| ch4adj<=0 | ...
                (finalTout>52200&finalTout<52220)|(finalTout>55800&finalTout<55820)|...
                (finalTout>59400&finalTout<59420)|(finalTout>63000&finalTout<63020)|...
                (finalTout>66600&finalTout<66620)|(finalTout>70200&finalTout<70220)|...
                (finalTout>73800&finalTout<73820)|(finalTout>77400&finalTout<77420)|...
                (finalTout>81000&finalTout<81020)|(finalTout>84600&finalTout<84620));
            
        case 'rf09'
            badix=find(finalMRout<=0|isnan(finalMRout)==1| ...
                (finalTout>52200&finalTout<52220)|(finalTout>55800&finalTout<55820)|...
                (finalTout>59400&finalTout<59420)|(finalTout>63000&finalTout<63020)|...
                (finalTout>66600&finalTout<66620)|(finalTout>70200&finalTout<70220)|...
                (finalTout>73800&finalTout<73820)|(finalTout>77400&finalTout<77420)|...
                (finalTout>81000&finalTout<81020)|(finalTout>84600&finalTout<84620));
            badixCO2=find(isnan(co2adj) == 1| co2adj<=0 | ...
                (finalTout>52200&finalTout<52220)|(finalTout>55800&finalTout<55820)|...
                (finalTout>59400&finalTout<59420)|(finalTout>63000&finalTout<63020)|...
                (finalTout>66600&finalTout<66620)|(finalTout>70200&finalTout<70220)|...
                (finalTout>73800&finalTout<73820)|(finalTout>77400&finalTout<77420)|...
                (finalTout>81000&finalTout<81020)|(finalTout>84600&finalTout<84620));
            badixCH4=find(isnan(ch4adj) == 1| ch4adj<=0 | ...
                (finalTout>52200&finalTout<52220)|(finalTout>55800&finalTout<55820)|...
                (finalTout>59400&finalTout<59420)|(finalTout>63000&finalTout<63020)|...
                (finalTout>66600&finalTout<66620)|(finalTout>70200&finalTout<70220)|...
                (finalTout>73800&finalTout<73820)|(finalTout>77400&finalTout<77420)|...
                (finalTout>81000&finalTout<81020)|(finalTout>84600&finalTout<84620));
        case 'rf10'
            badix=find(finalMRout<=0|isnan(finalMRout)==1| ...
                (finalTout<54331)|(finalTout>78584)|(finalTout>56440&finalTout<56447));
            badixCO2=find(isnan(co2adj) == 1| co2adj<=0 | ...
                (finalTout<54331)|(finalTout>78409&finalTout<78422)|(finalTout>78584)|...
                (finalTout>54765&finalTout<54791)|(finalTout>56775&finalTout<56801)|...
                (finalTout>58910&finalTout<59007)|(finalTout>64170&finalTout<64199)|...
                (finalTout>71532&finalTout<71549));
            badixCH4=find(isnan(ch4adj) == 1| ch4adj<=0 | ...
                (finalTout<54331)|(finalTout>78409&finalTout<78422)|(finalTout>78584)|...
                (finalTout>54765&finalTout<54791)|(finalTout>56775&finalTout<56801)|...
                (finalTout>58910&finalTout<59007)|(finalTout>64170&finalTout<64199)|...
                (finalTout>71532&finalTout<71549));
            
        case 'rf11'
            badix=find(finalMRout<=0|isnan(finalMRout)==1| ...
                (finalTout<55266)|(finalTout>57461&finalTout<57466));
            badixCO2=find(isnan(co2adj) == 1| co2adj<=0 |(finalTout<55266)|...
                (finalTout>55792&finalTout<55806)|(finalTout>57796&finalTout<57819)|...
                (finalTout>59939&finalTout<60024)|(finalTout>65195&finalTout<65211)|...
                (finalTout>72551&finalTout<72571)|(finalTout>75203&finalTout<75215)|...
                (finalTout>75344&finalTout<75457));
            badixCH4=find(isnan(ch4adj) == 1| ch4adj<=0 |(finalTout<55266)|...
                (finalTout>55792&finalTout<55806)|(finalTout>57796&finalTout<57819)|...
                (finalTout>59939&finalTout<60024)|(finalTout>65195&finalTout<65211)|...
                (finalTout>72551&finalTout<72571)|(finalTout>75203&finalTout<75215)|...
                (finalTout>75344&finalTout<75457));
            
        case 'rf12'
            badix=find(finalMRout<=0|isnan(finalMRout)==1| ...
                (finalTout>76911));
            badixCO2=find(isnan(co2adj) == 1| co2adj<=0 |(finalTout>76911));
            badixCH4=find(isnan(ch4adj) == 1| ch4adj<=0 |(finalTout>76911));
            
        case 'rf13'
            badix=find(finalMRout<=0|isnan(finalMRout)==1| ...
                (finalTout<55155)|(finalTout>79770));
            badixCO2=find(isnan(co2adj) == 1| co2adj<=0 |(finalTout<55155)|...
                (finalTout>55566&finalTout<55583)|(finalTout>55713&finalTout<55730)|...
                (finalTout>55766&finalTout<55777)|(finalTout>77023&finalTout<77037)|...
                (finalTout>79770));
            badixCH4=find(isnan(ch4adj) == 1| ch4adj<=0 |(finalTout<55155)|...
                (finalTout>55566&finalTout<55583)|(finalTout>55713&finalTout<55730)|...
                (finalTout>55766&finalTout<55777)|(finalTout>77023&finalTout<77037)|...
                (finalTout>79770));
            
        case 'rf14'
            badix=find(finalMRout<=0|isnan(finalMRout)==1| ...
                (finalTout<54549));
            badixCO2=find(isnan(co2adj) == 1| co2adj<=0 |(finalTout<54549)|...
                (finalTout>54585&finalTout<54604)|(finalTout>55219&finalTout<55232)|...
                (finalTout>77968&finalTout<77990)|(finalTout>78167));
            badixCH4=find(isnan(ch4adj) == 1| ch4adj<=0 |(finalTout<54549)|...
                (finalTout>54585&finalTout<54604)|(finalTout>55219&finalTout<55232)|...
                (finalTout>77968&finalTout<77990)|(finalTout>78167));
            
        case 'rf15'
            badix=find(finalMRout<=0|isnan(finalMRout)==1| ...
                (finalTout<54665)|(finalTout>79242));
            badixCO2=find(isnan(co2adj) == 1| co2adj<=0 |(finalTout<54665)|...
                (finalTout>54751&finalTout<54762)|(finalTout>58932&finalTout<58947)|...
                (finalTout>78135&finalTout<78155)|(finalTout>79242));
            badixCH4=find(isnan(ch4adj) == 1| ch4adj<=0 |(finalTout<54665)|...
                (finalTout>54751&finalTout<54762)|(finalTout>58932&finalTout<58947)|...
                (finalTout>78135&finalTout<78155)|(finalTout>79242));
            
        case 'rf16'
            badix=find(finalMRout<=0|isnan(finalMRout)==1| ...
                (finalTout<54249)|(finalTout>78478));
            badixCO2=find(isnan(co2adj) == 1| co2adj<=0 |(finalTout<54249)|...
                (finalTout>55569&finalTout<55580)|(finalTout>78478));
            badixCH4=find(isnan(ch4adj) == 1| ch4adj<=0 |(finalTout<54249)|...
                (finalTout>55569&finalTout<55580)|(finalTout>78478));
            
        case 'rf17'
            badix=find(finalMRout<=0|isnan(finalMRout)==1| ...
                (finalTout<54481)|(finalTout>58554&finalTout<58563)|...
                (finalTout>65067&finalTout<65075)|(finalTout>71535&finalTout<71993));
            badixCO2=find(isnan(co2adj) == 1| co2adj<=0 |(finalTout<54481)|...
                (finalTout>77937&finalTout<77960));
            badixCH4=find(isnan(ch4adj) == 1| ch4adj<=0 |(finalTout<54481)|...
                (finalTout>77937&finalTout<77960));
            
        case 'rf18'
            badix=find(finalMRout<=0|isnan(finalMRout)==1| ...
                (finalTout<73959)|(finalTout>99389));
            badixCO2=find(isnan(co2adj) == 1| co2adj<=0 |...
                (finalTout<73959)|(finalTout>98587&finalTout<98609)|(finalTout>99389));
            badixCH4=find(isnan(ch4adj) == 1| ch4adj<=0 |...
                (finalTout<73959)|(finalTout>98587&finalTout<98609)|(finalTout>99389));
            
        case 'rf19'
            badix=find(finalMRout<=0|isnan(finalMRout)==1| ...
                (finalTout>76065));
            badixCO2=find(isnan(co2adj) == 1| co2adj<=0 |...
                (finalTout>75025&finalTout<75055)|(finalTout>76065));
            badixCH4=find(isnan(ch4adj) == 1| ch4adj<=0 |...
                (finalTout>75025&finalTout<75055)|(finalTout>76065));
            
        otherwise
            badix= find(finalMRout<=0|isnan(finalMRout)==1);
            badixCO2=find(finalTout<0 | isnan(co2adj) == 1 | co2adj<=0);
            badixCH4=find(finalTout<0 | isnan(ch4adj) == 1 | ch4adj<=0);
            
    end
    
    stripBDF=find(finalStatOut~=0);
    finalMReditd=finalMRout;
    if exist('badixCO', 'var')
        finalMReditd(badixCO) = BDF;
    end
    finalMReditd(stripBDF)=BDF;
    finalMReditd(badix)=BDF;
    
    figure(10);plot(adjTime,adjCOmr,'r.',rafTime,rafMR.*100,'g.',finalTout,finalMReditd,'b.');title([proj '  ' char(fltno)  '  ' char(FltDate)],'FontSize',14);grid
    %ylim([0 500]);
    saveas(gcf,[ 'pix' slash char(Flight) '.co.timelag.fig'],'fig');
    saveas(gcf,[ 'pix' slash char(Flight) '.co.timelag.jpg'],'jpg');
    
    stripCO2=find(ADJpicStatus~=0);
    co2out=co2adj;  %Uses interpolated sensitivity
    co2out(stripCO2)=BDF;
    chgNaNCO2=find(isnan(co2out)==1);
    co2out(chgNaNCO2) = BDF; % NaN back to BDF
    %     co2out(badix)=BDF;
    co2out(badixCO2)=BDF;
    
    ch4out=ch4.*1000;
    ch4out(stripCO2)=BDF;
    %     ch4out(badix)=BDF;
    ch4out(badixCH4)=BDF;
    bdfFixCH4=find(ch4out==(BDF*1000)); %Finds all BDF values that were multiplied in the ppm to ppb conversion
    ch4out(bdfFixCH4)=BDF;
    
    h2oOut=h2oadj;
    h2oOut(stripCO2)=BDF;
    h2oOut(chgNaNCO2)=BDF;
    h2oOut(badixCO2)=BDF;
    
    figure(11);plot(rafTime,co2,'r.',finalTout,co2out,'b.');title([proj '  ' char(fltno)  '  ' char(FltDate) 'CO_2 '],'FontSize',14);grid
    %ylim([320 450]);
    saveas(gcf,[ 'pix' slash char(Flight) '.co2.timelag.fig'],'fig');
    saveas(gcf,[ 'pix' slash char(Flight) '.co2.timelag.jpg'],'jpg');
    
    figure(12);plot(rafTime,ch4.*1000,'r.',finalTout,ch4out,'b.');title([proj '  ' char(fltno)  '  ' char(FltDate) 'CH_4 '],'FontSize',14);grid
    %ylim([1300 2000]);
    saveas(gcf,[ 'pix' slash char(Flight) '.ch4.timelag.fig'],'fig');
    saveas(gcf,[ 'pix' slash char(Flight) '.ch4.timelag.jpg'],'jpg');
    
    %     corrsegix=find(rafTime>78500&rafTime<79200);
    % coOutmrg=interp1(finalTout,finalMReditd,rafTime);
    % instcl=spec_corrlag(vxlmr(corrsegix),coOutmrg(corrsegix),1,80);
    % figure,plot(instcl(:,1),instcl(:,2),'b*-'),grid;
    % grid
    % HIPPO only code w/in this if-clause:
    % if exist('CO_QCLS')
    % coQclMrg=interp1(UTC_QCLS,CO_QCLS,rafTime);
    % dCO=coQclMrg-coOutmrg;
    % figure,plot(coQclMrg,dCO,'b.');
    % xlim([0 300]);ylim([-50 50]);grid
    % figure,plot(finalTout,finalMReditd,'r.',UTC_QCLS,CO_QCLS,'b.');
    % ylim([0 200]);grid
    %     save([char(Flight) 'wQcl.mat']);
    % else
    %     save([char(Flight) 'gvOnly.mat']);
    % end
    %     if exist('co_qcls')
    %         figure(7);
    %         plot(mrgTime,finalMReditd,'b.',mrgTime,rafCO,'r.',qclsT,co_qcls,'g.');title([proj '  ' char(fltno)  '  ' char(FltDate)],'FontSize',14);
    %         ylim([-100 600]);
    %         saveas(gcf,[char(Flight) slash 'pix' slash char(Flight) '.comr.tseries.fig'],'fig');
    %         saveas(gcf,[char(Flight) slash 'pix' slash char(Flight) '.comr.tseries.jpg'],'jpg');
    %
    %         if length(co_qcls)==length(finalMReditd)
    %             dCO=co_qcls-finalMReditd;
    %             % figure(10);plot(adjTime,adjCOmr,'g.',mrgTime,comr_al,'r.');title([proj '  ' char(fltno)  '  ' char(FltDate)],'FontSize',14);
    %             % ylim([0 200]);grid
    %             figure(12),plot(rafTime,dCO,'b.');
    %             grid;ylim([-100 100]);
    %             title([proj '  ' char(fltno)  '  ' char(FltDate)],'FontSize',14);
    %             saveas(gcf,[char(Flight) slash 'pix' slash char(Flight) '.dCO.tseries.fig'],'fig');
    %             saveas(gcf,[char(Flight) slash 'pix' slash char(Flight) '.dCO.tseries.jpg'],'jpg');
    %         end
    %     end
    
    %    prelimMR(prelimIx)=BDF;
    %    prelimMR=prelimMR(prelimTix);
    %    prelimOut=[prelimT,prelimMR]';
    prelimOut=[finalTout,finalMReditd]';
    %    dPrelimT=diff(prelimT);
    %    dPrelimT=[dPrelimT; 1];
    
    outfile2=['20' year month day '_' char(fltno) 'COCO2CH4_RAF_v01.GV.txt'];
    delete(outfile2);
    fid2=fopen(outfile2,'a');
    %     fid4=fopen([StartPath,char(Flight), slash,outfile2],'a');
    %
    %     fprintf(fid4,'%s\n','UTC CO_RAF');
    %
    %     for ix=1:length(finalTout)
    %         %       for ix=1:length(prelimT)
    %         %           if(outTime(ix)>rafStartT&&outTime(ix)<rafEndT)
    %         fprintf(fid4,'%d %d\n',prelimOut(:,ix));
    %         %               if (dPrelimT(ix)>1)
    %         %                   for ixx=1:dPrelimT(ix)-1
    %         %                       fprintf(fid4,'%d -999\n',prelimT(ix)+ixx);
    %         %                   end
    %         %               end
    %         %           end
    %     end
    %     fclose(fid4);
    %
    %
    % delete([StartPath,char(Flight), slash,outfile]);
    % fid2=fopen([StartPath,char(Flight), slash,outfile],'a');
    % %fid3=fopen([StartPath,char(Flight), slash,outfile2],'a');
    
    fprintf(fid2,'%s\n','#8 Header Lines');
    fprintf(fid2, '%s\n','#NCAR N130AR C-130 In Situ CO Data');
    fprintf(fid2,'%s\n','#Teresa Campos, Frank Flocke, Mike Reeves, Meghan Stell, and Dan Stechman, NCAR NESL and EOL, CARI Group');
    fprintf(fid2,'%s\n%s\n','#PO Box 3000','#Boulder, CO 80307');
    fprintf(fid2,'%s\n','#Contact Info: 303-497-1048, campos@ucar.edu');
    fprintf(fid2,'%s%d  %s%d  %s%d  %s%d  %s%d  %s%d  %s%d %s%d  %s%f  %s%d  %s%f  %s%f  %s%f  %s%f\n',...
        '#Settings for this processing run: LowCalLim_cts: ',coCalLow,...
        'coCalMax_cts: ',coCalMax,'ZeroMax_cts: ',coZeroLimit,'ZeroMin_cts: ',ZeroMin,...
        'PriorPtsRemoved: ',before,'PostChangePtsRemoved: ',after,...
        'PostCalPtsRemoved: ',DataAfterCal,'NumPtsToAvg: ',ptsToAvg,...
        'CalTankCon: ',tankCon,'TimeShift_s: ',toffset,'co2CalLow: ',co2CalLow,'co2CalMax: ',co2CalMax,...
        'ch4CalLow: ',ch4CalLow,'ch4CalMax: ',ch4CalMax);
    % fprintf(fid2,'%s','#Time CO_ppbv Status Counter Sens ');
    % fprintf(fid2,'%s\n', 'Offset');
    fprintf(fid2,'%s\n','#Time CO_ppbv CO2_ppmv CH4_ppbv');
    % fprintf(fid3,'%s\n','UTC CO_ppbv');
    for ix=1:length(finalTout)
        %     fprintf(fid2,'%d\t%.1f\t%.2f\t%.0f\n',finalTout(ix),finalMRout(ix),co2out(ix),ch4out(ix));
        fprintf(fid2,'%d\t%.1f\t%.2f\t%.1f\n',finalTout(ix),finalMRout(ix),co2out(ix),ch4out(ix));
    end
    fclose(fid2);
    
    outfile4=['nomadss-CO_C130_20' year month day '_RA.ict'];
    delete(outfile4);
    fid4=fopen(outfile4,'a');
    
    fprintf(fid4,'%s\n','33, 1001');
    fprintf(fid4,'%s\n','Teresa Campos, Frank Flocke, Michael Reeves, Daniel Stechman, and Meghan Stell');
    fprintf(fid4,'%s\n','National Center for Atmospheric Research');
    fprintf(fid4,'%s\n','CO - Carbon monoxide in situ mixing ratio observations from the G-V');
    fprintf(fid4,'%s\n%s\n','NOMADSS','1, 1');
    fprintf(fid4,'%s\n',['20' year ', ' month ', ' day ', ' processingDateString]);
    fprintf(fid4,'%s\n%s\n%s\n%s\n%s\n','1', 'Start_UTC, seconds', '1', '1', '-99999');
    fprintf(fid4,'%s\n%s\n%s\n','CO, ppbv, volume_mixing_ratio_of_carbon_monoxide_in_air','0','18');
    fprintf(fid4,'%s\n','PI_CONTACT_INFO: Address: PO Box 3000, Boulder, CO  80307; email: campos@ucar.edu, ffl@ucar.edu');
    fprintf(fid4,'%s\n','PLATFORM: NSF NCAR C-130 - rack R13, right lower fuselage HIMIL, shared with AON, std 8" height, aft-facing inlet');
    fprintf(fid4,'%s\n','LOCATION: Aircraft location data in NCAR RAF netcdf and .ict file');
    fprintf(fid4,'%s\n','ASSOCIATED_DATA: see ftp://catalog.eol.ucar.edu');
    fprintf(fid4,'%s\n','INSTRUMENT_INFO: CO by Aero-Laser VUV Fluorescence');
    fprintf(fid4,'%s\n','DATA_INFO: CO units are ppbv');
    fprintf(fid4,'%s\n','UNCERTAINTY: The combined uncertainty is estimated to be 3 ppbv +/- 3% at two sigma confidence');
    fprintf(fid4,'%s\n%s\n','ULOD_FLAG: -7777','ULOD_VALUE: N/A');
    fprintf(fid4,'%s\n%s\n','LLOD_FLAG: -8888','LLOD_VALUE: N/A');
    fprintf(fid4,'%s\n','DM_CONTACT_INFO: Teresa Campos, campos@ucar.edu, Frank Flocke, ffl@ucar.edu');
    fprintf(fid4,'%s\n','PROJECT_INFO: NOMADSS Mission 1 June - 15 July, 2013; airborne ops base: Smyrna, TN; ground ops: Tennessee, Alabama, North Carolina, Indiana, Missouri');
    fprintf(fid4,'%s\n','STIPULATIONS_ON_USE: Use of these data requires prior approval from Teresa Campos and Frank Flocke');
    fprintf(fid4,'%s\n','OTHER_COMMENTS: N/A');
    fprintf(fid4,'%s\n','REVISION: RA');
    fprintf(fid4,'%s\n','RA: Field Data');
    fprintf(fid4,'%s\n','Start_UTC,CO');
    
    for ix=1:length(finalTout)
        fprintf(fid4,'%d,%.1f\n',finalTout(ix),finalMReditd(ix));
    end
    fclose(fid4);
    
    outfile3=['nomadss-CO2CH4_C130_20' year month day '_RA.ict'];
    delete(outfile3);
    fid3=fopen(outfile3,'a');
    
    fprintf(fid3,'%s\n','34, 1001');
    fprintf(fid3,'%s\n','Frank Flocke, Teresa Campos, Michael Reeves, Daniel Stechman, and Meghan Stell');
    fprintf(fid3,'%s\n','National Center for Atmospheric Research');
    fprintf(fid3,'%s\n','CO2CH4 - Picarro G1301-f Carbon dioxide and methane in situ mixing ratio observations from the C-130');
    fprintf(fid3,'%s\n%s\n','NOMADSS','1, 1');
    fprintf(fid3,'%s\n',['20' year ', ' month ', ' day ', ' processingDateString]);
    fprintf(fid3,'%s\n%s\n%s\n%s\n%s\n','1', 'Start_UTC, seconds', '2', '1, 1', '-99999, -99999');
    fprintf(fid3,'%s\n','CO2, ppmv, volume_mixing_ratio_of_carbon_dioxide_in_air');
    fprintf(fid3,'%s\n%s\n%s\n','Methane, ppbv, volume_mixing_ratio_of_methane_in_air','0','18');
    fprintf(fid3,'%s\n','PI_CONTACT_INFO: Address: PO Box 3000, Boulder, CO  80307; email: ffl@ucar.edu, campos@ucar.edu');
    fprintf(fid3,'%s\n','PLATFORM: NSF NCAR C-130 - rack R13, right lower fuselage HIMIL, shared with AON, std 8" height, aft-facing inlet');
    fprintf(fid3,'%s\n','LOCATION: Aircraft location data in NCAR RAF netcdf and .ict file');
    fprintf(fid3,'%s\n','ASSOCIATED_DATA: see ftp://catalog.eol.ucar.edu');
    fprintf(fid3,'%s\n','INSTRUMENT_INFO: CO2 and Methane by Picarro G1301-f WS-CRDS');
    fprintf(fid3,'%s\n','DATA_INFO: CO2 units are ppmv and Methane units are ppbv');
    fprintf(fid3,'%s\n','UNCERTAINTY: The one sigma precision is estimated to be 0.25 ppmv CO2 and 3 ppbv CH4 for a 0.2 sec averaging time.');
    fprintf(fid3,'%s\n%s\n','ULOD_FLAG: -7777','ULOD_VALUE: N/A');
    fprintf(fid3,'%s\n%s\n','LLOD_FLAG: -8888','LLOD_VALUE: N/A');
    fprintf(fid3,'%s\n','DM_CONTACT_INFO: Frank Flocke, ffl@ucar.edu, Teresa Campos, campos@ucar.edu');
    fprintf(fid3,'%s\n','PROJECT_INFO: NOMADSS Mission 1 June - 15 July, 2013; airborne ops base: Smyrna, TN; ground ops: Tennessee, Alabama, North Carolina, Indiana, and Missouri');
    fprintf(fid3,'%s\n','STIPULATIONS_ON_USE: Use of these data requires prior approval from Frank Flocke and Teresa Campos');
    fprintf(fid3,'%s\n','OTHER_COMMENTS: N/A');
    fprintf(fid3,'%s\n','REVISION: RA');
    fprintf(fid3,'%s\n','RA: Field Data');
    fprintf(fid3,'%s\n','Start_UTC,CO2,Methane');
    
    for ix=1:length(finalTout)
        fprintf(fid3,'%d,%.2f,%.1f\n',finalTout(ix),co2out(ix),ch4out(ix));
    end
    fclose(fid3);
    %       writeStatus=nc_varput([char(Flight) slash rafFile(11:end) ] ,'COMR_AL',finalMReditd)
    % mrl=nc_varget(rafFile,'XRAWMRL_MC');
    % theta=nc_varget(rafFile,'THETA');
    % atx=nc_varget(rafFile,'ATX');
    %     Flight
    %     figure(11);plot(finalMReditd,theta,'b.'); xlim([0 300]);title([proj '  ' char(fltno)  '  ' char(FltDate)],'FontSize',14);
    %     saveas(gcf,[char(Flight) slash 'pix' slash char(Flight) '.co.vs.theta.fig'],'fig');
    %     saveas(gcf,[char(Flight) slash 'pix' slash char(Flight) '.co.vs.theta.jpg'],'jpg');
    %     zoom
end % if(processNC)

save(['20' FltDate '_' char(fltno) '.mat']);

if writeIgorRAFexplore
    setToNaNCO2=find(co2out==BDF);
    setToNaNCH4=find(ch4out==BDF);
    setToNaNCO=find(finalMReditd==BDF);
    
    co2out(setToNaNCO2)=NaN;
    ch4out(setToNaNCH4)=NaN;
    finalMReditd(setToNaNCO)=NaN;
    
    ch4out=ch4out./1000;
    
    outfile100=['nomadss-IgorExploreRAFVars_20' year month day '_IG.txt'];
    delete(outfile100);
    fid100=fopen(outfile100,'a');
    
    
    fprintf(fid100,'%s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\t %s\n','Time', 'CO_Orig', 'CO_Out',...
        'CO2_Orig', 'CO2_Out', 'CH4_Orig', 'CH4_Out', 'O3', 'RAF_ALT');
    
    for ix=1:length(finalTout)
        fprintf(fid100,'%d\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\t %.4f\n',...
            finalTout(ix),adjCOmr(ix),finalMReditd(ix),co2orig(ix),co2out(ix),ch4orig(ix),ch4out(ix),o3(ix),rafAlt(ix));
    end
    fclose(fid100);
    
    load(['20' FltDate '_' char(fltno) '.mat']);
end

toc
%axlimdlg