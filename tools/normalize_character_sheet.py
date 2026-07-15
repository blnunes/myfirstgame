#!/usr/bin/env python3
"""Normalize a transparent 4x4 character sheet without redrawing its frames."""

from __future__ import annotations

import argparse
from collections import deque
from dataclasses import dataclass
from pathlib import Path
from statistics import median

from PIL import Image


GRID_SIZE = 4
DEFAULT_CELL_SIZE = 313
DEFAULT_SAFE_MARGIN = 12
ALPHA_COMPONENT_THRESHOLD = 32
MINIMUM_COMPONENT_PIXELS = 1000
SOFT_EDGE_PADDING = 2


@dataclass(frozen=True)
class Component:
    pixel_count: int
    box: tuple[int, int, int, int]

    @property
    def center(self) -> tuple[float, float]:
        left, top, right, bottom = self.box
        return ((left + right) / 2.0, (top + bottom) / 2.0)

    @property
    def width(self) -> int:
        return self.box[2] - self.box[0]

    @property
    def height(self) -> int:
        return self.box[3] - self.box[1]


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Detect the 16 opaque character components, center each one inside "
            "its 4x4 cell, and enforce a safe transparent margin."
        )
    )
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--cell-size", type=int, default=DEFAULT_CELL_SIZE)
    parser.add_argument("--safe-margin", type=int, default=DEFAULT_SAFE_MARGIN)
    return parser.parse_args()


def find_components(image: Image.Image) -> list[Component]:
    alpha = image.getchannel("A")
    width, height = image.size
    pixels = alpha.load()
    visited = bytearray(width * height)
    components: list[Component] = []

    for start_y in range(height):
        for start_x in range(width):
            start_index = start_y * width + start_x
            if visited[start_index] or pixels[start_x, start_y] <= ALPHA_COMPONENT_THRESHOLD:
                continue

            queue: deque[tuple[int, int]] = deque([(start_x, start_y)])
            visited[start_index] = 1
            pixel_count = 0
            minimum_x = maximum_x = start_x
            minimum_y = maximum_y = start_y

            while queue:
                x, y = queue.popleft()
                pixel_count += 1
                minimum_x = min(minimum_x, x)
                maximum_x = max(maximum_x, x)
                minimum_y = min(minimum_y, y)
                maximum_y = max(maximum_y, y)

                for neighbor_x, neighbor_y in (
                    (x - 1, y),
                    (x + 1, y),
                    (x, y - 1),
                    (x, y + 1),
                ):
                    if not (0 <= neighbor_x < width and 0 <= neighbor_y < height):
                        continue
                    neighbor_index = neighbor_y * width + neighbor_x
                    if visited[neighbor_index]:
                        continue
                    if pixels[neighbor_x, neighbor_y] <= ALPHA_COMPONENT_THRESHOLD:
                        continue
                    visited[neighbor_index] = 1
                    queue.append((neighbor_x, neighbor_y))

            if pixel_count >= MINIMUM_COMPONENT_PIXELS:
                components.append(
                    Component(
                        pixel_count,
                        (
                            minimum_x,
                            minimum_y,
                            maximum_x + 1,
                            maximum_y + 1,
                        ),
                    )
                )

    return components


def arrange_components(components: list[Component]) -> list[list[Component]]:
    expected_count = GRID_SIZE * GRID_SIZE
    if len(components) != expected_count:
        raise ValueError(
            f"Expected {expected_count} character components, found {len(components)}."
        )

    by_vertical_position = sorted(components, key=lambda component: component.center[1])
    rows: list[list[Component]] = []
    for row_index in range(GRID_SIZE):
        start = row_index * GRID_SIZE
        row = sorted(
            by_vertical_position[start : start + GRID_SIZE],
            key=lambda component: component.center[0],
        )
        rows.append(row)
    return rows


def expanded_box(
    box: tuple[int, int, int, int],
    image_size: tuple[int, int],
) -> tuple[int, int, int, int]:
    left, top, right, bottom = box
    width, height = image_size
    return (
        max(0, left - SOFT_EDGE_PADDING),
        max(0, top - SOFT_EDGE_PADDING),
        min(width, right + SOFT_EDGE_PADDING),
        min(height, bottom + SOFT_EDGE_PADDING),
    )


def normalize_sheet(
    image: Image.Image,
    rows: list[list[Component]],
    cell_size: int,
    safe_margin: int,
) -> Image.Image:
    canvas_size = GRID_SIZE * cell_size
    output = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    maximum_content_size = cell_size - 2 * safe_margin

    for row_index, row in enumerate(rows):
        maximum_height = max(component.height for component in row)
        original_bottoms = [
            component.box[3] - row_index * cell_size for component in row
        ]
        target_bottom = round(median(original_bottoms))
        target_bottom = max(target_bottom, maximum_height + safe_margin)
        target_bottom = min(target_bottom, cell_size - safe_margin)

        for column_index, component in enumerate(row):
            source_box = expanded_box(component.box, image.size)
            frame = image.crop(source_box)
            alpha_box = frame.getchannel("A").getbbox()
            if alpha_box is None:
                raise ValueError(f"Frame {row_index},{column_index} is empty.")
            frame = frame.crop(alpha_box)

            if frame.width > maximum_content_size or frame.height > maximum_content_size:
                raise ValueError(
                    f"Frame {row_index},{column_index} is {frame.width}x{frame.height}; "
                    f"maximum with a {safe_margin}px margin is "
                    f"{maximum_content_size}x{maximum_content_size}."
                )

            local_x = (cell_size - frame.width) // 2
            local_y = target_bottom - frame.height
            local_y = max(safe_margin, min(local_y, cell_size - safe_margin - frame.height))
            destination = (
                column_index * cell_size + local_x,
                row_index * cell_size + local_y,
            )
            output.alpha_composite(frame, destination)

    return output


def validate_cell_margins(
    image: Image.Image,
    cell_size: int,
    safe_margin: int,
) -> None:
    for row_index in range(GRID_SIZE):
        for column_index in range(GRID_SIZE):
            frame = image.crop(
                (
                    column_index * cell_size,
                    row_index * cell_size,
                    (column_index + 1) * cell_size,
                    (row_index + 1) * cell_size,
                )
            )
            box = frame.getchannel("A").getbbox()
            if box is None:
                raise ValueError(f"Frame {row_index},{column_index} is empty after normalization.")
            left, top, right, bottom = box
            margins = (left, cell_size - right, top, cell_size - bottom)
            if min(margins) < safe_margin:
                raise ValueError(
                    f"Frame {row_index},{column_index} has margins {margins}; "
                    f"minimum is {safe_margin}px."
                )


def main() -> None:
    arguments = parse_arguments()
    expected_size = GRID_SIZE * arguments.cell_size
    image = Image.open(arguments.input).convert("RGBA")
    if image.size != (expected_size, expected_size):
        raise ValueError(
            f"Expected {expected_size}x{expected_size}, found "
            f"{image.width}x{image.height}."
        )

    components = find_components(image)
    rows = arrange_components(components)
    normalized = normalize_sheet(
        image,
        rows,
        arguments.cell_size,
        arguments.safe_margin,
    )
    validate_cell_margins(normalized, arguments.cell_size, arguments.safe_margin)

    arguments.output.parent.mkdir(parents=True, exist_ok=True)
    normalized.save(arguments.output, format="PNG", optimize=True)
    print(
        f"Wrote {arguments.output} with {len(components)} frames and "
        f">={arguments.safe_margin}px margins."
    )


if __name__ == "__main__":
    main()
