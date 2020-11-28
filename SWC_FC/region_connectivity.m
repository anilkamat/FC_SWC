function [connectivity]  = region_connectivity(M)
a = [1 9 17 18 19 22];
aa = [8 16 17 18 21 24];
R = zeros(6);
for k = 1:6
    for m = (k+1):6
        R(m,k) =  mean(mean(M(a(m):aa(m),a(k):aa(k))));
    end
end
connectivity = R; 
end
