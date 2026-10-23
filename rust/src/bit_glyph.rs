use godot::{
    classes::{
        Image,
        image,
    },
    prelude::*,
};

#[derive(GodotClass, Clone)]
#[class(init, base = RefCounted)]
pub struct BitGlyph {
    size: Vector2i,
    data: PackedByteArray,
}

#[godot_api]
impl BitGlyph {
    #[func]
    pub fn get_size(&self) -> Vector2i {
        self.size
    }

    #[func]
    pub fn create(size: Vector2i) -> Gd<Self> {
        Self::create_from_bytes(size, PackedByteArray::new())
    }

    #[func]
    pub fn create_from_bytes(size: Vector2i, mut data: PackedByteArray) -> Gd<Self> {
        let size = size.maxi(0);
        data.resize(Self::vbytes(size));
        Self::clear_padding(&mut data, size.x);
        Gd::from_object(Self { size, data })
    }

    #[func]
    pub fn to_bytes(&self) -> PackedByteArray {
        self.data.clone()
    }

    #[func]
    pub fn used_rect(&self) -> Rect2i {
        let span = Self::bytes(self.size.x);
        let data = self.data.as_slice();

        let (Some(first), Some(last)) = (
            data.iter().position(|&b| b != 0),
            data.iter().rposition(|&b| b != 0),
        ) else {
            return Rect2i::default();
        };
        let y0 = first / span;
        let y1 = last / span + 1;

        let rows = &data[y0 * span..y1 * span];
        let mut cols = (0..span)
            .map(|i| (i, rows[i..].iter().step_by(span).fold(0, |a, &b| a | b)))
            .filter(|&(_, c)| c != 0);
        let (i0, c0) = cols.next().unwrap_or_default();
        let (i1, c1) = cols.next_back().unwrap_or((i0, c0));
        let x0 = (i0 * 8) as i32 + c0.leading_zeros() as i32;
        let x1 = (i1 * 8 + 8) as i32 - c1.trailing_zeros() as i32;

        Rect2i::from_position_end(Vector2i::new(x0, y0 as i32), Vector2i::new(x1, y1 as i32))
    }

    #[func]
    pub fn dup(&self) -> Gd<Self> {
        Gd::from_object(self.clone())
    }

    #[func]
    pub fn copy_from(&mut self, src: Gd<Self>) {
        let src = src.bind();
        self.size = src.size;
        self.data = src.data.clone();
    }

    #[func]
    pub fn get_bit(&self, p: Vector2i) -> bool {
        Self::index(self.size, p).is_some_and(|(i, mask)| self.data[i] & mask != 0)
    }

    #[func]
    pub fn set_bit(&mut self, p: Vector2i, v: bool) -> bool {
        Self::index(self.size, p).is_some_and(|(i, mask)| {
            let byte = &mut self.data[i];
            let old = *byte & mask != 0;
            if v {
                *byte |= mask;
            } else {
                *byte &= !mask;
            }
            old
        })
    }

    #[func]
    pub fn op(&mut self, op: VariantOperator, that: Gd<Self>) {
        let that = that.bind();
        assert_eq!(self.size, that.size);
        for (a, &b) in self
            .data
            .as_mut_slice()
            .iter_mut()
            .zip(that.data.as_slice())
        {
            *a = match op {
                VariantOperator::BIT_OR => *a | b,
                VariantOperator::BIT_AND => *a & b,
                VariantOperator::BIT_XOR => *a ^ b,
                VariantOperator::SUBTRACT => *a & !b,
                _ => return,
            };
        }
    }

    #[func]
    pub fn crop(&mut self, r: Rect2i) {
        let size = r.size.maxi(0);
        let w0 = Self::bytes(self.size.x);
        let w1 = Self::bytes(size.x);
        let mut data = PackedByteArray::new();
        data.resize(Self::vbytes(size));

        let bytes = r.position.x.div_euclid(8);
        let bits = r.position.x.rem_euclid(8);
        let win_skip = usize::try_from(-bytes).unwrap_or(0);
        let row_skip = usize::try_from(bytes).unwrap_or(0);
        let len = (w1 + 1)
            .saturating_sub(win_skip)
            .min(w0.saturating_sub(row_skip));

        if len > 0 {
            let mut window = vec![0u8; w1 + 1];
            let rows0 = self
                .data
                .as_slice()
                .chunks_exact(w0)
                .skip(usize::try_from(r.position.y).unwrap_or(0));
            let rows1 = data
                .as_mut_slice()
                .chunks_exact_mut(w1.max(1))
                .skip(usize::try_from(-r.position.y).unwrap_or(0));

            for (row0, row1) in rows0.zip(rows1) {
                window[win_skip..][..len].copy_from_slice(&row0[row_skip..][..len]);
                for (d, w) in row1.iter_mut().zip(window.windows(2)) {
                    *d = (u16::from_be_bytes([w[0], w[1]]) << bits).to_be_bytes()[0];
                }
                row1[w1 - 1] &= 0xFF << (-size.x & 7);
            }
        }

        self.size = size;
        self.data = data;
    }

    #[func]
    pub fn translate(&mut self, v: Vector2i) {
        self.crop(Rect2i::new(-v, self.size));
    }

    #[func]
    pub fn region(&self, r: Rect2i) -> Gd<Self> {
        let mut a = self.dup();
        a.bind_mut().crop(r);
        a
    }

    #[func]
    pub fn line(&mut self, mut a: Vector2i, b: Vector2i) {
        let d = (b - a).abs();
        let s = (b - a).sign();
        let mut e = d.x - d.y;

        let data = self.data.as_mut_slice();
        loop {
            if let Some((i, mask)) = Self::index(self.size, a) {
                data[i] |= mask;
            }
            if a == b {
                break;
            }
            let e2 = e * 2;
            if e2 > -d.y {
                e -= d.y;
                a.x += s.x;
            }
            if e2 < d.x {
                e += d.x;
                a.y += s.y;
            }
        }
    }

    #[func]
    pub fn rect(&mut self, r: Rect2i) {
        let Some(r) = r
            .intersect(Rect2i::new(Vector2i::ZERO, self.size))
            .filter(|r| r.size.x > 0)
        else {
            return;
        };
        let span = Self::bytes(self.size.x);
        let mut mask = vec![0u8; span];
        for x in r.position.x..r.end().x {
            mask[x as usize / 8] |= 0x80 >> (x % 8);
        }

        for row in self.data.as_mut_slice()[r.position.y as usize * span..r.end().y as usize * span]
            .chunks_exact_mut(span)
        {
            for (a, &b) in row.iter_mut().zip(&mask) {
                *a |= b;
            }
        }
    }

    #[func]
    pub fn fill(&mut self, v: bool) {
        self.data.fill(if v { 0xFF } else { 0 });
        if v {
            Self::clear_padding(&mut self.data, self.size.x);
        }
    }

    #[func]
    pub fn flip_x(&mut self) {
        let span = Self::bytes(self.size.x);
        if span == 0 {
            return;
        }
        let pad = -self.size.x & 7;
        for row in self.data.as_mut_slice().chunks_exact_mut(span) {
            row.reverse();
            for byte in row.iter_mut() {
                *byte = byte.reverse_bits();
            }
            if pad != 0 {
                for i in 0..span - 1 {
                    row[i] = row[i] << pad | row[i + 1] >> (8 - pad);
                }
                row[span - 1] <<= pad;
            }
        }
    }

    #[func]
    pub fn flip_y(&mut self) {
        let span = Self::bytes(self.size.x);
        if span == 0 {
            return;
        }
        let (rows0, rows1) = self
            .data
            .as_mut_slice()
            .split_at_mut(self.size.y as usize / 2 * span);
        for (row0, row1) in rows0
            .chunks_exact_mut(span)
            .zip(rows1.rchunks_exact_mut(span))
        {
            row0.swap_with_slice(row1);
        }
    }

    #[func]
    pub fn transpose(&mut self) {
        let size = Vector2i::new(self.size.y, self.size.x);
        let w0 = Self::bytes(self.size.x);
        let w1 = Self::bytes(size.x);
        let mut data = PackedByteArray::new();
        data.resize(Self::vbytes(size));

        let data0 = self.data.as_slice();
        let data1 = data.as_mut_slice();
        for by in 0..w1 {
            for bx in 0..w0 {
                let mut block = [0u8; 8];
                for (i, b) in block.iter_mut().enumerate() {
                    if let Some(&v) = data0.get((8 * by + i) * w0 + bx) {
                        *b = v;
                    }
                }
                let mut x = u64::from_be_bytes(block);
                let t = (x ^ (x >> 7)) & 0x00AA_00AA_00AA_00AA;
                x ^= t ^ (t << 7);
                let t = (x ^ (x >> 14)) & 0x0000_CCCC_0000_CCCC;
                x ^= t ^ (t << 14);
                let t = (x ^ (x >> 28)) & 0x0000_0000_F0F0_F0F0;
                x ^= t ^ (t << 28);
                for (i, &b) in x.to_be_bytes().iter().enumerate() {
                    if let Some(d) = data1.get_mut((8 * bx + i) * w1 + by) {
                        *d = b;
                    }
                }
            }
        }

        self.size = size;
        self.data = data;
    }

    #[func]
    pub fn rotate_cw(&mut self) {
        self.flip_y();
        self.transpose();
    }

    #[func]
    pub fn rotate_ccw(&mut self) {
        self.transpose();
        self.flip_y();
    }

    #[func]
    pub fn to_image(&self) -> Option<Gd<Image>> {
        const LUT: [u128; 256] = {
            let mut t = [0u128; 256];
            let mut b = 0;
            while b < 256 {
                let mut i = 0;
                while i < 8 {
                    t[b] |= 0xFF << (120 - 16 * i);
                    if b & (0x80 >> i) != 0 {
                        t[b] |= 0xFF << (112 - 16 * i);
                    }
                    i += 1;
                }
                b += 1;
            }
            t
        };

        if self.size.x == 0 || self.size.y == 0 {
            return None;
        }
        let w = self.size.x as usize;
        let mut data = PackedByteArray::new();
        data.resize(w * 2 * self.size.y as usize);

        for (px, row) in data
            .as_mut_slice()
            .chunks_exact_mut(w * 2)
            .zip(self.data.as_slice().chunks_exact(Self::bytes(self.size.x)))
        {
            let (chunks, rem) = px.as_chunks_mut();
            for (bs, &b) in chunks.iter_mut().zip(row) {
                *bs = LUT[b as usize].to_be_bytes();
            }
            if let Some(&b) = row.get(w / 8) {
                for (i, p) in rem.as_chunks_mut().0.iter_mut().enumerate() {
                    *p = [0xFF, 0u8.wrapping_sub((b >> (7 - i)) & 1)];
                }
            }
        }

        Image::create_from_data(self.size.x, self.size.y, false, image::Format::LA8, &data)
    }

    fn index(size: Vector2i, p: Vector2i) -> Option<(usize, u8)> {
        Rect2i::new(Vector2i::ZERO, size)
            .contains_point(p)
            .then(|| {
                (
                    Self::bytes(size.x) * p.y as usize + p.x as usize / 8,
                    0x80 >> (p.x % 8),
                )
            })
    }

    #[inline]
    fn vbytes(size: Vector2i) -> usize {
        Self::bytes(size.x) * size.y as usize
    }

    #[inline]
    fn bytes(n: i32) -> usize {
        (n as usize).div_ceil(8)
    }

    fn clear_padding(data: &mut PackedByteArray, w: i32) {
        if w % 8 == 0 {
            return;
        }
        let span = Self::bytes(w);
        for last in data.as_mut_slice().iter_mut().skip(span - 1).step_by(span) {
            *last &= 0xFF << (-w & 7);
        }
    }
}
