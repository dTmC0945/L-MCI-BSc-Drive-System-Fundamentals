// Geometrical data for inductor model

cm = 1e-2; // Unit

pp  = "Input/10Geometric dimensions/0";
pp2 = "Input/10Geometric dimensions/1Shell radius/";
ppm = "Input/11Mesh control (Nbr of divisions)/";

DefineConstant[
  Flag_3Dmodel = {0, Choices{0="2D",1="3D"},
    Name "Input/00FE model", Highlight "Blue"}
  Flag_boolean = {0, Choices{0,1},
    Name "Input/00OpenCASCADE model?", Visible Flag_3Dmodel, Highlight "Blue"}
  Flag_Symmetry2D = {1, Choices{0="Full",1="Half"},
    Name "Input/00Symmetry type", Highlight "Blue", Visible (Flag_3Dmodel==0)},
  Flag_Symmetry3D = {2, Choices{0="Full",1="Half",2="One fourth"},
    Name "Input/01Symmetry type", Highlight "Blue", Visible (Flag_3Dmodel==1)},
  Flag_OpenCore = {1, Choices{0,1}, ReadOnly Flag_boolean,
    Name "Input/02Core with air gap"},
  Flag_Infinity = {1, Choices{0,1},
    Name "Input/01Use shell transformation to infinity"}
];

Flag_Symmetry  = (Flag_3Dmodel==0) ? Flag_Symmetry2D : Flag_Symmetry3D;
SymmetryFactor = (Flag_Symmetry) ? 2*Flag_Symmetry:1;
Printf("====> SymmetryFactor=%g", SymmetryFactor);


close_menu = 1;
colorro  = "LightGrey";
colorpp = "Ivory";

DefineConstant[
  wcoreE = {3*cm,  Name StrCat[pp, "1E-core width of side legs [m]"],
    Highlight Str[colorpp],Closed close_menu},
  hcoil  = {9*cm,  Name StrCat[pp, "4Coil height [m]"],
    Highlight Str[colorpp]},
  wcoil  = {wcoreE, ReadOnly 1, Name StrCat[pp, "3Coil width [m]"],
    Highlight Str[colorro]},
  hcoreE = {hcoil+wcoreE, ReadOnly 1, Name StrCat[pp, "2E-core height of legs [m]"],
    Highlight Str[colorro]},
  ag     = {(TotalMemory <= 2048) ? 1*cm : 0.33*cm, Min 0.1*cm, Max 4*cm, Step 0.2*cm,
    ReadOnlyRange 1, Visible (Flag_OpenCore==1),
    Name StrCat[pp, "5Air gap width [m]"], Highlight Str[colorpp]},
  Lz     = {9*cm, Name StrCat[pp, "0Length along z-axis [m]"], Highlight Str[colorpp]}
];

// rest of EI-Core dimensions
wcoreE_centralleg = 2*wcoreE;

wcoreI = 2*wcoreE + wcoreE_centralleg + 2*wcoil;
hcoreI = wcoreE ;

htot = hcoil + wcoreE + ag + wcoreE ; // Total height of EI-core, including gap

// radious for surrounding air with transformation to infinity

If(Flag_Infinity==1)
  label_Rext = "1Outer [m]";
  Else
  label_Rext = "1[m]";
EndIf

DefineConstant[
  Rint = {20*cm, Min 0.15, Max 0.9, Step 0.1, Name StrCat[pp2, "0Inner [m]"],
    Visible (Flag_Infinity==1), Highlight Str[colorpp] },
  Rext = {28*cm, Min Rint, Max 1, Step 0.1, Name StrCat[pp2, StrCat["1", label_Rext]],
    Visible 1, Highlight Str[colorpp] }
];

Val_Rint = Rint;
Val_Rext = Rext;

//-------------------------------------------------------------------------
// Some mesh control stuff
DefineConstant[
  md = { 1., Name StrCat[ppm, "0Mesh density"],
    Highlight Str[colorpp], Closed close_menu},
  nn_wcore   = { Ceil[md*2], Name StrCat[ppm, "0Core width"], ReadOnly 1,
    Highlight Str[colorro], Closed close_menu},
  nn_airgap  = { Ceil[md*1], Name StrCat[ppm, "1Air gap width"], ReadOnly 1,
    Highlight Str[colorro]},
  nn_ri = { Ceil[md*6], Name StrCat[ppm, "2One fourth shell in"], ReadOnly 1,
    Visible (Flag_Infinity==1), Highlight Str[colorro]},
  nn_ro = { Ceil[md*6], Name StrCat[ppm, "3One fourth shell out"], ReadOnly 1,
    Highlight Str[colorro]}
];

//-------------------------------------------------------------------------

IA = 10;
Nw = 288;

sigma_al = 3.72e7 ; // conductivity of aluminum [S/m]
sigma_cu = 5.77e7  ; // conductivity of copper [S/m]


// ----------------------------------------------------
// Numbers for physical regions in .geo and .pro files
// ----------------------------------------------------

ECORE = 1000;
ICORE = 1100;

SKINECORE = 11110;
SKINICORE = 11111;

COIL  = 2000;
SKINCOIL = 2222;
SKINCOIL_ = 2223;

SURF_ELEC0 = 2333;
SURF_ELEC1 = 2444;
CUTCOIL = 2555;

AIR    = 3000;
AIRINF = 3100;
AIRGAP = 3200;

// Lines and surfaces for boundary conditions
SURF_AIROUT = 3333;

AXIS_Y = 10000;
CUT_YZ = 11000;
CUT_XY = 12000;
