clear all
clc
clf
%% INITIALIZATION 
%BASIC PARAMETERS 
imax = 21; 
xmin = 0; 
xmax = 1.; 
dx = (xmax-xmin)/(imax-1); 
epsilon = 0.5*dx;

global rho_vector
global p_vector
global velocity_vector
global dtnew


%SET UP VECTORS

x = xmin:dx:xmax;
x0 = find(x==0.2);

u = zeros(1,imax);

%SET UP STATE VECTORS
USTATE = zeros(3,imax);
USTATE_UPDATE = zeros(3,imax);

%SET UP MATRICES 

lamda_plus_i_plus = zeros(3,3);
lamda_minus_i_plus = zeros(3,3);
Ca_i_plus = zeros(3,3);
Ca_inverse_plus = zeros(3,3);
S_i_plus = zeros(3,3);
S_inverse_plus = zeros(3,3);
FPLUS = zeros(3,imax);
xplus = zeros(3,3);
xplusinv = zeros(3,3);
xminus= zeros(3,3);
xminusinv= zeros(3,3);
% FPLUS = zeros(3,3);


lamda_plus_i_minus = zeros(3,3);
lamda_minus_i_minus = zeros(3,3);
Ca_i_minus = zeros(3,3);
Ca_inverse_minus = zeros(3,3);
S_i_minus = zeros(3,3);
S_inverse_minus = zeros(3,3);
FMINUS = zeros(3,imax);
% FMINUS = zeros(3,3);


Abarplus_plus= zeros(3,3);
Abarminus_plus= zeros(3,3);

Abarplus_minus= zeros(3,3);
Abarminus_minus= zeros(3,3);




timestep = 1;






%% DECLARE PHI 



phi = zeros(1,imax);
phi2 = 1.0;
phi1 = 0.0;
% 
% for i = 1:imax
%    if (x(i)>=0.2)
%        phi(i) = 1.0;
%    elseif (x(i)<0.2)
%        phi(i) = 0.0;
%    end
%     
% end

phi = 0.5*(1+tanh((x-0.5)./(2*epsilon)));



phi_next = zeros(1,imax);

% phi_initial  = phi;

phi_initial = 1.0;
phi = ones(1,imax);









%% CALCULATING GAMMA USING Chaklas Eq 19b 

gamma2 = 1.4;
gamma1 = 1.4;


gamma_at_i = zeros(1,imax);

for i = 1:imax
    temp = (phi(i)./(gamma1-1)) + ((1-phi(i))./(gamma2-1));
%     gamma_at_i(i) = 1 + 1./temp;
    gamma_at_i(i) = 1.4;
end




%% Chaklas Eq 19c





p1_infty = 0;
p2_infty = 6000;

% p_infty = ((gamma_at_i-1)./(gamma_at_i)).*(((phi.*gamma1*p1_infty)./(gamma1-1))  + ...
% (((1-phi).*(gamma2*p2_infty))/(gamma2-1)));

p_infty = zeros(1,imax);

gamma_initial = gamma_at_i;


%% INITIAL CONDITION
% RHO- 1st state
USTATE(1,1:x0) = 10.;
USTATE(1,x0:imax) = 1.;


%U 

VELOCITY = zeros(1,imax);

VELOCITY(1:x0) = 81.25;
VELOCITY(x0:imax)=0;


%RHO U - 2nd state

USTATE(2,1:x0) = 0.0;
USTATE(2,x0:imax) = 0.0;


% FOR E- 3rd state 
USTATE(3,1:x0) = 10./(gamma_at_i(1:x0)-1);
USTATE(3,x0:imax) = 1./(gamma_at_i(x0:imax)-1);

USTATE_UPDATE = USTATE; 





%INTERNAL E

E_INTERNAL = zeros(1,imax);

E_INTERNAL(1:x0) = (USTATE(3,1:x0)./USTATE(1,1:x0))-0.5*81.25^2;
E_INTERNAL(x0:imax) = (USTATE(3,x0:imax)./USTATE(1,x0:imax))-0.5*0.0^2;

%PRESURE (using Chaklas Eq 19a)

PRESSSURE_INITIAL(1:x0) = ((gamma_at_i(1:x0)-1).*USTATE(1,1:x0).*E_INTERNAL(1:x0))  - ...
(gamma_at_i(1:x0).*p_infty(1:x0));
PRESSSURE_INITIAL(x0:imax) = ((gamma_at_i(x0:imax)-1).*USTATE(1,x0:imax).*E_INTERNAL(x0:imax)) - ...
(gamma_at_i(x0:imax).*p_infty(x0:imax));



PRESSURE = zeros(1,imax);


RHO_INITIAL = USTATE(1,:);




VELOCITY_INITIAL = USTATE(2,:)./USTATE(1,:);





%% MAIN LOOP
for timestep = 1: 5
    
    disp(timestep);
    
    
    %% PART 1: CALCULATE DT 
 
  
  for i = 1:imax
     u_at_i = USTATE_UPDATE(2,:)./USTATE_UPDATE(1,:); %%rho u by rho 
     rho_at_i = USTATE_UPDATE(1,:);
     E_at_i = USTATE_UPDATE(3,:);
     E_internal_at_i = (E_at_i./rho_at_i)-(0.5*u_at_i.^2);
     p_at_i = (gamma_at_i-1).*(rho_at_i.*E_internal_at_i)-(gamma_at_i).*p_infty(i);
     a_at_i = sqrt(gamma_at_i(i)*p_at_i./rho_at_i);
     abs_u_plus_a_at_i= abs(u_at_i+a_at_i);
     dt_at_i = dx./abs_u_plus_a_at_i;%this is an array of dt at i
     dt_smallest = min(dt_at_i); %smallest dt in dt array at i
     CFL = 0.4;
     real_dt = CFL*dt_smallest;
     
    
    
  end
  
  dt = real_dt;
  
   %% PART 2: DEAL WITH U PLUS HALF
   for i = 2:imax-1
    USTATE_PLUS(:,:) = 0.5*(USTATE(:,i)+USTATE(:,i+1));
        
    rho_plus = USTATE_PLUS(1,:);   
   

   
    u_plus = USTATE_PLUS(2,:)./USTATE_PLUS(1,:);
    
    
    E_plus = USTATE_PLUS(3,:);
    
    
    E_internal_plus = (E_plus/rho_plus)-(0.5*u_plus^2);
    
    
    p_plus = (gamma_at_i(i)-1).*rho_plus.*E_internal_plus-(gamma_at_i(i).*p_infty(i));
    
    
  
    sum_plus = p_plus+p_infty(i);
    
 
    sum_plus = abs(sum_plus);
    
    a_plus = sqrt(gamma_at_i(i).*(sum_plus)./rho_plus);
    
   
    
    %FORM LAMBDA PLUS AND MINUS FOR I PLUS HALF 
    lamda1plus = u_plus;
    lamda2plus = u_plus+a_plus;
    lamda3plus = u_plus-a_plus;
    
    lamda1plus_plus = 0.5*(lamda1plus+abs(lamda1plus));
    lamda2plus_plus = 0.5*(lamda2plus+abs(lamda2plus));
    lamda3plus_plus = 0.5*(lamda3plus+abs(lamda3plus));
    
    lamda1minus_plus = 0.5*(lamda1plus-abs(lamda1plus));
    lamda2minus_plus = 0.5*(lamda2plus-abs(lamda2plus));
    lamda3minus_plus = 0.5*(lamda3plus-abs(lamda3plus));
    
    %LAMDA PLUS FOR I PLUS HALF 
    lamda_plus_i_plus(1,1) = lamda1plus_plus;
    lamda_plus_i_plus(2,2) = lamda2plus_plus;
    lamda_plus_i_plus(3,3) = lamda3plus_plus;

    
    %LAMDA PLUS FOR I MINUS HALF 
    lamda_minus_i_plus(1,1) = lamda1minus_plus;
    lamda_minus_i_plus(2,2) = lamda2minus_plus;
    lamda_minus_i_plus(3,3) = lamda3minus_plus;
    
    
    
    %FORMING Ca, S for I PLUS HALF 
    %Form Ca plus
    Ca_i_plus(1,1) = 1.0;
    Ca_i_plus(1,2) = 0.0;
    
    Ca_i_plus(1,3) = -1./(a_plus.^2);
    Ca_i_plus(2,1) = 0.0;
    Ca_i_plus(2,2) = rho_plus.*a_plus;
    Ca_i_plus(2,3) = 1.0;
    
    Ca_i_plus(3,1) = 0.0;
    Ca_i_plus(3,2) = -rho_plus.*a_plus;
    Ca_i_plus(3,3) = 1.0;
    
    
      
    %Form S plus     
    beta = gamma_at_i(i)-1;
    alpha_plus = (u_plus.^2)./2;
    S_i_plus(1,1) = 1.0;
    S_i_plus(1,2) = 0.0;
    S_i_plus(1,3) = 0.0;
    S_i_plus(2,1) = -u_plus./rho_plus;
    S_i_plus(2,2) = 1.0./rho_plus;
    S_i_plus(2,3) = 0.0;
    S_i_plus(3,1) = alpha_plus.*beta;
    S_i_plus(3,2) = -u_plus.*beta;
    S_i_plus(3,3) = beta;
    
    
    %Form Ca inverse plus 
    
    Ca_inverse_plus(1,1) = 1.0;
    Ca_inverse_plus(1,2) = 1.0./(2.*a_plus.^2);
    Ca_inverse_plus(1,3) = 1.0./(2.*a_plus.^2);
    
    Ca_inverse_plus(2,1) = 0.0;
    
    Ca_inverse_plus(2,2) = 1.0./(2.*rho_plus.*a_plus);
    Ca_inverse_plus(2,3) = -1.0./(2.*rho_plus.*a_plus);
    
    Ca_inverse_plus(3,1) = 0.0;
    Ca_inverse_plus(3,2) = 0.5;
    Ca_inverse_plus(3,3) = 0.5;


    
    %Form S inverse plus 
    
    
    S_inverse_plus(1,1) = 1.0;
    S_inverse_plus(1,2) = 0.0;
    S_inverse_plus(1,3) = 0.0;
    S_inverse_plus(2,1) = u_plus;
    S_inverse_plus(2,2) = rho_plus;
    S_inverse_plus(2,3) = 0.0;
    S_inverse_plus(3,1) = alpha_plus;
    S_inverse_plus(3,2) = rho_plus.*u_plus;
    S_inverse_plus(3,3) = 1.0./beta;
    
   
  
   
    Abarplus_plus(:,:) = S_inverse_plus(:,:)*Ca_inverse_plus(:,:)*lamda_plus_i_plus(:,:)*Ca_i_plus(:,:)*S_i_plus(:,:);

    Abarminus_plus(:,:) = S_inverse_plus(:,:)*Ca_inverse_plus(:,:)*lamda_minus_i_plus(:,:)*Ca_i_plus(:,:)*S_i_plus(:,:);

    
    FPLUS(:,i) = Abarplus_plus(:,:)*USTATE(:,i)+Abarminus_plus(:,:)*USTATE(:,i+1);

   
    
    
    
    
    %% PART 3: DEAL WITH U MINUS HALF
    
    
    USTATE_MINUS(:,:) = 0.5*(USTATE(:,i)+USTATE(:,i-1));
    
    %PULL RHO, P, AT MINUS HALF
    
    rho_minus = USTATE_MINUS(1,:);
    u_minus = USTATE_MINUS(2,:)./USTATE_MINUS(1,:);
    p_minus = (USTATE_MINUS(3,:).*(gamma_at_i(i)-1)) - (0.5)*(gamma_at_i(i)-1)*rho_minus.*u_minus.^2;    
    E_minus = USTATE_MINUS(3,:);
    
    E_internal_minus = (E_minus/rho_minus)-(0.5*u_minus^2);
    
    p_minus = (gamma_at_i(i)-1).*rho_minus.*u_minus-(gamma_at_i(i).*p_infty(i));
    sum_minus = p_minus+p_infty(i);
    sum_minus = abs(sum_minus);
    a_minus = sqrt(gamma_at_i(i).*(sum_minus)./rho_minus);

    
    %FORM LAMBDA PLUS AND MINUS FOR I MINUS HALF 
    lamda1minus = u_minus;
    lamda2minus = u_minus+a_minus;
    lamda3minus = u_minus-a_minus;
    
    lamda1plus_minus = 0.5*(lamda1minus+abs(lamda1minus));
    lamda2plus_minus = 0.5*(lamda2minus+abs(lamda2minus));
    lamda3plus_minus = 0.5*(lamda3minus+abs(lamda3minus));
    
    lamda1minus_minus = 0.5*(lamda1minus-abs(lamda1minus));
    lamda2minus_minus = 0.5*(lamda2minus-abs(lamda2minus));
    lamda3minus_minus = 0.5*(lamda3minus-abs(lamda3minus));
    
    %LAMDA PLUS FOR I MINUS HALF 
    lamda_plus_i_minus(1,1) = lamda1plus_minus;
    lamda_plus_i_minus(2,2) = lamda2plus_minus;
    lamda_plus_i_minus(3,3) = lamda3plus_minus;
    
    %LAMDA MINUS FOR I MINUS HALF 
    lamda_minus_i_minus(1,1) = lamda1minus_minus;
    lamda_minus_i_minus(2,2) = lamda2minus_minus;
    lamda_minus_i_minus(3,3) = lamda3minus_minus;
    
    
    
    %FORMING Ca, S for I MINUS HALF 
    %Form Ca minus
    Ca_i_minus(1,1) = 1.0;
    Ca_i_minus(1,3) = -1./(a_minus.^2);
    Ca_i_minus(2,2) = rho_minus.*a_minus;
    Ca_i_minus(2,3) = 1.0;
    Ca_i_minus(3,2) = -rho_minus.*a_minus;
    Ca_i_minus(3,3) = 1.0;
    %Form S minus     
    beta = gamma_at_i(i)-1;
    alpha_minus = (u_minus.^2)./2;
    S_i_minus(1,1) = 1.0;
    S_i_minus(2,1) = -u_minus./rho_minus;
    S_i_minus(2,2) = 1.0./rho_minus;
    S_i_minus(3,1) = alpha_minus.*beta;
    S_i_minus(3,2) = -u_minus.*beta;
    S_i_minus(3,3) = beta;
    
    
    
    %Form Ca inverse minus 
    
    Ca_inverse_minus(1,1) = 1.0;
    Ca_inverse_minus(1,2) = 1.0./(2.*a_minus.^2);
    Ca_inverse_minus(1,3) = 1.0./(2.*a_minus.^2);
    Ca_inverse_minus(2,2) = 1.0./(2.*rho_minus.*a_minus);
    Ca_inverse_minus(2,3) = -1.0./(2.*rho_minus.*a_minus);
    Ca_inverse_minus(3,2) = 0.5;
    Ca_inverse_minus(3,3) = 0.5;
    
    %Form S inverse minus 
    
    
    S_inverse_minus(1,1) = 1.0;
    S_inverse_minus(2,1) = u_minus;
    S_inverse_minus(2,2) = rho_minus;
    S_inverse_minus(3,1) = alpha_minus;
    S_inverse_minus(3,2) = rho_minus.*u_minus;
    S_inverse_minus(3,3) = 1.0./beta;    
    
    
    
    Abarplus_minus(:,:) = S_inverse_minus(:,:)*Ca_inverse_minus(:,:)*lamda_plus_i_minus(:,:)*Ca_i_minus(:,:)*S_i_minus(:,:);

    Abarminus_minus(:,:) = S_inverse_minus(:,:)*Ca_inverse_minus(:,:)*lamda_minus_i_minus(:,:)*Ca_i_minus(:,:)*S_i_minus(:,:);
    
    FMINUS(:,i) = Abarplus_minus(:,:)*USTATE(:,i-1)+Abarminus_minus(:,:)*USTATE(:,i);
    
   end
    
    
    % PART 4: FINITE DIFFERENCE EQUATION
    
    for i = 2:imax-1    
        USTATE_UPDATE(:,i) = USTATE(:,i) - (dt/dx)*(FPLUS(:,i)-FMINUS(:,i)); 
             
    end
   
  
  
  %% SET BC AND PLOT VARIABLES FOR NUMERICAL 

  
  USTATE_UPDATE(:,imax) = USTATE_UPDATE(:,imax-1);
  USTATE = USTATE_UPDATE; 
  E = USTATE(3,:);
  RHO = USTATE(1,:);
  
  VELOCITY = USTATE(2,:)./RHO;
  E_INTERNAL = (E./RHO)-(0.5*VELOCITY.^2);




 %% CALCULATE PRESSURE

PRESSURE = ((gamma_at_i-1).*RHO.*E_INTERNAL)-(gamma_at_i).*p_infty;
 



    
  % PART 5: ANALYTICAL PART  (call analytical, use updated dt);
  
  for i = 1:imax
    max_ANALYTICAL_shock_tube(dt,gamma_at_i(i));
  end
  
  
  
  % PART 6: CALCULATE PHI
     
    phi_next = phi;
    
    %Loop and find Uminus, Uplus in the VELOCITY
    
%     for i = 2:imax-2
%         uplusDCU = max(0,VELOCITY(1,:));
%         uminusDCU = min(0,VELOCITY(1,:));
%     
%         %the finite difference expressions
%         forward_diffX_PHI = phi(i+1)-phi(i);
%         backward_diffX_PHI = phi(i)-phi(i-1);
% 
%         
%         %main equation            
%         phi_next(i)= phi(i)-(dt/dx)*(uplusDCU(i)*backward_diffX_PHI+uminusDCU(i)*...
%         forward_diffX_PHI); 
%                
%    
%     end
%     
%     
%     phi = phi_next;
%  
 

    
    % PART 7: RE CALCULATE GAMMA AT I 
    
     
%     for i = 1:imax
%         temp = (phi(i)./(gamma1-1)) + ((1-phi(i))./(gamma2-1));
% %         gamma_at_i(i) = 1 + 1./temp;
%     gamma_at_i(i) = 1.4;
%     end


    % PART 8: UPDATE P_infty 
    
%     p_infty = ((gamma_at_i-1)./(gamma_at_i)).*(((phi.*gamma1*p1_infty)./(gamma1-1))  + ...
% (((1-phi).*(gamma2*p2_infty))/(gamma2-1)));
  
                        


    
 
    timestep = timestep + dt;
    
    
    
end 


figure(1)
subplot(2,3,1)
% plot(x,PRESSSURE_INITIAL,'-xr')
hold on
plot(x,PRESSURE,'-ob');
title('PRESSURE')


subplot(2,3,2)
plot(x,RHO_INITIAL,'-xr')
hold on
plot(x,RHO,'-ob');
title('RHO')


subplot(2,3,3)
plot(x,VELOCITY_INITIAL,'-xr')
hold on
plot(x,VELOCITY,'-ob');
title('VELOCITY')


subplot(2,3,4)
plot(x,phi_initial,'-xr')
hold on
plot(x,phi,'-ob');
title('PHI')


subplot(2,3,5)
plot(x,gamma_initial,'-xr')
hold on
plot(x,gamma_at_i,'-ob');
title('GAMMA')





 