%% 角谱反演法（保留倏逝波）：已知测量平面复声压 → 源平面幅值与相位
% 特点：反向传播时包含倏逝波，但使用平滑窗限制放大，提高近场重建精度。
% 输入：测量平面复声压 p_meas（Ny × Nx）
% 输出：源平面幅值 amp_src 与相位 phase_src

clear; close all; clc;

%% 1. 物理与采样参数（请根据实验修改）
c = 343;                % 声速 (m/s)
f = 3430;               % 频率 (Hz)
lambda = c / f;         % 波长 (m)
k = 2*pi / lambda;      % 波数

Lx = 2;               % x方向物理尺寸 (m)
Ly = 2;               % y方向物理尺寸 (m)
Nx = 128;               % x方向采样点数
Ny = 128;               % y方向采样点数
dx = Lx / Nx; 
dy = Ly / Ny;

d_meas = 0.2;           % 测量平面与源平面的距离 (m)

% 空间频率网格
fx = (-Nx/2 : Nx/2-1) / Lx; 
fy = (-Ny/2 : Ny/2-1) / Ly;
[Fx, Fy] = meshgrid(fx, fy);
kx = 2*pi * Fx;
ky = 2*pi * Fy;
k_rho = sqrt(kx.^2 + ky.^2);   % 径向波数

%% 2. 准备测量平面复声压 p_meas（仿真示例，可替换为实测数据）
x = (-Nx/2 : Nx/2-1) * dx;
y = (-Ny/2 : Ny/2-1) * dy;
[X, Y] = meshgrid(x, y);

% 假想源平面真实声压（点源，包含倏逝波细节）
%xs = 0.02; ys = 0.01;         % 点源位置
%sigma_s = 0.005;              % 很小的高斯宽度 → 含丰富倏逝波成分
%p_src_true = exp(-((X-xs).^2 + (Y-ys).^2) / (2*sigma_s^2));

% 正向传播得到测量平面声压
%P_src_true = fftshift(fft2(fftshift(p_src_true)));
kz = sqrt(k^2 - kx.^2 - ky.^2);
kz = real(kz) + 1j*abs(imag(kz));  % 正传播：倏逝波衰减
%G_forward = exp(1j * kz * d_meas);
%p_meas = ifftshift(ifft2(ifftshift(P_src_true .* G_forward)));

%% 3.载入实际数据
load('my_measured_pressure.mat');  % 替换为实际数据加载语句

%% 4. 角谱反演：保留倏逝波并施加平滑窗
P_meas = fftshift(fft2(fftshift(p_meas)));

% 完整反向传播核（包含倏逝波指数增长部分）
G_back = exp(-1j * kz * d_meas);

% ---- 方法1：硬截止（仅传播波，丢弃倏逝波） ----
mask_hard = (k_rho <= k);
G_inv_hard = G_back .* mask_hard;

% 重建源平面（硬截止）
P_src_hard = P_meas .* G_inv_hard;
p_src_hard = ifftshift(ifft2(ifftshift(P_src_hard)));

% ---- 方法2：平滑窗保留倏逝波（高斯衰减） ----
% 目的：允许部分倏逝波参与重建，但抑制高频噪声的指数放大。
% 窗函数定义：对于 k_rho > k，以高斯函数逐渐衰减。
alpha = 2;   % 衰减因子，越大衰减越快（可调参数，典型值1~5）
win = ones(size(k_rho));
idx = k_rho > k;
win(idx) = exp(-alpha * ((k_rho(idx) - k)/k).^2);  % 高斯平滑衰减

G_inv_smooth = G_back .* win;

% 重建源平面（平滑窗）
P_src_smooth = P_meas .* G_inv_smooth;
p_src_smooth = ifftshift(ifft2(ifftshift(P_src_smooth)));

%% 5. 提取幅值与相位
% 硬截止结果
amp_hard = abs(p_src_hard);
phase_hard = angle(p_src_hard);
% 平滑窗结果
amp_smooth = abs(p_src_smooth);
phase_smooth = angle(p_src_smooth);

%% 6. 结果对比与可视化
figure('Name', '倏逝波处理对比 (无噪声)', 'Position', [50 50 1400 800]);

subplot(2,3,1);
imagesc(x*100, y*100, abs(P_meas)); axis equal tight; colorbar;
xlabel('x (cm)'); ylabel('y (cm)'); title('真实源 |p_{src}|');

subplot(2,3,2);
imagesc(x*100, y*100, amp_hard); axis equal tight; colorbar;
xlabel('x (cm)'); ylabel('y (cm)'); title('硬截止重建 |p_{src}|');

subplot(2,3,3);
imagesc(x*100, y*100, amp_smooth); axis equal tight; colorbar;
xlabel('x (cm)'); ylabel('y (cm)'); title('保留倏逝波 (平滑窗) 重建 |p_{src}|');

subplot(2,3,4);
imagesc(x*100, y*100, angle(P_meas)); axis equal tight; colorbar;
xlabel('x (cm)'); ylabel('y (cm)'); title('真实相位');

subplot(2,3,5);
imagesc(x*100, y*100, phase_hard); axis equal tight; colorbar;
xlabel('x (cm)'); ylabel('y (cm)'); title('硬截止重建相位');

subplot(2,3,6);
imagesc(x*100, y*100, phase_smooth); axis equal tight; colorbar;
xlabel('x (cm)'); ylabel('y (cm)'); title('保留倏逝波重建相位');

% 显示倏逝波窗函数
figure;
imagesc(fx*k, fy*k, win); axis equal tight; colorbar;
xlabel('k_x / k'); ylabel('k_y / k');
title('倏逝波平滑窗 (1 对应传播波，>k 区域高斯衰减)');

% 定量误差对比
err_amp_hard = norm(abs(P_meas(:)) - amp_hard(:)) / norm(abs(P_meas(:)));
err_amp_smooth = norm(abs(P_meas(:)) - amp_smooth(:)) / norm(abs(P_meas(:)));
fprintf('硬截止方法：幅度相对误差 = %.4f\n', err_amp_hard);
fprintf('保留倏逝波 (平滑窗)：幅度相对误差 = %.4f\n', err_amp_smooth);

%% 6. 使用建议
% 1. 调节 alpha 参数：alpha 越小，保留的倏逝波越多，对噪声越敏感；
%    实测数据有噪声时需适当加大 alpha 或改用正则化方法。
% 2. 平滑窗不仅限于高斯型，也可使用余弦衰减、指数窗等。
% 3. 当 d_meas 很大时，倏逝波已自然衰减殆尽，保留它们无实际意义。