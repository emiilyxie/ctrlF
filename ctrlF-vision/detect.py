import cv2
import torch
import numpy as np
import time
import requests
from ultralytics import YOLO
from transformers import DPTForDepthEstimation, DPTFeatureExtractor

print("Loading models...")

### 📌 Step 1: Load YOLOv8 for Object Detection
model_yolo = YOLO("yolov8n.pt")

### 📌 Step 2: Load MiDaS for Depth Estimation
model_midas = DPTForDepthEstimation.from_pretrained("Intel/dpt-large")
feature_extractor = DPTFeatureExtractor.from_pretrained("Intel/dpt-large")

# Camera Parameters (Adjust these based on your camera setup)
FOCAL_LENGTH = 600  # Approximate focal length in pixels (tune this)
CAMERA_POSITION = (0, 0, 0)  # (X, Y, Z) in meters (Assume 1.5m high on a desk)

# Flask API URL for database storage
API_URL = "http://127.0.0.1:5000/store-object"  # Change this to your backend server

print("Models loaded. Starting video stream...")

# Open camera
cap = cv2.VideoCapture(0)

### 📌 Function: Convert 2D Object Position to 3D World Coordinates
def screen_to_world(x_screen, y_screen, depth, focal_length, image_width, image_height):
    camera_center_x = image_width / 2
    camera_center_y = image_height / 2
    world_x = (x_screen - camera_center_x) * depth / focal_length
    world_y = (y_screen - camera_center_y) * depth / focal_length
    world_z = depth
    return world_x, world_y, world_z

### 📌 Function: Estimate Depth from Image
def estimate_depth(image):
    inputs = feature_extractor(images=image, return_tensors="pt")
    with torch.no_grad():
        depth_map = model_midas(**inputs).predicted_depth.squeeze().numpy()
    return depth_map

### 📌 Function: Send Object Position to Database
def store_object(name, x, y, z):
    data = {
        "name": name, 
        "x": float(x), 
        "y": float(y), 
        "z": float(z)}
    try:
        response = requests.post(API_URL, json=data)
        print(f"[INFO] Sent to DB: {data}, Response: {response.status_code}")
    except Exception as e:
        print(f"[ERROR] Failed to send data: {e}")

capture_interval = 2  # Capture every 2 seconds
last_capture_time = time.time()

### 📌 Main Loop: Process Video Stream
while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break

    current_time = time.time()
    if current_time - last_capture_time < capture_interval:
        continue

    last_capture_time = current_time

    image_height, image_width, _ = frame.shape

    # 📌 Step 1: Run YOLO Object Detection
    results = model_yolo(frame)

    # 📌 Step 2: Estimate Depth
    depth_map = estimate_depth(frame)
    depth_map_resized = cv2.resize(depth_map, (image_width, image_height))


    # 📌 Step 3: Process Detected Objects
    for result in results:
        for box in result.boxes:
            x1, y1, x2, y2 = map(int, box.xyxy[0])  # Bounding box coordinates
            label = model_yolo.names[int(box.cls)]  # Object name
            confidence = box.conf[0].item()  # Confidence score

            # 📌 Get Center of the Bounding Box
            obj_center_x = (x1 + x2) // 2
            obj_center_y = (y1 + y2) // 2

            # 📌 Estimate Depth at the Object’s Center
            depth = depth_map_resized[obj_center_y, obj_center_x] / 255.0 * 5.0  # Normalize & Scale (adjust as needed)

            # 📌 Convert 2D to 3D World Coordinates
            world_x, world_y, world_z = screen_to_world(obj_center_x, obj_center_y, depth, FOCAL_LENGTH, image_width, image_height)

            # 📌 Adjust for Camera Position
            world_x += CAMERA_POSITION[0]
            world_y += CAMERA_POSITION[1]
            world_z += CAMERA_POSITION[2]

            # 📌 Store Object Position in Database
            store_object(label, world_x, world_y, world_z)

            # 📌 Draw Bounding Box and Label
            cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
            cv2.putText(frame, f"{label} ({confidence:.2f})", (x1, y1 - 10),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)

    # Show Video Feed with Detections
    cv2.imshow("YOLO + Depth Detection", frame)

    if cv2.waitKey(1) & 0xFF == ord("q"):
        break

cap.release()
cv2.destroyAllWindows()
