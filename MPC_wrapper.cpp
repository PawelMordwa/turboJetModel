
/*
 * Include Files
 *
 */
#if defined(MATLAB_MEX_FILE)
#include "tmwtypes.h"
#include "simstruc_types.h"
#else
#define SIMPLIFIED_RTWTYPES_COMPATIBILITY
#include "rtwtypes.h"
#undef SIMPLIFIED_RTWTYPES_COMPATIBILITY
#endif



/* %%%-SFUNWIZ_wrapper_includes_Changes_BEGIN --- EDIT HERE TO _END */
#include <math.h>
#include <Eigen/Dense>
#include "ModelPredictiveController.cpp"

using namespace Eigen;
using namespace std;

// --- ZMIENNE GLOBALNE I STA£E ---
// Musz¹ byæ tutaj, ¿eby widzia³y je funkcja Start ORAZ Output

static ModelPredictiveController* mpc = nullptr;

// Parametry modelu i regulatora
const double Ac_val = -0.4137;
const double Bc_val = 42748;
const double Cc_val = 1.0;

const unsigned int f_horizon = 50;
const unsigned int v_horizon = 20;
const double sampling_time = 0.01; 

const double weight_Q = 10.0;
const double weight_R = 0.0001;
/* %%%-SFUNWIZ_wrapper_includes_Changes_END --- EDIT HERE TO _BEGIN */
#define u_width 1
#define u_1_width 1
#define y_width 1

/*
 * Create external references here.  
 *
 */
/* %%%-SFUNWIZ_wrapper_externs_Changes_BEGIN --- EDIT HERE TO _END */
/* extern double func(double a); */
/* %%%-SFUNWIZ_wrapper_externs_Changes_END --- EDIT HERE TO _BEGIN */

/*
 * Start function
 *
 */
void MPC_Start_wrapper(void)
{
/* %%%-SFUNWIZ_wrapper_Start_Changes_BEGIN --- EDIT HERE TO _END */
if (mpc == nullptr) {
    // 1. Definicja macierzy ci¹g³ych
    MatrixXd Ac(1,1); Ac << Ac_val;
    MatrixXd Bc(1,1); Bc << Bc_val;
    MatrixXd Cc(1,1); Cc << Cc_val;
    MatrixXd x0(1,1); x0 << 0; 

    unsigned int n = 1; unsigned int m = 1; unsigned int r = 1;

    // 2. Dyskretyzacja
    MatrixXd In = MatrixXd::Identity(n,n);
    MatrixXd A = (In - sampling_time * Ac).inverse();
    MatrixXd B = A * sampling_time * Bc;
    MatrixXd C = Cc;

    // 3. Wagi
    MatrixXd W3 = MatrixXd::Identity(v_horizon * m, v_horizon * m) * weight_R;
    MatrixXd W4 = MatrixXd::Identity(f_horizon * r, f_horizon * r) * weight_Q;

    // 4. Utworzenie instancji
    mpc = new ModelPredictiveController(A, B, C, f_horizon, v_horizon, W3, W4, x0);
}
/* %%%-SFUNWIZ_wrapper_Start_Changes_END --- EDIT HERE TO _BEGIN */
}
/*
 * Output function
 *
 */
void MPC_Outputs_wrapper(const real_T *x_meas,
			const real_T *ref_setpoint,
			real_T *u_fuel)
{
/* %%%-SFUNWIZ_wrapper_Outputs_Changes_BEGIN --- EDIT HERE TO _END */
if (mpc != nullptr) {
    
    // Pobierz wartoœci z wejœæ (traktujemy je jako tablice 1-elementowe)
    double measured_RPM = x_meas[0];
    double target_RPM   = ref_setpoint[0];

    // Przeka¿ stan do MPC
    MatrixXd current_x(1,1);
    current_x(0,0) = measured_RPM;
    mpc->updateState(current_x);

    // Przeka¿ cel do MPC
    mpc->updateSetpoint(target_RPM);

    // Oblicz sterowanie
    mpc->computeControlInputs();

    // Wyœlij wynik na wyjœcie
    MatrixXd u_result = mpc->getNextInput();
    u_fuel[0] = u_result(0,0);
}
/* %%%-SFUNWIZ_wrapper_Outputs_Changes_END --- EDIT HERE TO _BEGIN */
}

/*
 * Terminate function
 *
 */
void MPC_Terminate_wrapper(void)
{
/* %%%-SFUNWIZ_wrapper_Terminate_Changes_BEGIN --- EDIT HERE TO _END */
if (mpc != nullptr) {
    delete mpc;
    mpc = nullptr;
}
/* %%%-SFUNWIZ_wrapper_Terminate_Changes_END --- EDIT HERE TO _BEGIN */
}

