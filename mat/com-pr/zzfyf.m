%% 角谱反演法：从测量平面复声压重建源平面幅值与相位
% 输入：测量平面复声压 p_meas (已知，可以是实测或仿真数据)
% 输出：源平面声压幅度 abs(p_src) 和相位 angle(p_src)
% 适合单频、均匀介质、平行平面间的声场反演.

clear; close all; clc;

%% 1. 基本参数
c = 343;                % 声速 (m/s)
f = 3430;               % 频率 (Hz)
lambda = c / f;         % 波长 (m)
k = 2*pi / lambda;      % 波数

% 空间采样（需匹配你的测量网格）
Lx = 2;               % x方向物理尺寸 (m)
Ly = 2;               % y方向物理尺寸 (m)
Nx = 128;               % x方向点数 (建议2的幂)
Ny = 128;               % y方向点数
dx = Lx / Nx;           % 采样间隔 (m)
dy = Ly / Ny;

% 传播距离：从测量平面到源平面的距离（正值表示测量平面在源前方）
d_meas = 0.7;           % 测量平面位置 z = d_meas, 源平面在 z = 0

% 空间频率轴
fx = (-Nx/2 : Nx/2-1) / Lx;  % 1/m
fy = (-Ny/2 : Ny/2-1) / Ly;
[Fx, Fy] = meshgrid(fx, fy);
kx = 2*pi * Fx;
ky = 2*pi * Fy;

%% 2. 准备测量平面复声压 p_meas
% 这里用仿真数据演示：首先生成一个点源，正向传播到测量平面，并添加噪声
x = (-Nx/2 : Nx/2-1) * dx;
y = (-Ny/2 : Ny/2-1) * dy;
[X, Y] = meshgrid(x, y);

% 假想的源平面真实声压（用于生成测量数据，实际应用中你不会知道这个）
xs = 0.02; ys = 0.01;          % 点源位置
sigma_s = 0.005;               % 高斯宽度（近似点源）
p_src_true = exp(-((X-xs).^2 + (Y-ys).^2) / (2*sigma_s^2));

% 正向角谱传播得到测量平面理想复声压
%P_src_true = fftshift(fft2(fftshift(p_src_true)));
kz = sqrt(k^2 - kx.^2 - ky.^2);
kz = real(kz) + 1j*abs(imag(kz));  % 确保正向传播时倏逝波衰减
%G_forward = exp(1j * kz * d_meas);
%p_meas_ideal = ifftshift(ifft2(ifftshift(P_src_true .* G_forward)));

% 添加复高斯噪声模拟实际测量
SNR_dB = 100;                     % 信噪比 (dB)
%noise_power = mean(abs(p_meas_ideal(:)).^2) / (10^(SNR_dB/10));
%noise = sqrt(noise_power/2) * (randn(size(p_meas_ideal)) + 1j*randn(size(p_meas_ideal)));
%p_meas = p_meas_ideal + noise;   % 这就是模拟的"测量平面复声压”

% 如果你的实际数据已存在，直接载入：
load('my_measured_pressure.mat');  % 包含变量 p_meas, dx, dy, d_meas 等
% 确保 p_meas 是复矩阵，大小为 Ny × Nx

%% 3. 角谱反演 —— 核心算法
% 测量平面角谱
P_meas = fftshift(fft2(fftshift(p_meas)));

% 反向传播因子（注意符号：exp(-1j*kz*d)）
G_back = exp(-1j * kz * d_meas);

% 【关键】倏逝波与噪声滤波：直接乘以 G_back 会放大高频噪声和倏逝波。
% 这里采用一种简单的 Tikhonov 正则化（维纳滤波思想）：
%   滤波器 H = conj(G_back) ./ (abs(G_back).^2 + alpha * max(abs(G_back(:)))^2);
%   其中 alpha 是正则化参数。
%   结合倏逝波硬截止：只对传播波区域进行反演。
mask = (kx.^2 + ky.^2) <= k^2;   % 传播波区域

% 正则化参数（根据噪声水平调整，信噪比越低 alpha 越大）
alpha = 10^(-SNR_dB/20);         % 经验关系，可手动调节

% 构建正则化反传播核
G_inv = conj(G_back) ./ (abs(G_back).^2 + alpha * max(abs(G_back(:)))^2);
G_inv = G_inv .* mask;           % 滤除倏逝波

% 估计源平面角谱
P_src_est = P_meas .* G_inv;

% 逆变换得到源平面声压
p_src_est = ifftshift(ifft2(ifftshift(P_src_est)));

%% 4. 提取源平面幅值与相位
amp_src = abs(p_src_est);
phase_src = angle(p_src_est);   % 范围 [-pi, pi]

% 如果需要解包裹相位，可使用 unwrap
% phase_unwrapped = unwrap(phase_src, [], 1); % 按行或按列解裹，需谨慎

%% 5. 结果可视化
figure('Name', '角谱反演结果', 'Position', [50 50 1200 500]);

subplot(1,3,1);
imagesc(x*100, y*100, abs(p_meas));
axis equal tight; colorbar;
xlabel('x (cm)'); ylabel('y (cm)');
title('测量平面 |p_{meas}|');

subplot(1,3,2);
imagesc(x*100, y*100, amp_src);
axis equal tight; colorbar;
xlabel('x (cm)'); ylabel('y (cm)');
title('重建源平面 |p_{src}|');

subplot(1,3,3);
imagesc(x*100, y*100, phase_src);
axis equal tight; colorbar;
xlabel('x (cm)'); ylabel('y (cm)');
title('重建源平面相位 (rad)');

% 如有必要，显示相位对比
figure;
subplot(1,2,1);
imagesc(x*100, y*100, angle(p_src_true)); colorbar; title('真实相位');
subplot(1,2,2);
imagesc(x*100, y*100, phase_src); colorbar; title('重建相位');

%% 6. 误差评估（仿真时可用）
if exist('p_src_true', 'var')
    err_amp = norm(abs(p_src_true(:)) - amp_src(:)) / norm(abs(p_src_true(:)));
    err_phase = norm(angle(p_src_true(:)) - phase_src(:)) / norm(angle(p_src_true(:)));
    fprintf('幅度相对误差 = %.4f\n', err_amp);
    fprintf('相位相对误差 = %.4f\n', err_phase);
end

%% 注意事项与改进
% 1. 实际测量中的 p_meas 应为复数，包含幅度和相位信息。若只有幅度，无法直接反演。
% 2. 空间采样必须满足 Nyquist: dx, dy <= lambda/2，否则会产生混叠。
% 3. 正则化参数 alpha 需要根据噪声水平调节，或使用 L-curve、GCV 等方法自动选取。
% 4. 如果测量平面与源平面不平行或存在倾斜，需先进行坐标变换。
% 5. 对于大角度声场，可考虑扩展为基于声强测量的宽带声全息 (BAHIM) 等高级方法。