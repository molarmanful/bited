import mermaid from "https://unpkg.com/mermaid@11/dist/mermaid.esm.min.mjs";

const railroadCSS = `
.railroad-diagram,
.railroad-terminal text,
.railroad-nonterminal text,
.railroad-special text,
.railroad-comment text,
.railroad-rule-name {
  font-family: var(--md-mermaid-font-family);
}
.railroad-terminal text,
.railroad-nonterminal text,
.railroad-special text,
.railroad-comment text,
.railroad-rule-name {
  fill: var(--md-mermaid-label-fg-color);
}
.railroad-terminal rect,
.railroad-nonterminal rect,
.railroad-special rect {
  fill: var(--md-mermaid-node-bg-color);
  stroke: var(--md-mermaid-node-fg-color);
}
.railroad-comment ellipse {
  fill: var(--md-mermaid-label-bg-color);
  stroke: var(--md-mermaid-label-fg-color);
}
.railroad-line {
  stroke: var(--md-mermaid-edge-color);
}
.railroad-start circle,
.railroad-end circle {
  fill: var(--md-mermaid-edge-color);
}
`;

const { initialize } = mermaid;
mermaid.initialize = (config) =>
  initialize({ ...config, themeCSS: (config.themeCSS ?? '') + railroadCSS });

window.mermaid = mermaid;
