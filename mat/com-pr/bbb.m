%读取 x = 0.7 处 zy 平面数据
clear; close all; clc;
model = mphload('dxsf.mph');
N = 128;
y_vals = linspace(-1, 1, N);
z_vals = linspace(-1, 1, N);
[Y, Z] = meshgrid(y_vals, z_vals);
% 坐标：x 固定为 0.7，y 和 z 来自网格
coords = [0.7 * ones(1, numel(Y)); Y(:)'; Z(:)'];
% 一次性插值
p_all = mphinterp(model, 'comp1.acpr.p_t', 'coord', coords);
% 重塑为 N×N 矩阵
s21 = reshape(p_all, N, N);
p_meas = s21;
save('my_measured_pressure.mat', 'p_meas');