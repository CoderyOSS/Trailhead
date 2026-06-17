/* global React, ReactDOM, DesignCanvas, DCSection, DCArtboard, Board, DirF, TreeFamily */

// The chosen direction.
const NS_SYNTHESIS = [
  {
    tag: "F",
    name: "Role-tile + clean ports",
    label: "F · Role-tile + clean ports",
    render: () => DirF(),
    tagline: "C's leading role-tile ⊕ E's connector dots. One single-line capsule for every node.",
    rationale: "Keeps the leading role-tile you liked from C as the shared identity anchor, on the same flat capsule for all three. The branch is sized to its content — narrower than the others — and lists every case as a labeled row with its own output port down the right edge, so a router with N outputs reads cleanly. The map keeps a single output (it emits one collected result) with an ×n chip, signalling that parallel width is dynamic and set at runtime, not at planning.",
    move: "Leading role-tile + clean ports; branch sized to content, map = 1 output + ×n chip.",
    h: 430,
  },
];

// Tree mode — vertical connections.
const NS_TREE = [
  {
    tag: "F\u00b7tree",
    name: "Vertical flow",
    label: "Tree mode — vertical family",
    render: () => TreeFamily(),
    tagline: "F’s capsule rotated for top-down trees: input port on the top edge, output on the bottom.",
    rationale: "Same capsule and golden role-tile as horizontal F — only the ports move. Worker and map keep a single centered in/out pair. The branch stays worker-width and fans an output port for each case along the bottom edge, with the case label sitting in the connector lane beneath its port — so dense trees stay tidy and every branch reads at the same width.",
    move: "Ports move to top/bottom; branch fans bottom-edge ports with labels in the lane.",
    h: 360,
  },
];

function boardCard(d) {
  const h = d.h || 396;
  return (
    <DCArtboard key={d.tag} id={d.tag.toLowerCase()} label={d.label} width={700} height={h}>
      <Board tag={d.tag} name={d.name} tagline={d.tagline} rationale={d.rationale} move={d.move} render={d.render} h={h} />
    </DCArtboard>
  );
}

function NodeSystemDoc() {
  return (
    <DesignCanvas>
      <DCSection
        id="chosen"
        title="Chosen direction — F"
        subtitle="Role-tile + clean ports. The golden role-tile is the shared identity anchor; the branch sizes to its cases; the map has one output with a dynamic ×n fan width."
      >
        {NS_SYNTHESIS.map(boardCard)}
      </DCSection>

      <DCSection
        id="tree"
        title="Tree mode — vertical connections"
        subtitle="How the F family behaves when the graph runs top-to-bottom: input on the top edge, outputs on the bottom."
      >
        {NS_TREE.map(boardCard)}
      </DCSection>
    </DesignCanvas>
  );
}

ReactDOM.createRoot(document.getElementById("root")).render(<NodeSystemDoc />);
