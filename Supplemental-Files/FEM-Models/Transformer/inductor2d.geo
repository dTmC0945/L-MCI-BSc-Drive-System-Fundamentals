//Flag_3Dmodel = 0;

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

pnt1[] += newp; Point(newp) = { wcoreE,       htot/2-hcoreE+hcoil, 0, lc2};
pnt1[] += newp; Point(newp) = { wcoreE+wcoil, htot/2-hcoreE+hcoil, 0, lc2};

pnt2[] += newp; Point(newp) = { 0,             htot/2-hcoreE+hcoil+wcoreE, 0, lc0};
pnt2[] += newp; Point(newp) = { 2*wcoreE+wcoil, htot/2-hcoreE+hcoil+wcoreE, 0, lc0};

lnh[] += newl; Line(newl) = {pnt0[0],pnt0[1]};
lnh[] += newl; Line(newl) = {pnt0[1],pnt0[2]};
lnh[] += newl; Line(newl) = {pnt0[2],pnt0[3]};

lnh[] += newl; Line(newl) = {pnt1[0],pnt1[1]};
lnh[] += newl; Line(newl) = {pnt2[0],pnt2[1]};

lnv[] += newl; Line(newl) = {pnt0[0],pnt2[0]};
lnv[] += newl; Line(newl) = {pnt0[1],pnt1[0]};
lnv[] += newl; Line(newl) = {pnt0[2],pnt1[1]};
lnv[] += newl; Line(newl) = {pnt0[3],pnt2[1]};

Line Loop(newll) = {lnh[0],lnv[1],lnh[3],-lnv[2],lnh[2],lnv[3],-lnh[4],-lnv[0]};
surf_ECore[] += news ; Plane Surface(news) = newll-1;

Line Loop(newll) = {lnh[1],lnv[2],-lnh[3],-lnv[1]};
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

Line Loop(newll) = {-lnv[4],-lni[2],lnv[5],-lnh[{2:0}]};
surf_Airgap[] += news; Plane Surface(news) = {newll-1};


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

Line Loop(newll) = {-lnaxis[2], lnh[4], -lnv[{3,5}], -lni[{1,0}], -lnaxis[0],ln_rin[{0,1}]};
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


If(!Flag_Symmetry)
  // Symmetry of lines, just for convenience
  ln_rin[] += Symmetry {1,0,0,0} { Duplicata{Line{ln_rin[]};} };
  ln_rout[]+= Symmetry {1,0,0,0} { Duplicata{Line{ln_rout[]};} };

  surf_ECore[]  += Symmetry {1,0,0,0} { Duplicata{Surface{surf_ECore[0]};} };
  surf_ICore[]  += Symmetry {1,0,0,0} { Duplicata{Surface{surf_ICore[0]};} };
  surf_Coil[]   += Symmetry {1,0,0,0} { Duplicata{Surface{surf_Coil[0]};} };
  surf_Airgap[] += Symmetry {1,0,0,0} { Duplicata{Surface{surf_Airgap[0]};} };

  surf_Air[]    += Symmetry {1,0,0,0} { Duplicata{Surface{surf_Air[0]};} };
  surf_AirInf[] += Symmetry {1,0,0,0} { Duplicata{Surface{surf_AirInf[0]};} };

  Reverse Surface{ // For nice coloring of flux lines when highlighting is active
    surf_ECore[1], surf_ICore[1], surf_Coil[1],
    surf_Airgap[1], surf_Air[1], surf_AirInf[1]
  };

  Hide { Line{ ln_axis[] }; } // Hiding the symmetry line
EndIf

If(Flag_Infinity==0)
  //Hide{ Point{ Point '*' }; }
  pnt_ln_rin[] = Boundary{Line{ln_rin[]};};
  Hide{ Point{ pnt_ln_rin[] }; }
  Hide{ Line{ ln_rin[] }; }
EndIf

//=================================================
// Some colors... for aesthetics :-)
//=================================================
Color Red {Surface{surf_Coil[]};}
Color SteelBlue {Surface{surf_ECore[], surf_ICore[]};}
Color SkyBlue   {Surface{surf_Air[], surf_AirInf[]};}

If(Flag_OpenCore==1)
  Color SkyBlue   {Surface{surf_Airgap[]};}
EndIf
If(Flag_OpenCore==0)
  Color SteelBlue   {Surface{surf_Airgap[]};}
  fullcore[] = Boundary{Surface{surf_ECore[], surf_ICore[],surf_Airgap[]};};
  combinedfullcore[] = CombinedBoundary{Surface{surf_ECore[], surf_ICore[],surf_Airgap[]};};
  Hide{ Line{ fullcore[]}; }
  Show{ Line{ combinedfullcore[]}; }
EndIf

//=================================================
// Physical regions for FE analysis with GetDP
//=================================================

Physical Surface(ECORE) = surf_ECore[];
Physical Surface(ICORE) = surf_ICore[];
For k In {0:#surf_Coil[]-1}
  Physical Surface(COIL+k) = surf_Coil[k];
EndFor

Physical Surface(AIRGAP) = surf_Airgap[]; //either Fe or air
If(Flag_Infinity==0)
  Physical Surface(AIR) = {surf_Air[],surf_AirInf[]};
EndIf
If(Flag_Infinity==1)
  Physical Surface(AIR) = surf_Air[];
  Physical Surface(AIRINF) = surf_AirInf[];
EndIf
Physical Line(AXIS_Y) = ln_axis[] ; // BC if symmetry
Physical Line(SURF_AIROUT) = ln_rout[];
