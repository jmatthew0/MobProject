import json
import os
from flask import Flask, request, jsonify
from flask_cors import CORS
import psycopg2
import bcrypt
from supabase import create_client, Client
from dotenv import load_dotenv
import cv2
import mediapipe as mp
import numpy as np
from fastdtw import fastdtw
from scipy.spatial.distance import euclidean

# Load environment variables
load_dotenv()

app = Flask(__name__)
CORS(app)

# Supabase Configuration
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# PostgreSQL Database Connection
DATABASE_URL = os.getenv("DATABASE_URL")

def get_db_connection():
    return psycopg2.connect(DATABASE_URL)

UPLOAD_FOLDER = os.path.join(os.path.dirname(__file__), 'uploads')
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

DANCE_POSES_FILE = os.path.join(os.path.dirname(__file__), 'dance_poses', ''
'.json')

LANDMARK_IDS = [0, 11, 12, 13, 14, 15, 16, 23, 24, 25, 26, 27, 28]  # Match xyz.py
LANDMARK_NAMES = {
    0: "Head",
    11: "Left Shoulder",
    12: "Right Shoulder",
    13: "Left Elbow",
    14: "Right Elbow",
    15: "Left Wrist",
    16: "Right Wrist",
    23: "Left Hip",
    24: "Right Hip",
    25: "Left Knee",
    26: "Right Knee",
    27: "Left Ankle",
    28: "Right Ankle"
}

def load_dance_poses():
    try:
        with open(DANCE_POSES_FILE, 'r') as file:
            dance_data = json.load(file)

        print(f"✅ Loaded {len(dance_data)} dance poses")

        for pose in dance_data:
            if isinstance(pose, dict) and "landmarks" in pose:
                for landmark in pose["landmarks"]:
                    landmark["z"] = landmark.get("z", 0.0) or 0.0
            else:
                print(f"⚠️ Invalid pose format: {pose}")

        return dance_data
    except Exception as e:
        print(f"❌ Error loading dance poses: {e}")
        return []

dance_poses = load_dance_poses()
dance_poses = [
    pose for pose in dance_poses
    if isinstance(pose, dict) and "landmarks" in pose and pose["landmarks"]
]

@app.route('/signup', methods=['POST'])
def signup():
    try:
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')
        username = data.get('username')

        if not email or not password or not username:
            return jsonify({"error": "All fields are required"}), 400

        # Check if username or email already exists in your users table
        try:
            conn = get_db_connection()
            cursor = conn.cursor()
            cursor.execute("SELECT id FROM users WHERE username = %s", (username,))
            if cursor.fetchone():
                cursor.close()
                conn.close()
                return jsonify({"error": "Username already exists"}), 400
            cursor.execute("SELECT id FROM users WHERE email = %s", (email,))
            if cursor.fetchone():
                cursor.close()
                conn.close()
                return jsonify({"error": "Email already exists"}), 400
            cursor.close()
            conn.close()
        except Exception as db_error:
            print(f"❌ DB Check Error: {db_error}")
            return jsonify({"error": "Database error"}), 500

        # Supabase Auth signup with display_name
        auth_response = supabase.auth.sign_up({
            "email": email,
            "password": password,
            "options": {
                "data": {
                    "username": username,
                    "display_name": username
                }
            }
        })

        if getattr(auth_response, "error", None):
            return jsonify({"error": auth_response.error.message}), 400

        # Insert into your own users table
        user_id = auth_response.user.id
        try:
            conn = get_db_connection()
            cursor = conn.cursor()
            # Check if user already exists
            cursor.execute("SELECT id FROM users WHERE id = %s", (user_id,))
            exists = cursor.fetchone()
            if exists:
                # Update username if user exists
                cursor.execute(
                    "UPDATE users SET username = %s WHERE id = %s",
                    (username, user_id)
                )
            else:
                # Insert new user
                cursor.execute(
                    "INSERT INTO users (id, username, email, profile_picture_url) VALUES (%s, %s, %s, %s)",
                    (user_id, username, email, "default_profile_picture_url")
                )
            conn.commit()
            cursor.close()
            conn.close()
        except Exception as db_error:
            print(f"❌ DB Insert Error: {db_error}")
            # Optionally, return a warning but not an error to the client
            return jsonify({"message": "User registered in Supabase, but not in your table.", "db_error": str(db_error)}), 201

        return jsonify({"message": "User registered successfully"}), 201

    except Exception as e:
        print(f"❌ Signup Error: {e}")
        return jsonify({"error": "An error occurred"}), 500

@app.route('/login', methods=['POST'])
def login():
    try:
        data = request.get_json()
        email, password = data.get('email'), data.get('password')

        if not email or not password:
            return jsonify({"error": "Both email and password are required"}), 400

        # Use Supabase Auth to sign in
        auth_response = supabase.auth.sign_in_with_password({"email": email, "password": password})

        if getattr(auth_response, "error", None):
            return jsonify({"error": "Email or password is incorrect"}), 400

        # Return session or user info
        return jsonify({"message": "Login successful", "user": auth_response.user.id}), 200

    except Exception as e:
        import traceback
        print(f"❌ Login Error: {e}")
        traceback.print_exc()
        return jsonify({"error": f"An error occurred: {str(e)}"}), 500


@app.route('/upload', methods=['POST'])
def upload_video():
    try:
        file = request.files.get('file')
        figure = request.form.get('figure')
        print(f"DEBUG: Received figure file: {figure}")  # <-- Add this line

        if not file or file.filename == '':
            return jsonify({'error': 'No file selected'}), 400
        if not figure:
            return jsonify({'error': 'No figure specified'}), 400

        video_path = os.path.join(app.config['UPLOAD_FOLDER'], file.filename)
        file.save(video_path)
        print(f"📂 Video uploaded: {video_path}")

        # Load the correct JSON for this figure
        figure_json_path = os.path.join(os.path.dirname(__file__), 'dance_poses', figure)
        if not os.path.exists(figure_json_path):
            return jsonify({'error': f'Figure JSON not found: {figure}'}), 400

        # ADD THIS LINE FOR NOTIFICATION
        print(f"🔎 Comparing uploaded video to reference: {figure_json_path}")

        with open(figure_json_path, 'r') as f:
            dance_poses = json.load(f)
            for pose in dance_poses:
                if isinstance(pose, dict) and "landmarks" in pose:
                    for landmark in pose["landmarks"]:
                        landmark["z"] = landmark.get("z", 0.0) or 0.0

        # After processing the video
        accuracy, feedback = process_video(video_path, dance_poses)
        score = round(accuracy, 2) if accuracy is not None else 0  # Always a number
        # Determine dance_name from figure filename
        dance_name = None
        if figure.lower().startswith('tiklostut'):
            dance_name = 'Tiklos: Step-by-Step'
        elif figure.lower().startswith('tiklos'):
            dance_name = 'Tiklos'
        elif figure.lower().startswith('binungey'):
            dance_name = 'Binungey'
        elif figure.lower().startswith('pahid'):
            dance_name = 'Pahid'
        elif figure.lower().startswith('suakusua'):
            dance_name = 'Sua Ku Sua'
        # Increment the stat if it's a simulated dance
        if dance_name:
            increment_simulated_dance_stat(dance_name)

        # Save user history
        user_id = request.form.get('user_id')
        figure_name = figure  # from the form

        if user_id and dance_name and figure_name:
            try:
                conn = get_db_connection()
                cursor = conn.cursor()
                cursor.execute(
                    "INSERT INTO user_history (user_id, dance_name, figure_name, score) VALUES (%s, %s, %s, %s)",
                    (user_id, dance_name, figure_name, score)
                )
                conn.commit()
                cursor.close()
                conn.close()
                print(f"✅ Saved user history for {user_id} - {dance_name} - {figure_name} - {score}")
            except Exception as e:
                print(f"❌ Error saving user history: {e}")

        if score >= 81:
            rating = "Excellent"
            color = "green"
        elif score >= 41:
            rating = "Good"
            color = "orange"
        else:
            rating = "Needs Improvement"
            color = "red"

        return jsonify({
            'accuracy': score,
            'rating': rating,
            'color': color,
            'message': f'Your dance accuracy is {score}%. {rating}!',
            'feedback': {
                'worst_landmarks': feedback['worst_landmarks'],
                'frame_feedback': feedback['frame_feedback'],
                'angle_errors': feedback.get('angle_errors', {}),
                'body_part_feedback': feedback.get('body_part_feedback', []),
                'no_body_detected': feedback.get('no_body_detected', False)
            }
        })

    except Exception as e:
        print(f'❌ Upload Error: {e}')
        return jsonify({'error': 'An error occurred during video upload'}), 500

def extract_pose_landmarks(landmarks):
    if not landmarks or not landmarks.landmark:
        return []

    pose = []
    visible_count = 0
    for i in LANDMARK_IDS:
        lm = landmarks.landmark[i]
        if lm.visibility > 0.5:
            x, y, z = lm.x, lm.y, lm.z or 0.0
            visible_count += 1
        else:
            x, y, z = 0.0, 0.0, 0.0
        pose.append((x, y, z))
    # Only return pose if enough landmarks are visible
    if visible_count < len(LANDMARK_IDS) // 2:
        return []
    return pose

def dtw_score(user_poses, ref_poses):
    user_vecs = [np.array(normalize_pose(p)).flatten() for p in user_poses]
    ref_vecs = [np.array(normalize_pose(p)).flatten() for p in ref_poses]
    distance, path = fastdtw(user_vecs, ref_vecs, dist=euclidean)
    max_possible = len(path)
    score = max(0, 1 - (distance / max_possible))
    return score * 100

def process_video(video_path, dance_poses):
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        print("❌ Error: Could not open video.")
        return 0.0, {
            "worst_landmarks": [],
            "frame_feedback": [],
            "angle_errors": {},
            "body_part_feedback": [],
            "video_error": True,
            "message": "Could not process the video file. Please try recording again."
        }

    mp_pose = mp.solutions.pose
    pose = mp_pose.Pose()
    user_poses = []
    user_poses_flipped = []

    frame_skip = 5  # Match xyz.py (was 2)
    frame_idx = 0
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
        if frame_idx % frame_skip != 0:
            frame_idx += 1
            continue

        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        # Process original
        results = pose.process(frame_rgb)
        if results.pose_landmarks:
            extracted = extract_pose_landmarks(results.pose_landmarks)
            if extracted:  # Only add if valid
                user_poses.append(extracted)
        # Process flipped
        frame_rgb_flipped = cv2.flip(frame_rgb, 1)
        results_flipped = pose.process(frame_rgb_flipped)
        if results_flipped.pose_landmarks:
            extracted_flipped = extract_pose_landmarks(results_flipped.pose_landmarks)
            if extracted_flipped:  # Only add if valid
                user_poses_flipped.append(extracted_flipped)

        frame_idx += 1

    cap.release()
    print(f"📊 Total valid user poses extracted: {len(user_poses)} (normal), {len(user_poses_flipped)} (flipped)")

    # Strict check: require at least 5 valid frames in either normal or flipped
    if len(user_poses) < 5 and len(user_poses_flipped) < 5:
        print("❌ No valid body detected in video.")
        return 0.0, {
            "worst_landmarks": [],
            "frame_feedback": [],
            "angle_errors": {},
            "body_part_feedback": [],
            "no_body_detected": True,
            "message": "No body detected in the video. Please ensure you're visible in the frame and try again."
        }

    # --- MOVEMENT THRESHOLD CHECK ---
    def movement_amount(poses):
        if len(poses) < 2:
            return 0.0
        diffs = [
            np.linalg.norm(np.array(normalize_pose(poses[i])) - np.array(normalize_pose(poses[i-1])))
            for i in range(1, len(poses))
        ]
        return np.mean(diffs)

    min_movement = 1.0  # <-- This is the threshold

    user_movement = movement_amount(user_poses)
    user_movement_flipped = movement_amount(user_poses_flipped)

    if user_movement < min_movement and user_movement_flipped < min_movement:
        print("❌ Not enough movement detected.")
        return 0.0, {
            "worst_landmarks": [],
            "frame_feedback": [],
            "angle_errors": {},
            "body_part_feedback": [],
            "no_movement_detected": True,
            "message": "Not enough movement detected. Please perform the dance with more movement."
        }

    ref_poses = [extract_landmarks_by_id(pose["landmarks"], LANDMARK_IDS) for pose in dance_poses]

    # DTW for best alignment
    score_normal = dtw_score(user_poses, ref_poses) if user_poses else 0.0
    score_flipped = dtw_score(user_poses_flipped, ref_poses) if user_poses_flipped else 0.0

    # Resample for feedback (to same length)
    def resample_for_feedback(user_poses, ref_poses):
        min_len = min(len(user_poses), len(ref_poses))
        if min_len == 0:
            return [], []
        return resample_poses(user_poses, min_len), resample_poses(ref_poses, min_len)

    if score_flipped > score_normal:
        print("🔄 Using flipped video for best score.")
        user_poses_best, ref_poses_best = resample_for_feedback(user_poses_flipped, ref_poses)
        score, feedback = compare_dance(user_poses_best, ref_poses_best)
        return score, feedback
    else:
        user_poses_best, ref_poses_best = resample_for_feedback(user_poses, ref_poses)
        score, feedback = compare_dance(user_poses_best, ref_poses_best)
        return score, feedback

def compare_dance(user_poses, ref_poses):
    total_score, matched_frames = 0.0, 0
    landmark_errors = {lid: [] for lid in LANDMARK_IDS}
    frame_feedback = []
    frame_scores = []

    # --- Angle heuristics ---
    angle_errors = []

    for i, (user_pose, ref_pose) in enumerate(zip(user_poses, ref_poses)):
        user_pose_arr = np.array(normalize_pose(user_pose))
        ref_pose_arr = np.array(normalize_pose(ref_pose))
        differences = np.linalg.norm(user_pose_arr - ref_pose_arr, axis=1)
        avg_difference = np.mean(differences)
        threshold = 0.9
        if avg_difference < threshold:
            score = 1.0
        else:
            score = max(0, 1 - (avg_difference - threshold))
        errors = {LANDMARK_IDS[idx]: float(diff) for idx, diff in enumerate(differences)}
        total_score += score
        matched_frames += 1
        frame_feedback.append(errors)
        frame_scores.append(avg_difference)
        for lid, err in errors.items():
            landmark_errors[lid].append(err)

        # --- Angle error computation ---
        user_angles = get_joint_angles(user_pose)
        ref_angles = get_joint_angles(ref_pose)
        frame_angle_errors = {}
        for k in user_angles:
            if k in ref_angles:
                frame_angle_errors[k] = abs(user_angles[k] - ref_angles[k])
        angle_errors.append(frame_angle_errors)

    avg_landmark_errors = {LANDMARK_NAMES.get(lid, str(lid)): np.mean(vals) if vals else 0.0
                           for lid, vals in landmark_errors.items()}
    worst_landmarks = sorted(avg_landmark_errors.items(), key=lambda x: -x[1])

    # Only return top 3 worst frames
    sorted_feedback = sorted(zip(frame_scores, frame_feedback), key=lambda x: -x[0])
    top_feedback = [fb for _, fb in sorted_feedback[:3]]

    # --- Angle feedback: average error per angle ---
    avg_angle_errors = {}
    if angle_errors:
        angle_keys = angle_errors[0].keys()
        for k in angle_keys:
            vals = [ae.get(k, 0.0) for ae in angle_errors if k in ae]
            if vals:
                avg_angle_errors[k] = float(np.mean(vals))

    # --- Body part specific, time-stamped feedback ---
    fps = 30  # Or get from video metadata if available
    frame_skip = 2  # Should match your process_video
    body_part_feedback = []
    for idx, (frame_score, frame) in enumerate(sorted(zip(frame_scores, frame_feedback), key=lambda x: -x[0])[:3]):
        if not frame:
            continue
        worst_lid = max(frame, key=frame.get)
        part_name = LANDMARK_NAMES.get(worst_lid, f"Landmark {worst_lid}")
        time_sec = (idx * frame_skip) / fps
        body_part_feedback.append(
            f"At {time_sec:.1f}s, your {part_name.lower()} needs improvement."
        )

    feedback = {
        "worst_landmarks": worst_landmarks[:3],
        "frame_feedback": top_feedback,
        "angle_errors": avg_angle_errors,
        "body_part_feedback": body_part_feedback  # <-- Add this line
    }

    return (total_score / matched_frames) * 100 if matched_frames else 0.0, feedback

def compare_poses(pose1, pose2, return_errors=False):
    if not pose1 or not pose2:
        return (0.0, {}) if return_errors else 0.0

    pose1 = np.array(normalize_pose(pose1))
    pose2 = np.array(normalize_pose(pose2))

    min_length = min(len(pose1), len(pose2))
    pose1, pose2 = pose1[:min_length], pose2[:min_length]

    differences = np.linalg.norm(pose1 - pose2, axis=1)
    avg_difference = np.mean(differences)
    threshold = 0.9  # More lenient
    similarity_score = max(0, 1 - (avg_difference / threshold))

    # Per-landmark error (by index in LANDMARK_IDS order)
    errors = {list(LANDMARK_IDS)[idx]: float(diff) for idx, diff in enumerate(differences)}

    if return_errors:
        return similarity_score, errors
    else:
        return similarity_score

def normalize_pose(pose):
    if not pose or len(pose) < 2:
        return []

    # Use shoulders (index 1 and 2) as center
    center_x = (pose[1][0] + pose[2][0]) / 2
    center_y = (pose[1][1] + pose[2][1]) / 2
    center_z = (pose[1][2] + pose[2][2]) / 2

    # Use distance between shoulders for scale (3D)
    scale = np.linalg.norm(np.array(pose[1]) - np.array(pose[2]))
    if scale == 0:
        scale = 1.0

    normalized_pose = []
    for (x, y, z) in pose:
        norm_x = (x - center_x) / scale
        norm_y = (y - center_y) / scale
        norm_z = (z - center_z) / scale
        normalized_pose.append((norm_x, norm_y, norm_z))
    return normalized_pose

def increment_simulated_dance_stat(dance_name):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO simulated_dance_stats (dance_name, performed_count)
            VALUES (%s, 1)
            ON CONFLICT (dance_name)
            DO UPDATE SET performed_count = simulated_dance_stats.performed_count + 1
        """, (dance_name,))
        conn.commit()
        cursor.close()
        cursor.close()
    except Exception as e:
        print(f"❌ Error incrementing dance stat: {e}")


@app.route('/user_history', methods=['GET'])
def get_user_history():
    user_id = request.args.get('user_id')
    if not user_id:
        return jsonify({'error': 'Missing user_id'}), 400
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            SELECT dance_name, figure_name, score, attempted_at
            FROM user_history
            WHERE user_id = %s
            ORDER BY attempted_at DESC
            LIMIT 20
        """, (user_id,))
        latest_scores = cursor.fetchall()
        cursor.close()
        conn.close()
        return jsonify({
            'latest_scores': [
                {
                    'dance_name': row[0],
                    'figure_name': row[1],
                    'score': row[2],
                    'attempted_at': row[3].isoformat()
                } for row in latest_scores
            ]
        })
    except Exception as e:
        print(f"❌ Error fetching user history: {e}")
        return jsonify({'error': 'Database error'}), 500

@app.route('/feedback', methods=['POST'])
def submit_feedback():
    try:
        data = request.get_json()
        user_id = data.get('user_id')
        figure_name = data.get('figure_name')
        rating = data.get('rating')  # 1-5, as per your UI
        text_feedback = data.get('text_feedback', '')  # Optional

        if not user_id or not figure_name or rating is None:
            return jsonify({'error': 'Missing required fields'}), 400

        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO user_feedback (user_id, figure_name, rating, text_feedback) VALUES (%s, %s, %s, %s)",
            (user_id, figure_name, rating, text_feedback)
        )
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({'message': 'Feedback submitted!'}), 201
    except Exception as e:
        print(f"❌ Error saving feedback: {e}")
        return jsonify({'error': 'Database error'}), 500

def extract_landmarks_by_id(landmarks, ids):
    id_map = {lm.get('id'): lm for lm in landmarks if 'id' in lm}
    return [
        (id_map.get(i, {'x': 0.0, 'y': 0.0, 'z': 0.0}).get('x', 0.0),
         id_map.get(i, {'x': 0.0, 'y': 0.0, 'z': 0.0}).get('y', 0.0),
         id_map.get(i, {'x': 0.0, 'y': 0.0, 'z': 0.0}).get('z', 0.0))
        for i in LANDMARK_IDS
    ]

# --- ANGLE HEURISTICS UTILS ---

def calculate_angle(a, b, c):
    """Calculate the angle (in degrees) at point b given three points a, b, c."""
    a = np.array(a)
    b = np.array(b)
    c = np.array(c)
    ba = a - b
    bc = c - b
    cosine_angle = np.dot(ba, bc) / (np.linalg.norm(ba) * np.linalg.norm(bc) + 1e-8)
    angle = np.arccos(np.clip(cosine_angle, -1.0, 1.0))
    return np.degrees(angle)

def get_joint_angles(pose):
    """Given a pose (list of (x, y, z)), return a dict of key joint angles."""
    angles = {}
    try:
        # Left side: LShoulder-LHip-LAnkle
        angles['left_hip'] = calculate_angle(pose[1], pose[3], pose[5])
        # Right side: RShoulder-RHip-RAnkle
        angles['right_hip'] = calculate_angle(pose[2], pose[4], pose[6])
        # Shoulder angle (nose-shoulder-hip)
        angles['left_shoulder'] = calculate_angle(pose[0], pose[1], pose[3])
        angles['right_shoulder'] = calculate_angle(pose[0], pose[2], pose[4])
        # Hip spread (LHip-Nose-RHip)
        angles['hip_spread'] = calculate_angle(pose[3], pose[0], pose[4])
    except Exception as e:
        pass
    return angles

def resample_poses(poses, target_length):
    """
    Resample a list of poses to the target length by linear interpolation of indices.
    """
    if len(poses) == target_length:
        return poses
    if len(poses) == 0 or target_length == 0:
        return []
    idxs = np.linspace(0, len(poses) - 1, target_length).astype(int)
    return [poses[i] for i in idxs]

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5003)  # Change port if needed