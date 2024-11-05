const id = "";
const name = "";
const category = "";
const x = `



`;

let map = new Map(
  x
    .split("\n")
    .filter(
      (a) =>
        a &&
        !a.startsWith("#") &&
        a.split(/\s+/)[1] &&
        !a.split(/\s+/)[1].startsWith("#"),
    )
    .map((a) => {
      const [k, v] = a.split(/\s+/);
      return ["c" + +k, +v];
    }),
);
map = new Map(
  [
    ..."；∧∨“”⊞⊟➙⧴″¶‴＆｜↶↷⟲←↑→↓⎇‽↧↥⌊⌈±↖↗↘↙ !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~⭆？⪫⪪℅◧◨⮌≡№⊙⸿⬤≔≕▷▶✂ΣΠ↨⍘✳↔≦≧ⅈⅉ⌕⊕⊖⊗⊘⎚¬₂Φ§﹪ææ«»×⁺æ⁻·÷⁰¹²³⁴⁵⁶⁷⁸⁹¦‖‹⁼›¿æＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ⟦∕⟧æ…´αβχδεφγηιæκλμν¤πθρστυςωξψζ⦃æ⦄～æ",
  ].map((x, i) => ["c" + i, x.codePointAt()]),
);
nsole.log(
  `insert into sbcs (id, name, category, ${[...map.keys()]})\nvalues ('${id}', '${name}', '${category}', ${[...map.values()]});`,
);
