import cv2
import mediapipe as mp
import json

# Initialize MediaPipe Pose
mp_pose = mp.solutions.pose
pose = mp_pose.Pose()
mp_drawing = mp.solutions.drawing_utils

# Load video file
video_path = "TiklosBoyFig4.mp4"  # Change this to your video
cap = cv2.VideoCapture(video_path)

# List of landmark IDs to match app.py
LANDMARK_IDS = [0, 11, 12, 23, 24, 27, 28]

pose_data = []
frame_count = 0
max_frames = 300  # Process up to 300 frames

while cap.isOpened() and frame_count < max_frames:
    ret, frame = cap.read()
    if not ret:
        break

    # Process every 5th frame only
    if frame_count % 5 == 0:
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        result = pose.process(rgb_frame)

        frame_landmarks = {"frame": frame_count, "landmarks": []}
        if result.pose_landmarks:
            # Build a dict for quick lookup
            detected = {i: lm for i, lm in enumerate(result.pose_landmarks.landmark)}
            for id in LANDMARK_IDS:
                lm = detected.get(id)
                if lm:
                    frame_landmarks["landmarks"].append({
                        "id": id,
                        "x": round(lm.x, 4),
                        "y": round(lm.y, 4),
                        "z": round(lm.z, 4)
                    })
                else:
                    # If not detected, fill with zeros
                    frame_landmarks["landmarks"].append({
                        "id": id,
                        "x": 0.0,
                        "y": 0.0,
                        "z": 0.0
                    })
        else:
            # No landmarks detected, fill all with zeros
            for id in LANDMARK_IDS:
                frame_landmarks["landmarks"].append({
                    "id": id,
                    "x": 0.0,
                    "y": 0.0,
                    "z": 0.0
                })

        pose_data.append(frame_landmarks)

    frame_count += 1

cap.release()

# Save to JSON
with open("landmarks/TiklosBoyFig4.json", "w") as json_file:
    json.dump(pose_data, json_file, indent=2)

print("Pose data with X, Y, Z saved as TiklosBoyFig4.json")
