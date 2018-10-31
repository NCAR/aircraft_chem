function     [rtnMsg] = createUser2401file(StartPath,picPath2401user,slash,fltno,fltnoLC,...
    FltDate,crossesMidnite);
    cd([picPath2401user slash fltnoLC]);
    fileList_unsort = dir('*.dat');
    fileListUser2401 = sort({fileList_unsort.name});
    fileCountUser2401 = length(fileListUser2401);
    
        dTotal2401User = [];
        
        for i=1:fileCountUser2401(1)
            fprintf('Loading file %d of %d...\n',i,fileCountUser2401);
            newdata = importfile2401(char(fileListUser2401(i)));
            goodIx = find(isnan(newdata.data(:,4))==0);
            newdata.data=newdata.data(goodIx,:);
            dTotal2401User = [dTotal2401User;newdata.data];
        end
        
        
        UsrFracJulianDay2401=dTotal2401User(:,3);
        UsrEpochTime2401=dTotal2401User(:,4);
        UsrAlarmStat2401=dTotal2401User(:,5);
        UsrInst_stat2401=dTotal2401User(:,6);
        UsrAmbP2401=dTotal2401User(:,7);
        UsrCavPres2401=dTotal2401User(:,8);
        UsrCavTemp2401=dTotal2401User(:,9);
        UsrDasT=dTotal2401User(:,10);
        UsrEtalonTemp2401=dTotal2401User(:,11);
        UsrWarmBoxTemp2401=dTotal2401User(:,12);
        UsrCo_raw2401=dTotal2401User(:,17);
        UsrCo2_raw2401=dTotal2401User(:,18);
        UsrCo2_dry2401=dTotal2401User(:,19);
        UsrCh4_raw2401=dTotal2401User(:,20).*1000;
        UsrCh4_dry2401=dTotal2401User(:,21).*1000;
        UsrH2o=dTotal2401User(:,22).*10000;
%         UsrH2oReported=dTotal2401User(:,23);
%         Usr_b_H2o_pct=dTotal2401User(:,24);
        UsrMPVposition=dTotal2401User(:,13);
        UsrInletValves=dTotal2401User(:,14);
        UsrOutletValves=dTotal2401User(:,15);
%         UsrSolenoidValves=dTotal2401User(:,18);
%         UsrSpecies=dTotal2401User(:,13);
        
    [yearUsr2401,monthUsr2401,dayUsr2401,hourUsr2401,minuteUsr2401,secUsr2401]=unixsecs2date(UsrEpochTime2401);
    
    if crossesMidnite
        firstSecUsr2401 = secUsr2401(1)+60.*minuteUsr2401(1)+3600.*hourUsr2401(1);
        picTimeUsr2401=hms2sec(hourUsr2401,minuteUsr2401,secUsr2401);
        tempIx = find(picTimeUsr2401 < (firstSecUsr2401));
        if tempIx
            picTimeUsr2401(tempIx) = picTimeUsr2401(tempIx)+86400;
        else
% for the case where pic data acq after zulu midnight, but raf data file
% starts pre-midnight.
            picTimeUsr2401 = picTimeUsr2401 + 86400;
        end
    else
        picTimeUsr2401=hms2sec(hourUsr2401,minuteUsr2401,secUsr2401);
    end
%             goodIx = find(isnan(picTimeUsr2401)==0);
%         picTimeUsr2401=picTimeUsr2401(goodix);
%         UsrEpochTime2401=UsrEpochTime2401(goodIx);
%         UsrAlarmStat=UsrAlarmStat(goodIx);
%         UsrInst_stat=UsrInst_stat(goodIx);
%         UsrCh4_raw2401=UsrCh4_raw2401(goodIx);
%         UsrCh4_dry2401=UsrCh4_dry2401(goodIx);
%         UsrCo2_raw2401=UsrCo2_raw2401(goodIx);
%         UsrCo2_dry2401=UsrCo2_dry2401(goodIx);
%         UsrDasT=UsrDasT(goodIx);
%         UsrH2o=UsrH2o(goodIx);
%         UsrMPVposition=UsrMPVposition(goodIx);
%         UsrCavPres2401=UsrCavPres2401(goodIx);
%         UsrSolenoidValves=UsrSolenoidValves(goodIx);
%         UsrSpecies=UsrSpecies(goodIx);
%         dTotaldTotal2401User(goodIx,:);
            
%         save([StartPath slash char(fltnoLC) slash '20' FltDate '_' char(fltno) '_rawPic2401User.mat'],'picTimeUsr2401',...
%             'UsrEpochTime2401','UsrAlarmStat','UsrInst_stat','UsrCh4_raw2401','UsrCh4_dry2401','UsrCo2_raw2401',...
%             'UsrCo2_dry2401','UsrDasT','UsrH2o','UsrMPVposition','UsrCavPres2401','UsrSolenoidValves',...
%             'UsrSpecies','dTotal2401User');

        save([picPath2401user slash char(fltnoLC) slash FltDate '_' char(fltnoLC) '_rawPic2401User.mat']);
            
    rtnMsg = 'Reading Picarro G2401 User files\n';

end