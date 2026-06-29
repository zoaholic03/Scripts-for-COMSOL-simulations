clear
A=50e-6;
f_1=0.4714;
f_2=0.72727;
rho0=1000;
c0=1490;
f0=1.0e6;
w=2*pi*f0; 
lambda=c0/f0; 
k=2*pi/lambda;
% F=50*lambda;
% d=50*lambda;
% D=150*lambda;
F=15*lambda;
d=25*lambda;
D=50*lambda;
r0=d/2;
l=1;
n1=201;
% a=linspace(-2*d,2*d,n1);b=linspace(-2*d,2*d,n1);
a=linspace(-2*d,2*d,n1);b=linspace(-2*d,2*d,n1);
[x,y]=meshgrid(a,b); 
Fx=[d,d*cos(pi/3),d*cos(2*pi/3),d*cos(3*pi/3),d*cos(4*pi/3),d*cos(5*pi/3)];Fy=[0,d*sin(pi/3),d*sin(2*pi/3),d*sin(3*pi/3),d*sin(4*pi/3),d*sin(5*pi/3)];
L=length(Fx(:));
N=[1,1,1,1,1,1];

P1=zeros(n1,n1);
for i=1:2:5
    [theta,r]=cart2pol(x-Fx(i),y-Fy(i));
    for N1=1:1:4
        for m=1:1:n1
            for n=1:1:n1
                rr(m,n)=(r(m,n)).^2+F^2-(F+lambda+((2*N1*pi+theta(m,n))/2/pi-1)*lambda).^2;
                rrr(m,n)= (r(m,n)).^2+F^2-(F+3*lambda/2+((2*N1*pi+theta(m,n))/2/pi-1)*lambda).^2;
                if (rr(m,n)>= 0 && rrr(m,n)<= 0)
                    P1(m,n)=1;
                end
            end
       end
   end
end

for i=2:2:6
     g=0*pi;
     M1=[cos(g),sin(g);-sin(g),cos(g)];
     x1=cos(g)*x+sin(g)*y;
     y1=-sin(g)*x+cos(g)*y;
     Fx1(i)=cos(g)*Fx(i)+sin(g)*Fy(i);
     Fy1(i)=-sin(g)*Fx(i)+cos(g)*Fy(i);
    [theta,r]=cart2pol(x1-Fx1(i),y1-Fy1(i));
    for N1=1:1:4
        for m=1:1:n1
            for n=1:1:n1
                rr(m,n)=(r(m,n)).^2+F^2-(F+lambda+((2*N1*pi+theta(m,n))/2/pi-1)*lambda).^2;
                rrr(m,n)= (r(m,n)).^2+F^2-(F+3*lambda/2+((2*N1*pi+theta(m,n))/2/pi-1)*lambda)^2;
                if (rr(m,n)>= 0 && rrr(m,n)<= 0)
                    P1(m,n)=1;
                    
                end
            end
       end
   end
end

z=F+1*D;
C=linspace(-0.1*d,0.1*d,n1);D=linspace(-0.1*d,0.1*d,n1);
[X,Y]=meshgrid(C,D); 
P=0;
for i=1:1:n1
    for j=1:1:n1
        P=P+P1(i,j)*exp(-1i*k*((X-a(i)).^2+(Y-b(j)).^2+z^2).^0.5)./(((X-a(i)).^2+(Y-b(j)).^2+z^2).^0.5)/4/pi;
    end
end   

figure(1)
surf(y,x,abs(P1))
shading  interp;
view([-90,90])
hold on
figure(2)
surf(y,x,angle(P1))
shading  interp;
view([-90,90])


figure(3)
surf(X,Y,abs(P))
shading  interp;
view([-90,90])
hold on
figure(4)
surf(X,Y,angle(P))
shading  interp;
view([-90,90])
hold on


[VX,VY]=gradient((-1/(1i*rho0*w))*P,0.2*d/(n1-1),0.2*d/(n1-1));
V2=sqrt((abs(VX)).^2.+(abs(VY)).^2);
P2=abs(P);
U=pi*A^3*(2/3*f_1*(P2).^2/(rho0*c0^2)-rho0*f_2*(V2).^2);

figure(5)
quiver(X,Y,0.5*real(conj(P).*VX),0.5*real(conj(P).*VY),2)



P3(:,1) =X(:);
P3(:,2) =Y(:);
P3(:,3) =U(:);
xlswrite('E:\BANGONG\NJU\2022\4-6\vortex-talbot\a.xlsx',P3);  
% for i=1:1:160801
%     for j=1:1:3
%     E2(i,j)={num2str(P2(i,j))};
%     end
% end
 
% E2=cell(160801,3);