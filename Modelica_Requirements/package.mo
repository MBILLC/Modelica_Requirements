within ;
package Modelica_Requirements "Modelica_Requirements (Version 0.7.1) - Defining requirements formally and checking them when simulating"
  extends Modelica.Icons.Package;


package UsersGuide "User's Guide"
  extends Modelica.Icons.Information;

package ReleaseNotes "Release notes"
  extends Modelica.Icons.ReleaseNotes;

  class Version_0_7_1 "Version 0.7.1 (Sept. 14, 2026)"
  extends Modelica.Icons.ReleaseNotes;

    annotation (Documentation(info="<html>
<p>
Maintenance release. The library now runs in a third Modelica tool, Modelon Impact, and
its examples have been simulated with Dymola, OpenModelica and Modelon Impact and compared
tool against tool. No requirement semantics changed: every change below was checked to
leave the Dymola and OpenModelica results of every example unchanged.
</p>

<h4>Changes</h4>
<ul>
<li> <code>uses(Modelica(version=\"4.1.0\"))</code>. No change in the library was needed for
     the Modelica Standard Library 4.1.0.</li>

<li> <a href=\"modelica://Modelica_Requirements.Verify.PrintViolations\">PrintViolations</a> has two new parameters on its Advanced tab,
     <code>useEvaluationTime</code> (default <code>false</code>) and <code>evaluationTime</code>.
     The verdict of a requirement model is taken and printed at <code>terminal()</code>; a tool that
     does not support <code>terminal()</code> (Modelon Impact evaluates it to <code>false</code>) never
     printed it. With <code>useEvaluationTime = true</code> the verdict is taken at
     <code>evaluationTime</code> instead. <a href=\"modelica://Modelica_Requirements.Interfaces.PartialVerify\">PartialVerify</a> passes both
     parameters through and <a href=\"modelica://Modelica_Requirements.Interfaces.PartialRequirement\">PartialRequirement</a> reads them from the
     inner <code>printViolations</code>. Every example sets <code>evaluationTime</code> to its StopTime,
     so switching the option on is all such a tool needs; with the default the behaviour is as before.</li>

<li> <a href=\"modelica://Modelica_Requirements.LogicalBlocks.FallingEdgeTerminate\">FallingEdgeTerminate</a> has a new parameter
     <code>delay</code> (default 0, Advanced tab): the simulation terminates that long after the falling
     edge instead of at it. A tool that stores only the pre-event state at a <code>terminate()</code>
     instant (Modelon Impact) otherwise drops the verdict a requirement block takes at that very
     edge from its result. Dymola and OpenModelica record the edge's values and need no delay.</li>

<li> <a href=\"modelica://Modelica_Requirements.ChecksInFixedWindow_withFFT\">ChecksInFixedWindow_withFFT</a> did not run in
     Modelon Impact at all (the branch of an earlier port notes this). Four independent causes, each
     fixed in a form that leaves Dymola and OpenModelica bit-identical:
     <ol>
     <li> <code>Internal.checkDomain</code> declared local arrays <code>diff[:]</code>, <code>f[:]</code>.
          A function's local array needs a size that follows from its inputs; Impact refuses an
          undefined size. Both are now sized <code>size(A,1)</code>, the checked band is the slice
          <code>1:n</code>, and the division by the limit curve's maximum is guarded against an
          all-zero curve.</li>
     <li> <code>Internal.PartialFFT</code> starts its sampling chain through the edge
          <code>condition and not pre(condition)</code>, relying on the initial equation
          <code>pre(condition) = false</code> for a condition that is already true at
          initialization. A tool that initializes <code>pre(condition)</code> to the condition's own
          value never sees that edge, and the block was dead for the whole run. The start is now
          explicit: <code>(condition and not pre(condition)) or (initial() and condition)</code>.</li>
     <li> The FFT examples stop through <code>FallingEdgeTerminate</code> at the instant their
          FFT is evaluated; without the new <code>delay</code>, Impact's result did not contain the
          verdict.</li>
     <li> <a href=\"modelica://Modelica_Requirements.ChecksInFixedWindow_withFFT.WithinRelativeDomain\">WithinRelativeDomain</a> and
          <a href=\"modelica://Modelica_Requirements.ChecksInFixedWindow_withFFT.MaxTotalHarmonicDistortion\">MaxTotalHarmonicDistortion</a> evaluated
          their chain (base frequency, scaled limit curve or THD, check, icon curves) as eight
          equations in one when-clause. A tool that evaluates a when-body with the pre-event values
          of the variables assigned in that same when-clause (Impact, measured with an eleven-line
          model) checked the FFT against a limit curve scaled by the previous base amplitude, zero
          before the first FFT, and reported Violated for a satisfied requirement. Split over
          several when-clauses with the same condition, the same tool built a nonlinear block around
          them and failed its initialization in a fraction of the runs. The chain is now one
          function call, <code>Internal.checkRelativeDomain</code> and <code>Internal.checkTHD</code>.</li>
     </ol></li>

<li> <a href=\"modelica://Modelica_Requirements.LogicalFunctions.card\">card</a>, <code>cardSatisfied</code>,
     <code>cardUndecided</code>, <code>cardViolated</code>: the reduction is written over the indices,
     <code>sum(if p[i] == ... then 1 else 0 for i in 1:size(p, 1))</code>, instead of over the elements.
     The same count; Modelon Impact fails to scalarize the element form (\"Exception caught while
     scalarizing function cardSatisfied\"), which took
     <code>Examples.AircraftRequirements.MinimumOperationalServiceLife</code> down with it.</li>

<li> <a href=\"modelica://Modelica_Requirements.Examples.MotorsWithLosses\">Examples.MotorsWithLosses</a> and
     <a href=\"modelica://Modelica_Requirements.Examples.SimplePumpingSystem.CheckPumpingSystem\">Examples.SimplePumpingSystem.CheckPumpingSystem</a>
     passed model instances to their binding functions (<code>watchDCMotor(obj=dcpm1)</code>,
     <code>TankObservation_from_OpenTank(reservoir)</code> and the like) where the function input is a record.
     That is a Dymola extension; the form the Modelica Language Specification allows (3.6, section 12.6.1,
     the record cast <code>R(m)</code>) turned out to be implemented by Dymola alone: OpenModelica 1.27.1 reads
     it as a positional constructor call and Modelon Impact refuses any access to a model instance in an
     expression, in the implicit and the explicit form alike. The call sites now build the observation
     records with explicit record constructors, nested and vectorized where the instance was
     (<code>MotorData(VaNominal=dcpm1.VaNominal, ..., inertiaRotor=InertiaData(w=dcpm1.inertiaRotor.w))</code>),
     which all three tools run; <code>MotorData</code> and <code>InertiaData</code> moved out of the
     function's protected section so the call site can name them. Two consequences of the same measurement:
     <code>DCMotorWatching</code>'s nominal values lost their <code>parameter</code> prefix and the current
     limit in <code>DCMotorRequirements</code> became a <code>BooleanExpression</code> like the speed limit
     (a record with parameter components returned by a function is continuous-time to Impact and
     over-determined to OpenModelica); and the source and sink observations are built with the
     <code>Source</code> record constructor directly, <code>SourceObservation_from_PartialSource</code> and
     <code>Records.PartialSource</code> being removed, because OpenModelica 1.27.1 silently returns zeros
     from a function whose result is a record with an array component when the call has parameter
     variability, as a fixed boundary's pressures have. Both examples now simulate in OpenModelica and
     Modelon Impact with agreeing results.</li>
</ul>

<h4>Three tools compared</h4>
<p>
All 68 example models under <a href=\"modelica://Modelica_Requirements.Examples\">Examples</a> that carry an
<code>experiment</code> annotation were simulated with each tool with that annotation's StopTime and
Interval, CVode, a relative tolerance of 1e-6 (the annotation's Tolerance where it has one), and every
block output <code>*.y</code> was compared between tools on the output grid (an absolute
tolerance of 1e-3 of each signal's range, or its switching instants for a Boolean or Property
signal). The regression harness used is
<a href=\"https://github.com/MBILLC/ModCheck\">ModCheck</a>; the case lists, the stored results of
the three tools and the reports are kept beside it, not in this library.
</p>

<table border=1 cellspacing=0 cellpadding=2>
<tr><th>Tool</th><th>Examples simulated</th><th>Not simulated, and why</th></tr>
<tr><td valign=\"top\">Dymola 2026x</td>
    <td valign=\"top\">60</td>
    <td valign=\"top\">8 refused by the license used for the comparison (\"the model is too
        complex for the current license\", about 1000 unknowns): <code>MainPowerSupplyRequirements</code>,
        <code>LimitedCabinAltitudeRateOfChange</code>, four of the six FFT examples,
        <code>CheckMotorWithLosses</code>, <code>CheckPumpingSystem</code>. Not a library problem.</td></tr>
<tr><td valign=\"top\">OpenModelica 1.27.1</td>
    <td valign=\"top\">48</td>
    <td valign=\"top\">20 do not build: the 14 examples using a sliding-window block
        (\"No runtime support for this record assignment\" for the buffer record returned by
        <code>Internal.SlidingWindow.push</code>) and the 6 FFT examples
        (\"Internal error BackendDAECreate.lowerWhenEqn: equation not handled\").</td></tr>
<tr><td valign=\"top\">Modelon Impact (Sept. 2026)</td>
    <td valign=\"top\">68 (63 of them with a reference to compare against)</td>
    <td valign=\"top\">&mdash;</td></tr>
</table>

<p>
<b>OpenModelica against Dymola</b>, on the 45 examples both simulate: every continuous signal
agrees to better than 1e-4 of its range (most to 1e-13 or exactly), and every Boolean and Property
signal switches at identical instants in both tools; the only grid points that differ are those
instants themselves, sampled on opposite sides of the event. One example,
<code>SimplePumpingSystem.Components.PumpingSystem</code>, is an on-off pressure controller over
2000 s whose switching instants move with the tolerance, within one tool as between two.
</p>

<p>
<b>Modelon Impact against Dymola</b> (and against OpenModelica for the three examples Dymola's license
refuses and OpenModelica builds): on the 63 examples with a reference, all 296 signal checks pass. The 85 continuous signals lie inside their tolerance tube everywhere (a funnel error of exactly 0); of the 208 signals compared at their final value, 205 are identical and the other three agree to 5e-9; the relay signals of <code>PumpingSystem</code> agree by accumulated difference within the tolerance measured for Dymola against itself. The other 5 examples Impact simulates (<code>MainPowerSupplyRequirements</code> and four FFT examples) have no reference from either other tool.
</p>

<h4>Tool support for the record cast</h4>
<p>
The Modelica Language Specification (3.6, section 12.6.1) lets a record constructor take a model, block or
connector instance as its single argument, <code>R(m)</code>, copying the public components whose names
match, recursively and vectorized. Of the three tools compared here, only Dymola implements it (measured
2026-09-14 on a probe library); Dymola also accepts the instance itself where a record is expected, which
this library relied on until this release. The explicit record constructor,
<code>R(a=m.a, sub=S(w=m.sub.w))</code>, is what all three run, and it is what the examples now use.
</p>
</html>"));
  end Version_0_7_1;

  class Version_0_7_0 "Version 0.7.0 (Feb. 13, 2025)"
  extends Modelica.Icons.ReleaseNotes;

    annotation (Documentation(info="<html>
<p>
Updated implementation to Modelica 4.0.0.
</p>
</html>"));
  end Version_0_7_0;

  class Version_0_6_1 "Version 0.6.1 (Feb. 3, 2025)"
  extends Modelica.Icons.ReleaseNotes;

    annotation (Documentation(info="<html>
<p>
License changed to BSD 3-Clause license.
</p>
</html>"));
  end Version_0_6_1;

  class Version_0_6 "Version 0.6 (April 19, 2016)"
  extends Modelica.Icons.ReleaseNotes;

    annotation (Documentation(info="<html>
<p>
First version of the library provided to the public.
</p>
</html>"));
  end Version_0_6;

 annotation (Documentation(info="<html>

<p>
This section summarizes the changes that have been performed
on package Modelica_Requirements.
</p>
</html>"));
end ReleaseNotes;

class Contact "Contact"
  extends Modelica.Icons.Contact;

 annotation (Documentation(info="<html>
<dl>
<dt><b>Main Author</b></dt>
<dd>Martin Otter<br>
    German Aerospace Center (DLR)<br>
    Robotics and Mechatronics Center<br>
    <a href=\"http://www.dlr.de/rmc/sr/en/desktopdefault.aspx/tabid-8018/\">Institute of System Dynamics and Control</a><br>
    Postfach 1116<br>
    D-82230 Wessling<br>
    Germany<br>
    email: <a href=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</a><br></dd>
</dl>
<p><b>Acknowledgements:</b></p>

<ul>
<li> The structuring and most operators/models of this library are based on
     the informally defined <b>FORM-L</b> language by Nguyen Thuy from EDF.
     The backup-power-supply example is based on a description by
     Nguyen Thuy from EDF.</li>

<li> The example models in sublibrary <a href=\"modelica://Modelica_Requirements.Examples.AircraftRequirements\">AircraftRequirements</a>
     have been provided by the aircraft manufacturer Dassault Aviation and implemented by Dassault Aviation and DLR.</li>

<li> Some operators/models are based on work
     by Dassault Aviation (such as <a href=\"modelica://Modelica_Requirements.SignalAnalysis\">SignalAnalysis</a>)
     and by DLR (such as <a href=\"modelica://Modelica_Requirements.ChecksInFixedWindow_withFFT\">ChecksInFixedWindow_withFFT</a>).
     </li>

<li> The functions \"card\", \"forall\" and \"exists\" are based on a design
     by Hilding Elmqvist from Dassault Syst&egrave;mes Lund.</li>

<li> The functions \"first\", \"last\", \"oneTrue\"
     and the blocks \"WhenFalling\", \"WhenChanging\" are from Andrea Tunis (UNICAL).</li>

<li> Wladimir Schamai suggested to use a mix of 2- and 3-valued logic.</li>

<li> Earlier versions of this library have been tested with Dymola, OpenModelica and SimulationX.</li>

<li> Most of this library was developed within the ITEA2 project
     <a href=\"https://www.modelica.org/external-projects/modrio\">MODRIO</a>. Partial financial support of
     the German BMBF, the French DGE, and the Swedish VINNOVA are highly appreciated.</li>

<li> The FFT-based property blocks of this library
     (<a href=\"modelica://Modelica_Requirements.ChecksInFixedWindow_withFFT\">ChecksInFixedWindow_withFFT</a>)
     have been developed and implemented with help of partial funding in the European Union’s Seventh Framework Programme
     (FP7/2007-2016) for the Clean Sky Joint Technology Initiative under grant agreement no. CSJU-GAM-SGO-2008-001.
     This support is highly appreciated.</li>
</ul>
</html>"));

end Contact;

annotation (DocumentationClass=true, Documentation(info="<html>
<p>
Library <b>Modelica_Requirements</b> is a Modelica package
using temporal logic to formally define requirements
and automatically test these requirements when a model
is simulated.
</p>
</html>"));
end UsersGuide;

  annotation (preferredView="info",
  uses(Modelica(version="4.1.0")),
version="0.7.1",
versionDate="2026-09-14",
dateModified = "2026-09-14",
revisionId="$Id:: package.mo 9390 2016-06-21 06:35:11Z #$",
Documentation(info="<html>
<p>
Library <b>Modelica_Requirements</b> is a Modelica package
to formally define requirements and checking them automatically
when a model is simulated. An overview of this library is given in the publication
<a href=\"modelica://Modelica_Requirements/Resources/Documentation/ecp15118625.pdf\">Formal Requirements Modeling for Simulation-Based Verification</a>
</p>

<p>
In order to define properties and requirements mostly a 2-valued logic is used.
There are some functions and blocks based on 3-valued logic using type
<a href=\"modelica://Modelica_Requirements.Types.Property\">Property</a>, especially
block <a href=\"modelica://Modelica_Requirements.Verify.Requirement\">Requirement</a>.
Furthermore, there are cast-operators to map 2-valued to 3-valued logic and vice versa.
3-valued logic is used to define (a) if a property is not tested (because only relevant
in a certain situation) and (b) if a requirement was not tested in a simulation run.
</p>

<p>
In this package the standard convention is used that names of
memory-less operators (implemented as Modelica functions)
start with lower-case letters and names of operators
with memory (implemented as Modelica blocks) start with
upper-case letters.
</p>

<p>
This package uses basically Modelica 3.6 language elements and requires at least version 4.0.0 of
the Modelica Standard Library.
Additionally, the Modelica extension is used in some examples (but not outside of examples) to
pass a model instance as argument to a function (and the function argument is a record).
This feature is used to associate requirements in a reasonably convenient way with
behavioral models. This approach is currently under discussion at the Modelica Association.
Most likely a slightly different concept will be introduced in the next release of the
Modelica language by providing the cast of a model to a record. Once this is clear and
prototypes are available in Modelica tools, this new concept will be used in this library.
Earlier versions of this library contained also examples utilizing
the proposed new Modelica language element to \"call a block as a function\". These examples had been
removed from this version.
</p>

<p>
The current version of the library uses a buffer for the implementation of
sliding windows (<a href=\"modelica://Modelica_Requirements.Internal.SlidingWindow\">Internal.SlidingWindow</a>).
The size of this buffer is fixed to 20 (constant nBuffer in package SlidingWindow).
If the buffer is too small for a requirement from package
<a href=\"modelica://Modelica_Requirements.ChecksInSlidingWindow\">ChecksInSlidingWindow</a>,
then a warning is printed.
The result of the requirement verification might then not be correct.
</p>

<p>
<b>This package is not yet finalized. A redesign is planned. The redesigned library (with improved implementations
of models and new functionality) should be backwards compatible to this version, but
it is not guaranteed. If non-backwards compatible changes are introduced, most likely
automatic conversions will not be provided.</b>.
</p>

<p>
<i>This Modelica package is <u>free</u> software and
the use is completely at <u>your own risk</u>;
it can be redistributed and/or modified under the terms of the
3-Clause BSD license, see the license conditions (including the
disclaimer of warranty) at
<a href=\"https://github.com/modelica-3rdparty/Modelica_Requirements/blob/master/LICENSE\">
https://github.com/modelica-3rdparty/Modelica_Requirements/blob/master/LICENSE</a>.</i>
</p>


<p>
<b>Copyright &copy; 2014-2016, DLR, Dassault Aviation and UNICAL</b>
</p>
</html>"));
end Modelica_Requirements;
