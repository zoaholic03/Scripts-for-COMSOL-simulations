clear; close all; clc;
model = mphload('fyf.mph');
N = 128;
x_vals = linspace(0, 2, N);
z_vals = linspace(0, 2, N);
[X, Z] = meshgrid(x_vals, z_vals);
% 将网格坐标展开为 3×M 矩阵，y坐标固定为 0
coords = [X(:)'; zeros(1, numel(X)); Z(:)'];
% 一次性插值
p_all = mphinterp(model, 'comp1.acpr.p_t', 'coord', coords);
% 重塑为 N×N 矩阵
s21 = reshape(p_all, N, N);
p_meas = s21;
save('my_measured_pressure.mat', 'p_meas');