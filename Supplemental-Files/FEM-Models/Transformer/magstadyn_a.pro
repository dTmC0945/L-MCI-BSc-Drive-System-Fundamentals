Group {
   DefineGroup[
     DomainM, DomainB, DomainS, DomainInf,
     DomainL, DomainNL,
     Surf_bn0, Surf_Inf
  ];
}

Function{
 DefineConstant[
    Val_Rint, Val_Rext,
    Lz = 1,
    SymmetryFactor = 1,
    Nb_max_iter = 30,
    relaxation_factor = 1,
    stop_criterion = 1e-5,
    reltol = 1e-7,
    abstol = 1e-5,
    T = 1/Freq, // Fundamental period in s
    time0 = 0,
    NbT = 1,
    timemax = NbT*T,
    NbSteps = 100,
    delta_time = T/NbSteps,
    II, VV,
    Flag_NL = 0,
    Flag_NL_Newton_Raphson = {1, Choices{0,1}, Name "Input/41Newton-Raphson iteration",
      Visible Flag_NL},
    po = "Output 2D/"
  ];

  DefineFunction[
    dhdb_NL, dhdb, br, js0
  ];

}

Include "BH.pro"; // nonlinear BH caracteristic of magnetic material

Group {
  DomainB   = Region[ {Inds} ];

  If(Flag_Infinity)
    DomainInf = Region[ {AirInf} ];
  EndIf

  If(!Flag_ConductingCore)
    DomainCC = Region[ {Air, AirInf, Inds, Core} ];
    DomainC  = Region[ { } ];
  Else
    DomainCC = Region[ {Air, AirInf, Inds} ];
    DomainC  = Region[ {Core} ];
  EndIf


  If(!Flag_ConductingCore)
    DomainCC += Region[ {Core} ];
  Else
    DomainC += Region[ {Core} ];
  EndIf

  Domain  = Region[ {DomainCC, DomainC} ];

  If(Flag_NL)
    DomainNL = Region[ {Core} ];
    DomainL  = Region[ {Domain,-DomainNL} ];
  EndIf
  DomainDummy = Region[ 12345 ] ; // Dummy region number for postpro with functions
}

Function {
  nu [ Region[{Air, AirInf, Inds}] ]  = 1./mu0 ;

  If(!Flag_NL)
    nu [ Core ]  = 1/(mur_fe*mu0) ;
  EndIf
  If(Flag_NL)
    nu [ DomainNL ] = nu_EIcore[$1] ;
    dhdb_NL [ DomainNL ] = dhdb_EIcore_NL[$1];
    dhdb [ DomainNL ] = dhdb_EIcore[$1];
  EndIf

  sigma[Inds] = sigma_coil ;
  sigma[Core] = sigma_core ;
  rho[] = 1/sigma[] ;

  Resistance[Inds] = Lz*NbWires[]^2/SurfCoil[]/sigma[] ;
}

//-------------------------------------------------------------------------------------

Jacobian {
  { Name Vol;
    Case {
      { Region DomainInf ; Jacobian VolSphShell{Val_Rint, Val_Rext} ; }
      { Region All ; Jacobian Vol; }
    }
  }
}

Integration {
  { Name I1 ; Case {
      { Type Gauss ;
        Case {
          { GeoElement Triangle   ; NumberOfPoints  6 ; }
	  { GeoElement Quadrangle ; NumberOfPoints  4 ; }
	  { GeoElement Line       ; NumberOfPoints  13 ; }
        }
      }
    }
  }
}

//-------------------------------------------------------------------------------------

Constraint {

  { Name MVP_2D ;
    Case {
      { Region Surf_Inf ; Type Assign ; Value 0. ; }
      { Region Surf_bn0 ; Type Assign ; Value 0. ; }
    }
  }

  { Name Current_2D ;
    Case {
      { Region Inds ; Value II*Idir[] ; TimeFunction IA[]; }
    }
  }

  { Name Voltage_2D ;
    Case {
      If(Flag_ConductingCore)
        { Region Core ; Value 0; }
      EndIf
    }
  }

}

//-----------------------------------------------------------------------------------------------

FunctionSpace {
  // Magnetic Vector Potential
  { Name Hcurl_a_2D ; Type Form1P ;
    BasisFunction {
      { Name se1 ; NameOfCoef ae1 ; Function BF_PerpendicularEdge ;
        Support Region[{Domain}] ; Entity NodesOf [ All ] ; }
   }
    Constraint {
      { NameOfCoef ae1 ; EntityType NodesOf ; NameOfConstraint MVP_2D ; }
    }
  }

  // Gradient of Electric scalar potential (2D)
  { Name Hregion_u_Mag_2D ; Type Form1P ;
    BasisFunction {
      { Name sr ; NameOfCoef ur ; Function BF_RegionZ ;
        Support DomainC ; Entity DomainC ; }
    }
    GlobalQuantity {
      { Name U ; Type AliasOf        ; NameOfCoef ur ; }
      { Name I ; Type AssociatedWith ; NameOfCoef ur ; }
    }
    Constraint {
      { NameOfCoef U ; EntityType GroupsOfNodesOf ; NameOfConstraint Voltage_2D ; }
      { NameOfCoef I ; EntityType GroupsOfNodesOf ; NameOfConstraint Current_2D ; }
    }
  }

  { Name Hregion_i_Mag_2D ; Type Vector ;
    BasisFunction {
      { Name sr ; NameOfCoef ir ; Function BF_RegionZ ;
        Support DomainB ; Entity DomainB ; }
    }
    GlobalQuantity {
      { Name Ib ; Type AliasOf        ; NameOfCoef ir ; }
      { Name Ub ; Type AssociatedWith ; NameOfCoef ir ; }
    }
    Constraint {
      { NameOfCoef Ub ; EntityType Region ; NameOfConstraint Voltage_2D ; }
      { NameOfCoef Ib ; EntityType Region ; NameOfConstraint Current_2D ; }
    }
  }

}

//-----------------------------------------------------------------------------------------------

Formulation {

  { Name MagStaDyn_a_2D ; Type FemEquation ;
    Quantity {
      { Name a  ; Type Local  ; NameOfSpace Hcurl_a_2D ; }
      { Name ur ; Type Local  ; NameOfSpace Hregion_u_Mag_2D ; }
      { Name I  ; Type Global ; NameOfSpace Hregion_u_Mag_2D [I] ; }
      { Name U  ; Type Global ; NameOfSpace Hregion_u_Mag_2D [U] ; }

      { Name ir ; Type Local  ; NameOfSpace Hregion_i_Mag_2D ; }
      { Name Ub ; Type Global ; NameOfSpace Hregion_i_Mag_2D [Ub] ; }
      { Name Ib ; Type Global ; NameOfSpace Hregion_i_Mag_2D [Ib] ; }
    }

    Equation {
      Galerkin { [ nu[{d a}] * Dof{d a}  , {d a} ] ;
        In Domain ; Jacobian Vol ; Integration I1 ; }
      If(Flag_NL_Newton_Raphson)
        Galerkin { JacNL [ dhdb_NL[{d a}] * Dof{d a} , {d a} ] ;
          In DomainNL ; Jacobian Vol ; Integration I1 ; }
      EndIf
      Galerkin { [ -nu[] * br[] , {d a} ] ;
        In DomainM ; Jacobian Vol ; Integration I1 ; }

      Galerkin { DtDof[ sigma[] * Dof{a} , {a} ] ;
        In DomainC ; Jacobian Vol ; Integration I1 ; }
      Galerkin { [ sigma[] * Dof{ur}, {a} ] ;
        In DomainC ; Jacobian Vol ; Integration I1 ; }

      Galerkin { [ -js0[] , {a} ] ;
        In DomainS ; Jacobian Vol ; Integration I1 ; }

      Galerkin { DtDof[ sigma[] * Dof{a} , {ur} ] ;
        In DomainC ; Jacobian Vol ; Integration I1 ; }
      Galerkin { [ sigma[] * Dof{ur} , {ur} ] ;
        In DomainC ; Jacobian Vol ; Integration I1 ; }
      GlobalTerm { [ Dof{I} , {U} ] ; In DomainC ; }

      Galerkin { [ -NbWires[]/SurfCoil[] * Dof{ir} , {a} ] ;
        In DomainB ; Jacobian Vol ; Integration I1 ; }
      Galerkin { DtDof [ Lz * NbWires[]/SurfCoil[] * Dof{a} , {ir} ] ;
        In DomainB ; Jacobian Vol ; Integration I1 ; }
      GlobalTerm { [ Dof{Ub}/SymmetryFactor , {Ib} ] ; In DomainB ; }
      Galerkin { [ Resistance[]/SurfCoil[]* Dof{ir} , {ir} ] ;
        In DomainB ; Jacobian Vol ; Integration I1 ; } // Resistance term

      // GlobalTerm { [ Resistance[]  * Dof{Ib} , {Ib} ] ; In DomainB ; }
      // The above term can replace the resistance term:
      // if we have an estimation of the resistance of DomainB, via e.g. measurements
      // which is better to account for the end windings...

    }
  }

}

//-----------------------------------------------------------------------------------------------

DefineConstant[ Flag_NL_BFGS = 0, Flag_SNES = 0 ]; // test

Resolution {

  { Name Analysis ;
    System {
      If(Flag_AnalysisType==2)
        { Name A ; NameOfFormulation MagStaDyn_a_2D ; Type ComplexValue ; Frequency Freq ; }
      EndIf
      If(Flag_AnalysisType<2)
        { Name A ; NameOfFormulation MagStaDyn_a_2D ; }
      EndIf
    }
    Operation {
      CreateDir["res/"];

      If(Flag_AnalysisType==0 || Flag_AnalysisType==2) // Static or Frequency-domain
        If(!Flag_NL)
          Generate[A] ; Solve[A] ;
          Else
          IterativeLoop[Nb_max_iter, stop_criterion, relaxation_factor]{
              GenerateJac[A] ; SolveJac[A] ;
          }
        EndIf
        SaveSolution[A] ;

        PostOperation[Get_LocalFields] ;
        PostOperation[Get_GlobalQuantities] ;
      EndIf

      If(Flag_AnalysisType==1) // Time-domain
      InitSolution[A] ;
        TimeLoopTheta[time0, timemax, delta_time, 1.]{ // Implicit Euler (theta=1)
          If(!Flag_NL)
            Generate[A]; Solve[A];
            Else
            IterativeLoop[Nb_max_iter, stop_criterion, relaxation_factor] {
              GenerateJac[A] ; SolveJac[A] ; }
          EndIf
          SaveSolution[A];

          PostOperation[Get_LocalFields] ;
          Test[ $TimeStep > 1 ]{
            PostOperation[Get_GlobalQuantities];
          }
        }
      EndIf
    }
  }
}

//-----------------------------------------------------------------------------------------------

PostProcessing {

  { Name MagStaDyn_a_2D ; NameOfFormulation MagStaDyn_a_2D ;
    PostQuantity {
      { Name a  ; Value { Term { [ {a} ] ; In Domain ; Jacobian Vol ; } } }
      { Name az ; Value { Term { [ CompZ[{a}] ] ; In Domain ; Jacobian Vol ; } } }

      { Name b  ; Value { Term { [ {d a} ] ; In Domain ; Jacobian Vol ; } } }
      { Name nb  ; Value { Term { [ Norm[{d a}] ] ; In Domain ; Jacobian Vol ; } } }
      { Name br ; Value { Term { [ br[] ] ; In DomainM ; Jacobian Vol ; } } }

      { Name h ; Value { Term { [ nu[{d a}] * {d a} ] ; In Domain ; Jacobian Vol ; } } }

      { Name js0 ; Value { Term { [ js0[] ] ; In DomainS ; Jacobian Vol ; } } }

      { Name j  ; Value {
          Term { [ -sigma[]*(Dt[{a}]+{ur}) ]        ; In DomainC ; Jacobian Vol ; }
        }
      }

      { Name ir ; Value { Term { [ {ir} ] ; In Inds ; Jacobian Vol ; } } }

      { Name jz ; Value {
          Term { [ CompZ[-sigma[]*(Dt[{a}]+{ur})] ]       ; In DomainC ; Jacobian Vol ; }
        }
      }

      { Name rhoj2 ;
        Value {
          Term { [ sigma[]*SquNorm[ Dt[{a}]+{ur}] ] ; In Region[{DomainC}] ; Jacobian Vol ; }
          Term { [ 1./sigma[]*SquNorm[ IA[]*{ir} ] ] ; In Inds  ; Jacobian Vol ; }
        }
      }

      { Name JouleLosses ;
        Value {
          Integral { [ SymmetryFactor*Lz*sigma[] * SquNorm[ Dt[{a}]+{ur} ] ];
            In Region[{DomainC}] ; Jacobian Vol ; Integration I1 ; }
          Integral { [ SymmetryFactor*Lz*1./sigma[]*SquNorm[ IA[]*{ir} ] ];
            In Inds  ; Jacobian Vol ; Integration I1 ; }
        }
      }

      { Name MagEnergy ; Value {
          Integral { [ SymmetryFactor*Lz* 1/2 *nu[{d a}]*{d a}*{d a} ] ;
            In Domain ; Jacobian Vol ; Integration I1 ; } } }

      { Name Flux ; Value {
          Integral { [ SymmetryFactor*Lz*Idir[]*NbWires[]/SurfCoil[]* CompZ[{a}] ] ;
            In Inds  ; Jacobian Vol ; Integration I1 ; }
        }
      }

      { Name ComplexPower ; // S = P + i*Q
        Value {
          Integral { [ Complex[ sigma[]*SquNorm[Dt[{a}]+{ur}], nu[]*SquNorm[{d a}] ] ] ;
            In Region[{DomainC}] ; Jacobian Vol ; Integration I1 ; }
        }
      }

      { Name U ; Value {
          Term { [ {U} ]   ; In DomainC ; }
          Term { [ {Ub} ]  ; In DomainB ; }
        }
      }

      { Name I ; Value {
          Term { [ {I} ]   ; In DomainC ; }
          Term { [ {Ib} ]  ; In DomainB ; }
        }
      }

      { Name S ; Value {
          Term { [ {U}*Conj[{I}] ]    ; In DomainC ; }
          Term { [ {Ub}*Conj[{Ib}] ]  ; In DomainB ; }
        }
      }

      { Name Inductance_from_Flux ; Value { Term { Type Global; [ $Flux * 1e3/II ] ; In DomainDummy ; } } }
      { Name Inductance_from_MagEnergy ; Value { Term { Type Global; [ 2 * $MagEnergy * 1e3/(II*II) ] ; In DomainDummy ; } } }

    }
  }
}

//-----------------------------------------------------------------------------------------------

PostOperation Get_LocalFields UsingPost MagStaDyn_a_2D {
  Print[ ir, OnElementsOf Inds,   File StrCat[Dir,"ir",ExtGmsh], LastTimeStepOnly ] ;
  Print[ b,  OnElementsOf Domain, File StrCat[Dir,"b",ExtGmsh], LastTimeStepOnly ] ;
  Print[ nb,  OnElementsOf Domain, File StrCat[Dir,"nb",ExtGmsh], LastTimeStepOnly ] ;

  Print[ az, OnElementsOf Domain, File StrCat[Dir,"a",ExtGmsh], LastTimeStepOnly ];

  If(Flag_ConductingCore)
    Print[ jz, OnElementsOf DomainC, File StrCat[Dir,"jz",ExtGmsh], LastTimeStepOnly ];
  EndIf

  Echo[Str[ "For k In {0:PostProcessing.NbViews-1}",
      "View[k].RangeType = 3;" ,// per timestep
      "View[k].NbIso = 25;",
      "View[k].IntervalsType = 3;",
      "EndFor"// iso values
    ], File "tmp.opt"];

}


PostOperation Get_GlobalQuantities UsingPost MagStaDyn_a_2D {

  Print[ I, OnRegion Ind_1, Format Table,
    File > StrCat[Dir,"I",ExtGnuplot], LastTimeStepOnly,
    SendToServer StrCat[po,"20I [A]"], Color "LightYellow" ];

  Print[ U, OnRegion Ind_1, Format Table,
    File > StrCat[Dir,"U",ExtGnuplot], LastTimeStepOnly,
    SendToServer StrCat[po,"30U [V]"], Color "LightYellow" ];

  Print[ Flux[Inds], OnGlobal, Format TimeTable,
    File > StrCat[Dir,"Flux",ExtGnuplot], LastTimeStepOnly, StoreInVariable $Flux,
    SendToServer StrCat[po,"40Flux [Wb]"],  Color "LightYellow" ];

  Print[ MagEnergy[Domain], OnGlobal, Format TimeTable,
    File > StrCat[Dir,"ME",ExtGnuplot], LastTimeStepOnly, StoreInVariable $MagEnergy,
    SendToServer StrCat[po,"41Magnetic Energy [W]"],  Color "LightYellow" ];

  Print[ Inductance_from_Flux, OnRegion DomainDummy, Format Table, LastTimeStepOnly,
    File StrCat[Dir,"Inductance",ExtGnuplot],
    SendToServer StrCat[po,"50Inductance from Flux [mH]"], Color "LightYellow" ];
  Print[ Inductance_from_MagEnergy, OnRegion DomainDummy, Format Table, LastTimeStepOnly,
    File StrCat[Dir,"Inductance",ExtGnuplot],
    SendToServer StrCat[po,"51Inductance from Magnetic Energy [mH]"], Color "LightYellow" ];
}


DefineConstant[
  R_ = {"Analysis", Name "GetDP/1ResolutionChoices", Visible 0},
  C_ = {"-solve -v2", Name "GetDP/9ComputeCommand", Visible 0},
  P_ = {"", Name "GetDP/2PostOperationChoices", Visible 0}
];
