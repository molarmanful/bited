(async () => {
  const $ = "Thai";
  const id = `macos${$.toLowerCase()}`;
  const name = `Mac OS ${$}`;
  const category = "Mac OS";
  const res = await fetch(
    `https://www.unicode.org/Public/MAPPINGS/VENDORS/APPLE/${$.toUpperCase()}.TXT`,
  );
  const x = await res.text();

  const ascii = new Map([...Array(128).keys()].map((x) => ["c" + x, x]));
  let map = new Map([
    ...ascii,
    ...x
      .split("\n")
      .filter(
        (a) =>
          a &&
          !a.startsWith("#") &&
          a.split(/\s+/)[1] &&
          !isNaN(+a.split(/\s+/)[1]),
      )
      .map((a) => {
        const [k, v] = a.split(/\s+/);
        return ["c" + +k, +v];
      }),
  ]);
  //map = new Map(
  //  [
  //    ..."；∧∨“”⊞⊟➙⧴″¶‴＆｜↶↷⟲←↑→↓⎇‽↧↥⌊⌈±↖↗↘↙ !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~⭆？⪫⪪℅◧◨⮌≡№⊙⸿⬤≔≕▷▶✂ΣΠ↨⍘✳↔≦≧ⅈⅉ⌕⊕⊖⊗⊘⎚¬₂Φ§﹪ææ«»×⁺æ⁻·÷⁰¹²³⁴⁵⁶⁷⁸⁹¦‖‹⁼›¿æＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ⟦∕⟧æ…´αβχδεφγηιæκλμν¤πθρστυςωξψζ⦃æ⦄～æ",
  //  ].map((x, i) => ["c" + i, x.codePointAt()]),
  //);
  console.log(
    `insert into sbcs (id, name, category, ${[...map.keys()]})\nvalues ('${id}', '${name}', '${category}', ${[...map.values()]});`,
  );
})();
