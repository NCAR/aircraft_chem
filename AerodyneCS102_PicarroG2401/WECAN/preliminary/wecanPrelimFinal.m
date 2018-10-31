tic
for fltno = 1:18
%     fltno=3;
    slash = '/'
    
    StartPath = '/Users/campos/Documents/macBak/campos/chemData/2018wecan/ifpRAF';
    cd /Users/campos/Documents/macBak/campos/chemData/2018wecan/ifpRAF
    year = '18';
    BDF=-99999;
    
    co2lowcal=393; co2hical=398;
    ch4lowcal= 1750; ch4hical = 1770;
    h2ocal=100;h2oGoodCal=100;
    n2olowcal=240; n2ohical=280;
    cocal_ari_slope=1.131907;cocal_ari_int = - 1.770676
    cocal_pic_slope=1.049483;cocal_pic_int = 28.295071
    co2cal_pic_slope=0.99471; co2cal_pic_int = -0.93101;
    ch4cal_pic_slope=1.002903; ch4cal_pic_int = -10.014670;
    
    before=4;
    after=5;
    
    % Default time offsets for each instrument relative to best available
    % water sensor.  Variables used for sync analysis for each flight: 
    % rf01-15: STRONG_VXL2; rf16, rf18-19: XSIGV_UVH; rf17: DPXC.
            toffset_ari = -6;
            toffset_pic = -8;
processRawUser2401=1;
    createRawUser2401=1;
    % processNetcdf = 0;
    sync = 1;
    if (sync)
        picPath2401 = [ StartPath '/picarro/user_sync']
    else
        picPath2401 = [ StartPath '/picarro/user']
    end
    
    switch fltno
        case 1
            month='07'; day='24';
            beginT=68755; endT=89760;
            crossesMidnite=1;
            % co2lowcal=395; co2hical=398;
            toffset_pic = -10;
        case 2
            month='07'; day='26';
            beginT=73118; endT=94134;
            crossesMidnite=1;
            toffset_pic = -5;
        case 3
            month='07'; day='30';
            beginT=72332; endT=95064;
            crossesMidnite=1;
        case 4
            month='07'; day='31';
            beginT=72213; endT=95328;
            crossesMidnite=1;
        case 5
            month='08'; day='02';
            beginT=68505; endT=89609;
            crossesMidnite=1;
            toffset_pic = -5;
        case 6
            month='08'; day='03';
            beginT=72000; endT=95207;
            crossesMidnite=1;
            toffset_ari = -7;
            toffset_pic = -7;
        case 7
            month='08'; day='06';
            beginT=71775; endT=94491;
            crossesMidnite=1;
            toffset_pic = -5;
        case 8
            month='08'; day='08';
            beginT=68445; endT=90710;
            crossesMidnite=1;
            toffset_ari = -7;
        case 9
            month='08'; day='09';
            beginT=68087; endT=92700;
            crossesMidnite=1;
        case 10
            month='08'; day='13';
            beginT=66643; endT=88858;
            crossesMidnite=1;
            toffset_pic = -12;
        case 11
            month='08'; day='15';
            beginT=72034; endT=93423;
            crossesMidnite=1;
            toffset_ari = -7;
            toffset_pic = -11;
        case 12
            month='08'; day='16';
            beginT=63480; endT=84480;
            crossesMidnite=0;
            toffset_ari = -7;
            toffset_pic = -12;
        case 13
            month='08'; day='20';
            beginT=68748; endT=94454;
            crossesMidnite=1;
        case 14
            month='08'; day='23';
            beginT=75446; endT=96330;
            crossesMidnite=1;
            toffset_ari = -8;
            toffset_pic = -12;
        case 15
            month='08'; day='26';
            beginT=68200; endT=94608;
            crossesMidnite=1;
            toffset_ari = -7;
            toffset_pic = -13;
        case 16
            month='08'; day='28';
            beginT=67290; endT=78720;
            crossesMidnite=0;
            co2lowcal=404; co2hical=406;
            ch4lowcal= 1750; ch4hical = 1790;
            h2ocal=130;h2oGoodCal=130;
            toffset_ari = -7;
            toffset_pic = -16;
        case 17
            month='09'; day='06';
            beginT=63360; endT=72910;
            crossesMidnite=0;
            co2lowcal=404; co2hical=406;
            ch4lowcal= 1750; ch4hical = 1790;
            toffset_ari = -5;
            toffset_pic = -5;
        case 18
            month='09'; day='10';
            beginT=70289; endT=82920;
            crossesMidnite=0;
            co2lowcal=404; co2hical=406;
            ch4lowcal= 1750; ch4hical = 1790;
            toffset_ari = -7;
            toffset_pic = -10;
        case 19
            month='09'; day='13';
            beginT=69150; endT=84600;
            crossesMidnite=0;
            co2lowcal=404; co2hical=406;
            ch4lowcal= 1750; ch4hical = 1790;
            toffset_ari = -8;
            toffset_pic = -7;
    end
    
    FltDate = ['2018' month day];
    FlightLC=['rf' zero_pad(fltno)];
    fltnoLC=FlightLC;
    processingDateString = datestr(now, 'yyyy, mm, dd');    % current date
    proj='WECAN';
    ncfile=[proj FlightLC '.nc'];
    
%     rev='RA'    % RA => field data
    rev='R0'    % R0 => preliminary final data
    
    % if (processNetcdf)
    % Load data from field entcdf file; apply cal adjustments
    dat=nc_getall(ncfile);
    fullTime=dat.Time.data;
    goodTime=find(fullTime>beginT&fullTime<endT);
    rafTime=fullTime(goodTime);
    
    n2o_ari=dat.N2O_ARI.data(goodTime-toffset_ari);
    co_ari=dat.CO_ARI.data(goodTime-toffset_ari);
    h2o_ari=dat.H2O_ARI.data(goodTime-toffset_ari)./1000;
    
    co2c_pic2401=dat.CO2C_PIC2401.data(goodTime);
    ch4c_pic2401=dat.CH4C_PIC2401.data(goodTime).*1000;
    co_pic2401=dat.CO_PIC2401.data(goodTime);
    h2o_pic2401=dat.H2O_PIC2401.data(goodTime).*10000;
    
    
    lat=dat.LATC.data(goodTime);
    lon=dat.LONC.data(goodTime);
    rafAlt=dat.PALT.data(goodTime);
    concU100=dat.CONCU100_RPO.data(goodTime);
    fo3c=dat.FO3C_ACD.data(goodTime);
    dp=dat.DPXC.data(goodTime);
    vxlT=dat.STRONG_VXL2.data(goodTime);
    uvh=dat.XSIGV_UVH.data(goodTime);
    
mr=dat.MR.data(goodTime);
mr_ppm=mr.*1608;
    % end
    
    if (processRawUser2401)
        % Will re-import raw data from original data files if the matfile does not exist, or if user-specified
        if (createRawUser2401||~exist([picPath2401 slash char(fltnoLC) slash '20' FltDate '_' char(fltno) '_rawPic2401User.mat'],'file'))
            if sync
                [rtnMsg] = createUserSync2401file(StartPath,picPath2401,slash,fltno,fltnoLC,...
                    FltDate,crossesMidnite);
                fprintf(rtnMsg);
            else
                [rtnMsg] = createUser2401file(StartPath,picPath2401,slash,fltno,fltnoLC,...
                    FltDate,crossesMidnite);
                fprintf(rtnMsg);
            end
            if (~exist([picPath2401 slash char(fltnoLC) slash]))
                mkdir([picPath2401 slash char(fltnoLC) slash]);
            end
            load([picPath2401 slash char(fltnoLC) slash FltDate '_' char(fltnoLC) '_rawPic2401User.mat']);
        else
            load([picPath2401 slash char(fltnoLC) slash FltDate '_' char(fltnoLC) '_rawPic2401User.mat']);
        end
        
        raf_co2c_pic2401=co2c_pic2401;
        raf_co_pic2401=co_pic2401;
        raf_ch4c_pic2401=ch4c_pic2401;
        raf_h2o_pic2401=h2o_pic2401;
        
        picTimeUsr2401 = picTimeUsr2401 + toffset_pic;
        
        co2c_pic2401 = interp1(picTimeUsr2401,UsrCo2_dry2401,rafTime);
        co_pic2401 = interp1(picTimeUsr2401,UsrCo_raw2401,rafTime);
        ch4c_pic2401 = interp1(picTimeUsr2401,UsrCh4_dry2401,rafTime);
        h2o_pic2401 = interp1(picTimeUsr2401,UsrH2o,rafTime);
        cd(StartPath);
    end
    
    if fltno<16
        co2badIx=find(isnan(co2c_pic2401)==1 | co2c_pic2401<co2lowcal);
    else
        co2badIx=find(isnan(co2c_pic2401)==1 | co2c_pic2401<n2ohical);
    end
    ch4badIx=find(isnan(ch4c_pic2401)==1 | ch4c_pic2401<ch4lowcal);
    co_picbadIx=find(isnan(co_pic2401)==1 | co_pic2401<0);
    h2o_picbadIx=find(isnan(h2o_pic2401)==1 | h2o_pic2401<h2ocal);
    
    % Replace bad data flags and bad data with NaN prior to cal adjustments.
    co2c_pic2401(co2badIx)=NaN;
    ch4c_pic2401(ch4badIx)=NaN;
    co_pic2401(co_picbadIx)=NaN;
    h2o_pic2401(h2o_picbadIx)=NaN;
    
    co_aribadIx=find(isnan(co_ari)==1 | co_ari < 10);
    n2obadIx=find(isnan(n2o_ari)==1 | n2o_ari < n2olowcal);
    h2o_aribadIx=find(isnan(h2o_ari)==1 | h2o_ari < 10);
    co_ari(co_aribadIx)=NaN;
    n2o_ari(n2obadIx)=NaN;
    h2o_ari(h2o_aribadIx)=NaN;
    
    % Apply cal coefficients and n2o fudge factor (GMD lat dep data => 2018
    % 20-45N mean n2o should be 331)
    % cocal_ari_slope=1.131907;cocal_ari_int = - 1.770676
    % cocal_pic_slope=1.049483;cocal_pic_int = 28.295071
    co_ari_corr=(co_ari - cocal_ari_int)./cocal_ari_slope;
    co_pic2401_corr=(co_pic2401.*1000 - cocal_pic_int)./cocal_pic_slope;
    n2o_slope=1.0168;
    n2o_ari_corr=n2o_ari.*n2o_slope;
    
    % co2cal_pic_slope=0.99471; co2cal_pic_int = -0.93101;
    % ch4cal_pic_slope=1.002903; ch4cal_pic_int = -10.014670;
    co2_pic2401_corr=(co2c_pic2401 - co2cal_pic_int)./co2cal_pic_slope;
    ch4_pic2401_corr=(ch4c_pic2401 - ch4cal_pic_int)./ch4cal_pic_slope;
    
    % Create indices to id cals, plus data to remove pre- and post-cals.
    calIx=find(n2o_ari>n2olowcal&n2o_ari<n2ohical);
    % calIx=find((co2c_pic2401>co2lowcal&co2c_pic2401<co2hical)&...
    %     (ch4c_pic2401>ch4lowcal&ch4c_pic2401<ch4hical)&...
    %     (n2o_ari>n2olowcal&n2o_ari<n2ohical));
    calBDFix=[];
    
    if length(calIx)>0
        calChgIx=find(diff(calIx)>5);
        calStartIx=[calIx(1); calIx(calChgIx+1)];
        calEndIx=[calIx(calChgIx); calIx(end)];
        
        for ix=1:length(calStartIx)
            if (calStartIx(ix)-before) < 1
                calBDFix=[calBDFix 1:calEndIx(ix)+after];
            elseif calEndIx(ix)+after > length(rafTime)
                calBDFix=[calBDFix calStartIx(ix)-before:length(rafTime)];
            else
                calBDFix=[calBDFix calStartIx(ix)-before:calEndIx(ix)+after];
            end
        end
    end
    
    calAvgIx=find((co2c_pic2401>co2lowcal&co2c_pic2401<co2hical)&...
        (ch4c_pic2401>ch4lowcal&ch4c_pic2401<ch4hical)&...
        h2o_pic2401<h2ocal&h2o_pic2401<h2oGoodCal);
    
    % Create output variables with bad/missing/cal data replaced with output BDf
    % Pic vars first:
    co2_pic2401out=co2_pic2401_corr;
    ch4_pic2401out=ch4_pic2401_corr;
    co_pic2401out=co_pic2401_corr;
    h2o_pic2401out=h2o_pic2401;
    
    co2badOutIx=find(isnan(co2_pic2401out)==1);
    ch4badOutIx=find(isnan(ch4_pic2401out)==1);
    co_picbadOutIx=find(isnan(co_pic2401out)==1);
    h2o_picbadOutIx=find(isnan(h2o_pic2401out)==1);
    
    co2_pic2401out(calBDFix)=BDF; co2_pic2401out(co2badOutIx)=BDF;
    ch4_pic2401out(calBDFix)=BDF; ch4_pic2401out(ch4badOutIx)=BDF;
    co_pic2401out(calBDFix)=BDF; co_pic2401out(co_picbadOutIx)=BDF;
    h2o_pic2401out(calBDFix)=BDF; h2o_pic2401out(h2o_picbadOutIx)=BDF;
    
    % Now create ARI output vars:
    co_ari_out=co_ari_corr;
    n2o_ari_out=n2o_ari_corr;
    h2o_ari_out=h2o_ari;
    
    co_aribadOutIx=find(isnan(co_ari_out)==1);
    n2o_aribadOutIx=find(isnan(n2o_ari_out)==1);
    h2o_aribadOutIx=find(isnan(h2o_ari_out)==1);
    
    co_ari_out(calBDFix)=BDF; co_ari_out(co_aribadOutIx)=BDF;
    n2o_ari_out(calBDFix)=BDF; n2o_ari_out(n2o_aribadOutIx)=BDF;
    h2o_ari_out(calBDFix)=BDF; h2o_ari_out(h2o_aribadOutIx)=BDF;
    
    % Write icartt files for both instruments, first ARI, then Pic:
    outfile4 = ['ict/' proj '-CON2O_C130_20' year month day '_' rev '.ict']
    
    delete(outfile4);
    fid4=fopen(outfile4,'a');
    
    fprintf(fid4,'%s\n','35, 1001');
    fprintf(fid4,'%s\n','Teresa Campos, Ed Kosciuch, John Munnerlyn and Frank Flocke');
    fprintf(fid4,'%s\n','National Center for Atmospheric Research');
    fprintf(fid4,'%s\n','CON2OH2O - Aerodyne CS-108 miniQCL carbon monoxide, nitrous oxide and water vapor in situ mixing ratio observations from the NSF/NCAR C-130');
    fprintf(fid4,'%s\n%s\n',proj,'1, 1');
    fprintf(fid4,'%s\n',['20' year ', ' month ', ' day ', ' processingDateString]);
    fprintf(fid4,'%s\n%s\n%s\n%s\n%s\n','1', 'Start_UTC, seconds','3', '1, 1, 1', '-99999, -99999, -99999');
    fprintf(fid4,'%s\n%s\n%s\n%s\n%s\n','CO, ppbv, volume_mixing_ratio_of_carbon_monoxide_in_dry_air',...
        'N2O, ppbv, volume_mixing_ratio_of_nitrous_oxide_in_dry_air','H2O, ppmv, volume_mixing_ratio_of_water_in_dry_air',...
        '0','18');
    fprintf(fid4,'%s\n','PI_CONTACT_INFO: Address: PO Box 3000, Boulder, CO  80307; email: campos@ucar.edu');
    fprintf(fid4,'%s\n','PLATFORM: NSF/NCAR C-130 - rack R10 outboard, lower fuselage 12" himil, FS54, unheated, aft-facing 1/4" SS inlet');
    fprintf(fid4,'%s\n','LOCATION: Aircraft location data in NCAR netcdf and icartt files');
    fprintf(fid4,'%s\n','ASSOCIATED_DATA: see ftp://catalog.eol.ucar.edu');
    fprintf(fid4,'%s\n','INSTRUMENT_INFO: CO, N2O, and water vapor by Aerodyn mini QCL direct absorbance spectrometer, TILDAS CS-108');
    fprintf(fid4,'%s\n','DATA_INFO: CO units are ppbv, N2O units are ppbv, and H2O units are ppmv');
    fprintf(fid4,'%s\n','UNCERTAINTY: The combined 2-sigma uncertainty is estimated to be +/- 1 ppbv for CO, 0.2 ppbv for N2O, and <50 ppmv for H2O');
    fprintf(fid4,'%s\n%s\n','ULOD_FLAG: -7777','ULOD_VALUE: N/A');
    fprintf(fid4,'%s\n%s\n','LLOD_FLAG: -8888','LLOD_VALUE: N/A');
    fprintf(fid4,'%s\n','DM_CONTACT_INFO: Teresa Campos, campos@ucar.edu');
    fprintf(fid4,'%s\n','PROJECT_INFO: WE-CAN Mission 20 July - 15 September, 2018; airborne ops base: Boise, ID thru Aug and RMMA thereafter');
    fprintf(fid4,'%s\n','STIPULATIONS_ON_USE: Use of these data requires prior approval from lead instrument PI');
    fprintf(fid4,'%s\n','OTHER_COMMENTS: Revision A is field quality data, R0+ is final quality');
    fprintf(fid4,'%s%s%s\n','REVISION: ',rev,'');
    fprintf(fid4,'%s%s\n',rev,': Preliminary Final Data');
    fprintf(fid4,'%s\n','Start_UTC,CO,N2O,H2O');
    
    for ix=1:length(rafTime)
        fprintf(fid4,'%d,%.1f,%.1f,%d\n',rafTime(ix),co_ari_out(ix),n2o_ari_out(ix),h2o_ari_out(ix));
    end
    fclose(fid4);
    
    outfile5 = ['ict/' proj '-CO2CH4COH2O_C130_20' year month day '_' rev '.ict']
    
    delete(outfile5);
    fid5=fopen(outfile5,'a');
    
    fprintf(fid5,'%s\n','36, 1001');
    fprintf(fid5,'%s\n','Teresa Campos, Ed Kosciuch, John Munnerlyn and Frank Flocke');
    fprintf(fid5,'%s\n','National Center for Atmospheric Research');
    fprintf(fid5,'%s\n','CO2CH4COH2O - Picarro G2401-m WS-CRDS carbon dioxide, methane, carbon monoxide and water vapor in situ mixing ratio observations from the NSF/NCAR C-130');
    fprintf(fid5,'%s\n%s\n',proj,'1, 1');
    fprintf(fid5,'%s\n',['20' year ', ' month ', ' day ', ' processingDateString]);
    fprintf(fid5,'%s\n%s\n%s\n%s\n%s\n','1', 'Start_UTC, seconds', '4','1, 1, 1, 1', '-99999, -99999, -99999,-99999');
    fprintf(fid5,'%s\n%s\n%s\n%s\n%s\n%s\n','CO2, ppmv, volume_mixing_ratio_of_carbon_dioxide_in_dry_air',...
        'Methane, ppbv, volume_mixing_ratio_of_methane_in_dry_air',...
        'CO, ppbv, volume_mixing_ratio_of_carbon_monoxide_in_dry_air','H2O, ppmv, volume_mixing_ratio_of_water_in_dry_air',...
        '0','18');
    fprintf(fid5,'%s\n','PI_CONTACT_INFO: Address: PO Box 3000, Boulder, CO  80307; email: campos@ucar.edu');
    fprintf(fid5,'%s\n','PLATFORM: NSF/NCAR C-130 - rack R10 outboard, lower fuselage 12" himil, FS54, unheated, aft-facing 1/4" SS inlet');
    fprintf(fid5,'%s\n','LOCATION: Aircraft location data in NCAR netcdf and icartt files');
    fprintf(fid5,'%s\n','ASSOCIATED_DATA: see ftp://catalog.eol.ucar.edu');
    fprintf(fid5,'%s\n','INSTRUMENT_INFO: CO2, Methane, CO, and water vapor by Picarro G2401-m WS-CRD spectrometer');
    fprintf(fid5,'%s\n','DATA_INFO: CO2 units are ppmv, Methane units are ppbv, CO units are ppbv, and H2O units are ppmv');
    fprintf(fid5,'%s\n','UNCERTAINTY: The combined 2-sigma uncertainty is estimated to be +/- .1 ppmv for CO2, 3 ppbv for Methane, 50 ppbv for CO and <100 ppmv for H2O');
    fprintf(fid5,'%s\n%s\n','ULOD_FLAG: -7777','ULOD_VALUE: N/A');
    fprintf(fid5,'%s\n%s\n','LLOD_FLAG: -8888','LLOD_VALUE: N/A');
    fprintf(fid5,'%s\n','DM_CONTACT_INFO: Teresa Campos, campos@ucar.edu');
    fprintf(fid5,'%s\n','PROJECT_INFO: WE-CAN Mission 20 July - 15 September, 2018; airborne ops base: Boise, ID thru Aug and RMMA thereafter');
    fprintf(fid5,'%s\n','STIPULATIONS_ON_USE: Use of these data requires prior approval from lead instrument PI');
    fprintf(fid5,'%s\n','OTHER_COMMENTS: Revision A is field quality data, R0+ is final quality');
    fprintf(fid5,'%s%s%s\n','REVISION: ',rev,'');
    fprintf(fid5,'%s%s\n',rev,': Preliminary Final Data');
    fprintf(fid5,'%s\n','Start_UTC,CO2,Methane,CO,H2O');
    
    for ix=1:length(rafTime)
        fprintf(fid5,'%d,%.1f,%.1f,%.1f,%d\n',rafTime(ix),co2_pic2401out(ix),ch4_pic2401out(ix),co_pic2401out(ix),h2o_pic2401out(ix));
    end
    fclose(fid5);
    
    figure,plot(rafTime,ch4_pic2401out,'b.');ylim([1700 3000]);
    figure,plot(rafTime,co2_pic2401out,'b.');ylim([390 500]);
    figure,plot(rafTime,co_pic2401out,'b.');ylim([0 10000]);
    figure,plot(rafTime,h2o_pic2401out,'b.');ylim([0 20000]);
    figure,plot(rafTime,co_ari_out,'b.');ylim([0 10000]);
    figure,plot(rafTime,n2o_ari_out,'b.');ylim([0 500]);
    figure,plot(rafTime,h2o_ari_out,'b.');ylim([0 20000]);
    
    save([ncfile(1:9) '.mat'])
    clear all; close all
end
toc