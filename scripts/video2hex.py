import cv2
import json
import os


def video_to_hex(input_video_path, output_hex_path, target_width=640,
                 target_height=480, max_frames=0):
    # 1. Open the video file
    cap = cv2.VideoCapture(input_video_path)

    if not cap.isOpened():
        print(f"Error: Could not open {input_video_path}")
        return

    fps = cap.get(cv2.CAP_PROP_FPS)
    if not fps or fps <= 0:
        fps = 30.0  # sensible fallback if the container doesn't report fps

    os.makedirs(os.path.dirname(output_hex_path), exist_ok=True)

    # 2. Stream every frame into one continuous hex file, back to back.
    #    The hardware pipeline is a continuous pixel stream, so frames are
    #    simply concatenated; hex2video.py slices them apart afterwards using
    #    the metadata sidecar written below.
    frame_count = 0
    frame_size = target_width * target_height

    with open(output_hex_path, "w") as f:
        while True:
            ret, frame = cap.read()
            if not ret:
                break  # end of video

            # Resize to the FPGA's target resolution (VGA is 640x480)
            resized_frame = cv2.resize(frame, (target_width, target_height))

            # Convert from BGR color to 8-bit grayscale
            gray_frame = cv2.cvtColor(resized_frame, cv2.COLOR_BGR2GRAY)

            # Flatten the 2D matrix into a 1D continuous stream (like a video cable)
            pixel_stream = gray_frame.flatten()

            # Write each pixel as a 2-character hex value followed by a newline
            f.write("".join(f"{pixel:02X}\n" for pixel in pixel_stream))

            frame_count += 1
            if max_frames and frame_count >= max_frames:
                break

    cap.release()

    if frame_count == 0:
        print("Error: Could not read any frames from video.")
        return

    # 3. Write a metadata sidecar so downstream stages know how to slice the
    #    stream back into frames and rebuild a video at the right frame rate.
    meta_path = os.path.join(os.path.dirname(output_hex_path), "stream_meta.json")
    meta = {
        "width": target_width,
        "height": target_height,
        "frame_size": frame_size,
        "frame_count": frame_count,
        "fps": fps,
    }
    with open(meta_path, "w") as m:
        json.dump(meta, m, indent=2)

    print(f"Success! Wrote {frame_count} frames "
          f"({frame_count * frame_size} pixels) to {output_hex_path}")
    print(f"Resolution: {target_width}x{target_height} @ {fps:.3f} fps")
    print(f"Metadata written to {meta_path}")


if __name__ == "__main__":
    # Resolve paths relative to the project root (the parent of scripts/),
    # so the script works regardless of the current working directory.
    PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    INPUT_PATH = os.path.join(PROJECT_ROOT, "data", "input", "raw_video.mp4")
    OUTPUT_PATH = os.path.join(PROJECT_ROOT, "data", "input", "frame_in.hex")

    # Set max_frames to a small number (e.g. 10) for quick test runs,
    # or 0 to process the entire video.
    video_to_hex(INPUT_PATH, OUTPUT_PATH, max_frames=0)
