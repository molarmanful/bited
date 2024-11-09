(async () => {
  const $ = "737";
  const id = `ibm${$.padStart(5, "0")}`;
  const name = `IBM-${$}`;
  const category = "IBM";
  const res = await fetch(
    `https://raw.githubusercontent.com/unicode-org/icu/refs/heads/main/icu4c/source/data/mappings/ibm-${$}_P100-1997.ucm`,
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
  //map = new Map(
  //  [
  //    ..."；∧∨“”⊞⊟➙⧴″¶‴＆｜↶↷⟲←↑→↓⎇‽↧↥⌊⌈±↖↗↘↙ !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~⭆？⪫⪪℅◧◨⮌≡№⊙⸿⬤≔≕▷▶✂ΣΠ↨⍘✳↔≦≧ⅈⅉ⌕⊕⊖⊗⊘⎚¬₂Φ§﹪ææ«»×⁺æ⁻·÷⁰¹²³⁴⁵⁶⁷⁸⁹¦‖‹⁼›¿æＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ⟦∕⟧æ…´αβχδεφγηιæκλμν¤πθρστυςωξψζ⦃æ⦄～æ",
  //  ].map((x, i) => ["c" + i, x.codePointAt()]),
  //);
  map = new Map(
    x.split("\n").flatMap((a) => {
      const m = a.match(/<U(\w{4})>\s+\\x(\w{2})\s+\|0/i);
      if (!m) return [];
      const k = parseInt(m[2], 16);
      const v = parseInt(m[1], 16);
      if (isNaN(k) || isNaN(v)) return [];
      uniq.add(v);
      return [["c" + k, v]];
    }),
  );
  if (map.size != uniq.size)
    console.log(
      "WARN: NOT UNIQ",
      [...map.values()].filter((e, i, a) => a.indexOf(e) != i),
    );
  console.log(
    `insert into sbcs (id, name, category, ${[...map.keys()]})\nvalues ('${id}', '${name}', '${category}', ${[...map.values()]});`,
  );
})();
