import cv2
import os

def video_to_hex(input_video_path, output_hex_path, target_width=640, target_height=480):
    # 1. Open the video file
    cap = cv2.VideoCapture(input_video_path)

    if not cap.isOpened():
        print(f"Error: Could not open {input_video_path}")
        return

    # 2. Read the first frame
    ret, frame = cap.read()
    if not ret:
        print("Error: Could not read frame from video.")
        return

    # 3. Resize to your FPGA's target resolution (VGA is 640x480)
    resized_frame = cv2.resize(frame, (target_width, target_height))

    # 4. Convert from RGB Color to 8-bit Grayscale
    gray_frame = cv2.cvtColor(resized_frame, cv2.COLOR_BGR2GRAY)

    # 5. Flatten the 2D matrix into a 1D continuous stream (like a video cable)
    pixel_stream = gray_frame.flatten()

    # 6. Write the pixels to a hex text file
    os.makedirs(os.path.dirname(output_hex_path), exist_ok=True)

    with open(output_hex_path, 'w') as f:
        for pixel in pixel_stream:
            # Write each pixel as a 2-character hex value followed by a newline (e.g., "A5\n")
            f.write(f"{pixel:02X}\n")

    print(f"Success! Wrote {len(pixel_stream)} pixels to {output_hex_path}")
    print(f"Resolution: {target_width}x{target_height}")

    cap.release()

if __name__ == "__main__":
    # Ensure these match the project directory structure
    INPUT_PATH = "../data/input/raw_video.mp4" 
    OUTPUT_PATH = "../data/input/frame_in.hex"

    video_to_hex(INPUT_PATH, OUTPUT_PATH)
