const id = "lang05ab1e";
const name = "05AB1E";
const category = "Eso/Golf/etc.";
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
//map = new Map(
//  "ǝʒαβγδεζηθ\nвимнтΓΔΘιΣΩ≠∊∍∞₁₂₃₄₅₆ !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~Ƶ€Λ‚ƒ„…†‡ˆ‰Š‹ŒĆŽƶĀ‘’“”•–—˜™š›œćžŸā¡¢£¤¥¦§¨©ª«¬λ®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ"
//    .split``.map((x, i) => ["c" + i, x.codePointAt()]),
//);
console.log(
  `insert into sbcs (id, name, category, ${[...map.keys()]})\nvalues ('${id}', '${name}', '${category}', ${[...map.values()]});`,
);
