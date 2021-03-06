%% Script Description:
% Each block is marked as essential or un-necessary for continious execuation
% Essential block is marked as #<Exec: %i>#, where %i indicates the sequence
% Un-necessary block is marked as <optional@%i> where %i indicates the block that should be
%       running before the optional block could run
%
% Regular variable that should be kept in workspace
clear
clc


arch='linux'; % | 'linux', 'mac'
fid='024';
leak=[222,222,85,86,1,2];   % source location
% leak=[299,300,80,81];   % source location
strength=1;  % source strength
lk_start=100;   % time to leak
lk_end=200;     % time leak ends
layer=1;        % default z layer
T_end=400;      % Total simulation time

if strcmp(arch,'win')
    
    disp('Working on ''Windows'' platform')
    matpath='D:\fdsmat\Facility';                     % Must end with '\'
    addpath(matpath)
elseif strcmp(arch,'linux')
    cd /home/wangbing/GitHub/MATLAB/CA
    disp('Working on ''Linux'' Platform')
    matpath='/disk/fdsmat/Facility/';           % Must end with '/'
    tmppath='/home/tmp/';                      % Make sure folder exist
    addpath(matpath)
elseif strcmp(arch,'mac')
    disp('Working on ''MacOS'' Platform')
    matpath='/disk/fdsmat/';
    addpath(matpath)
end
% chid=['Spectra_',fid];
chid=['Facility_',fid];

load('mycolormap.mat')

fdsf=matfile([chid,'.mat']);

dims=fdsf.dims;
IX=dims(1);
IY=dims(2);
IZ=dims(3);
IT=dims(4);

IT=IT-1;
time=fdsf.time(1:IT,1);



%% <optional@02>    Plot Original Chlorine Concentration
layer=1;
CHLORINE_VOLUME_FRACTION=fdsf.CHLORINE_VOLUME_FRACTION;
fun_plot2D_FDS(CHLORINE_VOLUME_FRACTION,time,3,mycmap,chid,layer,arch)
clear CHLORINE_VOLUME_FRACTION

%% #<Exec:02>#    Some statistics
% time space analysis

Dtimearray=time(2:IT)-time(1:IT-1);
plot(Dtimearray)
Dt_test=mean(Dtimearray);
pause(2)
% mean wind velocity at time t
for i=IT:-1:1
    mean_vel_array(i)=mean(mean(mean(fdsf.VELOCITY(:,:,:,i))));
end
plot(mean_vel_array)
vel_mean_time=mean(mean_vel_array);

clear VELOCITY

%% #<Exec:03>#    Determine Dt and Dspace given specific Dispersion coefficient
% Rule: mean_vel*Dt/Dspace <= 1/2
Dspace_test=1.0;
% 1. Given Dspace
Dt_upperbound=Dspace_test/2/vel_mean_time;
disp(['Maximum time interval is: <',num2str(Dt_upperbound),' given space interval = ',num2str(Dspace_test)])
% 2. Given Dtime
Dspace_lowbound=2*vel_mean_time*Dt_test;
disp(['Minimum space interval is: >',num2str(Dspace_lowbound),' given time interval = ',num2str(Dt_test)])


%% #<Exec:04>#     Velocity field time interpolation


% ------------ Dt & Dspace could change according to Exec:03
Dt=0.05;
Dspace=1;
% ------------------------------------------------------------

% Create mat file
fdsq=matfile([tmppath,chid,'_q.mat'],'Writable',true);

% Write time_q to file
time_q=0:Dt:T_end;
ITq=length(time_q);

fdsq.time_q=time_q;
fdsq.dimsq=[IX,IY,IZ,ITq];

total=double(IX*IY*IZ);

% ------------------------------------------------------------------
tic;

u_vel=fdsf.U_VELOCITY;
count=0;
textprogressbar('U-Velocity ... ')

for k=IZ:-1:1
    for j=IY:-1:1
        for i=IX:-1:1
            u_vel_temp=reshape(u_vel(i, j, k, 1:IT),1,IT);
            u_vel_new=spline(time,u_vel_temp,time_q);
            u_vel_q(i,j,k,1:ITq)=single(reshape(u_vel_new,1,1,1,ITq));
            count=count+1;
            textprogressbar(count/total*100);
        end
%             disp(num2str(count));
    end
end
time_for_interp=toc;   % about two minites
textprogressbar([' Time Elapse: ',round(num2str(time_for_interp)),'s']);

tic
fdsq.u_vel_q=u_vel_q;
time_for_save=toc;
disp(['Time for saving u_vel : ',round(num2str(time_for_save)),'s'])

clear u_vel_temp u_vel_new u_vel_q u_vel



% --------------------------------------------------------
tic
count=0;

v_vel=fdsf.V_VELOCITY;

textprogressbar('V-Velocity ... ')

for k=IZ:-1:1
    for j=IY:-1:1
        for i=IX:-1:1
            v_vel_temp=reshape(v_vel(i, j, k, 1:IT),1,IT);
            v_vel_new=spline(time,v_vel_temp,time_q);
            v_vel_q(i,j,k,1:ITq)=single(reshape(v_vel_new,1,1,1,ITq));
            count=count+1;
             textprogressbar(count/total*100);
        end
    end
end
time_for_interp=toc;   
textprogressbar(['Time Elapse: ',round(num2str(time_for_interp)),'s']);

tic
fdsq.v_vel_q=v_vel_q;
time_for_save=toc;
disp(['Time for saving v_vel is: ',round(num2str(time_for_save)),'s'])

clear v_vel v_vel_temp v_vel_ew v_vel_q

% --------------------------------------------------

tic
count=0;
w_vel=fdsf.W_VELOCITY;

textprogressbar('W-Velocity ... ')

for k=IZ:-1:1
    for j=IY:-1:1
        for i=IX:-1:1
            w_vel_temp=reshape(w_vel(i, j, k, 1:IT),1,IT);
            w_vel_new=spline(time,w_vel_temp,time_q);
            w_vel_q(i,j,k,1:ITq)=single(reshape(w_vel_new,1,1,1,ITq));
            count=count+1;
              textprogressbar(count/total*100);
        end      
    end
end
time_for_interp=toc;   % about two minites
textprogressbar([' Time Elapse: ',round(num2str(time_for_interp)),'s']);

tic
fdsq.w_vel_q=w_vel_q;
time_for_save=toc;
disp(['Time for saving w_vel_q is: ',round(num2str(time_for_save)),'s'])


clear w_vel w_vel_new w_vel_temp w_vel_q

if strcmp(arch, 'linux')
    cmdline=['mv ',tmppath,chid,'_q.mat',' ',matpath,chid,'_q.mat'];
    system(cmdline,'-echo')
end



%% #<Exec:05># / #<Spectial:02#
% %%%%%%%%% Begin to simulate CA dispersion %%%%%%%%%%%%%%%

mf=matfile([matpath,chid,'_q.mat']);
time_q=mf.time_q;

nmf=matfile([matpath,chid,'_con.mat'],'Writable',true);
nmf.time_q=time_q;

t=0;            % time start
save_loop=100;
file_count=0;
% Initial condition
if t == 0
    C=zeros(IX,IY,IZ);      % Array initialization
    Source=zeros(IX,IY,IZ);      % Source Character
    nmf.con=single(zeros(IX,IY,IZ,IT));  % initialize dimension
end
step=0;

save_count=0;

% Begin Loop
tic;
textprogressbar('Executing CA: ')
while t<=T_end
    t=t+Dt;
    step=step+1;
    save_count=save_count+1;
    % Extract one layer at time step from 3-D velocity field
    u_vel_t=reshape(mf.u_vel_q(1:IX,1:IY,1:IZ,step),IX,IY,IZ);
    v_vel_t=reshape(mf.v_vel_q(1:IX,1:IY,1:IZ,step),IX,IY,IZ);
    w_vel_t=reshape(mf.w_vel_q(1:IX,1:IY,1:IZ,step),IX,IY,IZ);
    
    if t >= lk_start && t < lk_end
        Source(leak(1):leak(2),leak(3):leak(4),leak(5):leak(6))=strength;
    else
        Source=zeros(IX,IY,IZ);
    end
    
    New_C=fun_update3D(C,u_vel_t,v_vel_t,w_vel_t,Dt,Dspace,Source);
    
    C=New_C;
    nmf.con(1:IX,1:IY,1:IZ,step)=single(New_C);
    
    %     if save_count <= save_loop
    %         con(:,:,:,save_count)=New_C;
    %     else
    %         file_count=file_count+1;
    %         if strcmp(arch, 'linux')
    %             save([matpath,chid,'_con_',num2str(file_count,'%03d'),'.mat'],'con');
    %         elseif strcmp(arch,'win')
    %             save([matpath,chid,'_con_',num2str(file_count,'%03d'),'.mat'],'con');
    %         end
    %         con=zeros(IX,IY,IZ,save_loop);
    %         save_count=1;
    %         con(:,:,:,save_count)=New_C;
    %     end
    
    textprogressbar(round(t/T_end*100))
    
end
CA_loop_time=toc;
textprogressbar(['Time Elapse: ',num2str(CA_loop_time),' s'])

%% #<Exec:06>#  Results visulization
% -------------------------
%   Go to initial to clear
% ---------------------------
nmf=matfile([matpath,chid,'_con.mat']);

layer=1;

% Generate CA results
fun_plot3D_CA(nmf,mycmap,chid,layer,arch)


%% Debug purpose
iskp=100;
k=0;
seqns=1:iskp:size(con,3);
for i=seqns
    k=k+1;
    CMax(k)=max(max(con(:,:,i)));
end
plot(time_q(seqns),CMax)



