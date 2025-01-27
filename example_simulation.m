%Copyright 2018-2019 - Abdelrahman Zayed (c) Nov 2019
%Please cite the following paper if you are using this code:
%       Zayed, A., Rivaz, H., Fast Strain Estimation and Frame Selection in
%Ultrasound Elastography using Machine Learning, IEEE Trans. UFFC, 2020


clear all
close all
clc



%The is the result of Figure 10, subfigures from (a) to (d) (i.e when there
%is no noise).

h_a=1041-80;
w_a=250-30;

f_sample=40e6;
c_sound=1540e3;

%This is to choose which RF line to start with. In this example, we start
%with RF line number 59. Our step is 15, which means that the next RF line
%is 59+15 and so on.
step_line_10=15;
start_line_10=59;
num_of_lines_10=ceil((w_a-(start_line_10-1))/(step_line_10));

%This is used to load the 12 principal components
load 12_principal_components_simulation.mat
axial_principal_components=10^4*axial_principal_components;

load Axial_lateral_ground_truth.mat

s=1;
for jjj=[0]

    for i=[1]
    i       
    s
    load(['Im' num2str(jjj+i) '_with_tstart_level_1.mat'])
    exist RfDataDouble;
    ex1=ans;
    if ex1==1
    RfDataDouble=double(RfDataDouble);
    Imm1 = RfDataDouble(:,:);
    else
    BfData=double(Im0);
    Imm1 = BfData(5*2*round(f_sample/c_sound):25*2*round(f_sample/c_sound), : );
    end
    maxIm = max(Imm1(:));
    Imm1 = Imm1/maxIm;

    load(['Im' num2str(jjj) '_with_tstart_level_1.mat'])
    exist RfDataDouble;
    ex2=ans;
    if ex2==1
    RfDataDouble=double(RfDataDouble);
    Imm2 = RfDataDouble(:,:);
    else
    BfData=double(Im0);
    Imm2 = BfData(5*2*round(f_sample/c_sound):25*2*round(f_sample/c_sound), : );
    end
    maxIm = max(Imm2(:));
    Imm2 = Imm2/maxIm;     



    IRF = [0 30];
    IA = [-1 1]; 
    alfa_DP = 0.2;
    size(Imm1);
    dim=ans(2);

    % This is to run the NCC algorithm
    num_win =1160;
    len_win =51;
    lat_len_win =21;
    Range = 5;

    [disp4, rho4,RangeNCC] = disp_est(Imm1, Imm2, num_win, len_win,lat_len_win, Range); 
    
    %This is to run DP on all of the RF lines for GLUE
    [ax00, rot00] = DP(Imm1, Imm2, IRF, IA, alfa_DP);

    %This is to run DP on all only 5 RF lines for PCA-GLUE
    [ax10, rot10] = zayedDP_5lines_p2(abs(hilbert(Imm1)), abs(hilbert(Imm2)), IRF, IA, alfa_DP,dim);


    ax10=zeros(size(ax00));
    rot10=zeros(size(rot00));
    ax10 = ax10(41:end-40, 16:end-15);
    rot10 = rot10(41:end-40, 16:end-15);
    ax00 = ax00(41:end-40, 16:end-15);
    rot00 = rot00(41:end-40, 16:end-15);
    Imm1 = Imm1(41:end-40, 16:end-15);
    Imm2 = Imm2(41:end-40, 16:end-15);


    for jj=start_line_10:step_line_10:w_a
        ax10(:,jj)=ax00(:,jj);
        rot10(:,jj)=rot00(:,jj);
    end

    mmm=1;
    for jj=start_line_10:step_line_10:w_a
        rot110(:,mmm)=rot10(:,jj);
        mmm=mmm+1;
    end

    rot10 = imresize(rot110,[h_a w_a], 'bilinear');

    for p=start_line_10:step_line_10:w_a
        ax10(:,p)=interpolate_line(ax10(:,p),h_a);
    end




    alfa1 = 5 ; 
    alfa2 = 1 ;
    beta1 = 5 ; 
    beta2 = 1 ;

    



    k_10=ceil((w_a-(start_line_10-1))/(step_line_10))*h_a;




    mm=1;
    for jj=start_line_10:step_line_10:w_a
        if(mm>=k_10) break; end
        for ii=1:1:h_a
            p_10(mm,1)=ii;
            p_10(mm,2)=jj;
            mm=mm+1;
        end
    end




    for r=1:1:k_10
        q_10(r,1)=ax10(p_10(r,1),p_10(r,2))+p_10(r,1);
        q_10(r,2)=rot10(p_10(r,1),p_10(r,2))+p_10(r,2);
    end





    vv_10=q_10-p_10;
    v1_10=vv_10(:,1);
    clear A
    N=12;


    for z=1:1:N
         temp=reshape(axial_principal_components(:,z), [h_a w_a]);
        for j=1:1:k_10
             A_10(j,z)=temp(p_10(j,1),p_10(j,2));
        end
    end





    w_10=lsqlin(A_10,v1_10);

    axial_restored_10=axial_principal_components*w_10;
    axial_restored_10=reshape(axial_restored_10, [h_a w_a]);

     %Now we run get the fine-tuned displacement estimation. 
    [Axial, roteral] = GLUE (ax00, rot00, Imm1, Imm2, alfa1, alfa2, beta1, beta2);
    [Axial_PCAFlow_10, roteral_PCAFlow_10] = GLUE (axial_restored_10, rot10, Imm1, Imm2, alfa1, alfa2, beta1, beta2);


    max_strain=15e-3;
    min_strain=0;


    %This is used to get the strain using PCA-GLUE
    xRat = (40.8-2.5)/w_a;
    yRat = 42.95/2233;
    wDIff = 93; % window length of the differentiation kernel
    strainA_10 = LSQ(Axial_PCAFlow_10(41:end-41,11:end-10),wDIff);
    strainA_10 = strainA_10((wDIff+1)/2:end-(wDIff-1)/2,:);
    strainA_10(strainA_10>max_strain) = max_strain;
    strainA_10(strainA_10<min_strain) = min_strain;
    startA = 1; endA = size(strainA_10,2);
    startRF = 1; endRF = size(strainA_10,1); 
    figure;
    imagesc([0 xRat*(endA-startA)],yRat*[startRF endRF],strainA_10); set(gca,'fontsize',53);
%     colorbar 
    colormap(gray);xlabel('width (mm)','fontsize',53); ylabel('depth (mm)','fontsize',53);

    %This is used to get the strain using GLUE
    xRat = (40.8-2.5)/w_a;
    yRat = 42.95/2233;
    wDIff = 93; % window length of the differentiation kernel
    strainA = LSQ(Axial(41:end-41,11:end-10),wDIff);
    strainA = strainA((wDIff+1)/2:end-(wDIff-1)/2,:);
    strainA(strainA>max_strain) = max_strain;
    strainA(strainA<min_strain) = min_strain;
    startA = 1; endA = size(strainA,2);
    startRF = 1; endRF = size(strainA,1); 
    figure;
    imagesc([0 xRat*(endA-startA)],yRat*[startRF endRF],strainA); set(gca,'fontsize',53);
%     colorbar
    colormap(gray);xlabel('width (mm)','fontsize',53); ylabel('depth (mm)','fontsize',53)



    %This is used to get the Bmode image
    BMODE1 = log(abs(hilbert(Imm1))+.01);
    figure;
    imagesc([0 xRat*(endA-startA)],yRat*[startRF endRF],BMODE1(1:end-100,:)); set(gca,'fontsize',53);
    colormap(gray);xlabel('width (mm)','fontsize',53); ylabel('depth (mm)','fontsize',53);
    
    dAxial2=imresize(dAxial,[h_a w_a],'bilinear');
    
    %This is used to get the strain using NCC
    xRat = (40.8-2.5)/w_a;
    yRat = 42.95/2233;
    wDIff = 93; % window length of the differentiation kernel
    strain7 = LSQ(dAxial2(41:end-41,11:end-10),wDIff);
    strain7 = strain7((wDIff+1)/2:end-(wDIff-1)/2,:);
    strain7=strain7*44.8;
    strain7(strain7>max_strain) = max_strain;
    strain7(strain7<min_strain) = min_strain;
    
    k=floor(200/(xRat*(endA-startA))*9);
    strain7=strain7(:,k+1:end-k);
    
    figure;
    imagesc([0 xRat*(endA-startA)],yRat*[startRF endRF],strain7); set(gca,'fontsize',53);
    colormap(gray);xlabel('width (mm)','fontsize',53); ylabel('depth (mm)','fontsize',53);

    
    
    
    s=s+1;


    
    end
end

