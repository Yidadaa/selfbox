import { expect, test } from "vitest";
import { imageRows } from "../layout";

test.each([
  [0, []],
  [1, [1]],
  [2, [2]],
  [3, [1, 2]],
  [4, [2, 2]],
  [5, [3, 2]],
  [6, [3, 3]],
  [7, [3, 2, 2]],
  [8, [3, 3, 2]],
  [9, [3, 3, 3]],
  [10, [3, 3, 2, 2]],
] as const)(
  "lays out %i photos in balanced rows without losing their order",
  (count, sizes) => {
    const images = Array.from({ length: count }, (_, index) => ({
      file: `photo-${index}.jpg`,
      width: 800,
      height: 600,
    }));
    const rows = imageRows(images);
    expect(rows.map((row) => row.length)).toEqual(sizes);
    expect(rows.flat()).toEqual(images);
  },
);
