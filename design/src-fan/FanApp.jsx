/* global React, ReactDOM, DesignCanvas, DCSection, DCArtboard, DCPostIt,
   ConceptA, ConceptB, ConceptC, ConceptD, ConceptDRun, ConceptE */

function FanApp() {
  return (
    <DesignCanvas>
      <DCSection id="A" title="A · Subflow bracket"
        subtitle="By-the-book. Collapses to one node with a ×7 multiplicity stack; expands to a header + a dashed “repeats per item” frame.">
        <DCArtboard id="a-collapsed" label="collapsed" width={648} height={340}><ConceptA initial="collapsed" /></DCArtboard>
        <DCArtboard id="a-expanded" label="expanded" width={648} height={340}><ConceptA initial="expanded" /></DCArtboard>
        <DCPostIt top={-6} right={40} rotate={2} width={196}>Click any container header to expand ↔ collapse.</DCPostIt>
      </DCSection>

      <DCSection id="B" title="B · Stacked deck"
        subtitle="Multiplicity as a deck of copies. Expands so the deck fans into one solid iteration lane over N ghosted siblings.">
        <DCArtboard id="b-collapsed" label="collapsed" width={634} height={366}><ConceptB initial="collapsed" /></DCArtboard>
        <DCArtboard id="b-expanded" label="expanded" width={634} height={366}><ConceptB initial="expanded" /></DCArtboard>
      </DCSection>

      <DCSection id="C" title="C · Fan rails"
        subtitle="The most literal. A splitter wedge (1 → N) feeds the body; a collector wedge (N → 1) merges it. Expand to see the parallel lanes wired.">
        <DCArtboard id="c-collapsed" label="collapsed" width={684} height={344}><ConceptC initial="collapsed" /></DCArtboard>
        <DCArtboard id="c-expanded" label="expanded" width={684} height={344}><ConceptC initial="expanded" /></DCArtboard>
      </DCSection>

      <DCSection id="D" title="D · Capsule reactor"
        subtitle="Novel. A gradient capsule with inlet/outlet funnels; items stream through as tokens. Third frame shows it mid-run as a live job.">
        <DCArtboard id="d-collapsed" label="collapsed" width={684} height={350}><ConceptD initial="collapsed" /></DCArtboard>
        <DCArtboard id="d-expanded" label="expanded" width={684} height={350}><ConceptD initial="expanded" /></DCArtboard>
        <DCArtboard id="d-running" label="running · live job" width={684} height={350}><ConceptDRun /></DCArtboard>
      </DCSection>

      <DCSection id="E" title="E · Group frame"
        subtitle="Scales to arbitrary bodies. A tinted frame wraps a real multi-node sub-graph; collapses to a single “pipeline” node. Best when the fanned body is more than one worker.">
        <DCArtboard id="e-collapsed" label="collapsed" width={760} height={384}><ConceptE initial="collapsed" /></DCArtboard>
        <DCArtboard id="e-expanded" label="expanded" width={760} height={384}><ConceptE initial="expanded" /></DCArtboard>
      </DCSection>
    </DesignCanvas>
  );
}

ReactDOM.createRoot(document.getElementById("root")).render(<FanApp />);
