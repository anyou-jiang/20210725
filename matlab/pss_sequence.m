function [d] = pss_sequence(N_ID_2)

x = zeros(127, 1);
x(1 : 7) = [0, 1, 1, 0, 1, 1, 1];
for i = 8 : 127
    x(i) = mod(x(i-3) + x(i-7), 2);
end

d = zeros(127, 1);
for n = 0 : 126
    m = mod(n + 43 * N_ID_2, 127);
    d(n+1) = 1 - 2 * x(m+1);
end