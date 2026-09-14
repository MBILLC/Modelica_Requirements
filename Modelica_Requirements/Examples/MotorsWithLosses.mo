within Modelica_Requirements.Examples;
package MotorsWithLosses
  "Demonstrate requirements definition and checking at hand of a electrical motors"
  extends Modelica.Icons.ExamplesPackage;

  model CheckMotorWithLosses
    "Check model Modelica.Electrical.Machines.Examples.DCMachines.DCPM_withLosses"
    extends Modelica.Icons.Example;

    Modelica.Electrical.Machines.Examples.DCMachines.DCPM_withLosses DCPM_withLosses
      annotation (Placement(transformation(extent={{-60,60},{-40,80}})));

    Components.Verify checkRequirements(
       dcmotorWatching={
         Components.watchDCMotor(name="DCPM_withLosses.dcpm1",
           obj=Components.MotorData(
             VaNominal=DCPM_withLosses.dcpm1.VaNominal,
             IaNominal=DCPM_withLosses.dcpm1.IaNominal,
             wNominal=DCPM_withLosses.dcpm1.wNominal,
             va=DCPM_withLosses.dcpm1.va,
             ia=DCPM_withLosses.dcpm1.ia,
             inertiaRotor=Components.InertiaData(w=DCPM_withLosses.dcpm1.inertiaRotor.w))),
         Components.watchDCMotor(name="DCPM_withLosses.dcpm2",
           obj=Components.MotorData(
             VaNominal=DCPM_withLosses.dcpm2.VaNominal,
             IaNominal=DCPM_withLosses.dcpm2.IaNominal,
             wNominal=DCPM_withLosses.dcpm2.wNominal,
             va=DCPM_withLosses.dcpm2.va,
             ia=DCPM_withLosses.dcpm2.ia,
             inertiaRotor=Components.InertiaData(w=DCPM_withLosses.dcpm2.inertiaRotor.w)))})
      annotation (Placement(transformation(extent={{60,60},{80,80}})));

    annotation (experiment(StopTime=2),
      Documentation(revisions="<html>
<table border=1 cellspacing=0 cellpadding=2>
<tr><th>Date</th> <th align=\"left\">Description</th></tr>

<tr><td valign=\"top\"> Sept. 14, 2026 </td>
    <td valign=\"top\"> The two motor instances are no longer passed to <code>watchDCMotor</code> themselves; the call site builds <code>Components.MotorData</code> with an explicit record constructor. Passing the instance is a Dymola extension, and the record cast <code>MotorData(dcpm1)</code> of the Modelica Language Specification (section 12.6.1) is implemented by Dymola alone; OpenModelica 1.27 and Modelon Impact run the explicit form (H. Tummescheit, Model Based Innovation LLC)</td></tr>
</table>
</html>"));
  end CheckMotorWithLosses;

  package Components "Utility components needed for example"
    extends Modelica.Icons.UtilitiesPackage;

    record DCMotorWatching
      "Signals observed from a DC motor as needed by DCMotorRequirements block"
       extends Modelica_Requirements.Interfaces.PartialWatching;

      Modelica.Units.SI.Voltage VaNominal "Nominal voltage (no parameter prefix: see the package documentation)";
      Modelica.Units.SI.Current IaNominal "Nominal current";
      Modelica.Units.SI.AngularVelocity wNominal "Nominal speed";

      Modelica.Units.SI.Voltage v annotation (Dialog);
      Modelica.Units.SI.Current i annotation (Dialog);
      Modelica.Units.SI.AngularVelocity w annotation (Dialog);
      annotation (Documentation(revisions="<html>
<table border=1 cellspacing=0 cellpadding=2>
<tr><th>Date</th> <th align=\"left\">Description</th></tr>

<tr><td valign=\"top\"> Sept. 14, 2026 </td>
    <td valign=\"top\"> <code>VaNominal</code>, <code>IaNominal</code>, <code>wNominal</code> lose their <code>parameter</code> prefix. The record is built by <code>watchDCMotor</code>, and a record with parameter components returned by a function is continuous-time to Modelon Impact (a variability error) and over-determined to OpenModelica; Dymola alone takes it (H. Tummescheit, Model Based Innovation LLC)</td></tr>
</table>
</html>"));
    end DCMotorWatching;

    block DCMotorRequirements "Requirements for one DC Motor"
      import Modelica_Requirements;
      extends Modelica_Requirements.Interfaces.PartialRequirements;

      input DCMotorWatching watch "Signals observed from source" annotation (Dialog,
          Placement(transformation(extent={{-74,80},{-54,100}})));
      Sources.BooleanExpression speed(y=abs(watch.w) <= 1.2*watch.wNominal)
        annotation (Placement(transformation(extent={{-100,30},{-40,50}})));
      Modelica_Requirements.Verify.BooleanRequirement R_SpeedMax(text="Maximum speed is limited")
        annotation (Placement(transformation(extent={{0,30},{60,50}})));
      Sources.BooleanExpression current(y=abs(watch.i) <= 1.5*watch.IaNominal)
        annotation (Placement(transformation(extent={{-100,-10},{-40,10}})));
      Modelica_Requirements.Verify.BooleanRequirement R_IaMax(text="Maximum current is limited")
        annotation (Placement(transformation(extent={{40,-36},{100,-16}})));
    equation

      connect(speed.y, R_SpeedMax.u) annotation (Line(
          points={{-38.5,40},{-2,40}},
          color={255,0,255},
          smooth=Smooth.None));
      connect(current.y, R_IaMax.u) annotation (Line(
          points={{-38.5,0},{60,0},{60,-12},{26,-12},{26,-26},{38,-26}},
          color={255,0,255},
          smooth=Smooth.None));
      annotation (Diagram(coordinateSystem(preserveAspectRatio=false, extent=
                {{-100,-100},{100,100}}), graphics),
        Documentation(revisions="<html>
<table border=1 cellspacing=0 cellpadding=2>
<tr><th>Date</th> <th align=\"left\">Description</th></tr>

<tr><td valign=\"top\"> Sept. 14, 2026 </td>
    <td valign=\"top\"> The current limit is a <code>BooleanExpression</code>, <code>abs(watch.i) &lt;= 1.5*watch.IaNominal</code>, as the speed limit already was, instead of <code>Abs</code> and <code>LessEqualThreshold</code> blocks: <code>watch.IaNominal</code> is no longer a parameter and cannot bind a parameter threshold (H. Tummescheit, Model Based Innovation LLC)</td></tr>
</table>
</html>"));
    end DCMotorRequirements;

    record InertiaData
      "Data needed from Modelica.Mechanics.Rotational.Components.Inertia"
      Modelica.Units.SI.AngularVelocity w;
    end InertiaData;

    record MotorData
      "Data needed from Modelica.Electrical.Machines.BasicMachines.DCMachines.DC_PermanentMagnet"
      parameter Modelica.Units.SI.Voltage VaNominal;
      parameter Modelica.Units.SI.Current IaNominal;
      parameter Modelica.Units.SI.AngularVelocity wNominal;
      Modelica.Units.SI.Voltage va;
      Modelica.Units.SI.Current ia;
      InertiaData inertiaRotor;
      annotation (Documentation(info="<html>
<p>The subset of a <code>DC_PermanentMagnet</code> instance that the requirements
observe, built at the call site with an explicit record constructor,
<code>MotorData(VaNominal=dcpm1.VaNominal, ..., inertiaRotor=InertiaData(w=dcpm1.inertiaRotor.w))</code>.
The Modelica Language Specification (section 12.6.1, casting to record) also
allows the short form <code>MotorData(dcpm1)</code>, and Dymola accepts it;
OpenModelica 1.27 and Modelon Impact (OCT) do not, nor do they accept passing
the instance itself. The explicit constructor is what all three run
(measured 2026-09-14).</p>
</html>"));
    end MotorData;

    function watchDCMotor
      "Map data from Modelica.Electrical.Machines.BasicMachines.DCMachines.DC_PermanentMagnet to DCMotor"
      input String name "Full name of DCmotor instance";
      input MotorData obj "DCmotor model data to be watched, cast with MotorData(<instance>)";
      output DCMotorWatching watchObj=DCMotorWatching(
          name=name,
          VaNominal=obj.VaNominal,
          IaNominal=obj.IaNominal,
          wNominal=obj.wNominal,
          v=obj.va,
          i=obj.ia,
          w=obj.inertiaRotor.w) "Data in DCmotor format";
    algorithm
      annotation(Inline=true,
        Documentation(revisions="<html>
<table border=1 cellspacing=0 cellpadding=2>
<tr><th>Date</th> <th align=\"left\">Description</th></tr>

<tr><td valign=\"top\"> Sept. 14, 2026 </td>
    <td valign=\"top\"> <code>MotorData</code> and <code>InertiaData</code> moved from the protected part of this function into the package, so that the call site can build them (H. Tummescheit, Model Based Innovation LLC)</td></tr>
</table>
</html>"));
    end watchDCMotor;

    block Verify "Check requirements of OpenTanks and of Pumps"
      import Modelica_Requirements.Examples.MotorsWithLosses.Components;

      extends Modelica_Requirements.Interfaces.PartialVerify;

      Components.DCMotorWatching dcmotorWatching[:]=fill(Components.DCMotorWatching(
                                                 name="Unknown",
                                                 VaNominal=100,
                                                 IaNominal=10,
                                                 wNominal=100,
                                                 v=100,
                                                 i=10,
                                                 w=100),0)
        "Vector of DCMotorWatching records"
        annotation (Dialog, Placement(transformation(extent={{-40,20},{-20,40}})));

      Components.DCMotorRequirements dcmotorRequirements[size(dcmotorWatching,1)](
                                                              watch=dcmotorWatching)
        annotation (Placement(transformation(extent={{-40,-20},{-20,0}})));

    end Verify;
  end Components;
end MotorsWithLosses;
