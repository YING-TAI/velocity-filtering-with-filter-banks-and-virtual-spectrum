clear all;
close all;
clc;

tic
%%
%CT模型
% 
SIGMArmse=0;
PDflag=0;
%     for flag=1:100
        
        w=0.2;
        v=3;
        filter_number=2;
        
        theta0=0;
        x0=35;
        y0=10;%初始位置
        SNR=8       ;
        I=10^(SNR/20);%目标幅度
        total_frame=8;%观测总帧数
        x_max=50;
        y_max=50;%观测总范围
        sigma=0.7;%虚拟谱中的sigma
        %%
        %建立目标真实航迹
        for k=1:total_frame
            x(k)=x0+(cos(theta0-w*k)-cos(theta0))/w*v;
            y(k)=y0+(-sin(theta0-w*k)+sin(theta0))/w*v;
            vx(k)=sin(theta0-w*k)*v;
            vy(k)=cos(theta0-w*k)*v;
        end%目标真实航迹
        
        %%
        %建立目标观测模型
        for k=1:total_frame
            for i=1:x_max
                for j=1:y_max
                    z(i,j,k)=0;
                end
            end
            
        end%建立观测模型，雷达观测时空域z，k为时间帧数，ij为空间位置
        %%
        %生成点扩散目标
        for k=1:total_frame
            for i=1:x_max
                for j=1:y_max
                    virtual_target(i,j,k)=I*exp(-((x(k)-i)^2+(y(k)-j)^2)/(2*sigma^2));
                end
            end%生成点扩散目标
            z(:,:,k)=virtual_target(:,:,k)+normrnd(0,1,x_max,y_max);%加上均值为0,方差为1的高斯白噪声
            %z(:,:,k)=virtual_target(:,:,k)+ones(x_max,y_max);
        end%将目标信息移动到观测点上
        
        figure(1)
        plot(y,x,'*');
        axis([0 50 0 50]);
        xlabel('单元格数/个');
        ylabel('单元格数/个');
%         title('单一非机动目标CT轨迹');
        figure(2)
        axis([0 50 0 50]);
        surf(z(:,:,total_frame));
        xlabel('单元格数/个');
        ylabel('单元格数/个');
        zlabel('回波幅值/单位1')
%         title('末帧目标回波，带噪声');
        %%
        %w滤波器组
        w_filter=w;
        w_filter_max=w-0.02*filter_number:0.02:w+0.02*filter_number;
        v_filter_max=v-0.2*filter_number:0.2:v+0.2*filter_number;
        for w_filter10=1:length(w_filter_max)
            w_filter=w_filter_max(w_filter10);
            %v滤波器组（假设第一幅图已得到，初始x0,y0已知,w,theta0已知,v未知，那么vx,vk也是未知的）
            for v_filter10=1:length(v_filter_max)
                v_filter=v_filter_max(v_filter10);%假设已知v的范围为【0.5,1.5】
                for k=1:total_frame
                    %             x_v_filter(k)=x0+(cos(theta0-w*k)-cos(theta0))/w*v_filter;
                    %             y_v_filter(k)=y0+(-sin(theta0-w*k)+sin(theta0))/w*v_filter;
                    vx_v_filter(k)=sin(theta0-w_filter*k)*v_filter;
                    vy_v_filter(k)=cos(theta0-w_filter*k)*v_filter;
                end%每个vx_filter下目标可能航迹
                
                %积累至最后一帧
                output_matrix(:,:,w_filter10,v_filter10)=jilei(w_filter,z,total_frame,x_max,y_max,vx_v_filter,vy_v_filter);
                %        output_matrix(:,:,w_filter10,v_filter10)=jilei_virtual_spectrum(w_filter,z,total_frame,x_max,y_max,vx_v_filter,vy_v_filter,sigma);
                output_max(w_filter10,v_filter10)=max(max(output_matrix(:,:,w_filter10,v_filter10)));
            end
        end
        
        %%
        %寻找最佳v滤波器及该v下的目标位置
        output_matrix_max=max(max(output_max));
        for i=1:x_max
            for j=1:y_max
                for w_filter=1:length(w_filter_max)
                    for v_filter=1:length(v_filter_max)
                        if output_matrix(i,j,w_filter,v_filter)==output_matrix_max
                            target=[i,j,w_filter,v_filter];
                        end
                    end
                end
            end
        end
        
%%        
%         画出积累后的图
%        
        figure(3)
        surf(output_matrix(:,:,3,3));
%          title('所有帧积累至末帧回波');
        xlabel('单元格数/个');
        ylabel('单元格数/个');
        zlabel('回波幅值/单位1')
        

        
       
        if abs(target(1)-x(total_frame))<=2&&abs(target(2)-y(total_frame))
            PDflag=PDflag+1;
            SIGMArmse=(target(1)-x(total_frame))^2+(target(2)-y(total_frame))^2+SIGMArmse;
        end
        
        

    
%    end
% PD=PDflag/flag;
% RMSE=sqrt(SIGMArmse/2/PDflag);
% ex=0;
% ex2=0;
% for i=10:44
%     for y=1:23
%         ex=output_matrix(i,j,3,3)+ex;
%         ex2=output_matrix(i,j,3,3)^2+ex2;
%     end
% end
% for i=15:25
%     for y=4:14
%         ex=ex-output_matrix(i,j,3,3);
%         ex2=ex2-output_matrix(i,j,3,3)^2;
%     end
% end

toc

