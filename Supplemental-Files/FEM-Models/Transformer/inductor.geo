Include "inductor_data.geo";

If(Flag_3Dmodel==0)
  Include "inductor2d.geo";
EndIf
If(Flag_3Dmodel==1 && !Flag_boolean)
  Include "inductor3d.geo";
EndIf
If(Flag_3Dmodel==1 && Flag_boolean)
  Include "inductor3d_bool.geo";
EndIf
