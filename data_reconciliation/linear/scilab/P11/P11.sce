// Data Reconciliation Benchmark Problems From Lietrature Review
// Author: Edson Cordeiro do Valle
// Contact - edsoncv@{gmail.com}{vrtech.com.br}
// Skype: edson.cv

//Rao, R Ramesh, and Shankar Narasimhan. 1996.
//“Comparison of Techniques for Data Reconciliation of Multicomponent Processes.” 
//Industrial & Engineering Chemistry Research 35:1362-1368. 
//http://dx.doi.org/10.1021/ie940538b.
//Bibtex Citation

//@article{Rao1996,
//author = {Rao, R Ramesh and Narasimhan, Shankar},
//isbn = {0888-5885},
//journal = {Industrial \& Engineering Chemistry Research},
//month = apr,
//number = {4},
//pages = {1362--1368},
//publisher = {American Chemical Society},
//title = {{Comparison of Techniques for Data Reconciliation of Multicomponent Processes}},
//url = {http://dx.doi.org/10.1021/ie940538b},
//volume = {35},
//year = {1996}
//}

// 12 Streams
// 7 Equipments 

clear xm var jac nc nv i1 i2 nnzeros sparse_dg sparse_dh lower upper var_lin_type constr_lin_type constr_lhs constr_rhs
getd('../functions');
// In the original paper, all streams for this problem are unmeasures, 
//theses values are estimates givem by the paper's original author.
xm =[691.67
727.54
699.36
687.15
35.87
12.51
27.88
23.36
22.67
4.79
4.52
9.31
];
//the variance proposed by the original author
//var = (0.0001*ones(12,1)).^2;
//the variance proposed by this work 
var = (0.03*xm).^2;

// gross error
gerror = zeros(length(xm),1);
// to setup gross errors, select the stream and magnitude as the line bellow
//gerror(2) = 9*sqrt(var(2));
xm = xm + gerror;

//The jacobian of the constraints
//      1   2   3   4   5   6   7   8    9   10  11  12
jac = [ 1   -1  0   0   1   0   0   0    0   0   0   0 
        0   1   -1  0   0   0   -1  0    0   0   0   0 
        0   0   1   -1  0   -1  0   0    0   0   0   0 
        0   0   0   0   -1  1   0   1    0   0   0   0 
        0   0   0   0   0   0   0   -1   1   0   0  -1  
        0   0   0   0   0   0   1   0    -1  1   0   0
        0   0   0   0   0   0   0   0    0   -1  -1  1 ];                                
//      1   2   3   4   5   6   7   8    9   10  11  12

//observability/redundancy tests                  
umeas_P11 = [];
[red_P11, just_measured_P11, observ_P11, non_obs_P11, spec_cand_P11] = qrlinclass(jac,umeas_P11)

// reconcile with all measured. To reconcile with only redundant variables, uncomment the "red" assignments
measured_P11 = setdiff([1:length(xm)], umeas_P11);
red = measured_P11;//
// to reconcile with all variables, comment the line above and uncomment bellow
//red = [1:length(xm)];

// to run robust reconciliation,, one must choose between the folowing objective functions to set up the functions path and function parameters:
//WLS = 0
// Absolute sum of squares = 1
//Cauchy = 2
//Contamined Normal = 3
//Fair  = 4
//Hampel = 5
//Logistic = 6
//Lorenztian = 7
//Quasi Weighted = 8
// run the configuration functions with the desired objective function type
obj_function_type = 0;
exec ../functions/setup_DR.sce
// to run robust reconciliation, it is also necessary to choose the function to return the problem structure
if obj_function_type > 0 then
[nc_eq, n_non_lin_eq, nv, nnzjac_ineq, nnzjac_eq, nnz_hess, sparse_dg, sparse_dh, lower, upper, var_lin_type, constr_lin_type, constr_lhs, constr_rhs]  = robust_structure(jac, 0, xm, objfun, res_eq, res_ineq);
else
// for WLS, only the line bellow must be choosen and comment the 3 lines above
[nc, nv, i1, i2, nnzeros, sparse_dg, sparse_dh, lower, upper, var_lin_type, constr_lin_type, constr_lhs, constr_rhs]  = wls_structure(jac);
end


params = init_param();
// We use the given Hessian
params = add_param(params,"hessian_approximation","exact");
params = add_param(params,"derivative_test","second-order");
params = add_param(params,"tol",1e-8);
params = add_param(params,"acceptable_tol",1e-8);
params = add_param(params,"mu_strategy","adaptive");
params = add_param(params,"journal_level",5);

[x_sol, f_sol, extra] = ipopt(xm, objfun, gradf, confun, dg, sparse_dg, dh, sparse_dh, var_lin_type, constr_lin_type, constr_rhs, constr_lhs, lower, upper, params);

//Q = 2*hessf ( xm );
//p=-4*(xm./var)';
//C=jac;
//me=nc;
//b=zeros(nc,1);
//ci=lower;
//cs=upper;
//
//[x,iact,iter,f_sol]=qpsolve(Q,p,C,b,ci,cs,me)
//[x_solqp,lagr,info]=qld(Q,p,C,b,ci,cs,me, 1.0e-8)
//status = info;
//x_sol = x';
//f_sol=0;

mprintf("\n\nSolution: , x\n");
for i = 1 : nv
    mprintf("x[%d] = %e\n", i, x_sol(i));
end

mprintf("\n\nObjective value at optimal point\n");
mprintf("f(x*) = %e\n", f_sol);

