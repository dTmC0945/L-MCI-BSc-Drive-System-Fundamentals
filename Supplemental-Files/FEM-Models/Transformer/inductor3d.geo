// Flag_3Dmodel = 1;
// Mesh.Optimize = 1;

// characteristic lengths
lc0  = wcoil/nn_wcore;
lc1  = ag/nn_airgap;
lc2  = 2*lc1;

lcri = Pi*Rint/4/nn_ri;
lcro = Pi*Rext/4/nn_ro;


// center of the model at (0,0)
cen = newp; Point(newp) = {0,0,0, lc0};

// E-core
pnt0[] += newp; Point(newp) = { 0,             htot/2-hcoreE, 0, lc1};
pnt0[] += newp; Point(newp) = { wcoreE,         htot/2-hcoreE, 0, lc1};
pnt0[] += newp; Point(newp) = { wcoreE+wcoil,   htot/2-hcoreE, 0, lc1};
pnt0[] += newp; Point(newp) = { 2*wcoreE+wcoil, htot/2-hcoreE, 0, lc1};

pnt1[] += newp; Point(newp) = { 0,           htot/2-hcoreE+hcoil, 0, lc0};
pnt1[] += newp; Point(newp) = { wcoreE,       htot/2-hcoreE+hcoil, 0, lc2};
pnt1[] += newp; Point(newp) = { wcoreE+wcoil, htot/2-hcoreE+hcoil, 0, lc2};

pnt2[] += newp; Point(newp) = { 0,             htot/2-hcoreE+hcoil+wcoreE, 0, lc0};
pnt2[] += newp; Point(newp) = { 2*wcoreE+wcoil, htot/2-hcoreE+hcoil+wcoreE, 0, lc0};

lnh0[] += newl; Line(newl) = {pnt0[0],pnt0[1]};
lnh0[] += newl; Line(newl) = {pnt0[1],pnt0[2]};
lnh0[] += newl; Line(newl) = {pnt0[2],pnt0[3]};

lnh1[] += newl; Line(newl) = {pnt1[0],pnt1[1]};
lnh1[] += newl; Line(newl) = {pnt1[1],pnt1[2]};

lnh2[] += newl; Line(newl) = {pnt2[0],pnt2[1]};

lnv[] += newl; Line(newl) = {pnt0[0],pnt1[0]};
lnv[] += newl; Line(newl) = {pnt1[0],pnt2[0]};
lnv[] += newl; Line(newl) = {pnt0[1],pnt1[1]};
lnv[] += newl; Line(newl) = {pnt0[2],pnt1[2]};
lnv[] += newl; Line(newl) = {pnt0[3],pnt2[1]};

Line Loop(newll) = {lnh0[0],lnv[2],-lnh1[0],-lnv[0]};
surf_ECore[] += news ; Plane Surface(news) = newll-1;
Line Loop(newll) = {lnh0[2],lnv[4],-lnh2[0],-lnv[1],lnh1[{0,1}],-lnv[3]};
surf_ECore[] += news ; Plane Surface(news) = newll-1;

Line Loop(newll) = {lnh0[1],lnv[3],-lnh1[1],-lnv[2]};
surf_Coil[] += news ; Plane Surface(news) = newll-1;


// I-core
pnt3[] += newp; Point(newp) = { 0,       htot/2-hcoreE-ag-hcoreI, 0, lc0};
pnt3[] += newp; Point(newp) = { 2*wcoreE+wcoil, htot/2-hcoreE-ag-hcoreI, 0, lc0};
pnt3[] += newp; Point(newp) = { 2*wcoreE+wcoil, htot/2-hcoreE-ag, 0, lc1};
pnt3[] += newp; Point(newp) = { 0,       htot/2-hcoreE-ag, 0, lc1};

For k In {0:#pnt3[]-1}
  lni[]+=newl; Line(newl) = {pnt3[k], pnt3[(k==#pnt3[]-1)?0:k+1]};
EndFor

Line Loop(newll) = {lni[]};
surf_ICore[] += news ; Plane Surface(news) = {newll-1};


// Closing the airgap for testing different configurations
lnv[] += newl; Line(newl) = {pnt3[3], pnt0[0]};
lnv[] += newl; Line(newl) = {pnt3[2], pnt0[3]};

Line Loop(newll) = {-lnv[5],-lni[2],lnv[6],-lnh0[{2:0}]};
surf_Airgap[] += news; Plane Surface(news) = {newll-1};

//===========================================================
// Extruding surfaces // Just 1/4 of the model!

vol[] = Extrude {0,0,-Lz/2} { Surface{surf_ECore[0]};};
surf_in_coil = vol[0];
vol_ECore[]  += vol[1];
surf_cut_yz[]+= vol[5];
surf_cut_coil[]    += vol[2];
surf_cut_coil_up[] += vol[4];
vol_in_Coil[] += vol[1];

vol[] = Extrude {0,0,-Lz/2} { Surface {surf_ECore[1]}; };
vol_ECore[] += vol[1]; surf_cut_yz[]+=vol[5];

vol[] = Extrude {0,0,-Lz/2} { Surface{ surf_ICore[0]}; };
vol_ICore[] = vol[1]; surf_cut_yz[]+=vol[5];

vol[] = Extrude {0,0,-Lz/2} { Surface{surf_Airgap[0]}; };
vol_Airgap[] = vol[1]; surf_cut_yz[]+=vol[2];

vol[] = Extrude {0,0,-Lz/2}{ Surface{surf_Coil[0]}; };

vol_Coil[] += vol[1]; surf_Coil[] += vol[0];
vol[] = Extrude {{0, 1, 0}, {wcoreE, 0, -Lz/2}, Pi/2}{ Surface{surf_Coil[1]}; };
vol_Coil[] += vol[1]; surf_Coil[] += vol[0];

vol[] = Extrude {-wcoreE, 0, 0} { Surface{surf_Coil[2]}; };
vol_Coil[] += vol[1]; surf_Coil[] += vol[0];
surf_cut_yz[]+=vol[0];

// changing the sense, wcoil=wcoreE
// vol[] = Extrude {0,0,-wcoreE} { Surface{surf_in_coil}; };
// vol_Coil[] += vol[1]; surf_Coil[] += vol[0];
// surf_cut_yz[]+=vol[5];


aux_bnd[] = CombinedBoundary{ Surface{ surf_cut_yz[] };};
bnd_cut_yz[]= aux_bnd[{4:11}]; // Everything but the axis

// Air around
// Inner circle
pnta[] += newp; Point(newp) = { 0,-Rint, 0, lcri};
pnta[] += newp; Point(newp) = { Rint, 0, 0, lcri};
pnta[] += newp; Point(newp) = { 0, Rint, 0, lcri};

ln_rin[]+=newl; Circle(newl) = {pnta[0], cen, pnta[1]};
ln_rin[]+=newl; Circle(newl) = {pnta[1], cen, pnta[2]};

// Closing de domain...axis at x=0
lnaxis[]+=newl; Line(newl) = {pnta[0], pnt3[0]};
lnaxis[]+=lnv[4];
lnaxis[]+=newl; Line(newl) = {pnt2[0], pnta[2]};


Line Loop(newll) = {-lnaxis[2], lnh2[0], -lnv[{4,6}], -lni[{1,0}], -lnaxis[0], ln_rin[{0,1}]};
surf_Air[] += news; Plane Surface(news) = {newll-1};


// Outer circle - Infinity
pnta_[] += newp; Point(newp) = { 0,-Rext, 0, lcro};
pnta_[] += newp; Point(newp) = { Rext, 0, 0, lcro};
pnta_[] += newp; Point(newp) = { 0, Rext, 0, lcro};

ln_rout[]+=newl; Circle(newl) = {pnta_[0], cen, pnta_[1]};
ln_rout[]+=newl; Circle(newl) = {pnta_[1], cen, pnta_[2]};

lnaxis_[]+=newl; Line(newl) = {pnta_[0], pnta[0]};
lnaxis_[]+=newl; Line(newl) = {pnta[2], pnta_[2]};

Line Loop(newll) = {-ln_rin[{1,0}], -lnaxis_[0], ln_rout[{0,1}], -lnaxis_[1]};
surf_AirInf[] += news; Plane Surface(news) = {newll-1};

ln_axis[] = {lnaxis[],lnaxis_[],lni[3],lnv[0]};

vol[] = Extrude {{0, 1, 0}, {0, 0, 0}, Pi/2}{ Surface{surf_AirInf[0]}; };
vol_AirInf[] = vol[1]; surf_cut_yz[]+= vol[0];
surf_airinf_out[] = vol[{4,5}];
surf_airinf_in[] = vol[{2,3}];
bnd_cut_yz_airinf[] = Boundary{Surface{vol[0]};};

// Symmetry YZ
Line Loop(newll) = {lnaxis[2], bnd_cut_yz_airinf[{0,1}], lnaxis[0], bnd_cut_yz[]};
surf_cut_yz[]+= news; Plane Surface(news) = {newll-1};
surf_cut_yz_air[] = news-1;

surf_cut_xy[] = {surf_ECore[{0,1}], surf_ICore[0], surf_Airgap[0], surf_Air[0], surf_AirInf[0], surf_Coil[{0}]} ;

aux_surf[] = Abs(CombinedBoundary{ Volume{vol_ECore[], vol_ICore[], vol_Coil[], vol_Airgap[]}; });
aux_surf[] -= {surf_ECore[{0,1}], surf_ICore[0], surf_Airgap[0], surf_Coil[{0}], surf_cut_yz[]};

Surface Loop(newsl) = {surf_Air[0], surf_cut_yz_air[0], surf_airinf_in[], aux_surf[]};
vol_Air[]+=newv; Volume(newv) = {newsl-1};

If(Flag_Symmetry<2)
  surf_airinf_out[]  += Symmetry {1,0,0,0} { Duplicata{Surface{surf_airinf_out[]};} }; // For convenience
  surf_cut_coil[]    += Symmetry {1,0,0,0} { Duplicata{Surface{surf_cut_coil[]};} };
  surf_cut_coil_up[] += Symmetry {1,0,0,0} { Duplicata{Surface{surf_cut_coil_up[]};} };
  surf_cut_xy[]      += Symmetry {1,0,0,0} { Duplicata{Surface{surf_cut_xy[]};} };

  vol_ECore[]  += Symmetry {1,0,0,0} { Duplicata{Volume{vol_ECore[]};} };
  vol_in_Coil[]+= vol_ECore[2];

  vol_ICore[]  += Symmetry {1,0,0,0} { Duplicata{Volume{vol_ICore[]};} };
  vol_Coil[]   += Symmetry {1,0,0,0} { Duplicata{Volume{vol_Coil[]};} };
  vol_Airgap[] += Symmetry {1,0,0,0} { Duplicata{Volume{vol_Airgap[]};} };
  vol_Air[]    += Symmetry {1,0,0,0} { Duplicata{Volume{vol_Air[]};} };
  vol_AirInf[] += Symmetry {1,0,0,0} { Duplicata{Volume{vol_AirInf[]};} };

  If(!Flag_Symmetry) // Full model
    surf_airinf_out[]  += Symmetry {0,0,1,0} { Duplicata{Surface{surf_airinf_out[]};} };// For convenience
    surf_cut_coil[]    += Symmetry {0,0,1,0} { Duplicata{Surface{surf_cut_coil[]};} };
    surf_cut_coil_up[] += Symmetry {0,0,1,0} { Duplicata{Surface{surf_cut_coil_up[]};} };

    vol_ECore[]  += Symmetry {0,0,1,0} { Duplicata{Volume{vol_ECore[]};} };
    vol_in_Coil[]+= vol_ECore[{4,6}];

    vol_ICore[]  += Symmetry {0,0,1,0} { Duplicata{Volume{vol_ICore[]};} };
    vol_Coil[]   += Symmetry {0,0,1,0} { Duplicata{Volume{vol_Coil[]};} };
    vol_Airgap[] += Symmetry {0,0,1,0} { Duplicata{Volume{vol_Airgap[]};} };
    vol_Air[]    += Symmetry {0,0,1,0} { Duplicata{Volume{vol_Air[]};} };
    vol_AirInf[] += Symmetry {0,0,1,0} { Duplicata{Volume{vol_AirInf[]};} };
  EndIf
EndIf

Characteristic Length { PointsOf{ Volume{vol_Coil[]}; } } = lc2;
Characteristic Length { PointsOf{ Volume{vol_Airgap[]}; } } = lc1;

//=================================================
// Some colors... for aesthetics :-)
//=================================================

Recursive Color SkyBlue { Volume{vol_Air[], vol_AirInf[]}; }
Recursive Color SteelBlue {  Volume{ vol_ECore[], vol_ICore[]}; }
If(Flag_OpenCore==1)
  Recursive Color SkyBlue {Volume{vol_Airgap[]}; }
Else
  Recursive Color SteelBlue {Volume{vol_Airgap[]}; }
EndIf
Recursive Color Red { Volume{vol_Coil[]}; }

//=================================================
// Physical regions for FE analysis with GetDP
//=================================================

// Emptying cut list if no symmetry considered
If(Flag_Symmetry==0)
  surf_cut_xy[] = {};
  surf_cut_yz[] = {};
EndIf
If(Flag_Symmetry==1)
  surf_cut_yz[] = {};
EndIf

Physical Volume(ECORE) = vol_ECore[];
Physical Volume(ICORE) = vol_ICore[];

Physical Volume(COIL) = vol_Coil[];

bnd_Coil[] = Abs(CombinedBoundary{Volume{vol_Coil[]};});
bnd_Coil[] -= {surf_cut_xy[], surf_cut_yz[]} ; // list empty if no symmetry
Physical Surface(SKINCOIL) = bnd_Coil[];

Physical Volume(AIRGAP) = vol_Airgap[]; //either Fe or air
If(Flag_Infinity==0)
  Physical Volume(AIR) = {vol_Air[],vol_AirInf[]};
EndIf
If(Flag_Infinity==1)
  Physical Volume(AIR) = vol_Air[];
  Physical Volume(AIRINF) = vol_AirInf[];
EndIf
Physical Surface(SURF_AIROUT) = surf_airinf_out[];

Physical Surface(SURF_ELEC0) = surf_Coil[{0}];

all_surf_ECore[] = Abs(CombinedBoundary{Volume{vol_ECore[]};});
all_surf_ECore[] -= {surf_cut_xy[], surf_cut_yz[]};

all_surf_ICore[] = Abs(CombinedBoundary{Volume{vol_ICore[]};});
all_surf_ICore[] -= {surf_cut_xy[], surf_cut_yz[]};

Physical Surface(SKINECORE) = all_surf_ECore[];
Physical Surface(SKINICORE) = all_surf_ICore[];

Physical Surface(CUT_XY) = {surf_cut_xy[]};
Physical Surface(CUT_YZ) = {surf_cut_yz[]};
