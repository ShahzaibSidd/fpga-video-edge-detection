import cv2
import json
import numpy as np
import os


# Hardware pipeline latency, in pixels, before valid_out is first asserted.
# Must match PIPELINE_DELAY in rtl/sobel_top.sv = (2 * SCREEN_WIDTH) + 2.
PIPELINE_DELAY = (2 * 640) + 2

def _load_meta(meta_path, width, height):
    """Load the stream metadata sidecar, falling back to a single frame."""
    if os.path.exists(meta_path):
        with open(meta_path) as m:
            meta = json.load(m)
        return (
            meta.get("width", width),
            meta.get("height", height),
            meta.get("frame_count", 1),
            float(meta.get("fps", 30.0)),
        )
    # No metadata: assume one frame (legacy single-frame behaviour).
    return width, height, 1, 30.0

def _read_pixels(input_hex_path):
    """Read the processed pixel stream (one 8-bit hex value per line)."""
    pixels = []
    with open(input_hex_path, "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            pixels.append(int(line, 16))
    return pixels


def hex_to_video(input_hex_path, output_video_path, output_png_path,
                 width=640, height=480):
    if not os.path.exists(input_hex_path):
        print(f"Error: Could not open {input_hex_path}")
        return

    meta_path = os.path.join(os.path.dirname(input_hex_path), "..", "input",
                             "stream_meta.json")
    meta_path = os.path.normpath(meta_path)
    width, height, frame_count, fps = _load_meta(meta_path, width, height)
    frame_size = width * height

    pixels = _read_pixels(input_hex_path)
    if not pixels:
        print(f"Error: {input_hex_path} contained no pixel data.")
        return

    # The output stream is the input stream delayed by PIPELINE_DELAY pixels
    # (valid_out stays high once asserted, with no per-frame gaps). Re-align by
    # prepending that many zeros so output index i maps back to input index i.
    aligned = np.concatenate([
        np.zeros(PIPELINE_DELAY, dtype=np.uint8),
        np.array(pixels, dtype=np.uint8),
    ])

    # Pad or trim to a whole number of frames.
    total_needed = frame_count * frame_size
    if len(aligned) < total_needed:
        aligned = np.concatenate([
            aligned,
            np.zeros(total_needed - len(aligned), dtype=np.uint8),
        ])
    else:
        aligned = aligned[:total_needed]

    os.makedirs(os.path.dirname(output_video_path), exist_ok=True)

    # Always write a PNG of the first frame (handy single-frame sanity check).
    first_frame = aligned[:frame_size].reshape((height, width))
    cv2.imwrite(output_png_path, first_frame)

    if frame_count <= 1:
        print(f"Single frame detected. Wrote image to {output_png_path}")
        return

    # Write the full video. mp4v is widely available with stock OpenCV builds.
    fourcc = cv2.VideoWriter_fourcc(*"mp4v")
    writer = cv2.VideoWriter(output_video_path, fourcc, fps, (width, height),
                             isColor=False)
    if not writer.isOpened():
        print(f"Error: Could not open VideoWriter for {output_video_path}")
        return

    for k in range(frame_count):
        start = k * frame_size
        frame = aligned[start:start + frame_size].reshape((height, width))
        writer.write(frame)

    writer.release()
    print(f"Success! Wrote {frame_count} frames @ {fps:.3f} fps "
          f"to {output_video_path}")
    print(f"First-frame preview written to {output_png_path}")


if __name__ == "__main__":
    # Resolve paths relative to the project root (the parent of scripts/),
    # so the script works regardless of the current working directory.
    PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    INPUT_PATH = os.path.join(PROJECT_ROOT, "data", "output", "frame_out.hex")
    VIDEO_PATH = os.path.join(PROJECT_ROOT, "data", "output", "frame_out.mp4")
    PNG_PATH = os.path.join(PROJECT_ROOT, "data", "output", "frame_out.png")

    hex_to_video(INPUT_PATH, VIDEO_PATH, PNG_PATH)
