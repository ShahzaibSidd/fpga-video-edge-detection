import cv2
import numpy as np
import os


def hex_to_image(input_hex_path, output_image_path, width=640, height=480):
    # 1. Read the processed pixel stream (one 8-bit hex value per line)
    if not os.path.exists(input_hex_path):
        print(f"Error: Could not open {input_hex_path}")
        return

    pixels = []
    with open(input_hex_path, "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            pixels.append(int(line, 16))

    if not pixels:
        print(f"Error: {input_hex_path} contained no pixel data.")
        return

    # 2. Pad or trim to exactly one frame. The Sobel pipeline drops a couple of
    #    border rows, so the stream may be slightly shorter than width*height.
    frame_size = width * height
    if len(pixels) < frame_size:
        pixels.extend([0] * (frame_size - len(pixels)))
    elif len(pixels) > frame_size:
        pixels = pixels[:frame_size]

    # 3. Reshape the 1D stream back into a 2D grayscale image
    frame = np.array(pixels, dtype=np.uint8).reshape((height, width))

    # 4. Write the image to disk
    os.makedirs(os.path.dirname(output_image_path), exist_ok=True)
    ok = cv2.imwrite(output_image_path, frame)
    if not ok:
        print(f"Error: Failed to write image to {output_image_path}")
        return

    print(f"Success! Reconstructed {width}x{height} image at {output_image_path}")


if __name__ == "__main__":
    # Resolve paths relative to the project root (the parent of scripts/),
    # so the script works regardless of the current working directory.
    PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    INPUT_PATH = os.path.join(PROJECT_ROOT, "data", "output", "frame_out.hex")
    OUTPUT_PATH = os.path.join(PROJECT_ROOT, "data", "output", "frame_out.png")

    hex_to_image(INPUT_PATH, OUTPUT_PATH)
