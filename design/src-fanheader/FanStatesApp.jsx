/* global React, ReactDOM, DesignCanvas, DCSection, DCArtboard, DCPostIt, FscBoard */

function FanStatesApp() {
  return (
    <DesignCanvas>
      <DCSection id="fs-problem" title="The problem today"
        subtitle="The deselected fan capsule wears an accent-tinted border and an orange glow — the same chrome that means “selected” on a worker node. At a glance, an idle fan and a selected worker are near-twins.">
        <DCArtboard id="fs-current" label="current · deselected fan ≈ selected worker" width={930} height={216}>
          <FscBoard variant="current" fanIdleSub="accent border + glow — the conflict" fanSelSub="halo only — weaker than idle?" />
        </DCArtboard>
        <DCPostIt top={-10} right={36} rotate={2} width={210}>
          Rule everywhere else on the canvas: accent outline = selection. The fan is the only node that breaks it.
        </DCPostIt>
      </DCSection>

      <DCSection id="fs-a" title="A · Quiet chrome"
        subtitle="Minimal fix. The shell goes neutral (border-2, plain shadow); the gradient header alone carries the fan identity. Selection uses the exact worker ring + halo, so one selection language covers every node.">
        <DCArtboard id="fs-a-board" label="neutral shell · header stays the hero" width={930} height={216}>
          <FscBoard variant="quiet" fanIdleSub="border-2 · shadow-1 · no glow" />
        </DCArtboard>
      </DCSection>

      <DCSection id="fs-b" title="B · Toasted header"
        subtitle="The header itself becomes the state indicator. Deselected, it bakes down to a muted cocoa-orange; selecting re-ignites the full crust gradient and adds the ring. The node visibly “lights up” when picked — strongest idle/selected separation.">
        <DCArtboard id="fs-b-board" label="muted header idle · full crust when selected" width={930} height={216}>
          <FscBoard variant="toasted" fanIdleSub="cocoa-muted header · neutral shell" fanSelSub="crust re-ignites + halo" />
        </DCArtboard>
      </DCSection>

      <DCSection id="fs-c" title="C · Crust rail"
        subtitle="Lowest accent budget. The header strip goes neutral (bg-3) with the accent living in a 3px crust cap, the glyph, and the ×7 chip. Best on dense canvases with many fans — the orange stays legible without shouting.">
        <DCArtboard id="fs-c-board" label="neutral header · thin crust cap" width={930} height={216}>
          <FscBoard variant="rail" fanIdleSub="3px crust cap · accent glyph + chip" />
        </DCArtboard>
      </DCSection>

      <DCSection id="fs-d" title="D · Stacked deck"
        subtitle="Differentiates by silhouette instead of color. Two ghost cards behind the capsule say “×N copies” — no accent chrome needed on the shell at all. Pairs with the full gradient header from A.">
        <DCArtboard id="fs-d-board" label="deck silhouette · neutral shell" width={930} height={216}>
          <FscBoard variant="deck" fanIdleSub="ghost stack signals multiplicity" />
        </DCArtboard>
      </DCSection>

      <DCSection id="fs-e" title="E · Dashed hull"
        subtitle="Container convention: a dashed neutral hull when idle (it “contains” a subworkflow), turning solid accent only on selection. Keeps the full gradient header. Familiar from grouping frames in most graph tools.">
        <DCArtboard id="fs-e-board" label="dashed idle · solid accent selected" width={930} height={216}>
          <FscBoard variant="dashed" fanIdleSub="1px dashed border-3" />
        </DCArtboard>
        <DCPostIt top={246} left={48} rotate={-2} width={230}>
          Recommendation: A if you want the smallest diff; B if you want selection to feel unmistakable. C, D, E are flavors on top of A's neutral shell.
        </DCPostIt>
      </DCSection>
    </DesignCanvas>
  );
}

ReactDOM.createRoot(document.getElementById("root")).render(<FanStatesApp />);
