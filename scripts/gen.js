(async () => {
  const $ = "1026";
  const id = `ibm${$.padStart(5, "0")}`;
  const name = `IBM-${$}`;
  const category = "IBM";
  const res = await fetch(
    `https://raw.githubusercontent.com/kreativekorp/bitsnpicas/refs/heads/master/main/java/BitsNPicas/src/com/kreative/unicode/mappings/${id.toUpperCase()}.txt`,
  );
  const x = await res.text();

  const uniq = new Set();
  const ascii = new Map([...Array(128).keys()].map((x) => ["c" + x, x]));
  let map = new Map(
    x
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
        uniq.add(+v);
        return ["c" + +k, +v];
      }),
  );
  if (map.size != uniq.size) console.log("WARN: NOT UNIQ");
  //map = new Map(
  //  [
  //    ..."；∧∨“”⊞⊟➙⧴″¶‴＆｜↶↷⟲←↑→↓⎇‽↧↥⌊⌈±↖↗↘↙ !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~⭆？⪫⪪℅◧◨⮌≡№⊙⸿⬤≔≕▷▶✂ΣΠ↨⍘✳↔≦≧ⅈⅉ⌕⊕⊖⊗⊘⎚¬₂Φ§﹪ææ«»×⁺æ⁻·÷⁰¹²³⁴⁵⁶⁷⁸⁹¦‖‹⁼›¿æＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ⟦∕⟧æ…´αβχδεφγηιæκλμν¤πθρστυςωξψζ⦃æ⦄～æ",
  //  ].map((x, i) => ["c" + i, x.codePointAt()]),
  //);
  console.log(
    `insert into sbcs (id, name, category, ${[...map.keys()]})\nvalues ('${id}', '${name}', '${category}', ${[...map.values()]});`,
  );
})();
